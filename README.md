# Script de Instalação do Void Linux com Cinnamon

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
  - Possui uma etapa interativa para decidir se deseja pular o menu de inicialização (muito útil para notebooks com problemas de teclas fantasmas/firmware).
  - Aplica plano de fundo personalizado e paleta de cores.
  - Utiliza `update-grub` com suporte a fallback automático para `grub-mkconfig`.
- **Localização e Idioma (Locales)**: 
  - Gera e configura o sistema globalmente para o Português do Brasil (`pt_BR.UTF-8`).
  - Configura separadamente as variáveis `LC_TIME=pt_BR.UTF-8` e `LC_COLLATE=C` de forma segura no `/etc/locale.conf`.
- **Drivers de Vídeo e Jogos**:
  - Opção interativa para instalação dos drivers proprietários da NVIDIA com bibliotecas de 32 bits.
  - Instala dependências essenciais para compatibilidade com a Steam e jogos.
- **Customizações e Ferramentas**:
  - Configura o teclado brasileiro (ABNT2) e ativa o NumLock no boot.
  - Baixa e aplica os temas, ícones e cursores visuais do Linux Mint (`Mint-Y-Dark`).
  - Configura a transparência e estilo visual do `xfce4-terminal`.
  - Ativa o Scroll Lock nativo no X11 (`scrolllock:mod3`).
  - Configura montagem automática de partições e discos (`udisks2` + `polkit`), dispensando edições manuais no `/etc/fstab`.

## Feedback
Sugestões, correções e melhorias são sempre muito bem-vindas! 😊