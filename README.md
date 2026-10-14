<div align="center">

[![PT-BR](https://img.shields.io/badge/Lang-PT--BR-green.svg)](#português-pt-br) 
[![EN-US](https://img.shields.io/badge/Lang-EN--US-blue.svg)](#english-en-us)
[![ES-ES](https://img.shields.io/badge/Lang-ES--ES-yellow.svg)](#español-es-es)

</div>

---

# <a id="português-pt-br"></a>🇧🇷 Script de Instalação do Void Linux com Cinnamon

Este script automatiza a pós-instalação do Void Linux, transformando uma instalação em modo texto puro em um sistema desktop completo, moderno e otimizado com o ambiente gráfico Cinnamon.

## Requisitos
- Void Linux (`glibc`) instalado utilizando a imagem base.
- Sistema já inicializado após a primeira instalação.
- Conexão com a internet ativa.

## Passos Iniciais

1. **Faça login no Void Linux** (como usuário normal).
2. **Instale o `git`**:
   ```bash
   sudo xbps-install -S git
   ```
3. **Clone o repositório** (como usuário normal):
   ```bash
   git clone https://github.com/Ruintar/void.git
   ```
   > *Nota:* O repositório será clonado na pasta `~/void`.
4. **Entre no diretório**:
   ```bash
   cd void
   ```
5. **Torne o lançador executável**:
   ```bash
   chmod +x cinnamon_install.sh
   ```
6. **Execute o lançador com sudo** (obrigatório):
   ```bash
   sudo ./cinnamon_install.sh
   ```
   > *Nota:* O lançador pede a seleção do idioma (PT-BR, EN-US ou ES-ES), verifica os privilégios de root e aplica automaticamente as permissões de execução em todos os scripts.

## O que o script faz?

- **Lançador Multilíngue**: Menu interativo de idioma que executa o instalador correspondente (Português, Inglês ou Espanhol), com correção automática das permissões de execução dos scripts.
- **Ambiente Gráfico e Login**: Instala o Xorg, o Cinnamon completo (`cinnamon-all`) e o LightDM junto com o painel de configurações.
- **Serviços Essenciais (Runit)**: NetworkManager, PipeWire/WirePlumber, CUPS, Bluetooth e Elogind — com remoção automática de serviços conflitantes (`wpa_supplicant`, `dhcpcd`, `sshd`).
- **Gerenciador de Arquivos Completo**: Nemo (padrão do Cinnamon) + File Roller com integração no Nemo, `unrar` (suporte a RAR protegidos por senha) e `p7zip`.
- **Bulky (Renomeador em Massa)**: Instala o renomeador do Linux Mint no Void via `xdeb`, incluindo as dependências Python (`python3-setproctitle`, `python3-Unidecode`) e a compilação dos schemas do GLib.
- **Configuração Inteligente do GRUB**: etapa interativa para decidir se deseja pular o menu de inicialização (útil para notebooks com tecla fantasma), plano de fundo personalizado e `grub-mkconfig` como fallback.
- **Localização e Teclado**: `pt_BR.UTF-8`, layout ABNT2 e pacote de idioma pt-BR para o Firefox.
- **Drivers de Vídeo e Jogos**: opção interativa para os drivers NVIDIA com bibliotecas de 32 bits + dependências da Steam.
- **Customizações**:
  - Temas, ícones e cursores do Linux Mint (`Mint-Y-Dark`).
  - `xfce4-terminal` com transparência e estilo próprio (opcional, interativo).
  - NumLock no boot, relógio 24h com data brasileira e Scroll Lock nativo no X11.
  - Montagem automática de discos (`udisks2` + `polkit`), dispensando o `/etc/fstab`.

## Feedback
Sugestões, correções e melhorias são sempre muito bem-vindas! 😊

---

# <a id="english-en-us"></a>🇺🇸 Void Linux Cinnamon Installation Script

This script automates the post-installation of Void Linux, turning a pure text installation into a full, modern, and optimized desktop environment powered by the Cinnamon graphical environment.

## Requirements
- Void Linux (`glibc`) installed using the base image.
- System already booted after the initial installation.
- Active internet connection.

## Initial Steps

1. **Log into Void Linux** (as a normal user).
2. **Install `git`**:
   ```bash
   sudo xbps-install -S git
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
5. **Make the launcher executable**:
   ```bash
   chmod +x cinnamon_install.sh
   ```
6. **Run the launcher with sudo** (required):
   ```bash
   sudo ./cinnamon_install.sh
   ```
   > *Note:* The launcher asks for the installation language (PT-BR, EN-US or ES-ES), checks root privileges, and automatically fixes execution permissions on all scripts.

## What does the script do?

- **Multilingual Launcher**: Interactive language menu that runs the matching installer (Portuguese, English, or Spanish), with automatic execution-permission fixing.
- **Graphical Environment & Login**: Installs Xorg, full Cinnamon (`cinnamon-all`), and LightDM along with the configuration panel.
- **Essential Services (Runit)**: NetworkManager, PipeWire/WirePlumber, CUPS, Bluetooth, and Elogind — with automatic removal of conflicting services (`wpa_supplicant`, `dhcpcd`, `sshd`).
- **Full File Manager Stack**: Nemo (Cinnamon default) + File Roller with Nemo integration, `unrar` (password-protected RAR support), and `p7zip`.
- **Bulky (Bulk Renamer)**: Installs the Linux Mint bulk renamer on Void via `xdeb`, including Python dependencies (`python3-setproctitle`, `python3-Unidecode`) and GLib schema compilation.
- **Smart GRUB Configuration**: Interactive step to decide whether to skip the boot menu (useful for laptops with ghost-key firmware issues), custom background, and `grub-mkconfig` fallback.
- **Localization and Keyboard**: `en_US.UTF-8`, US keyboard layout, and the English US Firefox language pack.
- **Video Drivers and Gaming**: Interactive option for proprietary NVIDIA drivers with 32-bit libraries + Steam dependencies.
- **Customizations**:
  - Linux Mint themes, icons, and cursors (`Mint-Y-Dark`).
  - `xfce4-terminal` transparency and visual style (optional, interactive).
  - NumLock on boot, 24h clock with US date format, native X11 Scroll Lock.
  - Automatic mounting of drives (`udisks2` + `polkit`), avoiding manual `/etc/fstab` edits.

## Feedback
Suggestions, corrections, and improvements are always welcome! 😊

---

# <a id="español-es-es"></a>🇪🇸 Script de Instalación de Void Linux con Cinnamon

Este script automatiza la posinstalación de Void Linux, transformando una instalación en modo texto puro en un entorno de escritorio completo, moderno y optimizado con el entorno gráfico Cinnamon.

## Requisitos
- Void Linux (`glibc`) instalado utilizando la imagen base.
- Sistema ya inicializado tras la primera instalación.
- Conexión a internet activa.

## Pasos Iniciales

1. **Inicie sesión en Void Linux** (como usuario normal).
2. **Instale `git`**:
   ```bash
   sudo xbps-install -S git
   ```
3. **Clone el repositorio** (como usuario normal):
   ```bash
   git clone https://github.com/Ruintar/void.git
   ```
   > *Nota:* El repositorio se clonará en la carpeta `~/void`.
4. **Entre al directorio**:
   ```bash
   cd void
   ```
5. **Haga ejecutable el lanzador**:
   ```bash
   chmod +x cinnamon_install.sh
   ```
6. **Ejecute el lanzador con sudo** (obligatorio):
   ```bash
   sudo ./cinnamon_install.sh
   ```
   > *Nota:* El lanzador pide seleccionar el idioma (PT-BR, EN-US o ES-ES), verifica los privilegios de root y aplica automáticamente los permisos de ejecución en todos los scripts.

## ¿Qué hace el script?

- **Lanzador Multilingüe**: Menú interactivo de idioma que ejecuta el instalador correspondiente (Portugués, Inglés o Español), con corrección automática de los permisos de ejecución.
- **Entorno Gráfico y Login**: Instala Xorg, el Cinnamon completo (`cinnamon-all`) y LightDM junto con el panel de configuración.
- **Servicios Esenciales (Runit)**: NetworkManager, PipeWire/WirePlumber, CUPS, Bluetooth y Elogind — con eliminación automática de servicios en conflicto (`wpa_supplicant`, `dhcpcd`, `sshd`).
- **Gestor de Archivos Completo**: Nemo (predeterminado de Cinnamon) + File Roller con integración en Nemo, `unrar` (soporte de RAR protegidos por contraseña) y `p7zip`.
- **Bulky (Renombrador Masivo)**: Instala el renombrador de Linux Mint en Void vía `xdeb`, incluyendo las dependencias Python (`python3-setproctitle`, `python3-Unidecode`) y la compilación de los schemas de GLib.
- **Configuración Inteligente de GRUB**: paso interactivo para decidir si omitir el menú de arranque (útil para portátiles con teclas fantasma), fondo personalizado y `grub-mkconfig` como respaldo.
- **Localización y Teclado**: `es_ES.UTF-8`, teclado español y paquete de idioma español para Firefox.
- **Controladores Gráficos y Juegos**: opción interactiva para los controladores NVIDIA con bibliotecas de 32 bits + dependencias de Steam.
- **Personalizaciones**:
  - Temas, iconos y cursores de Linux Mint (`Mint-Y-Dark`).
  - `xfce4-terminal` con transparencia y estilo propio (opcional, interactivo).
  - NumLock en el arranque, reloj 24h con fecha en español y Scroll Lock nativo en X11.
  - Montaje automático de discos (`udisks2` + `polkit`), evitando el `/etc/fstab`.

## Feedback
¡Sugerencias, correcciones y mejoras son siempre bienvenidas! 😊
