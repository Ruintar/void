#!/bin/bash
# This script is intended to be used by NVIDIA-GPU Owners / AMD GPU owners can comment out the NVIDIA package installation line!
# Este script é destinado a proprietários de GPU NVIDIA / Proprietários de AMD podem comentar a linha de instalação do pacote NVIDIA!

# The following script is for installing Cinnamon & services after the base installation has been performed!
# O seguinte script serve para instalar o Cinnamon e diversos serviços após a instalação base ter sido realizada!

# Start bash - set for root / Iniciar bash e definir bash para o root
clear
echo "Set rootshell to /bin/bash / Definindo rootshell para /bin/bash"
echo "Please give rootpassword / Por favor, digite a senha do root"
su -c "chsh -s /bin/bash root"
sleep 2

# Activate sudo / Configurar sudo
clear
echo "Activate sudo for wheel-group / Ativando sudo para o grupo wheel"
echo "Please give rootpassword / Por favor, digite a senha do root"
su -c 'echo "%wheel ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers > /dev/null'
sleep 2

# Styling / Backgrounds / Estilização e Planos de Fundo
clear
echo "Setting up Lightdm/Cinnamon backgroundimage / Configurando plano de fundo do LightDM e Cinnamon"
echo " -- Please give sudo-password / Por favor, digite a senha sudo abaixo -- "
sudo mkdir -p /usr/share/backgrounds/
sudo cp ~/void/*.jpg /usr/share/backgrounds/

# Copy automount script for udisks2 / Copiar script de autoinicialização para o udisks2
sudo cp ~/void/mount_disks.sh /usr/bin/

# Check systemupdates / Verificar atualizações do sistema
sudo xbps-install -Syu

# Activate all essential additional repos / Ativar repositórios adicionais essenciais do Void
clear
echo "Activate nonfree, multilib, and multilib-nonfree repos / Ativando repositórios nonfree, multilib e multilib-nonfree"
sudo xbps-install -y void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
sleep 2

# Update void repository / Atualizar repositório do Void
sudo xbps-install -Syu

# Install editor / Instalar editor
clear
echo "Install nano... / Instalando nano..."
sudo xbps-install -y nano
sleep 1

# Network & Authentication / Rede e Autenticação
clear
echo "Install NetworkManager, polkit and gnome-keyring / Instalando NetworkManager, polkit e gnome-keyring"
sudo xbps-install -y NetworkManager polkit gnome-keyring
sudo ln -s /etc/sv/NetworkManager /var/service/

# Remove conflicting network and remote services / Removendo serviços conflitantes e SSH
echo "Removing conflicting services (wpa_supplicant, dhcpcd, sshd)..."
sudo rm -f /var/service/wpa_supplicant
sudo rm -f /var/service/dhcpcd
sudo rm -f /var/service/dhcpcd-eth0
sudo rm -f /var/service/sshd
sleep 1

# dbus
clear
echo "Install dbus... / Instalando dbus..."
sudo xbps-install -y dbus
sudo ln -s /etc/sv/dbus /var/service/
sleep 1

# elogind
clear
echo "Install elogind... / Instalando elogind..."
sudo xbps-install -y elogind
sudo ln -s /etc/sv/elogind /var/service/
sleep 1

# Audio, Bluetooth and Mixer / Áudio, Bluetooth e Mixer
clear
echo "Install pipewire, wireplumber, pavucontrol, pulsemixer / Instalando pipewire, wireplumber, pavucontrol, pulsemixer"
sudo xbps-install -y pipewire wireplumber pavucontrol pulsemixer libspa-bluetooth blueman bluez-cups
sleep 1

# Install NVIDIA-driver / Instalar driver NVIDIA
clear
echo "Available NVIDIA drivers (Intel + GeForce 930MX):"
echo "1) Latest NVIDIA driver (nvidia) / Driver mais recente"
echo "0) No installation / Nenhuma instalação"
read -p "Please select a driver (1, 0 to cancel) / Por favor, selecione um driver (1, 0 para cancelar): " auswahl

case "$auswahl" in
    1)
        echo "Installing latest NVIDIA driver... / Instalando driver NVIDIA mais recente..."
        sudo xbps-install -y nvidia nvidia-libs-32bit
        ;;
    0)
        echo "NVIDIA setup skipped! / Configuração da NVIDIA ignorada."
        ;;
    *)
        echo "Invalid selection! No changes made. / Seleção inválida. Nenhuma alteração feita."
        ;;
esac

sleep 1

# Install some Steam-related-stuff / Componentes da Steam
sudo xbps-install -y libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit

# XORG & Cinnamon & Tools / XORG, Cinnamon e Ferramentas
clear
echo "Install XORG/Cinnamon-all... / Instalando XORG/Cinnamon-all..."
sudo xbps-install -y xorg
sudo xbps-install -y octoxbps cinnamon-all xdg-desktop-portal xdg-desktop-portal-gtk xdg-user-dirs xdg-user-dirs-gtk xdg-utils
sudo xbps-install -y wget binutils xz hicolor-icon-theme
sleep 1

# Printer support / Suporte a impressoras
clear
echo "Install Printer... / Instalando suporte a impressoras..."
sudo xbps-install -y cups cups-filters gutenprint system-config-printer
sudo ln -s /etc/sv/cupsd /var/service/
sudo xbps-install -y gnome-system-tools users-admin
sleep 1

# Filesystem & additional tools / Sistema de arquivos e ferramentas adicionais
clear
echo "Installing additional tools... / Instalando ferramentas adicionais..."
sudo xbps-install -y exfat-utils fuse-exfat gvfs-afc gvfs-mtp gvfs-smb udisks2 ntfs-3g gptfdisk bluez
sudo ln -s /etc/sv/bluetoothd /var/service/
sleep 1

# Upgradetool / Ferramenta de atualização
clear
echo "Install topgrade... / Instalando topgrade..."
sudo xbps-install -y topgrade
sleep 1

# Fonts / Fontes
clear
echo "Install Fonts... / Instalando fontes..."
sudo xbps-install -y noto-fonts-cjk noto-fonts-emoji noto-fonts-ttf noto-fonts-ttf-extra
sleep 1

# Software / Softwares essenciais e novos pacotes solicitados
clear
echo "Install Software... / Instalando softwares..."
sudo xbps-install -y firefox xfce4-terminal firefox-i18n-pt-BR gnome-calendar qalculate-gtk smplayer qt5-styleplugins qt5ct qt6ct flameshot fastfetch numlockx
sleep 1

# Variável de ambiente QT
echo "Configurando variável QT_QPA_PLATFORMTHEME..."
echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment > /dev/null

# Configuração do XFCE Terminal
echo "Configurando perfil visual do xfce4-terminal..."
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

# Scroll Lock Nativo X11
echo "Ativando Scroll Lock nativo no X11..."
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/30-scrolllock.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "br"
    Option "XkbVariant" "abnt2"
    Option "XkbOptions" "scrolllock:mod3"
EndSection
EOF

# Autostart NumLock Cinnamon
echo "Criando entrada de inicialização do NumLock para o Cinnamon..."
mkdir -p ~/.config/autostart
cat << 'EOF' > ~/.config/autostart/numlockx.desktop
[Desktop Entry]
Type=Application
Name=NumLock
Exec=numlockx on
X-GNOME-Autostart-enabled=true
EOF

# Download and install Linux Mint Themes, Icons, and Cursors for the user
echo "Downloading and installing Linux Mint themes, icons, and cursors..."
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

# Create a script that sets keyboard layout, styling, and clock format after login
echo "Creating autostart script for custom settings..."
cat <<EOL > /home/$USER/set-keyboard.sh
#!/bin/bash
# Set pt_BR keyboard layout, Mint-Y-Dark theme, and custom clock format on session start
gsettings set org.cinnamon.desktop.input-sources sources "[('xkb', 'br')]"
gsettings set org.cinnamon.desktop.background picture-uri 'file:///usr/share/backgrounds/cinnamon_background.jpg'

# Apply Mint-Y-Dark theme settings
gsettings set org.cinnamon.desktop.interface gtk-theme 'Mint-Y-Dark'
gsettings set org.cinnamon.desktop.wm.preferences theme 'Mint-Y-Dark'
gsettings set org.cinnamon.theme name 'Mint-Y-Dark'
gsettings set org.cinnamon.desktop.interface icon-theme 'Mint-Y'
gsettings set org.cinnamon.desktop.interface cursor-theme 'Mint-Y'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Configure clock applet format (Time with seconds on top, date on bottom)
gsettings set org.cinnamon.desktop.interface clock-use-24h true
gsettings set org.cinnamon.desktop.interface clock-show-seconds true
gsettings set org.cinnamon.muffin.window-picker-style custom-format
gsettings set org.cinnamon.desktop.interface clock-custom-format '%H:%M:%S\\n%d/%m/%Y'

# Delete autostart entry after first execution
rm -f ~/.config/autostart/set-keyboard.desktop
echo "Custom configurations have been applied."
EOL

chmod +x /home/$USER/set-keyboard.sh

# Create autostart file that executes the script
cat <<EOL > ~/.config/autostart/set-keyboard.desktop
[Desktop Entry]
Type=Application
Exec=/home/$USER/set-keyboard.sh
Name=Set Mint Customization and Keyboard
Comment=Set the default keyboard layout, Mint themes, and clock format after login
X-GNOME-Autostart-enabled=true
EOL

# Create .desktop files
cat > ~/.config/autostart/octoxbps-notifier.desktop <<EOL
[Desktop Entry]
Type=Application
Exec=/bin/octoxbps-notifier
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=OctoXBPS Notifier
Comment=Start OctoXBPS Update Notifier automatically
EOL

cat > ~/.config/autostart/x11kb-brazil.desktop <<EOL
[Desktop Entry]
Type=Application
Exec=/usr/bin/setxkbmap br
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=X11-KB-Brazil
Comment=Activate Brazilian keyboard under X11
EOL

cat > ~/.config/autostart/automount-udisks2.desktop <<EOL
[Desktop Entry]
Type=Application
Exec=/usr/bin/mount_disks.sh 
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=X11-automount-udisks2
Comment=Automount script for udisks2
EOL

echo "Autostart script created. Script finished."

# Login manager / Gerenciador de login
clear
echo "Install LightDM... / Instalando LightDM..."
sudo xbps-install -y lightdm lightdm-gtk-greeter
sudo ln -s /etc/sv/lightdm/ /var/service/
sleep 1

# Configure LightDM background and Mint-Y-Dark Theme
sudo tee -a /etc/lightdm/lightdm-gtk-greeter.conf > /dev/null << 'EOF'
background=/usr/share/backgrounds/lightdmbackground.jpg
theme-name=Mint-Y-Dark
icon-theme-name=Mint-Y
EOF

# Configuração unificada do LightDM Greeter para Scroll Lock e NumLock
echo "Configurando script de inicialização do LightDM..."
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

# Setup Autostart - pipewire & wireplumber / Configurar autostart do PipeWire e WirePlumber
sudo mkdir -p /etc/pipewire/pipewire.conf.d
sudo ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
sudo ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
sudo ln -s /usr/share/applications/pipewire.desktop /etc/xdg/autostart/
sleep 1
clear

# Activate Brazilian locale / Ativar localidade pt_BR
echo "pt_BR.UTF-8" > "$HOME/.config/user-dirs.locale"

# Setup automount for ssds/hdds
sudo cp ~/void/10-mount-drives.rules /etc/polkit-1/rules.d/
clear
echo "Setup finished - please reboot / Script de configuração finalizado - o sistema já pode ser reiniciado"
echo "Use sudo reboot"