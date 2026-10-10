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
   git clone [https://github.com/Ruintar/void.git](https://github.com/Ruintar/void.git)
   ```
   > *Nota:* O repositório será clonado na pasta `~/void`.
4. **Entre no diretório**:
   ```bash
   cd void
   ```
5. **Torne o script executável**:
   ```bash
   chmod +x cinnamon_install.sh
   ```
6. **Execute o script**:
   ```bash
   ./cinnamon_install.sh
   ```

## O que o script faz?

- **Ambiente Gráfico e Login**: Instala o servidor gráfico Xorg, o Cinnamon completo (`cinnamon-all`) e o gerenciador de login LightDM junto com o painel de configurações (`lightdm-gtk-greeter-settings`).
- **Serviços Essenciais (Runit)**: Configura e ativa automaticamente serviços vitais:
  - NetworkManager (gerenciamento de redes)
  - PipeWire e WirePlumber (servidor de áudio)
  - CUPS (suporte a impressoras)
  - Bluetooth e Elogind
- **Configuração Inteligente do GRUB**: 
  - Possui uma etapa interativa para decidir se deseja pular o menu de inicialização.
  - Aplica plano de fundo personalizado e paleta de cores.
  - Utiliza `update-grub` com suporte a fallback automático para `grub-mkconfig`.
- **Localização e Teclado**: 
  - Configura o sistema para o Português do Brasil (`pt_BR.UTF-8` e `LC_TIME=pt_BR.UTF-8`, com `LC_COLLATE=C`).
  - Configura o layout de teclado brasileiro (ABNT2) e pacote de idioma pt-BR para o Firefox.
- **Drivers de Vídeo e Jogos**:
  - Opção interativa para instalação dos drivers proprietários da NVIDIA com bibliotecas de 32 bits.
  - Instala dependências essenciais para compatibilidade com a Steam e jogos.
- **Customizações e Ferramentas**:
  - Ativa o NumLock no boot e formatação de relógio 24h/data brasileira.
  - Baixa e aplica os temas, ícones e cursores visuais do Linux Mint (`Mint-Y-Dark`).
  - Configura a transparência e estilo visual do `xfce4-terminal`.
  - Ativa o Scroll Lock nativo no X11 (`scrolllock:mod3`).
  - Configura montagem automática de partições e discos (`udisks2` + `polkit`), dispensando edições manuais no `/etc/fstab`.

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
   git clone [https://github.com/Ruintar/void.git](https://github.com/Ruintar/void.git)
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

- **Graphical Environment & Login**: Installs the Xorg graphic server, full Cinnamon (`cinnamon-all`), and LightDM display manager along with the configuration panel (`lightdm-gtk-greeter-settings`).
- **Essential Services (Runit)**: Automatically configures and starts vital services:
  - NetworkManager (network management)
  - PipeWire & WirePlumber (audio server)
  - CUPS (printer support)
  - Bluetooth and Elogind
- **Smart GRUB Configuration**: 
  - Features an interactive step to decide whether to skip the boot menu.
  - Applies custom background and color palette.
  - Uses `update-grub` with automatic fallback support to `grub-mkconfig`.
- **Localization and Keyboard**: 
  - Configures the system globally for English US (`en_US.UTF-8` and `LC_TIME=en_US.UTF-8`, with `LC_COLLATE=C`).
  - Configures US keyboard layout and English US Firefox language pack (`firefox-i18n-en-US`).
- **Video Drivers and Gaming**:
  - Interactive option to install proprietary NVIDIA drivers with 32-bit libraries.
  - Installs essential dependencies for Steam and gaming compatibility.
- **Customizations and Tools**:
  - Enables NumLock on boot and US date format (`mm/dd/yyyy`).
  - Downloads and applies Linux Mint themes, icons, and cursor styles (`Mint-Y-Dark`).
  - Configures `xfce4-terminal` transparency and visual style.
  - Enables native X11 Scroll Lock (`scrolllock:mod3`).
  - Configures automatic mounting of partitions and drives (`udisks2` + `polkit`), avoiding manual edits to `/etc/fstab`.

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
   git clone [https://github.com/Ruintar/void.git](https://github.com/Ruintar/void.git)
   ```
   > *Nota:* El repositorio se clonará en la carpeta `~/void`.
4. **Entre al directorio**:
   ```bash
   cd void
   ```
5. **Haga que el script sea ejecutable**:
   ```bash
   chmod +x cinnamon_install.sh
   ```
6. **Ejecute el script**:
   ```bash
   ./cinnamon_install.sh
   ```

## ¿Qué hace el script?

- **Entorno Gráfico y Login**: Instala el servidor gráfico Xorg, el Cinnamon completo (`cinnamon-all`) y el gestor de inicio de sesión LightDM junto con el panel de configuración (`lightdm-gtk-greeter-settings`).
- **Servicios Esenciales (Runit)**: Configura y activa automáticamente servicios vitales:
  - NetworkManager (gestión de redes)
  - PipeWire y WirePlumber (servidor de audio)
  - CUPS (soporte para impresoras)
  - Bluetooth y Elogind
- **Configuración Inteligente de GRUB**: 
  - Incluye un paso interactivo para decidir si desea omitir el menú de arranque.
  - Aplica un fondo personalizado y paleta de colores.
  - Utiliza `update-grub` con soporte de respaldo automático a `grub-mkconfig`.
- **Localización y Teclado**: 
  - Configura el sistema globalmente para Español (`es_ES.UTF-8` y `LC_TIME=es_ES.UTF-8`, con `LC_COLLATE=C`).
  - Configura la distribución de teclado en español (`es`) y el paquete de idioma en español para Firefox (`firefox-i18n-es-ES`).
- **Controladores Gráficos y Juegos**:
  - Opción interactiva para instalar controladores propietarios NVIDIA con bibliotecas de 32 bits.
  - Instala dependencias esenciales para compatibilidad con Steam y juegos.
- **Personalizaciones y Herramientas**:
  - Activa NumLock en el arranque y formato de fecha en español (`dd/mm/yyyy`).
  - Descarga y aplica temas, iconos y cursores visuales de Linux Mint (`Mint-Y-Dark`).
  - Configura la transparencia y estilo visual de `xfce4-terminal`.
  - Activa Scroll Lock nativo en X11 (`scrolllock:mod3`).
  - Configura el montaje automático de particiones y discos (`udisks2` + `polkit`), evitando ediciones manuales en `/etc/fstab`.

## Feedback
¡Sugerencias, correcciones y mejoras son siempre bienvenidas! 😊