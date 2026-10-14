#!/bin/bash
# ==============================================================================
# Script de Pós-Instalação do Void Linux (Cinnamon Desktop - PT_BR)
# ==============================================================================

# Interrompe a execução imediatamente se algum comando retornar erro não tratado
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Verificações de Segurança e Permissões Básicas
# ------------------------------------------------------------------------------

# Identificar o usuário real (mesmo se executado via sudo)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificar privilégios de administrador
if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script deve ser executado com privilégios de root (ou via sudo)."
    echo "Exemplo: sudo ./cinnamon_install_PT_BR.sh"
    exit 1
fi

# Diretório temporário seguro para compilação/extração
TMP_DIR=$(mktemp -d -t void-install-XXXXXX)
# Permissão de travessia: o xdeb roda como usuário comum dentro deste diretório
chmod 755 "$TMP_DIR"

# Função de limpeza executada na saída ou interrupção (Ctrl+C / Erro)
cleanup() {
    local exit_code=$?
    echo -e "\nLimpando arquivos temporários..."
    rm -rf "$TMP_DIR"
    if [ $exit_code -ne 0 ]; then
        echo "O script foi interrompido ou encontrou um erro no processo."
    fi
}
# Correção: apenas EXIT. Com INT/TERM o cleanup rodava duas vezes no Ctrl+C.
trap cleanup EXIT

# Executa um comando como o usuário real (o xdeb não deve ser executado como root)
# -H: garante que o HOME seja o do usuário real (essencial para xdg-mime e xdeb)
run_as_user() {
    if [ "$REAL_USER" != "root" ]; then
        sudo -H -u "$REAL_USER" "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 2. Configuração de Shell e Sudoers
# ------------------------------------------------------------------------------
echo "==> Configurando shell do root e permissões do sudo..."
chsh -s /bin/bash root

if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

# ------------------------------------------------------------------------------
# 3. Planos de Fundo e Scripts de Suporte
# ------------------------------------------------------------------------------
echo "==> Copiando recursos e planos de fundo do repositório..."
mkdir -p /usr/share/backgrounds/

if compgen -G "$SCRIPT_DIR/*.jpg" > /dev/null; then
    cp "$SCRIPT_DIR"/*.jpg /usr/share/backgrounds/
else
    echo "Aviso: Nenhuma imagem .jpg encontrada em $SCRIPT_DIR"
fi

if [ -f "$SCRIPT_DIR/mount_disks.sh" ]; then
    cp "$SCRIPT_DIR/mount_disks.sh" /usr/bin/
    chmod +x /usr/bin/mount_disks.sh
fi

# ------------------------------------------------------------------------------
# 4. Atualização de Repositórios e Atualização Inicial
# ------------------------------------------------------------------------------
echo "==> Sincronizando e ativando repositórios adicionais do Void Linux..."
xbps-install -Syu
xbps-install -y void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
xbps-install -Syu

# ------------------------------------------------------------------------------
# 5. Instalação e Ativação de Serviços Principais
# ------------------------------------------------------------------------------
echo "==> Instalando utilitários essenciais, rede e login..."
xbps-install -y nano NetworkManager polkit gnome-keyring dbus elogind

# Remoção sanitária de serviços conflitantes de rede
for svc in wpa_supplicant dhcpcd dhcpcd-eth0 sshd; do
    if [ -L "/var/service/$svc" ] || [ -e "/var/service/$svc" ]; then
        rm -f "/var/service/$svc"
    fi
done

# Ativação segura de serviços (evita erro de link duplicado)
for svc in NetworkManager dbus elogind; do
    if [ ! -L "/var/service/$svc" ]; then
        ln -s "/etc/sv/$svc" /var/service/
    fi
done

# Configuração de Laptop (Detecção / Pergunta ao usuário)
clear
echo "Você está instalando em um Desktop ou Laptop/Notebook?"
echo "0) Desktop"
echo "1) Laptop/Notebook"
read -r -p "Selecione uma opção [0-1]: " tipo_maquina

if [ "$tipo_maquina" = "1" ]; then
    echo "Configurando ignoramento do fechamento da tampa em elogind..."
    sed -i 's/.*HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/elogind/logind.conf
    sed -i 's/.*HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/elogind/logind.conf
    sed -i 's/.*HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/elogind/logind.conf
fi

# ------------------------------------------------------------------------------
# 6. Servidor de Áudio e Bluetooth
# ------------------------------------------------------------------------------
echo "==> Instalando PipeWire, WirePlumber, RTKit e suporte a Bluetooth..."
xbps-install -y pipewire wireplumber rtkit pavucontrol pulsemixer libspa-bluetooth blueman bluez-cups

# ------------------------------------------------------------------------------
# 7. Driver de Vídeo NVIDIA (Opcional)
# ------------------------------------------------------------------------------
clear
echo "Drivers NVIDIA disponíveis:"
echo "1) Driver NVIDIA proprietário + Suporte 32-bits (nvidia nvidia-libs-32bit)"
echo "0) Ignorar instalação"
read -r -p "Por favor, selecione (1 ou 0): " opt_nvidia

if [ "$opt_nvidia" = "1" ]; then
    echo "Instalando drivers NVIDIA..."
    xbps-install -y nvidia nvidia-libs-32bit
fi

# Componentes e compatibilidade Steam (32-bits)
xbps-install -y libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit

# ------------------------------------------------------------------------------
# 8. Interface Gráfica Cinnamon e Pacotes do Sistema
# ------------------------------------------------------------------------------
echo "==> Instalando XOrg, Cinnamon Desktop e Ferramentas..."
xbps-install -y xorg octoxbps cinnamon-all xdg-desktop-portal xdg-desktop-portal-gtk \
                xdg-user-dirs xdg-user-dirs-gtk xdg-utils wget binutils xz hicolor-icon-theme

# Nemo (padrão do Cinnamon) + File Roller e suporte a arquivos RAR
# (incluindo protegidos por senha, via unrar) e 7-Zip, com integração no Nemo
echo "==> Instalando Nemo, File Roller e suporte a compactação (RAR/7Zip)..."
xbps-install -y nemo file-roller nemo-fileroller unrar p7zip

# Garante o Nemo como gerenciador de arquivos padrão do usuário
run_as_user xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

# Correção no Spices.py do Cinnamon
if [ -f "/usr/share/cinnamon/cinnamon-settings/bin/Spices.py" ]; then
    echo "Aplicando patch de correção em Spices.py..."
    python3 -c "
import os
path = '/usr/share/cinnamon/cinnamon-settings/bin/Spices.py'
with open(path, 'r') as f:
    content = f.read()
old_code = 'totalSize = int(response.headers.get(\'content-length\'))'
new_code = 'content_length = response.headers.get(\'content-length\')\n            totalSize = int(content_length) if content_length is not None else -1'
if old_code in content:
    with open(path, 'w') as f:
        f.write(content.replace(old_code, new_code))
"
fi

# Suporte a Impressão e Dispositivos
echo "==> Instalando suporte a impressão e sistemas de arquivos..."
xbps-install -y cups cups-filters gutenprint system-config-printer \
                exfat-utils fuse-exfat gvfs-afc gvfs-mtp gvfs-smb udisks2 ntfs-3g gptfdisk bluez GPaste \
                gnome-disk-utility topgrade noto-fonts-cjk noto-fonts-emoji noto-fonts-ttf noto-fonts-ttf-extra

for svc in cupsd bluetoothd; do
    if [ ! -L "/var/service/$svc" ]; then
        ln -s "/etc/sv/$svc" /var/service/
    fi
done

# Softwares do Usuário
echo "==> Instalando aplicativos de usuário..."
xbps-install -y firefox xfce4-terminal firefox-i18n-pt-BR gnome-calendar qalculate-gtk \
                smplayer qt5-styleplugins qt5ct qt6ct flameshot fastfetch numlockx gnome-screenshot

if ! grep -q "^QT_QPA_PLATFORMTHEME=" /etc/environment; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment
fi

# ------------------------------------------------------------------------------
# 9. Personalização Opcional do XFCE Terminal
# ------------------------------------------------------------------------------
clear
echo "Deseja aplicar a personalização visual no xfce4-terminal (transparência e fonte)?"
echo "S) Sim"
echo "N) Não"

personalizar_terminal=""
while true; do
    read -r -p "Por favor, selecione [S/N]: " input_val
    if [[ "$input_val" =~ ^[sS]$ ]]; then
        personalizar_terminal="sim"
        break
    elif [[ "$input_val" =~ ^[nN]$ ]]; then
        personalizar_terminal="nao"
        break
    else
        echo "Opção inválida! Digite S para Sim ou N para Não."
    fi
done

if [ "$personalizar_terminal" = "sim" ]; then
    echo "Configurando perfil visual do xfce4-terminal..."
    mkdir -p "$REAL_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
    cat << 'EOF' > "$REAL_HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml"
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xfce4-terminal" version="1.0">
  <property name="background-mode" type="string" value="TERMINAL_BACKGROUND_TRANSPARENT"/>
  <property name="background-darkness" type="double" value="0"/>
  <property name="font-name" type="string" value="DejaVu Sans Mono Bold 12"/>
  <property name="cell-height-scale" type="double" value="1"/>
  <property name="color-selection-use-default" type="bool" value="false"/>
  <property name="color-bold-use-default" type="bool" value="false"/>
  <property name="color-selection" type="string" value="#0000aaaa0000"/>
  <property name="color-bold" type="string" value="#aaaa00000000"/>
  <property name="color-use-theme" type="bool" value="true"/>
  <property name="misc-cursor-shape" type="string" value="TERMINAL_CURSOR_SHAPE_IBEAM"/>
  <property name="misc-cursor-blinks" type="bool" value="true"/>
  <property name="misc-show-unsafe-paste-dialog" type="bool" value="false"/>
  <property name="color-palette" type="string" value="rgb(0,0,0);rgb(170,0,0);rgb(0,170,0);rgb(170,85,0);rgb(0,0,170);rgb(170,0,170);rgb(0,170,170);rgb(170,170,170);rgb(85,85,85);rgb(255,85,85);rgb(85,255,85);rgb(255,255,85);rgb(85,85,255);rgb(255,85,255);rgb(85,255,255);rgb(255,255,255)"/>
</channel>
EOF
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/xfce4"
fi

# ------------------------------------------------------------------------------
# 10. Bulk Renamer (Bulky) via xdeb
# ------------------------------------------------------------------------------
echo "==> Instalando o Bulky (renomeador em massa do Linux Mint) via xdeb..."

# Dependências do xdeb
xbps-install -y binutils tar curl xbps xz

# Diretório de build (propriedade do usuário real, pois o xdeb não roda como root)
BULKY_DIR="$TMP_DIR/bulky-build"
mkdir -p "$BULKY_DIR"
chown -R "$REAL_USER:$REAL_USER" "$BULKY_DIR"

# Download do .deb do Bulky e do xdeb (com HTTPS)
run_as_user bash -c "
    set -e
    cd '$BULKY_DIR'
    echo 'Baixando bulky_4.2_all.deb...'
    wget -q 'http://packages.linuxmint.com/pool/main/b/bulky/bulky_4.2_all.deb'
    echo 'Baixando o xdeb...'
    curl -sLO 'https://github.com/xdeb-org/xdeb/releases/latest/download/xdeb'
    chmod +x xdeb
"

# Torna o xdeb global
mv "$BULKY_DIR/xdeb" /usr/local/bin/xdeb

# Converte o .deb em pacote xbps (gera o repositório local 'binpkgs')
echo "Convertendo o Bulky (.deb -> xbps) com o xdeb..."
run_as_user bash -c "cd '$BULKY_DIR' && xdeb -Sedf bulky_4.2_all.deb"

# Instala o pacote convertido a partir do repositório local gerado pelo xdeb
if compgen -G "$BULKY_DIR/binpkgs/bulky-*.xbps" > /dev/null; then
    echo "Instalando o pacote convertido..."
    xbps-install -y -R "$BULKY_DIR/binpkgs" -i bulky
else
    echo "Erro: o xdeb não gerou o pacote do Bulky em $BULKY_DIR/binpkgs." >&2
    exit 1
fi

# Dependências Python do Bulky (via xbps, sem pip)
echo "Instalando dependências Python (python3-setproctitle, python3-Unidecode)..."
xbps-install -y python3-setproctitle python3-Unidecode

# Compila os schemas do GLib para que o schema 'org.x.bulky' seja reconhecido
echo "Compilando schemas do GLib..."
glib-compile-schemas /usr/share/glib-2.0/schemas/

# ------------------------------------------------------------------------------
# 11. Configurações de Teclado, X11 e Autostart
# ------------------------------------------------------------------------------
mkdir -p /etc/X11/xorg.conf.d
cat << 'EOF' > /etc/X11/xorg.conf.d/30-scrolllock.conf
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "br"
    Option "XkbVariant" "abnt2"
    Option "XkbOptions" "scrolllock:mod3"
EndSection
EOF

# ------------------------------------------------------------------------------
# 12. Download Seguro de Temas do Linux Mint
# ------------------------------------------------------------------------------
echo "==> Baixando e instalando temas, ícones e cursores do Linux Mint..."
mkdir -p "$REAL_HOME/.themes" "$REAL_HOME/.icons"

download_and_extract_deb() {
    local url="$1"
    local pkg_name
    pkg_name=$(basename "$url")

    echo "Baixando $pkg_name..."
    cd "$TMP_DIR"
    wget -q "$url"
    ar x "$pkg_name"
    tar -xf data.tar.xz --wildcards --no-anchored 'usr/share/*'
}

# ATENÇÃO: packages.linuxmint.com NÃO serve os .debs de forma confiável via
# HTTPS (wget/curl falham o handshake). HTTP aqui é INTENCIONAL não troque!
download_and_extract_deb "http://packages.linuxmint.com/pool/main/m/mint-themes/mint-themes_2.4.2_all.deb"
if [ -d "$TMP_DIR/usr/share/themes" ]; then
    cp -r "$TMP_DIR/usr/share/themes/"* "$REAL_HOME/.themes/"
    rm -rf "${TMP_DIR:?}"/*
fi

download_and_extract_deb "http://packages.linuxmint.com/pool/main/m/mint-y-icons/mint-y-icons_1.9.7_all.deb"
if [ -d "$TMP_DIR/usr/share/icons" ]; then
    cp -r "$TMP_DIR/usr/share/icons/"* "$REAL_HOME/.icons/"
    rm -rf "${TMP_DIR:?}"/*
fi

download_and_extract_deb "http://packages.linuxmint.com/pool/main/m/mint-cursor-themes/mint-cursor-themes_1.0.2_all.deb"
if [ -d "$TMP_DIR/usr/share/icons" ]; then
    cp -r "$TMP_DIR/usr/share/icons/"* "$REAL_HOME/.icons/"
    rm -rf "${TMP_DIR:?}"/*
fi

chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.themes" "$REAL_HOME/.icons"

# Script de inicialização do usuário
# set -e: o autostart abaixo só se auto-remove se TODAS as configurações
# aplicarem com sucesso (caso contrário, re-tenta no próximo login)
cat <<EOL > "$REAL_HOME/set-keyboard.sh"
#!/bin/bash
set -e
gsettings set org.cinnamon.desktop.input-sources sources "[('xkb', 'br')]"
gsettings set org.cinnamon.desktop.background picture-uri 'file:///usr/share/backgrounds/cinnamon_background.jpg'

gsettings set org.cinnamon.desktop.interface gtk-theme 'Mint-Y-Dark'
gsettings set org.cinnamon.desktop.wm.preferences theme 'Mint-Y-Dark'
gsettings set org.cinnamon.theme name 'Mint-Y-Dark'
gsettings set org.cinnamon.desktop.interface icon-theme 'Mint-Y'
gsettings set org.cinnamon.desktop.interface cursor-theme 'Mint-Y'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

gsettings set org.cinnamon.desktop.interface clock-use-24h true
gsettings set org.cinnamon.desktop.interface clock-show-seconds true

rm -f ~/.config/autostart/set-keyboard.desktop
EOL

chmod +x "$REAL_HOME/set-keyboard.sh"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/set-keyboard.sh"

# Formato empilhado do relógio (applet calendar@cinnamon.org)
# O applet não lê chaves globais nem um JSON de nome fixo: cada instância tem
# seu próprio "<instance-id>.json" gerado a partir do settings-schema.json.
# Estratégia dupla: (1) parchear o schema global para novas instalações;
# (2) corrigir instâncias já criadas (re-execuções / home reaproveitado).
# O formato usa uma QUEBRA DE LINHA REAL entre hora e data (é assim que a GUI
# do Cinnamon grava quando se cola o formato em duas linhas): o json.dump do
# Python serializa como "\n", que o applet renderiza como duas linhas no painel.
# Resultado:  %H:%M:%S   (em cima, com segundos)
#             %d/%m/%Y   (embaixo)

# 1) Schema global do applet (afeta apenas instâncias ainda não criadas)
CAL_SCHEMA="/usr/share/cinnamon/applets/calendar@cinnamon.org/settings-schema.json"
if [ -f "$CAL_SCHEMA" ]; then
    python3 - "$CAL_SCHEMA" << 'PYEOF'
import json, sys
path = sys.argv[1]
with open(path) as f:
    schema = json.load(f)
if isinstance(schema.get("use-custom-format"), dict):
    schema["use-custom-format"]["default"] = True
if isinstance(schema.get("custom-format"), dict):
    schema["custom-format"]["default"] = "%H:%M:%S\n%d/%m/%Y"
with open(path, "w") as f:
    json.dump(schema, f, indent=4)
PYEOF
fi

# 2) Instâncias já criadas (ex.: reinstalações sobre o mesmo /home)
CAL_SPICES="$REAL_HOME/.config/cinnamon/spices/calendar@cinnamon.org"
if [ -d "$CAL_SPICES" ]; then
    python3 - "$CAL_SPICES" << 'PYEOF'
import glob, json, sys
for path in glob.glob(sys.argv[1] + "/*.json"):
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception:
        continue
    changed = False
    if isinstance(data.get("use-custom-format"), dict):
        data["use-custom-format"]["value"] = True
        changed = True
    if isinstance(data.get("custom-format"), dict):
        data["custom-format"]["value"] = "%H:%M:%S\n%d/%m/%Y"
        changed = True
    if changed:
        # __md5__ permanece como está: checksum antigo sinaliza edição externa
        # e faz o applet recarregar os valores do disco.
        with open(path, "w") as f:
            json.dump(data, f, indent=4)
PYEOF
fi

# Entradas de Autostart
AUTOSTART_DIR="$REAL_HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat <<EOL > "$AUTOSTART_DIR/set-keyboard.desktop"
[Desktop Entry]
Type=Application
Exec=$REAL_HOME/set-keyboard.sh
Name=Set Mint Customization and Keyboard
Comment=Definir o layout do teclado padrão, temas Mint e formato do relógio após o login
X-GNOME-Autostart-enabled=true
EOL

cat <<EOL > "$AUTOSTART_DIR/octoxbps-notifier.desktop"
[Desktop Entry]
Type=Application
Exec=/bin/octoxbps-notifier
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=OctoXBPS Notifier
EOL

cat <<EOL > "$AUTOSTART_DIR/x11kb-brazil.desktop"
[Desktop Entry]
Type=Application
Exec=/usr/bin/setxkbmap br
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=X11-KB-Brazil
EOL

cat <<EOL > "$AUTOSTART_DIR/automount-udisks2.desktop"
[Desktop Entry]
Type=Application
Exec=/usr/bin/mount_disks.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=X11-automount-udisks2
EOL

cat <<EOL > "$AUTOSTART_DIR/gpaste-daemon.desktop"
[Desktop Entry]
Type=Application
Exec=/usr/bin/gpaste-client daemon
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=GPaste Daemon
EOL

# ------------------------------------------------------------------------------
# CORREÇÃO CRÍTICA: propriedade do ~/.config
# Este script roda como root e os mkdir -p acima podem ter criado o ~/.config
# como root:root. Sem o usuário como dono, o dconf não consegue gravar e TODAS
# as configurações gsettings (tema, fundo, ícones, teclado) falham em silêncio.
# ------------------------------------------------------------------------------
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config"

# ------------------------------------------------------------------------------
# 13. Display Manager (LightDM)
# ------------------------------------------------------------------------------
echo "==> Configurando LightDM..."
xbps-install -y lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

if [ ! -L "/var/service/lightdm" ]; then
    ln -s /etc/sv/lightdm/ /var/service/
fi

cat << 'EOF' > /etc/lightdm/lightdm-gtk-greeter.conf
[greeter]
background=/usr/share/backgrounds/lightdmbackground.jpg
theme-name=Adwaita-dark
icon-theme-name=Adwaita
EOF

cat << 'EOF' > /usr/local/bin/lightdm-greeter-setup.sh
#!/bin/bash
/usr/bin/setxkbmap -option scrolllock:mod3
/usr/bin/numlockx on
EOF
chmod +x /usr/local/bin/lightdm-greeter-setup.sh

mkdir -p /etc/lightdm/lightdm.conf.d
cat << 'EOF' > /etc/lightdm/lightdm.conf.d/60-custom-greeter.conf
[Seat:*]
greeter-setup-script=/usr/local/bin/lightdm-greeter-setup.sh
EOF

# Desbloqueio automático do chaveiro (gnome-keyring) no login via PAM
# Resolve o erro "keyringPrompt: Failed to show modal dialog" do .xsession-errors
if [ -f /etc/pam.d/lightdm ] && ! grep -q pam_gnome_keyring /etc/pam.d/lightdm; then
    sed -i '0,/^auth.*/s//&\nauth        optional    pam_gnome_keyring.so/' /etc/pam.d/lightdm
    printf '%s\n' 'session     optional    pam_gnome_keyring.so auto_start' >> /etc/pam.d/lightdm
fi

# Pipewire Autostart Config
mkdir -p /etc/pipewire/pipewire.conf.d
[ -f /usr/share/examples/wireplumber/10-wireplumber.conf ] && ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
[ -f /usr/share/examples/pipewire/20-pipewire-pulse.conf ] && ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
[ -f /usr/share/applications/pipewire.desktop ] && ln -sf /usr/share/applications/pipewire.desktop /etc/xdg/autostart/

# ------------------------------------------------------------------------------
# 14. Configuração do GRUB
# ------------------------------------------------------------------------------
echo "==> Configurando o GRUB..."
sed -i 's/.*GRUB_BACKGROUND=.*/GRUB_BACKGROUND="\/usr\/share\/void-artwork\/splash.png"/' /etc/default/grub

clear
echo "Deseja pular a contagem do GRUB e iniciar automaticamente?"
echo "Aviso: se você usa um notebook e ele tiver problema de tecla fantasma"
echo "com defeito no firmware e você não quiser confirmar a entrada toda vez,"
echo "é necessário efetuar essa alteração para pular o menu."
echo "1) Sim, iniciar direto e pular tempo"
echo "0) Não, manter contagem padrão e exibir menu"
read -r -p "Por favor, selecione (0 ou 1): " pular_grub

if [ "$tipo_maquina" = "1" ] || [ "$pular_grub" = "1" ]; then
    echo "Aplicando configuração de inicialização direta..."
    sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
else
    echo "Mantendo a contagem padrão do GRUB..."
    sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
fi

if command -v update-grub >/dev/null 2>&1; then
    update-grub
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# ------------------------------------------------------------------------------
# 15. Locale do Sistema (pt_BR.UTF-8)
# ------------------------------------------------------------------------------
echo "==> Configurando locales do sistema..."
sed -i 's/^[[:space:]]*#[[:space:]]*\(pt_BR\.UTF-8[[:space:]]\+UTF-8\)/\1/' /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

touch /etc/locale.conf
{
    echo "LANG=pt_BR.UTF-8"
    echo "LC_TIME=pt_BR.UTF-8"
    echo "LC_COLLATE=C"
} > /etc/locale.conf

if [ -f "$SCRIPT_DIR/10-mount-drives.rules" ]; then
    mkdir -p /etc/polkit-1/rules.d/
    cp "$SCRIPT_DIR/10-mount-drives.rules" /etc/polkit-1/rules.d/
fi

# Garantia final: assegura que os schemas do GLib (incluindo o org.x.bulky)
# continuam compilados, caso algum pacote instalado depois tenha regenerado o cache
glib-compile-schemas /usr/share/glib-2.0/schemas/ > /dev/null 2>&1 || true

echo "=============================================================================="
echo " Concluído! O sistema foi configurado com sucesso e está pronto para reiniciar."
echo "=============================================================================="