#!/bin/bash
# ==============================================================================
# Lançador Central de Pós-Instalação do Void Linux (Cinnamon Desktop)
# ==============================================================================

set -euo pipefail

# Obter o diretório absoluto onde o lançador está localizado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificar privilégios de root para a execução do lançador
if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script lançador precisa ser executado com privilégios de root (via sudo)."
    echo "Exemplo: sudo ./cinnamon_install.sh"
    exit 1
fi

clear
echo "=============================================================================="
echo "      Void Linux Cinnamon Post-Installation / Pós-Instalação / Posinstalación"
echo "=============================================================================="
echo ""
echo "Select language / Selecione o idioma / Seleccione el idioma:"
echo ""
echo "  1) Português (Brasil)  - [PT-BR]"
echo "  2) English (US)        - [EN-US]"
echo "  3) Español (España)    - [ES-ES]"
echo "  0) Exit / Sair / Salir"
echo ""

while true; do
    read -r -p "Option / Opção / Opción [0-3]: " lang_choice
    case "$lang_choice" in
        1)
            echo "Iniciando instalação em Português (Brasil)..."
            exec "$SCRIPT_DIR/cinnamon_install_PT_BR.sh"
            ;;
        2)
            echo "Starting installation in English (US)..."
            exec "$SCRIPT_DIR/cinnamon_install_EN_US.sh"
            ;;
        3)
            echo "Iniciando instalación en Español (España)..."
            exec "$SCRIPT_DIR/cinnamon_install_ES_ES.sh"
            ;;
        0)
            echo "Exiting / Saindo / Saliendo..."
            exit 0
            ;;
        *)
            echo ""
            echo "----------------------------------------------------------"
            echo " [EN-US] Invalid option! Please try again or exit."
            echo " [PT-BR] Opção inválida! Tente novamente ou cancele."
            echo " [ES-ES] ¡Opción inválida! Inténtelo de nuevo o salga."
            echo "----------------------------------------------------------"
            ;;
    esac
done