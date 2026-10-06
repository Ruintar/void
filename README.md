# Void Linux Cinnamon Installation Script

This script simplifies the installation of Void Linux with the Cinnamon desktop environment.

## Requirements
- Void Linux (glibc) has been installed using the base image.
- The installed Void Linux has been booted.
- An internet connection is available.

## Initial Steps

1. **Log into Void Linux** (as a normal user).
2. **Install `git`**:
   ```bash
   sudo xbps-install git
   ```
3. **Clone the repository** (as a normal user):
   ```bash
   git clone https://github.com/Ruintar/void.git
   ```
   > *Note:* The repository will be cloned to `~/void`.
4. **Navigate to the directory**:
   ```bash
   cd void
   ```
5. **Make the script executable**:
   ```bash
   chmod +x cinnamon_install.sh
   ```
6. **Run the script**:
   ```bash
   ./cinnamon_install.sh
   ```

## What does the script do?
- Installs Void Linux with the Cinnamon desktop environment (`cinnamon-all`) in its vanilla state.
- Activates essential services:
  - PipeWire & WirePlumber
  - Printer support (CUPS)
  - Bluetooth
- During installation, you will be prompted to choose whether you want to install NVIDIA drivers.
- Automatically mounts drives using `udisks2` & `polkit`, so there's no need to edit `/etc/fstab`.
- Customizations:
  - Cinnamon and LightDM background images are configured.
  - Autostart entries and scripts:
    - **Enables `octoxbps-updater`**.
    - **Sets the Brazilian Portuguese keyboard layout (`br`)**.
    - **Automounts Linux filesystem drives**, perfect for organizing files or a Steam library.

## Feedback
Suggestions and improvements are always welcome! 😊