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

# Secure temporary directory for build/extraction
TMP_DIR=$(mktemp -d -t void-install-XXXXXX)
# Traversal permission: xdeb runs as a regular user inside this directory
chmod 755 "$TMP_DIR"

# Cleanup function executed on exit (Ctrl+C / Error / Normal end)
cleanup() {
    local exit_code=$?
    echo -e "\nCleaning up temporary files..."
    rm -rf "$TMP_DIR"
    if [ $exit_code -ne 0 ]; then
        echo "The script was interrupted or encountered an error during execution."
    fi
}
trap cleanup EXIT

# Run a command as the real user (xdeb and xdg-mime must not run as root).
# The -H flag ensures the real user's HOME is used.
run_as_user() {
    if [ "$REAL_USER" != "root" ]; then
        sudo -H -u "$REAL_USER" "$@"
    else
        "$@"
    fi
}

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
echo "==> Installing essential utilities, network, and login tools..."
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

# Laptop Configuration (Detection / User prompt)
clear
echo "Are you installing on a Desktop or Laptop/Notebook?"
echo "0) Desktop"
echo "1) Laptop/Notebook"
read -r -p "Please select an option [0-1]: " tipo_maquina

if [ "$tipo_maquina" = "1" ]; then
    echo "Configuring lid switch handling in elogind..."
    sed -i 's/.*HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/elogind/logind.conf
    sed -i 's/.*HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/elogind/logind.conf
    sed -i 's/.*HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/elogind/logind.conf
fi

# ------------------------------------------------------------------------------
# 6. Audio Server and Bluetooth
# ------------------------------------------------------------------------------
echo "==> Installing PipeWire, WirePlumber, and Bluetooth support..."
# rtkit: allows PipeWire to run with real-time priority
xbps-install -y pipewire wireplumber rtkit pavucontrol pulsemixer libspa-bluetooth blueman bluez-cups

# ------------------------------------------------------------------------------
# 7. GPU Detection and Video Drivers (NVIDIA + Steam 32-bit)
# ------------------------------------------------------------------------------
# Automatic NVIDIA GPU detection via lspci (works on hybrid Intel + NVIDIA /
# Optimus laptops). Machines WITHOUT NVIDIA skip this step on their own.
#
# The driver family is recommended from the PCI device ID (10de:XXXX),
# following the Void Linux support table:
#   nvidia     -> Turing or newer (595, open kernel modules)
#   nvidia580  -> Maxwell, Pascal and Volta (e.g.: 930MX, GTX 9xx/10xx, 1650)
#   nvidia470  -> Kepler (GTX 6xx/7xx)
#   nvidia390  -> Fermi (GeForce 400/500)
#
# The chosen package already handles everything else automatically (DKMS
# module, Nouveau blacklist and initramfs regeneration) via xbps hooks —
# no manual blacklist/dracut steps are needed.
# On Optimus laptops, only the NVIDIA GPU gets the driver; the Intel GPU
# keeps working through the Mesa drivers already included in Xorg.

NVIDIA_PKG=""

if command -v lspci >/dev/null 2>&1; then
    GPU_NVIDIA=$(lspci -d 10de: 2>/dev/null || true)
    # Classify only display devices (PCI class 03xx: VGA/3D/Display), skipping
    # the HDA audio function that ships alongside the GPU
    NVIDIA_IDS=$(lspci -d 10de: -n 2>/dev/null | awk '$2 ~ /^03/ {print $3}' | cut -d: -f2 || true)
else
    GPU_NVIDIA=""
    NVIDIA_IDS=""
fi

if [ -n "$GPU_NVIDIA" ]; then
    clear
    echo "NVIDIA GPU detected:"
    echo "$GPU_NVIDIA" | sed 's/^/  /'
    echo ""

    # Recommend the driver family based on each detected NVIDIA display GPU
    RECOMMENDED=""
    MIXED_FAMILIES=0
    for devid in $NVIDIA_IDS; do
        # Validate the ID (4 hexadecimal digits)
        if ! [[ "$devid" =~ ^[0-9a-fA-F]{4}$ ]]; then
            continue
        fi
        devnum=$((16#$devid))
        if   (( devnum >= 0x1E00 )); then fam="nvidia"      # Turing or newer
        elif (( devnum >= 0x1D80 )); then fam="nvidia580"   # Volta
        elif (( devnum >= 0x1B00 )); then fam="nvidia580"   # Pascal
        elif (( devnum >= 0x1300 )); then fam="nvidia580"   # Maxwell
        elif (( devnum >= 0x0F00 )); then fam="nvidia470"   # Kepler
        elif (( devnum >= 0x06C0 )); then fam="nvidia390"   # Fermi
        else fam="none"                                     # pre-Fermi: Nouveau only
        fi
        if [ -z "$RECOMMENDED" ]; then
            RECOMMENDED="$fam"
        elif [ "$RECOMMENDED" != "$fam" ]; then
            MIXED_FAMILIES=1
        fi
    done

    echo "NVIDIA drivers available on Void:"
    echo "  nvidia     (Turing or newer)"
    echo "  nvidia580  (Maxwell, Pascal, Volta)"
    echo "  nvidia470  (Kepler)"
    echo "  nvidia390  (Fermi)"
    echo ""
    if [ "$MIXED_FAMILIES" -eq 1 ]; then
        echo "More than one NVIDIA family was detected — please choose manually."
        RECOMMENDED=""
    elif [ "$RECOMMENDED" = "none" ]; then
        echo "GPU older than Fermi: the proprietary driver does not support it."
        echo "The free Nouveau driver will be kept."
        RECOMMENDED=""
    elif [ -n "$RECOMMENDED" ]; then
        echo "Detected family — recommended driver: $RECOMMENDED"
    fi
    echo ""
    echo "1) Install the recommended NVIDIA driver + 32-bit support"
    echo "2) Choose another driver version manually"
    echo "0) Skip installation (keep Nouveau)"

    while true; do
        read -r -p "Please select (0, 1 or 2): " opt_nvidia
        case "$opt_nvidia" in
            0)
                echo "NVIDIA driver installation skipped."
                NVIDIA_PKG=""
                break
                ;;
            1)
                if [ -z "$RECOMMENDED" ]; then
                    echo "No driver could be recommended automatically."
                    echo "Choose manually (option 2) or skip the installation (option 0)."
                else
                    NVIDIA_PKG="$RECOMMENDED"
                    break
                fi
                ;;
            2)
                while true; do
                    echo "Available versions:"
                    echo "1) nvidia     (Turing or newer)"
                    echo "2) nvidia580  (Maxwell, Pascal, Volta)"
                    echo "3) nvidia470  (Kepler)"
                    echo "4) nvidia390  (Fermi)"
                    read -r -p "Please select (1-4): " opt_familia
                    case "$opt_familia" in
                        1) NVIDIA_PKG="nvidia"; break ;;
                        2) NVIDIA_PKG="nvidia580"; break ;;
                        3) NVIDIA_PKG="nvidia470"; break ;;
                        4) NVIDIA_PKG="nvidia390"; break ;;
                        *) echo "Invalid option! Type a number between 1 and 4." ;;
                    esac
                done
                break
                ;;
            *)
                echo "Invalid option! Type 0, 1 or 2."
                ;;
        esac
    done

    if [ -n "$NVIDIA_PKG" ]; then
        echo "Installing the NVIDIA driver ($NVIDIA_PKG) + 32-bit libraries..."
        xbps-install -y "$NVIDIA_PKG" "${NVIDIA_PKG}-libs-32bit"
    fi
elif [ ! -e /proc/cmdline ] || ! command -v lspci >/dev/null 2>&1; then
    # Fallback: without pciutils there is no automatic detection — old-style prompt
    clear
    echo "Notice: the lspci command was not found (pciutils package)."
    echo "Automatic GPU detection is unavailable in this run."
    echo "Do you want to install the NVIDIA driver anyway?"
    echo "1) Proprietary NVIDIA Driver + 32-bit Support (nvidia nvidia-libs-32bit)"
    echo "0) Skip installation"
    while true; do
        read -r -p "Please select (1 or 0): " opt_nvidia
        case "$opt_nvidia" in
            1) NVIDIA_PKG="nvidia"; break ;;
            0) echo "NVIDIA driver installation skipped."; break ;;
            *) echo "Invalid option! Type 1 or 0." ;;
        esac
    done
    if [ -n "$NVIDIA_PKG" ]; then
        echo "Installing the NVIDIA driver ($NVIDIA_PKG) + 32-bit libraries..."
        xbps-install -y "$NVIDIA_PKG" "${NVIDIA_PKG}-libs-32bit"
    fi
else
    clear
    echo "No NVIDIA GPU detected — the NVIDIA driver step was skipped."
    echo "(Intel and AMD GPUs use the Mesa drivers installed ahead.)"
fi

# ------------------------------------------------------------------------------
# 32-bit components for Steam compatibility (independent prompt)
# ------------------------------------------------------------------------------
# Asked to ALL users, regardless of the GPU or chosen driver:
#   - AMD/Intel/Nouveau: these libraries are the 32-bit support for Steam and
#     32-bit games (Mesa/GLVnd).
#   - Proprietary NVIDIA: the driver's own 32-bit libraries were installed
#     above; the packages below complement the environment (gcc, libstdc++, drm).
clear
echo "Do you want to install the 32-bit components for Steam compatibility?"
echo "(libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit)"

opt_steam32=""
while true; do
    read -r -p "Please select (1 = Yes / 0 = No): " input_steam
    case "$input_steam" in
        1) opt_steam32="yes"; break ;;
        0) opt_steam32="no"; break ;;
        *) echo "Invalid option! Type 1 for Yes or 0 for No." ;;
    esac
done

if [ "$opt_steam32" = "yes" ]; then
    echo "Installing 32-bit components for Steam..."
    xbps-install -y libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit
else
    echo "Steam 32-bit components will not be installed."
fi

# ------------------------------------------------------------------------------
# 8. Cinnamon Desktop Environment and System Tools
# ------------------------------------------------------------------------------
echo "==> Installing XOrg, Cinnamon Desktop, and Tools..."
xbps-install -y xorg octoxbps cinnamon-all xdg-desktop-portal xdg-desktop-portal-gtk \
                xdg-user-dirs xdg-user-dirs-gtk xdg-utils wget binutils xz hicolor-icon-theme

# Nemo (Cinnamon default) + File Roller and RAR archive support
# (including password-protected files, via unrar) and 7-Zip, with Nemo integration
echo "==> Installing Nemo, File Roller, and compression support (RAR/7Zip)..."
xbps-install -y nemo file-roller nemo-fileroller unrar p7zip

# Guarantees Nemo as the user's default file manager
run_as_user xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

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
echo "==> Installing printer support and filesystem tools..."
# gnome-disk-utility: GNOME Disks (disk management)
# gnome-screenshot: used by the Cinnamon Print key
xbps-install -y cups cups-filters gutenprint system-config-printer \
                gnome-disk-utility gnome-screenshot \
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
# 10. Bulk Renamer (Bulky) via xdeb
# ------------------------------------------------------------------------------
echo "==> Installing Bulky (Linux Mint bulk renamer) via xdeb..."

# xdeb dependencies
xbps-install -y binutils tar curl xbps xz

# Build directory (owned by the real user, since xdeb must not run as root)
BULKY_DIR="$TMP_DIR/bulky-build"
mkdir -p "$BULKY_DIR"
chown -R "$REAL_USER:$REAL_USER" "$BULKY_DIR"

# Download of the Bulky .deb and xdeb
# NOTICE: the packages.linuxmint.com HTTP URL is INTENTIONAL — HTTPS on this
# host fails the wget/curl handshake in this environment. Do not switch to HTTPS.
run_as_user bash -c "
    set -e
    cd '$BULKY_DIR'
    echo 'Downloading bulky_4.2_all.deb...'
    wget -q 'http://packages.linuxmint.com/pool/main/b/bulky/bulky_4.2_all.deb'
    echo 'Downloading xdeb...'
    curl -sLO 'https://github.com/xdeb-org/xdeb/releases/latest/download/xdeb'
    chmod +x xdeb
"

# Makes xdeb globally available
mv "$BULKY_DIR/xdeb" /usr/local/bin/xdeb

# Converts the .deb into an xbps package (generates the xdeb local 'binpkgs' repo)
echo "Converting Bulky (.deb -> xbps) with xdeb..."
run_as_user bash -c "cd '$BULKY_DIR' && xdeb -Sedf bulky_4.2_all.deb"

# Installs the converted package from the local repository generated by xdeb
if compgen -G "$BULKY_DIR/binpkgs/bulky-*.xbps" > /dev/null; then
    echo "Installing the converted package..."
    xbps-install -y -R "$BULKY_DIR/binpkgs" -i bulky
else
    echo "Error: xdeb did not generate the Bulky package in $BULKY_DIR/binpkgs." >&2
    exit 1
fi

# Python dependencies of Bulky (via xbps, no pip)
echo "Installing Python dependencies (python3-setproctitle, python3-Unidecode)..."
xbps-install -y python3-setproctitle python3-Unidecode

# Compiles the GLib schemas so the 'org.x.bulky' schema is recognized
echo "Compiling GLib schemas..."
glib-compile-schemas /usr/share/glib-2.0/schemas/

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

# NOTICE: the packages.linuxmint.com HTTP URL is INTENTIONAL — HTTPS on this
# host fails the wget/curl handshake in this environment. Do not switch to HTTPS.
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

# User initialization script
# (applies keyboard, themes and clock on first login; no ghost keys —
#  the clock applet format is handled by the repair block below)
cat <<EOL > "$REAL_HOME/set-keyboard.sh"
#!/bin/bash
set -e
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
# Clock format repair (calendar@cinnamon.org applet)
# ------------------------------------------------------------------------------
# The clock applet stores its settings in JSON files:
#   1) Fresh installs: defaults come from the applet's global settings-schema.json.
#   2) Re-runs: per-instance JSONs already exist under
#      ~/.config/cinnamon/spices/calendar@cinnamon.org/ and must be fixed.
# In both cases we apply the two-line format (time/seconds on top,
# date below) with a real newline. The __md5__ is left untouched — the old
# checksum makes the applet reload the values from disk instead of resetting
# the schema.

REAL_HOME="$REAL_HOME" python3 - <<'PYEOF'
import glob, json, os

REAL_HOME = os.environ.get('REAL_HOME', '')
FORMAT = "%H:%M:%S\n%m/%d/%Y"

# 1) Global applet schema (affects fresh installs and new instances)
schema_path = '/usr/share/cinnamon/applets/calendar@cinnamon.org/settings-schema.json'
if os.path.isfile(schema_path):
    with open(schema_path, 'r', encoding='utf-8') as f:
        schema = json.load(f)
    changed = False
    for key, item in schema.items():
        if key == '__md5__' or not isinstance(item, dict):
            continue
        if key == 'use-custom-format':
            item['default'] = True
            changed = True
        elif key == 'custom-format':
            item['default'] = FORMAT
            changed = True
    if changed:
        with open(schema_path, 'w', encoding='utf-8') as f:
            json.dump(schema, f, indent=4, ensure_ascii=False)

# 2) Existing instances (script re-runs)
if REAL_HOME:
    spice_dir = os.path.join(REAL_HOME, '.config/cinnamon/spices/calendar@cinnamon.org')
    for path in glob.glob(os.path.join(spice_dir, '*.json')):
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        changed = False
        if isinstance(data.get('use-custom-format'), dict):
            data['use-custom-format']['value'] = True
            changed = True
        if isinstance(data.get('custom-format'), dict):
            data['custom-format']['value'] = FORMAT
            changed = True
        if changed:
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=4, ensure_ascii=False)
PYEOF

# ------------------------------------------------------------------------------
# Critical ownership guarantee for ~/.config
# ------------------------------------------------------------------------------
# The script runs as root: without this chown, files created inside ~/.config
# in this section end up root:root and dconf/Cinnamon fails silently
# (theme, wallpaper, icons and keyboard never persist in the session).
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config"

# ------------------------------------------------------------------------------
# 13. Display Manager (LightDM)
# ------------------------------------------------------------------------------
echo "==> Configuring LightDM..."
xbps-install -y lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

if [ ! -L "/var/service/lightdm" ]; then
    ln -s /etc/sv/lightdm/ /var/service/
fi

# PAM: unlocks the gnome-keyring together with the LightDM login
# (fixes the "keyringPrompt: Failed to show modal dialog" error)
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

# Pipewire Autostart Config
mkdir -p /etc/pipewire/pipewire.conf.d
[ -f /usr/share/examples/wireplumber/10-wireplumber.conf ] && ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
[ -f /usr/share/examples/pipewire/20-pipewire-pulse.conf ] && ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
[ -f /usr/share/applications/pipewire.desktop ] && ln -sf /usr/share/applications/pipewire.desktop /etc/xdg/autostart/

# ------------------------------------------------------------------------------
# 14. GRUB Configuration
# ------------------------------------------------------------------------------
echo "==> Configuring GRUB..."
sed -i 's/.*GRUB_BACKGROUND=.*/GRUB_BACKGROUND="\/usr\/share\/void-artwork\/splash.png"/' /etc/default/grub

clear
echo "Do you want to skip the GRUB countdown and boot automatically?"
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

# Final guarantee: makes sure the GLib schemas (including org.x.bulky) stay
# compiled, in case a package installed afterwards regenerated the cache
glib-compile-schemas /usr/share/glib-2.0/schemas/ > /dev/null 2>&1 || true

echo "=============================================================================="
echo " Setup complete! The system is successfully configured and ready to reboot."
echo "=============================================================================="
