#!/bin/bash
# ==============================================================================
# Void Linux Post-Installation Script (Cinnamon Desktop - EN_US)
# ==============================================================================

# Abort execution immediately if any command fails
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Security Checks and Basic Permissions
# ------------------------------------------------------------------------------

# Identify the real user (even when running under sudo)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with root privileges (or via sudo)."
    echo "Example: sudo ./cinnamon_install_EN_US.sh"
    exit 1
fi

# Secure temporary directory for package extraction
TMP_DIR=$(mktemp -d -t void-install-XXXXXX)

# Cleanup function executed on exit or interruption (Ctrl+C / Error)
cleanup() {
    local exit_code=$?
    echo -e "\nCleaning up temporary files..."
    rm -rf "$TMP_DIR"
    if [ $exit_code -ne 0 ]; then
        echo "The script was interrupted or encountered an error during execution."
    fi
}
trap cleanup EXIT INT TERM

# ------------------------------------------------------------------------------
# 2. Shell and Sudoers Configuration
# ------------------------------------------------------------------------------
echo "==> Configuring root shell and sudo permissions..."
chsh -s /bin/bash root

if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

# ------------------------------------------------------------------------------
# 3. Backgrounds and Support Scripts
# ------------------------------------------------------------------------------
echo "==> Copying resources and backgrounds from repository..."
mkdir -p /usr/share/backgrounds/

if compgen -G "$SCRIPT_DIR/*.jpg" > /dev/null; then
    cp "$SCRIPT_DIR"/*.jpg /usr/share/backgrounds/
else
    echo "Notice: No .jpg images found in $SCRIPT_DIR"
fi

if [ -f "$SCRIPT_DIR/mount_disks.sh" ]; then
    cp "$SCRIPT_DIR/mount_disks.sh" /usr/bin/
    chmod +x /usr/bin/mount_disks.sh
fi

# ------------------------------------------------------------------------------
# 4. Repository Sync and Initial Update
# ------------------------------------------------------------------------------
echo "==> Syncing and enabling additional Void Linux repositories..."
xbps-install -Syu
xbps-install -y void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
xbps-install -Syu

# ------------------------------------------------------------------------------
# 5. Core Services Installation and Activation
# ------------------------------------------------------------------------------
echo "==> Installing essential utilities, network, and authentication tools..."
xbps-install -y nano NetworkManager polkit gnome-keyring dbus elogind

# Clean removal of conflicting network services
for svc in wpa_supplicant dhcpcd dhcpcd-eth0 sshd; do
    if [ -L "/var/service/$svc" ] || [ -e "/var/service/$svc" ]; then
        rm -f "/var/service/$svc"
    fi
done

# Safe service symlinking (prevents duplicate link errors)
for svc in NetworkManager dbus elogind; do
    if [ ! -L "/var/service/$svc" ]; then
        ln -s "/etc/sv/$svc" /var/service/
    fi
done

# Laptop Lid Configuration
clear
echo "Are you installing on a Desktop or Laptop/Notebook?"
echo "0) Desktop"
echo "1) Laptop/Notebook"
read -r -p "Please select an option [0-1]: " tipo_maquina

if [ "$tipo_maquina" = "1" ]; then
    echo "Configuring laptop lid switch options in elogind..."
    sed -i 's/.*HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/elogind/logind.conf
    sed -i 's/.*HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/elogind/logind.conf
    sed -i 's/.*HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/elogind/logind.conf
fi

# ------------------------------------------------------------------------------
# 6. Audio Server and Bluetooth
# ------------------------------------------------------------------------------
echo "==> Installing PipeWire, WirePlumber, and Bluetooth support..."
xbps-install -y pipewire wireplumber pavucontrol pulsemixer libspa-bluetooth blueman bluez-cups

# ------------------------------------------------------------------------------
# 7. NVIDIA Video Driver (Optional)
# ------------------------------------------------------------------------------
clear
echo "Available NVIDIA drivers:"
echo "1) Proprietary NVIDIA Driver + 32-bit Support (nvidia nvidia-libs-32bit)"
echo "0) Skip installation"
read -r -p "Please select (1 or 0): " opt_nvidia

if [ "$opt_nvidia" = "1" ]; then
    echo "Installing NVIDIA drivers..."
    xbps-install -y nvidia nvidia-libs-32bit
fi

# Steam compatibility and 32-bit libraries
xbps-install -y libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit

# ------------------------------------------------------------------------------
# 8. Cinnamon Desktop Environment and System Tools
# ------------------------------------------------------------------------------
echo "==> Installing XOrg, Cinnamon Desktop, and Tools..."
xbps-install -y xorg octoxbps cinnamon-all xdg-desktop-portal xdg-desktop-portal-gtk \
                xdg-user-dirs xdg-user-dirs-gtk xdg-utils wget binutils xz hicolor-icon-theme

# Cinnamon Spices.py Patch
if [ -f "/usr/share/cinnamon/cinnamon-settings/bin/Spices.py" ]; then
    echo "Applying patch to Spices.py for Cinnamon's download tab..."
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

# Printer Support and Filesystems
echo "==> Installing printer support and additional tools..."
xbps-install -y cups cups-filters gutenprint system-config-printer gnome-system-tools users-admin \
                exfat-utils fuse-exfat gvfs-afc gvfs-mtp gvfs-smb udisks2 ntfs-3g gptfdisk bluez GPaste \
                topgrade noto-fonts-cjk noto-fonts-emoji noto-fonts-ttf noto-fonts-ttf-extra

for svc in cupsd bluetoothd; do
    if [ ! -L "/var/service/$svc" ]; then
        ln -s "/etc/sv/$svc" /var/service/
    fi
done

# User Applications
echo "==> Installing user software..."
xbps-install -y firefox xfce4-terminal firefox-i18n-en-US gnome-calendar qalculate-gtk \
                smplayer qt5-styleplugins qt5ct qt6ct flameshot fastfetch numlockx

if ! grep -q "^QT_QPA_PLATFORMTHEME=" /etc/environment; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment
fi

# ------------------------------------------------------------------------------
# 9. Optional XFCE Terminal Customization
# ------------------------------------------------------------------------------
clear
echo "Do you want to apply visual customization to xfce4-terminal (transparency and font)?"
echo "Y) Yes"
echo "N) No"

personalizar_terminal=""
while true; do
    read -r -p "Please select [Y/N]: " input_val
    if [[ "$input_val" =~ ^[yY]$ ]]; then
        personalizar_terminal="yes"
        break
    elif [[ "$input_val" =~ ^[nN]$ ]]; then
        personalizar_terminal="no"
        break
    else
        echo "Invalid option! Type Y for Yes or N for No."
    fi
done

if [ "$personalizar_terminal" = "yes" ]; then
    echo "Configuring xfce4-terminal visual profile..."
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
# 10. File Manager Selection (Nemo, Thunar, or Nautilus)
# ------------------------------------------------------------------------------
clear
echo "=============================================================================="
echo "                     FILE MANAGER SELECTION"
echo "=============================================================================="
echo "Cinnamon installs Nemo by default. Choose which file manager you want to use:"
echo ""
echo "0) Keep Nemo (Cinnamon default)"
echo "   -> Note: On Void Linux, Nemo lacks 'Bulky' (bulk renamer)"
echo "      as it depends on X-apps modules not fully ported to Void yet."
echo ""
echo "1) Thunar (XFCE) [RECOMMENDED]"
echo "   -> Includes xarchiver and unrar integration."
echo "   -> If selected, Nemo and file-roller will be removed (via -Fy)."
echo ""
echo "2) Nautilus (GNOME)"
echo "   -> Warning: Nautilus does not come with unrar pre-installed. Even if you"
echo "      decide to install unrar later to handle .rar files,"
echo "      it still cannot extract password-protected .rar files."
echo "   -> If selected, Nemo will be removed (via -Fy)."
echo "=============================================================================="
read -r -p "Please select an option [0-2]: " fm_choice

case "$fm_choice" in
    1)
        echo "Installing Thunar and compression tools..."
        xbps-install -y Thunar thunar-archive-plugin xarchiver unrar

        echo "Removing Nemo and file-roller forcefully (-Fy)..."
        xbps-remove -Fy nemo file-roller

        xdg-mime default thunar.desktop inode/directory application/x-gnome-saved-search
        ;;
    2)
        echo "Installing Nautilus..."
        xbps-install -y nautilus

        echo "Removing Nemo forcefully (-Fy)..."
        xbps-remove -Fy nemo

        xdg-mime default org.gnome.Nautilus.desktop inode/directory application/x-gnome-saved-search
        ;;
    0|*)
        echo "Keeping Nemo as the default file manager."
        ;;
esac
sleep 1

# ------------------------------------------------------------------------------
# 11. Keyboard Layout, X11, and Autostart
# ------------------------------------------------------------------------------
mkdir -p /etc/X11/xorg.conf.d
cat << 'EOF' > /etc/X11/xorg.conf.d/30-scrolllock.conf
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "us"
    Option "XkbOptions" "scrolllock:mod3"
EndSection
EOF

# ------------------------------------------------------------------------------
# 12. Secure Download of Linux Mint Themes
# ------------------------------------------------------------------------------
echo "==> Downloading and installing Linux Mint themes, icons, and cursors..."
mkdir -p "$REAL_HOME/.themes" "$REAL_HOME/.icons"

download_and_extract_deb() {
    local url="$1"
    local pkg_name
    pkg_name=$(basename "$url")

    echo "Downloading $pkg_name..."
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

# User Initialization Script
cat <<EOL > "$REAL_HOME/set-keyboard.sh"
#!/bin/bash
gsettings set org.cinnamon.desktop.input-sources sources "[('xkb', 'us')]"
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
gsettings set org.cinnamon.desktop.interface clock-custom-format '%H:%M:%S\n%m/%d/%Y'

rm -f ~/.config/autostart/set-keyboard.desktop
EOL

chmod +x "$REAL_HOME/set-keyboard.sh"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/set-keyboard.sh"

# Autostart Entries
AUTOSTART_DIR="$REAL_HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat <<EOL > "$AUTOSTART_DIR/set-keyboard.desktop"
[Desktop Entry]
Type=Application
Exec=$REAL_HOME/set-keyboard.sh
Name=Set Mint Customization and Keyboard
Comment=Set default US keyboard layout, Mint themes, and clock format after login
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

cat <<EOL > "$AUTOSTART_DIR/x11kb-us.desktop"
[Desktop Entry]
Type=Application
Exec=/usr/bin/setxkbmap us
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=X11-KB-US
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
# 13. Display Manager (LightDM)
# ------------------------------------------------------------------------------
echo "==> Configuring LightDM..."
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
# 14. GRUB Configuration
# ------------------------------------------------------------------------------
echo "==> Configuring GRUB..."
sed -i 's/.*GRUB_BACKGROUND=.*/GRUB_BACKGROUND="\/usr\/share\/void-artwork\/splash.png"/' /etc/default/grub

clear
echo "Do you want to skip GRUB countdown and boot automatically?"
echo "Notice: If you use a laptop and it has a ghost key / firmware issue,"
echo "and you do not want to confirm the boot entry every time,"
echo "it is necessary to apply this change to skip the menu."
echo "1) Yes, boot directly and skip countdown"
echo "0) No, keep standard countdown and display menu"
read -r -p "Please select (0 or 1): " pular_grub

if [ "$tipo_maquina" = "1" ] || [ "$pular_grub" = "1" ]; then
    echo "Applying direct boot configuration..."
    sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
else
    echo "Keeping default GRUB countdown..."
    sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
fi

if command -v update-grub >/dev/null 2>&1; then
    update-grub
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# ------------------------------------------------------------------------------
# 15. System Locales (en_US.UTF-8)
# ------------------------------------------------------------------------------
echo "==> Configuring system locales..."
sed -i 's/^[[:space:]]*#[[:space:]]*\(en_US\.UTF-8[[:space:]]\+UTF-8\)/\1/' /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

touch /etc/locale.conf
{
    echo "LANG=en_US.UTF-8"
    echo "LC_TIME=en_US.UTF-8"
    echo "LC_COLLATE=C"
} > /etc/locale.conf

if [ -f "$SCRIPT_DIR/10-mount-drives.rules" ]; then
    mkdir -p /etc/polkit-1/rules.d/
    cp "$SCRIPT_DIR/10-mount-drives.rules" /etc/polkit-1/rules.d/
fi

echo "=============================================================================="
echo " Setup complete! The system is successfully configured and ready to reboot."
echo "=============================================================================="