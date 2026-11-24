#!/bin/bash
# ==============================================================================
# Script de Postinstalación de Void Linux (Cinnamon Desktop - ES_ES)
# ==============================================================================

# Interrumpe la ejecución inmediatamente si algún comando devuelve un error no tratado
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Verificaciones de Seguridad y Permisos Básicos
# ------------------------------------------------------------------------------

# Identificar el usuario real (incluso si se ejecuta con sudo)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificar privilegios de administrador
if [ "$EUID" -ne 0 ]; then
    echo "Error: Este script debe ejecutarse con privilegios de root (o con sudo)."
    echo "Ejemplo: sudo ./cinnamon_install_ES_ES.sh"
    exit 1
fi

# Directorio temporal seguro para compilación/extracción
TMP_DIR=$(mktemp -d -t void-install-XXXXXX)
# Permiso de travessia: el xdeb se ejecuta como usuario común dentro de este directorio
chmod 755 "$TMP_DIR"

# Función de limpieza ejecutada al salir (Ctrl+C / Error / Fin normal)
cleanup() {
    local exit_code=$?
    echo -e "\nLimpiando archivos temporales..."
    rm -rf "$TMP_DIR"
    if [ $exit_code -ne 0 ]; then
        echo "El script fue interrumpido o encontró un error durante el proceso."
    fi
}
trap cleanup EXIT

# Ejecuta un comando como el usuario real (el xdeb y el xdg-mime no deben
# ejecutarse como root). El -H garantiza que se use el HOME del usuario real.
run_as_user() {
    if [ "$REAL_USER" != "root" ]; then
        sudo -H -u "$REAL_USER" "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 2. Configuración de Shell y Sudoers
# ------------------------------------------------------------------------------
echo "==> Configurando shell del root y permisos del sudo..."
chsh -s /bin/bash root

if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

# ------------------------------------------------------------------------------
# 3. Fondos de Pantalla y Scripts de Apoyo
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
echo "==> Instalando utilidades esenciales, red e inicio de sesión..."
xbps-install -y nano NetworkManager polkit gnome-keyring dbus elogind

# Eliminación sanitaria de servicios de red conflictivos
for svc in wpa_supplicant dhcpcd dhcpcd-eth0 sshd; do
    if [ -L "/var/service/$svc" ] || [ -e "/var/service/$svc" ]; then
        rm -f "/var/service/$svc"
    fi
done

# Activación segura de servicios (evita error de enlace duplicado)
for svc in NetworkManager dbus elogind; do
    if [ ! -L "/var/service/$svc" ]; then
        ln -s "/etc/sv/$svc" /var/service/
    fi
done

# Configuración de Laptop (Detección / Pregunta al usuario)
clear
echo "¿Estás instalando en un Desktop o Laptop/Notebook?"
echo "0) Desktop"
echo "1) Laptop/Notebook"
read -r -p "Por favor, seleccione [0-1]: " tipo_maquina

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
# rtkit: permite que PipeWire se ejecute con prioridad en tiempo real
xbps-install -y pipewire wireplumber rtkit pavucontrol pulsemixer libspa-bluetooth blueman bluez-cups

# ------------------------------------------------------------------------------
# 7. Detección de GPU y Controladores de Video (NVIDIA + Steam 32 bits)
# ------------------------------------------------------------------------------
# Detección automática de GPUs NVIDIA vía lspci (funciona en notebooks híbridos
# Intel + NVIDIA / Optimus). Las máquinas SIN NVIDIA saltan esta etapa solas.
#
# La familia del controlador se recomienda a partir del ID PCI del dispositivo
# (10de:XXXX), según la tabla de soporte de Void Linux:
#   nvidia     -> Turing o más nueva (595, módulos abiertos del kernel)
#   nvidia580  -> Maxwell, Pascal y Volta (ej.: 930MX, GTX 9xx/10xx, 1650)
#   nvidia470  -> Kepler (GTX 6xx/7xx)
#   nvidia390  -> Fermi (GeForce 400/500)
#
# El paquete elegido ya se encarga del resto automáticamente (módulo DKMS,
# blacklist del Nouveau y regeneración del initramfs) vía hooks de xbps —
# no se necesitan pasos manuales de blacklist/dracut.
# En notebooks Optimus, solo la GPU NVIDIA recibe el controlador; la Intel
# sigue funcionando con los controladores Mesa ya incluidos en Xorg.

NVIDIA_PKG=""

if command -v lspci >/dev/null 2>&1; then
    GPU_NVIDIA=$(lspci -d 10de: 2>/dev/null || true)
    # Clasifica solo dispositivos de video (clase PCI 03xx: VGA/3D/Display),
    # ignorando la función de audio HDA que acompaña a la GPU
    NVIDIA_IDS=$(lspci -d 10de: -n 2>/dev/null | awk '$2 ~ /^03/ {print $3}' | cut -d: -f2 || true)
else
    GPU_NVIDIA=""
    NVIDIA_IDS=""
fi

if [ -n "$GPU_NVIDIA" ]; then
    clear
    echo "GPU NVIDIA detectada:"
    echo "$GPU_NVIDIA" | sed 's/^/  /'
    echo ""

    # Recomienda la familia del controlador a partir de cada NVIDIA de video encontrada
    RECOMENDADO=""
    FAMILIAS_MEZCLADAS=0
    for devid in $NVIDIA_IDS; do
        # Valida el ID (4 dígitos hexadecimales)
        if ! [[ "$devid" =~ ^[0-9a-fA-F]{4}$ ]]; then
            continue
        fi
        devnum=$((16#$devid))
        if   (( devnum >= 0x1E00 )); then fam="nvidia"      # Turing o más nueva
        elif (( devnum >= 0x1D80 )); then fam="nvidia580"   # Volta
        elif (( devnum >= 0x1B00 )); then fam="nvidia580"   # Pascal
        elif (( devnum >= 0x1300 )); then fam="nvidia580"   # Maxwell
        elif (( devnum >= 0x0F00 )); then fam="nvidia470"   # Kepler
        elif (( devnum >= 0x06C0 )); then fam="nvidia390"   # Fermi
        else fam="none"                                     # pre-Fermi: solo Nouveau
        fi
        if [ -z "$RECOMENDADO" ]; then
            RECOMENDADO="$fam"
        elif [ "$RECOMENDADO" != "$fam" ]; then
            FAMILIAS_MEZCLADAS=1
        fi
    done

    echo "Controladores NVIDIA disponibles en Void:"
    echo "  nvidia     (Turing o más nueva)"
    echo "  nvidia580  (Maxwell, Pascal, Volta)"
    echo "  nvidia470  (Kepler)"
    echo "  nvidia390  (Fermi)"
    echo ""
    if [ "$FAMILIAS_MEZCLADAS" -eq 1 ]; then
        echo "Se detectó más de una familia NVIDIA — elija manualmente."
        RECOMENDADO=""
    elif [ "$RECOMENDADO" = "none" ]; then
        echo "GPU anterior a Fermi: el controlador propietario no ofrece soporte."
        echo "Se mantendrá el controlador libre Nouveau."
        RECOMENDADO=""
    elif [ -n "$RECOMENDADO" ]; then
        echo "Familia detectada — controlador recomendado: $RECOMENDADO"
    fi
    echo ""
    echo "1) Instalar el controlador NVIDIA recomendado + Soporte de 32 bits"
    echo "2) Elegir otra versión del controlador manualmente"
    echo "0) Omitir instalación (mantener Nouveau)"

    while true; do
        read -r -p "Por favor, seleccione (0, 1 o 2): " opt_nvidia
        case "$opt_nvidia" in
            0)
                echo "Instalación del controlador NVIDIA omitida."
                NVIDIA_PKG=""
                break
                ;;
            1)
                if [ -z "$RECOMENDADO" ]; then
                    echo "No se pudo recomendar un controlador automáticamente."
                    echo "Elija manualmente (opción 2) u omita la instalación (opción 0)."
                else
                    NVIDIA_PKG="$RECOMENDADO"
                    break
                fi
                ;;
            2)
                while true; do
                    echo "Versiones disponibles:"
                    echo "1) nvidia     (Turing o más nueva)"
                    echo "2) nvidia580  (Maxwell, Pascal, Volta)"
                    echo "3) nvidia470  (Kepler)"
                    echo "4) nvidia390  (Fermi)"
                    read -r -p "Por favor, seleccione (1-4): " opt_familia
                    case "$opt_familia" in
                        1) NVIDIA_PKG="nvidia"; break ;;
                        2) NVIDIA_PKG="nvidia580"; break ;;
                        3) NVIDIA_PKG="nvidia470"; break ;;
                        4) NVIDIA_PKG="nvidia390"; break ;;
                        *) echo "¡Opción inválida! Escriba un número entre 1 y 4." ;;
                    esac
                done
                break
                ;;
            *)
                echo "¡Opción inválida! Escriba 0, 1 o 2."
                ;;
        esac
    done

    if [ -n "$NVIDIA_PKG" ]; then
        echo "Instalando el controlador NVIDIA ($NVIDIA_PKG) + librerías de 32 bits..."
        xbps-install -y "$NVIDIA_PKG" "${NVIDIA_PKG}-libs-32bit"
    fi
elif [ ! -e /proc/cmdline ] || ! command -v lspci >/dev/null 2>&1; then
    # Alternativa: sin pciutils no hay detección automática — pregunta al estilo anterior
    clear
    echo "Aviso: el comando lspci no fue encontrado (paquete pciutils)."
    echo "La detección automática de GPU no está disponible en esta ejecución."
    echo "¿Desea instalar el controlador NVIDIA de todos modos?"
    echo "1) Controlador propietario NVIDIA + Soporte de 32 bits (nvidia nvidia-libs-32bit)"
    echo "0) Omitir instalación"
    while true; do
        read -r -p "Por favor, seleccione (1 o 0): " opt_nvidia
        case "$opt_nvidia" in
            1) NVIDIA_PKG="nvidia"; break ;;
            0) echo "Instalación del controlador NVIDIA omitida."; break ;;
            *) echo "¡Opción inválida! Escriba 1 o 0." ;;
        esac
    done
    if [ -n "$NVIDIA_PKG" ]; then
        echo "Instalando el controlador NVIDIA ($NVIDIA_PKG) + librerías de 32 bits..."
        xbps-install -y "$NVIDIA_PKG" "${NVIDIA_PKG}-libs-32bit"
    fi
else
    clear
    echo "Ninguna GPU NVIDIA detectada — etapa del controlador NVIDIA omitida."
    echo "(Las GPUs Intel y AMD utilizan los controladores Mesa instalados más adelante.)"
fi

# ------------------------------------------------------------------------------
# Componentes de 32 bits para compatibilidad con Steam (pregunta independiente)
# ------------------------------------------------------------------------------
# Se hace a TODOS los usuarios, independientemente de la GPU o del controlador:
#   - AMD/Intel/Nouveau: estas librerías son el soporte de 32 bits del Steam y
#     de los juegos de 32 bits (Mesa/GLVnd).
#   - NVIDIA propietaria: las librerías de 32 bits del propio controlador ya
#     fueron instaladas arriba; los paquetes de abajo complementan el entorno
#     (gcc, libstdc++, drm).
clear
echo "¿Desea instalar los componentes de 32 bits para compatibilidad con Steam?"
echo "(libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit)"

opt_steam32=""
while true; do
    read -r -p "Por favor, seleccione (1 = Sí / 0 = No): " input_steam
    case "$input_steam" in
        1) opt_steam32="si"; break ;;
        0) opt_steam32="no"; break ;;
        *) echo "¡Opción inválida! Escriba 1 para Sí o 0 para No." ;;
    esac
done

if [ "$opt_steam32" = "si" ]; then
    echo "Instalando componentes de 32 bits para Steam..."
    xbps-install -y libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit
else
    echo "Los componentes de 32 bits de Steam no serán instalados."
fi

# ------------------------------------------------------------------------------
# 8. Entorno de Escritorio Cinnamon y Herramientas del Sistema
# ------------------------------------------------------------------------------
echo "==> Instalando XOrg, Cinnamon Desktop y Herramientas..."
xbps-install -y xorg octoxbps cinnamon-all xdg-desktop-portal xdg-desktop-portal-gtk \
                xdg-user-dirs xdg-user-dirs-gtk xdg-utils wget binutils xz hicolor-icon-theme

# Nemo (predeterminado de Cinnamon) + File Roller y soporte de archivos RAR
# (incluyendo protegidos por contraseña, vía unrar) y 7-Zip, con integración en Nemo
echo "==> Instalando Nemo, File Roller y soporte de compresión (RAR/7Zip)..."
xbps-install -y nemo file-roller nemo-fileroller unrar p7zip

# Garantiza Nemo como administrador de archivos predeterminado del usuario
run_as_user xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

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
echo "==> Instalando soporte para impresoras y sistemas de archivos..."
# gnome-disk-utility: GNOME Disks (administración de discos)
# gnome-screenshot: utilizado por la tecla Print de Cinnamon
xbps-install -y cups cups-filters gutenprint system-config-printer \
                gnome-disk-utility gnome-screenshot \
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
# 10. Bulk Renamer (Bulky) vía xdeb
# ------------------------------------------------------------------------------
echo "==> Instalando el Bulky (renombrador masivo de Linux Mint) vía xdeb..."

# Dependencias del xdeb
xbps-install -y binutils tar curl xbps xz

# Directorio de build (propiedad del usuario real, ya que el xdeb no corre como root)
BULKY_DIR="$TMP_DIR/bulky-build"
mkdir -p "$BULKY_DIR"
chown -R "$REAL_USER:$REAL_USER" "$BULKY_DIR"

# Descarga del .deb del Bulky y del xdeb
# ATENCIÓN: el HTTP de packages.linuxmint.com es INTENCIONAL — el HTTPS de este
# host falla en el handshake de wget/curl en este entorno. No cambiar por HTTPS.
run_as_user bash -c "
    set -e
    cd '$BULKY_DIR'
    echo 'Descargando bulky_4.2_all.deb...'
    wget -q 'http://packages.linuxmint.com/pool/main/b/bulky/bulky_4.2_all.deb'
    echo 'Descargando el xdeb...'
    curl -sLO 'https://github.com/xdeb-org/xdeb/releases/latest/download/xdeb'
    chmod +x xdeb
"

# Hace el xdeb global
mv "$BULKY_DIR/xdeb" /usr/local/bin/xdeb

# Convierte el .deb en paquete xbps (genera el repositorio local 'binpkgs' del xdeb)
echo "Convirtiendo el Bulky (.deb -> xbps) con el xdeb..."
run_as_user bash -c "cd '$BULKY_DIR' && xdeb -Sedf bulky_4.2_all.deb"

# Instala el paquete convertido a partir del repositorio local generado por el xdeb
if compgen -G "$BULKY_DIR/binpkgs/bulky-*.xbps" > /dev/null; then
    echo "Instalando el paquete convertido..."
    xbps-install -y -R "$BULKY_DIR/binpkgs" -i bulky
else
    echo "Error: el xdeb no generó el paquete del Bulky en $BULKY_DIR/binpkgs." >&2
    exit 1
fi

# Dependencias Python del Bulky (vía xbps, sin pip)
echo "Instalando dependencias Python (python3-setproctitle, python3-Unidecode)..."
xbps-install -y python3-setproctitle python3-Unidecode

# Compila los schemas de GLib para que el schema 'org.x.bulky' sea reconocido
echo "Compilando schemas de GLib..."
glib-compile-schemas /usr/share/glib-2.0/schemas/

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

# ATENCIÓN: el HTTP de packages.linuxmint.com es INTENCIONAL — el HTTPS de este
# host falla en el handshake de wget/curl en este entorno. No cambiar por HTTPS.
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

# Script de inicialización del usuario
# (aplica teclado, temas y reloj en el primer inicio de sesión; sin claves
#  fantasma — el formato del reloj del applet lo trata el bloque de reparo abajo)
cat <<EOL > "$REAL_HOME/set-keyboard.sh"
#!/bin/bash
set -e
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
Comment=Definir el layout de teclado predeterminado, temas Mint y formato del reloj tras el inicio de sesión
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
# Reparo del formato del reloj (applet calendar@cinnamon.org)
# ------------------------------------------------------------------------------
# El applet del reloj guarda sus configuraciones en archivos JSON:
#   1) Instalaciones nuevas: los patrones vienen del settings-schema.json global
#      del applet.
#   2) Re-ejecuciones: los JSON por instancia ya existen en
#      ~/.config/cinnamon/spices/calendar@cinnamon.org/ y deben corregirse.
# En ambos casos aplicamos el formato en dos líneas (hora/segundos arriba,
# fecha abajo) con newline real. El __md5__ no se altera — el checksum antiguo
# hace que el applet recargue los valores del disco en lugar de resetear el schema.

REAL_HOME="$REAL_HOME" python3 - <<'PYEOF'
import glob, json, os

REAL_HOME = os.environ.get('REAL_HOME', '')
FORMATO = "%H:%M:%S\n%d/%m/%Y"

# 1) Schema global del applet (afecta instalaciones nuevas y nuevas instancias)
schema_path = '/usr/share/cinnamon/applets/calendar@cinnamon.org/settings-schema.json'
if os.path.isfile(schema_path):
    with open(schema_path, 'r', encoding='utf-8') as f:
        schema = json.load(f)
    cambiado = False
    for clave, item in schema.items():
        if clave == '__md5__' or not isinstance(item, dict):
            continue
        if clave == 'use-custom-format':
            item['default'] = True
            cambiado = True
        elif clave == 'custom-format':
            item['default'] = FORMATO
            cambiado = True
    if cambiado:
        with open(schema_path, 'w', encoding='utf-8') as f:
            json.dump(schema, f, indent=4, ensure_ascii=False)

# 2) Instancias existentes (re-ejecuciones del script)
if REAL_HOME:
    spice_dir = os.path.join(REAL_HOME, '.config/cinnamon/spices/calendar@cinnamon.org')
    for path in glob.glob(os.path.join(spice_dir, '*.json')):
        with open(path, 'r', encoding='utf-8') as f:
            datos = json.load(f)
        cambiado = False
        if isinstance(datos.get('use-custom-format'), dict):
            datos['use-custom-format']['value'] = True
            cambiado = True
        if isinstance(datos.get('custom-format'), dict):
            datos['custom-format']['value'] = FORMATO
            cambiado = True
        if cambiado:
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(datos, f, indent=4, ensure_ascii=False)
PYEOF

# ------------------------------------------------------------------------------
# Garantía crítica de propiedad del ~/.config
# ------------------------------------------------------------------------------
# El script corre como root: sin este chown, los archivos creados dentro de
# ~/.config en esta sección quedan root:root y el dconf/Cinnamon falla en
# silencio (tema, fondo, iconos y teclado nunca persisten en la sesión).
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config"

# ------------------------------------------------------------------------------
# 13. Display Manager (LightDM)
# ------------------------------------------------------------------------------
echo "==> Configurando LightDM..."
xbps-install -y lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

if [ ! -L "/var/service/lightdm" ]; then
    ln -s /etc/sv/lightdm/ /var/service/
fi

# PAM: desbloquea el gnome-keyring junto con el inicio de sesión de LightDM
# (resuelve el error "keyringPrompt: Failed to show modal dialog")
if ! grep -q "pam_gnome_keyring" /etc/pam.d/lightdm; then
    echo "auth       optional    pam_gnome_keyring.so" >> /etc/pam.d/lightdm
    echo "session    optional    pam_gnome_keyring.so auto_start" >> /etc/pam.d/lightdm
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

# Config de Autostart de Pipewire
mkdir -p /etc/pipewire/pipewire.conf.d
[ -f /usr/share/examples/wireplumber/10-wireplumber.conf ] && ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
[ -f /usr/share/examples/pipewire/20-pipewire-pulse.conf ] && ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
[ -f /usr/share/applications/pipewire.desktop ] && ln -sf /usr/share/applications/pipewire.desktop /etc/xdg/autostart/

# ------------------------------------------------------------------------------
# 14. Configuración del GRUB
# ------------------------------------------------------------------------------
echo "==> Configurando el GRUB..."
sed -i 's/.*GRUB_BACKGROUND=.*/GRUB_BACKGROUND="\/usr\/share\/void-artwork\/splash.png"/' /etc/default/grub

clear
echo "¿Desea saltar la cuenta del GRUB e iniciar automáticamente?"
echo "Aviso: si usa un notebook y este tiene problema de tecla fantasma"
echo "con defecto en el firmware y no quiere confirmar la entrada cada vez,"
echo "es necesario efectuar este cambio para saltar el menú."
echo "1) Sí, iniciar directo y saltar tiempo"
echo "0) No, mantener cuenta estándar y mostrar menú"
read -r -p "Por favor, seleccione (0 o 1): " pular_grub

if [ "$tipo_maquina" = "1" ] || [ "$pular_grub" = "1" ]; then
    echo "Aplicando configuración de arranque directo..."
    sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
else
    echo "Manteniendo la cuenta estándar del GRUB..."
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
echo "==> Configurando locales del sistema..."
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

# Garantía final: asegura que los schemas de GLib (incluyendo el org.x.bulky)
# sigan compilados, en caso de que algún paquete instalado después haya
# regenerado el caché
glib-compile-schemas /usr/share/glib-2.0/schemas/ > /dev/null 2>&1 || true

echo "=============================================================================="
echo " ¡Concluido! El sistema fue configurado con éxito y está listo para reiniciar."
echo "=============================================================================="
