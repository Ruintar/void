#!/bin/bash
# ==============================================================================
# Script de Posinstalación de Void Linux (Cinnamon Desktop - ES_ES)
# ==============================================================================

# Detiene la ejecución inmediatamente si algún comando falla
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Verificaciones de Seguridad y Permisos Básicos
# ------------------------------------------------------------------------------

# Identificar el usuario real (incluso si se ejecuta mediante sudo)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificar privilegios de root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Este script debe ejecutarse con privilegios de root (o mediante sudo)."
    echo "Ejemplo: sudo ./cinnamon_install_ES_ES.sh"
    exit 1
fi

# Directorio temporal seguro para la extracción de paquetes
TMP_DIR=$(mktemp -d -t void-install-XXXXXX)

# Función de limpieza ejecutada al salir o interrumpir (Ctrl+C / Error)
cleanup() {
    local exit_code=$?
    echo -e "\nLimpiando archivos temporales..."
    rm -rf "$TMP_DIR"
    if [ $exit_code -ne 0 ]; then
        echo "El script fue interrumpido o encontró un error durante la ejecución."
    fi
}
trap cleanup EXIT INT TERM

# ------------------------------------------------------------------------------
# 2. Configuración de Shell y Sudoers
# ------------------------------------------------------------------------------
echo "==> Configurando el shell de root y los permisos de sudo..."
chsh -s /bin/bash root

if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

# ------------------------------------------------------------------------------
# 3. Fondos de Pantalla y Scripts de Soporte
# ------------------------------------------------------------------------------
echo "==> Copiando recursos y fondos de pantalla del repositorio..."
mkdir -p /usr/share/backgrounds/

if compgen -G "$SCRIPT_DIR/*.jpg" > /dev/null; then
    cp "$SCRIPT_DIR"/*.jpg /usr/share/backgrounds/
else
    echo "Aviso: No se encontraron imágenes .jpg en $SCRIPT_DIR"
fi

if [ -f "$SCRIPT_DIR/mount_disks.sh" ]; then
    cp "$SCRIPT_DIR/mount_disks.sh" /usr/bin/
    chmod +x /usr/bin/mount_disks.sh
fi

# ------------------------------------------------------------------------------
# 4. Sincronización de Repositorios y Actualización Inicial
# ------------------------------------------------------------------------------
echo "==> Sincronizando y activando repositorios adicionales de Void Linux..."
xbps-install -Syu
xbps-install -y void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
xbps-install -Syu

# ------------------------------------------------------------------------------
# 5. Instalación y Activación de Servicios Principales
# ------------------------------------------------------------------------------
echo "==> Instalando utilidades esenciales, red y herramientas de autenticación..."
xbps-install -y nano NetworkManager polkit gnome-keyring dbus elogind

# Eliminación limpia de servicios de red en conflicto
for svc in wpa_supplicant dhcpcd dhcpcd-eth0 sshd; do
    if [ -L "/var/service/$svc" ] || [ -e "/var/service/$svc" ]; then
        rm -f "/var/service/$svc"
    fi
done

# Enlace seguro de servicios (evita errores de enlaces duplicados)
for svc in NetworkManager dbus elogind; do
    if [ ! -L "/var/service/$svc" ]; then
        ln -s "/etc/sv/$svc" /var/service/
    fi
done

# Configuración de Tapa de Portátil
clear
echo "¿Está instalando en un Escritorio (Desktop) o Portátil (Laptop/Notebook)?"
echo "0) Desktop"
echo "1) Laptop/Notebook"
read -r -p "Por favor, seleccione una opción [0-1]: " tipo_maquina

if [ "$tipo_maquina" = "1" ]; then
    echo "Configurando la acción de cierre de tapa en elogind..."
    sed -i 's/.*HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/elogind/logind.conf
    sed -i 's/.*HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/elogind/logind.conf
    sed -i 's/.*HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/elogind/logind.conf
fi

# ------------------------------------------------------------------------------
# 6. Servidor de Audio y Bluetooth
# ------------------------------------------------------------------------------
echo "==> Instalando PipeWire, WirePlumber y soporte Bluetooth..."
xbps-install -y pipewire wireplumber pavucontrol pulsemixer libspa-bluetooth blueman bluez-cups

# ------------------------------------------------------------------------------
# 7. Controlador de Video NVIDIA (Opcional)
# ------------------------------------------------------------------------------
clear
echo "Controladores NVIDIA disponibles:"
echo "1) Controlador propietario NVIDIA + Soporte de 32 bits (nvidia nvidia-libs-32bit)"
echo "0) Omitir instalación"
read -r -p "Por favor, seleccione (1 o 0): " opt_nvidia

if [ "$opt_nvidia" = "1" ]; then
    echo "Instalando controladores NVIDIA..."
    xbps-install -y nvidia nvidia-libs-32bit
fi

# Compatibilidad con Steam y librerías de 32 bits
xbps-install -y libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit

# ------------------------------------------------------------------------------
# 8. Entorno de Escritorio Cinnamon y Herramientas del Sistema
# ------------------------------------------------------------------------------
echo "==> Instalando XOrg, Cinnamon Desktop y Herramientas..."
xbps-install -y xorg octoxbps cinnamon-all xdg-desktop-portal xdg-desktop-portal-gtk \
                xdg-user-dirs xdg-user-dirs-gtk xdg-utils wget binutils xz hicolor-icon-theme

# Parche para Spices.py en Cinnamon
if [ -f "/usr/share/cinnamon/cinnamon-settings/bin/Spices.py" ]; then
    echo "Aplicando parche de corrección en Spices.py..."
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

# Soporte de Impresión y Sistemas de Archivos
echo "==> Instalando soporte para impresoras y herramientas adicionales..."
xbps-install -y cups cups-filters gutenprint system-config-printer gnome-system-tools users-admin \
                exfat-utils fuse-exfat gvfs-afc gvfs-mtp gvfs-smb udisks2 ntfs-3g gptfdisk bluez GPaste \
                topgrade noto-fonts-cjk noto-fonts-emoji noto-fonts-ttf noto-fonts-ttf-extra

for svc in cupsd bluetoothd; do
    if [ ! -L "/var/service/$svc" ]; then
        ln -s "/etc/sv/$svc" /var/service/
    fi
done

# Aplicaciones de Usuario
echo "==> Instalando software de usuario..."
xbps-install -y firefox xfce4-terminal firefox-i18n-es-ES gnome-calendar qalculate-gtk \
                smplayer qt5-styleplugins qt5ct qt6ct flameshot fastfetch numlockx

if ! grep -q "^QT_QPA_PLATFORMTHEME=" /etc/environment; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment
fi

# ------------------------------------------------------------------------------
# 9. Personalización Opcional de XFCE Terminal
# ------------------------------------------------------------------------------
clear
echo "¿Desea aplicar la personalización visual en xfce4-terminal (transparencia y fuente)?"
echo "S) Sí"
echo "N) No"

personalizar_terminal=""
while true; do
    read -r -p "Por favor, seleccione [S/N]: " input_val
    if [[ "$input_val" =~ ^[sS]$ ]]; then
        personalizar_terminal="si"
        break
    elif [[ "$input_val" =~ ^[nN]$ ]]; then
        personalizar_terminal="no"
        break
    else
        echo "¡Opción inválida! Escriba S para Sí o N para No."
    fi
done

if [ "$personalizar_terminal" = "si" ]; then
    echo "Configurando perfil visual de xfce4-terminal..."
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
# 10. Selección del Administrador de Archivos (Nemo, Thunar o Nautilus)
# ------------------------------------------------------------------------------
clear
echo "=============================================================================="
echo "                 SELECCIÓN DEL ADMINISTRADOR DE ARCHIVOS"
echo "=============================================================================="
echo "Cinnamon instala Nemo por defecto. Elija qué administrador desea utilizar:"
echo ""
echo "0) Mantener Nemo (Predeterminado de Cinnamon)"
echo "   -> Nota: En Void Linux, Nemo no incluye 'Bulky' (renombrador masivo)"
echo "      ya que depende de módulos de X-apps que aún no están totalmente portados a Void."
echo ""
echo "1) Thunar (XFCE) [RECOMENDADO]"
echo "   -> Incluye integración con xarchiver y unrar."
echo "   -> Si se selecciona, Nemo y file-roller serán eliminados (vía -Fy)."
echo ""
echo "2) Nautilus (GNOME)"
echo "   -> Aviso: Nautilus no viene con unrar preinstalado. E incluso si decide"
echo "      instalar unrar posteriormente para gestionar archivos .rar,"
echo "      no puede extraer archivos .rar protegidos con contraseña."
echo "   -> Si se selecciona, Nemo será eliminado (vía -Fy)."
echo "=============================================================================="
read -r -p "Por favor, seleccione una opción [0-2]: " fm_choice

case "$fm_choice" in
    1)
        echo "Instalando Thunar y herramientas de compresión..."
        xbps-install -y Thunar thunar-archive-plugin xarchiver unrar

        echo "Eliminando Nemo y file-roller de forma forzada (-Fy)..."
        xbps-remove -Fy nemo file-roller

        xdg-mime default thunar.desktop inode/directory application/x-gnome-saved-search
        ;;
    2)
        echo "Instalando Nautilus..."
        xbps-install -y nautilus

        echo "Eliminando Nemo de forma forzada (-Fy)..."
        xbps-remove -Fy nemo

        xdg-mime default org.gnome.Nautilus.desktop inode/directory application/x-gnome-saved-search
        ;;
    0|*)
        echo "Manteniendo Nemo como el administrador de archivos predeterminado."
        ;;
esac
sleep 1

# ------------------------------------------------------------------------------
# 11. Configuración de Teclado, X11 y Autostart
# ------------------------------------------------------------------------------
mkdir -p /etc/X11/xorg.conf.d
cat << 'EOF' > /etc/X11/xorg.conf.d/30-scrolllock.conf
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "es"
    Option "XkbOptions" "scrolllock:mod3"
EndSection
EOF

# ------------------------------------------------------------------------------
# 12. Descarga Segura de Temas de Linux Mint
# ------------------------------------------------------------------------------
echo "==> Descargando e instalando temas, iconos y cursores de Linux Mint..."
mkdir -p "$REAL_HOME/.themes" "$REAL_HOME/.icons"

download_and_extract_deb() {
    local url="$1"
    local pkg_name
    pkg_name=$(basename "$url")

    echo "Descargando $pkg_name..."
    cd "$TMP_DIR"
    wget -q "$url"
    ar x "$pkg_name"
    tar -xf data.tar.xz --wildcards --no-anchored 'usr/share/*'
}

download_and_extract_deb "http://packages.linuxmint.com/pool/main/m/mint-themes/mint-themes_2.4.2_all.deb"
if [ -d "$TMP_DIR/usr/share/themes" ]; then
    cp -r "$TMP_DIR/usr/share/themes/"* "$REAL_HOME/.themes/"
    rm -rf "${TMP_DIR:?}"/*
fi

download_and_extract_deb "http://packages.linuxmint.com/pool/main/m/mint-y-icons/mint-y-icons_1.9.6_all.deb"
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

# Script de Inicialización de Usuario
cat <<EOL > "$REAL_HOME/set-keyboard.sh"
#!/bin/bash
gsettings set org.cinnamon.desktop.input-sources sources "[('xkb', 'es')]"
gsettings set org.cinnamon.desktop.background picture-uri 'file:///usr/share/backgrounds/cinnamon_background.jpg'

gsettings set org.cinnamon.desktop.interface gtk-theme 'Mint-Y-Dark'
gsettings set org.cinnamon.desktop.wm.preferences theme 'Mint-Y-Dark'
gsettings set org.cinnamon.theme name 'Mint-Y-Dark'
gsettings set org.cinnamon.desktop.interface icon-theme 'Mint-Y'
gsettings set org.cinnamon.desktop.interface cursor-theme 'Mint-Y'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

gsettings set org.cinnamon.desktop.interface clock-use-24h true
gsettings set org.cinnamon.desktop.interface clock-show-seconds true
gsettings set org.cinnamon.muffin.window-picker-style custom-format
gsettings set org.cinnamon.desktop.interface clock-custom-format '%H:%M:%S\n%d/%m/%Y'

rm -f ~/.config/autostart/set-keyboard.desktop
EOL

chmod +x "$REAL_HOME/set-keyboard.sh"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/set-keyboard.sh"

# Entradas de Autostart
AUTOSTART_DIR="$REAL_HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat <<EOL > "$AUTOSTART_DIR/set-keyboard.desktop"
[Desktop Entry]
Type=Application
Exec=$REAL_HOME/set-keyboard.sh
Name=Set Mint Customization and Keyboard
Comment=Configurar distribución de teclado en español, temas Mint y formato de reloj tras iniciar sesión
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

cat <<EOL > "$AUTOSTART_DIR/x11kb-spanish.desktop"
[Desktop Entry]
Type=Application
Exec=/usr/bin/setxkbmap es
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=X11-KB-Spanish
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

chown -R "$REAL_USER:$REAL_USER" "$AUTOSTART_DIR"

# ------------------------------------------------------------------------------
# 13. Administrador de Inicio de Sesión (LightDM)
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

# Pipewire Autostart Config
mkdir -p /etc/pipewire/pipewire.conf.d
[ -f /usr/share/examples/wireplumber/10-wireplumber.conf ] && ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
[ -f /usr/share/examples/pipewire/20-pipewire-pulse.conf ] && ln -sf /usr/share/examples/wireplumber/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
[ -f /usr/share/applications/pipewire.desktop ] && ln -sf /usr/share/applications/pipewire.desktop /etc/xdg/autostart/

# ------------------------------------------------------------------------------
# 14. Configuración de GRUB
# ------------------------------------------------------------------------------
echo "==> Configurando GRUB..."
sed -i 's/.*GRUB_BACKGROUND=.*/GRUB_BACKGROUND="\/usr\/share\/void-artwork\/splash.png"/' /etc/default/grub

clear
echo "¿Desea omitir la cuenta atrás de GRUB e iniciar automáticamente?"
echo "Aviso: si usa un portátil y tiene un problema de teclas fantasma"
echo "con un defecto de firmware y no desea confirmar la entrada cada vez,"
echo "es necesario aplicar este cambio para omitir el menú."
echo "1) Sí, iniciar directamente y omitir tiempo"
echo "0) No, mantener cuenta atrás predeterminada y mostrar menú"
read -r -p "Por favor, seleccione (0 o 1): " pular_grub

if [ "$tipo_maquina" = "1" ] || [ "$pular_grub" = "1" ]; then
    echo "Aplicando configuración de inicio directo..."
    sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
else
    echo "Manteniendo la cuenta atrás predeterminada de GRUB..."
    sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
fi

if command -v update-grub >/dev/null 2>&1; then
    update-grub
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# ------------------------------------------------------------------------------
# 15. Locales del Sistema (es_ES.UTF-8)
# ------------------------------------------------------------------------------
echo "==> Configurando los locales del sistema..."
sed -i 's/^[[:space:]]*#[[:space:]]*\(es_ES\.UTF-8[[:space:]]\+UTF-8\)/\1/' /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

touch /etc/locale.conf
{
    echo "LANG=es_ES.UTF-8"
    echo "LC_TIME=es_ES.UTF-8"
    echo "LC_COLLATE=C"
} > /etc/locale.conf

if [ -f "$SCRIPT_DIR/10-mount-drives.rules" ]; then
    mkdir -p /etc/polkit-1/rules.d/
    cp "$SCRIPT_DIR/10-mount-drives.rules" /etc/polkit-1/rules.d/
fi

echo "=============================================================================="
echo " ¡Instalación completa! El sistema se ha configurado con éxito y está listo para reiniciar."
echo "=============================================================================="