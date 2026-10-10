#!/bin/bash
# Este script está destinado a los propietarios de GPU NVIDIA. ¡Los propietarios de AMD pueden comentar la línea de instalación del paquete NVIDIA!

# ¡El siguiente script sirve para instalar Cinnamon y diversos servicios después de realizar la instalación base!

# Iniciar bash y definir bash para el root
clear
echo "Configurando rootshell a /bin/bash"
echo "Por favor, introduzca la contraseña de root"
su -c "chsh -s /bin/bash root"
sleep 2

# Configurar sudo
clear
echo "Activando sudo para el grupo wheel"
echo "Por favor, introduzca la contraseña de root"
su -c 'echo "%wheel ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers > /dev/null'
sleep 2

# Estilización y Fondos de pantalla
clear
echo "Configurando la imagen de fondo de LightDM y Cinnamon"
echo " -- Por favor, introduzca la contraseña de sudo abajo -- "
sudo mkdir -p /usr/share/backgrounds/
sudo cp ~/void/*.jpg /usr/share/backgrounds/

# Copiar script de montaje automático para udisks2
sudo cp ~/void/mount_disks.sh /usr/bin/

# Verificar actualizaciones del sistema
sudo xbps-install -Syu

# Activar repositorios adicionales esenciales de Void
clear
echo "Activando repositorios nonfree, multilib y multilib-nonfree"
sudo xbps-install -y void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
sleep 2

# Actualizar repositorios de Void
sudo xbps-install -Syu

# Instalar editor
clear
echo "Instalando nano..."
sudo xbps-install -y nano
sleep 1

# Red y Autenticación
clear
echo "Instalando NetworkManager, polkit y gnome-keyring"
sudo xbps-install -y NetworkManager polkit gnome-keyring
sudo ln -s /etc/sv/NetworkManager /var/service/

# Eliminando servicios en conflicto y SSH
echo "Eliminando servicios en conflicto (wpa_supplicant, dhcpcd, sshd)..."
sudo rm -f /var/service/wpa_supplicant
sudo rm -f /var/service/dhcpcd
sudo rm -f /var/service/dhcpcd-eth0
sudo rm -f /var/service/sshd
sleep 1

# dbus
clear
echo "Instalando dbus..."
sudo xbps-install -y dbus
sudo ln -s /etc/sv/dbus /var/service/
sleep 1

# elogind
clear
echo "Instalando elogind..."
sudo xbps-install -y elogind
sudo ln -s /etc/sv/elogind /var/service/
sleep 1

clear
echo "¿Está utilizando un Escritorio (Desktop) o un Portátil (Laptop/Notebook)?"
echo "0) Desktop"
echo "1) Laptop/Notebook"
read -p "Por favor, seleccione (0 o 1): " tipo_maquina

if [ "$tipo_maquina" = "1" ]
then
    echo "Aplicando configuraciones de la tapa del portátil..."
    sudo sed -i 's/.*HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/elogind/logind.conf
    sudo sed -i 's/.*HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/elogind/logind.conf
    sudo sed -i 's/.*HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/elogind/logind.conf
else
    echo "Desktop seleccionado. Configuración de tapa omitida."
fi
sleep 1

# Audio, Bluetooth y Mezclador
clear
echo "Instalando pipewire, wireplumber, pavucontrol, pulsemixer"
sudo xbps-install -y pipewire wireplumber pavucontrol pulsemixer libspa-bluetooth blueman bluez-cups
sleep 1

# Instalar controlador NVIDIA
clear
echo "Controladores NVIDIA disponibles (Intel + GeForce 930MX):"
echo "1) Controlador NVIDIA más reciente (nvidia)"
echo "0) Sin instalación"
read -p "Por favor, seleccione un controlador (1, 0 para cancelar): " auswahl

case "$auswahl" in
    1)
        echo "Instalando el controlador NVIDIA más reciente..."
        sudo xbps-install -y nvidia nvidia-libs-32bit
        ;;
    0)
        echo "¡Configuración de NVIDIA omitida!"
        ;;
    *)
        echo "¡Selección inválida! No se realizaron cambios."
        ;;
esac

sleep 1

# Componentes relacionados con Steam
sudo xbps-install -y libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit

# XORG, Cinnamon y Herramientas
clear
echo "Instalando XORG/Cinnamon-all..."
sudo xbps-install -y xorg
sudo xbps-install -y octoxbps cinnamon-all xdg-desktop-portal xdg-desktop-portal-gtk xdg-user-dirs xdg-user-dirs-gtk xdg-utils
# Instalar herramientas adicionales requeridas para la extracción de temas/iconos (auxiliares .deb y xz)
sudo xbps-install -y wget binutils xz hicolor-icon-theme
sleep 1

# Parche en Spices.py de Cinnamon para corregir la pestaña de descargas
echo "Aplicando corrección en Spices.py para la pestaña de descargas de Cinnamon..."
sudo python3 -c "
import os
path = '/usr/share/cinnamon/cinnamon-settings/bin/Spices.py'
if os.path.exists(path):
    with open(path, 'r') as f:
        content = f.read()
    old_code = 'totalSize = int(response.headers.get(\'content-length\'))'
    new_code = 'content_length = response.headers.get(\'content-length\')\n            totalSize = int(content_length) if content_length is not None else -1'
    if old_code in content:
        with open(path, 'w') as f:
            f.write(content.replace(old_code, new_code))
"
sleep 1

# Soporte de impresora
clear
echo "Instalando soporte para impresoras..."
sudo xbps-install -y cups cups-filters gutenprint system-config-printer
sudo ln -s /etc/sv/cupsd /var/service/
sudo xbps-install -y gnome-system-tools users-admin
sleep 1

# Sistema de archivos y herramientas adicionales
clear
echo "Instalando herramientas adicionales..."
sudo xbps-install -y exfat-utils fuse-exfat gvfs-afc gvfs-mtp gvfs-smb udisks2 ntfs-3g gptfdisk bluez GPaste
# Activar bluetoothd
sudo ln -s /etc/sv/bluetoothd /var/service/
sleep 1

# Herramienta de actualización
clear
echo "Instalando topgrade..."
sudo xbps-install -y topgrade
sleep 1

# Fuentes
clear
echo "Instalando fuentes..."
sudo xbps-install -y noto-fonts-cjk noto-fonts-emoji noto-fonts-ttf noto-fonts-ttf-extra
sleep 1

# Software esencial (con paquete de idioma en español para Firefox)
clear
echo "Instalando software..."
sudo xbps-install -y firefox xfce4-terminal firefox-i18n-es-ES gnome-calendar qalculate-gtk smplayer qt5-styleplugins qt5ct qt6ct flameshot fastfetch numlockx
sleep 1

# Variable de entorno QT
echo "Configurando la variable QT_QPA_PLATFORMTHEME..."
echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment > /dev/null

# Configuración de XFCE Terminal
echo "Configurando el perfil visual de xfce4-terminal..."
mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
cat << 'EOF' > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml
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

# Scroll Lock Nativo X11 (Teclado Español)
echo "Activando Scroll Lock nativo en X11..."
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/30-scrolllock.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "es"
    Option "XkbOptions" "scrolllock:mod3"
EndSection
EOF

# Inicio automático de NumLock en Cinnamon
echo "Creando entrada de inicio automático para NumLock en Cinnamon..."
mkdir -p ~/.config/autostart
cat << 'EOF' > ~/.config/autostart/numlockx.desktop
[Desktop Entry]
Type=Application
Name=NumLock
Exec=numlockx on
X-GNOME-Autostart-enabled=true
EOF

# Descargar e instalar temas, iconos y cursores de Linux Mint para el usuario
echo "Descargando e instalando temas, iconos y cursores de Linux Mint..."
mkdir -p ~/.themes ~/.icons

# 1. Mint-Themes (v2.4.2)
wget -q http://packages.linuxmint.com/pool/main/m/mint-themes/mint-themes_2.4.2_all.deb
ar x mint-themes_2.4.2_all.deb
tar -xf data.tar.xz --wildcards --no-anchored 'usr/share/themes/*'
mv usr/share/themes/* ~/.themes/
rm -rf usr data.tar.xz control.tar.xz debian-binary mint-themes_2.4.2_all.deb

# 2. Mint-Y-Icons (v1.9.6)
wget -q http://packages.linuxmint.com/pool/main/m/mint-y-icons/mint-y-icons_1.9.6_all.deb
ar x mint-y-icons_1.9.6_all.deb
tar -xf data.tar.xz --wildcards --no-anchored 'usr/share/icons/*'
mv usr/share/icons/* ~/.icons/
rm -rf usr data.tar.xz control.tar.xz debian-binary mint-y-icons_1.9.6_all.deb

# 3. Mint-Cursor-Themes (v1.0.2)
wget -q http://packages.linuxmint.com/pool/main/m/mint-cursor-themes/mint-cursor-themes_1.0.2_all.deb
ar x mint-cursor-themes_1.0.2_all.deb
tar -xf data.tar.xz --wildcards --no-anchored 'usr/share/icons/*'
mv usr/share/icons/* ~/.icons/
rm -rf usr data.tar.xz control.tar.xz debian-binary mint-cursor-themes_1.0.2_all.deb

# Crear script que configura el diseño de teclado en español, estilo y formato de reloj tras el inicio de sesión
echo "Creando script de inicio automático para configuraciones personalizadas..."
cat <<EOL > /home/$USER/set-keyboard.sh
#!/bin/bash
# Configurar diseño de teclado español, tema Mint-Y-Dark y formato de reloj al iniciar la sesión
gsettings set org.cinnamon.desktop.input-sources sources "[('xkb', 'es')]"
gsettings set org.cinnamon.desktop.background picture-uri 'file:///usr/share/backgrounds/cinnamon_background.jpg'

# Aplicar configuraciones del tema Mint-Y-Dark
gsettings set org.cinnamon.desktop.interface gtk-theme 'Mint-Y-Dark'
gsettings set org.cinnamon.desktop.wm.preferences theme 'Mint-Y-Dark'
gsettings set org.cinnamon.theme name 'Mint-Y-Dark'
gsettings set org.cinnamon.desktop.interface icon-theme 'Mint-Y'
gsettings set org.cinnamon.desktop.interface cursor-theme 'Mint-Y'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Configurar formato del applet de reloj (Hora con segundos arriba, fecha abajo)
gsettings set org.cinnamon.desktop.interface clock-use-24h true
gsettings set org.cinnamon.desktop.interface clock-show-seconds true
gsettings set org.cinnamon.muffin.window-picker-style custom-format
gsettings set org.cinnamon.desktop.interface clock-custom-format '%H:%M:%S\n%d/%m/%Y'

# Eliminar entrada de inicio automático tras la primera ejecución
rm -f ~/.config/autostart/set-keyboard.desktop
echo "Se han aplicado las configuraciones personalizadas."
EOL

# Hacer ejecutable el script
chmod +x /home/$USER/set-keyboard.sh

# Crear archivo de inicio automático que ejecuta el script
mkdir -p ~/.config/autostart
cat <<EOL > ~/.config/autostart/set-keyboard.desktop
[Desktop Entry]
Type=Application
Exec=/home/$USER/set-keyboard.sh
Name=Set Mint Customization and Keyboard
Comment=Configurar distribución de teclado, temas Mint y formato de reloj tras iniciar sesión
X-GNOME-Autostart-enabled=true
EOL

# Crear archivo .desktop para octoxbps-notifier
cat > ~/.config/autostart/octoxbps-notifier.desktop <<EOL
[Desktop Entry]
Type=Application
Exec=/bin/octoxbps-notifier
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=OctoXBPS Notifier
Comment=Iniciar el notificador de actualizaciones de OctoXBPS automáticamente
EOL

# Crear archivo .desktop para teclado español
cat > ~/.config/autostart/x11kb-spanish.desktop <<EOL
[Desktop Entry]
Type=Application
Exec=/usr/bin/setxkbmap es
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=X11-KB-Spanish
Comment=Activar teclado español en X11
EOL

# Crear archivo .desktop para el script de automontaje (udisks2)
cat > ~/.config/autostart/automount-udisks2.desktop <<EOL
[Desktop Entry]
Type=Application
Exec=/usr/bin/mount_disks.sh 
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=X11-automount-udisks2
Comment=Script de automontaje para udisks2
EOL

# Crear archivo .desktop para el demonio GPaste
cat > ~/.config/autostart/gpaste-daemon.desktop <<EOL
[Desktop Entry]
Type=Application
Exec=/usr/bin/gpaste-client daemon
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=GPaste Daemon
Comment=Iniciar el demonio GPaste automáticamente
EOL

echo "Script de inicio automático creado. Script finalizado."

# Administrador de inicio de sesión
clear
echo "Instalando LightDM..."
sudo xbps-install -y lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
sudo ln -s /etc/sv/lightdm/ /var/service/
sleep 1

# Configurar fondo y tema de LightDM
sudo tee -a /etc/lightdm/lightdm-gtk-greeter.conf > /dev/null << 'EOF'
[greeter]
background=/usr/share/backgrounds/lightdmbackground.jpg
theme-name=Adwaita-dark
icon-theme-name=Adwaita
EOF

# Configuración unificada de LightDM Greeter para Scroll Lock y NumLock
echo "Configurando script de inicio de LightDM..."
sudo tee /usr/local/bin/lightdm-greeter-setup.sh > /dev/null << 'EOF'
#!/bin/bash
/usr/bin/setxkbmap -option scrolllock:mod3
/usr/bin/numlockx on
EOF
sudo chmod +x /usr/local/bin/lightdm-greeter-setup.sh

sudo mkdir -p /etc/lightdm/lightdm.conf.d
sudo tee /etc/lightdm/lightdm.conf.d/60-custom-greeter.conf > /dev/null << 'EOF'
[Seat:*]
greeter-setup-script=/usr/local/bin/lightdm-greeter-setup.sh
EOF

# Configurar inicio automático de PipeWire y WirePlumber
sudo mkdir -p /etc/pipewire/pipewire.conf.d
sudo ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
sudo ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
sudo ln -s /usr/share/applications/pipewire.desktop /etc/xdg/autostart/
sleep 1

# Configuración de GRUB
clear
echo "Configurando GRUB..."
sudo sed -i 's/.*GRUB_BACKGROUND=.*/GRUB_BACKGROUND="\/usr\/share\/void-artwork\/splash.png"/' /etc/default/grub
sudo sed -i 's/.*GRUB_COLOR_NORMAL=.*/GRUB_COLOR_NORMAL="light-blue\/black"/' /etc/default/grub

echo "¿Desea omitir la cuenta atrás de GRUB e iniciar automáticamente?"
echo "Aviso: si usa un portátil y tiene un problema de teclas fantasma"
echo "con un defecto de firmware y no desea confirmar la entrada cada vez,"
echo "es necesario aplicar este cambio para omitir el menú."
echo "1) Sí, iniciar directamente y omitir tiempo"
echo "0) No, mantener cuenta atrás predeterminada y mostrar menú"
read -p "Por favor, seleccione (0 o 1): " pular_grub

if [ "$tipo_maquina" = "1" ] || [ "$pular_grub" = "1" ]
then
    echo "Aplicando configuración de inicio directo..."
    sudo sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
else
    echo "Manteniendo la cuenta atrás predeterminada de GRUB..."
    sudo sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
fi

sudo update-grub || sudo grub-mkconfig -o /boot/grub/grub.cfg
sleep 1

# Configurar locales del sistema globalmente (es_ES.UTF-8, LC_TIME y LC_COLLATE=C)
echo "Configurando los locales del sistema..."
sudo sed -i 's/^[[:space:]]*#[[:space:]]*\(es_ES\.UTF-8[[:space:]]\+UTF-8\)/\1/' /etc/default/libc-locales
sudo sed -i '/es_ES\.UTF-8/!s/^[[:space:]]*\([^#[:space:]].*UTF-8\)/# \1/' /etc/default/libc-locales
sudo xbps-reconfigure -f glibc-locales

sudo touch /etc/locale.conf

if grep -q "^LANG=" /etc/locale.conf; then
    sudo sed -i 's/^LANG=.*/LANG=es_ES.UTF-8/' /etc/locale.conf
else
    echo "LANG=es_ES.UTF-8" | sudo tee -a /etc/locale.conf > /dev/null
fi

if grep -q "^LC_TIME=" /etc/locale.conf; then
    sudo sed -i 's/^LC_TIME=.*/LC_TIME=es_ES.UTF-8/' /etc/locale.conf
else
    echo "LC_TIME=es_ES.UTF-8" | sudo tee -a /etc/locale.conf > /dev/null
fi

if grep -q "^LC_COLLATE=" /etc/locale.conf; then
    sudo sed -i 's/^LC_COLLATE=.*/LC_COLLATE=C/' /etc/locale.conf
else
    echo "LC_COLLATE=C" | sudo tee -a /etc/locale.conf > /dev/null
fi

# Configurar montaje automático para SSDs/HDDs
sudo cp ~/void/10-mount-drives.rules /etc/polkit-1/rules.d/
clear
echo "Script de configuración finalizado - el sistema ya se puede reiniciar"
echo "Use sudo reboot"