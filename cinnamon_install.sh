#!/bin/bash

while true; do
    clear
    echo "=========================================================="
    echo " Select Language / Selecione o Idioma / Seleccione el Idioma"
    echo "=========================================================="
    echo " 1) English (EN_US)"
    echo " 2) Português (PT_BR)"
    echo " 3) Español (ES_ES)"
    echo " 0) Exit / Sair / Salir"
    echo "=========================================================="
    read -p "Option / Opção / Opción [0-3]: " input_val

    # Valida se a entrada é estritamente 0, 1, 2 ou 3 (rejeita letras, símbolos, espaços e vazios)
    # Validates if input is strictly 0, 1, 2 or 3 (rejects letters, symbols, spaces and empty inputs)
    # Valida si la entrada es estrictamente 0, 1, 2 o 3 (rechaza letras, símbolos, espacios y vacíos)
    if [[ "$input_val" =~ ^[0-3]$ ]]; then
        case "$input_val" in
            1)
                # Checks and runs the English script
                if [ -f "./cinnamon_install_EN_US.sh" ]; then
                    bash ./cinnamon_install_EN_US.sh
                else
                    echo "Error: cinnamon_install_EN_US.sh not found!"
                fi
                exit 0
                ;;
            2)
                # Verifica e executa o script em português
                if [ -f "./cinnamon_install_PT_BR.sh" ]; then
                    bash ./cinnamon_install_PT_BR.sh
                else
                    echo "Erro: cinnamon_install_PT_BR.sh não encontrado!"
                fi
                exit 0
                ;;
            3)
                # Verifica y ejecuta el script en español
                if [ -f "./cinnamon_install_ES_ES.sh" ]; then
                    bash ./cinnamon_install_ES_ES.sh
                else
                    echo "Error: cinnamon_install_ES_ES.sh no encontrado!"
                fi
                exit 0
                ;;
            0)
                echo "Exiting. / Saindo. / Saliendo."
                exit 0
                ;;
        esac
    else
        echo ""
        echo "----------------------------------------------------------"
        echo " [EN-US] Invalid option! Please try again or exit."
        echo " [PT-BR] Opção inválida! Tente novamente ou cancele."
        echo " [ES-ES] ¡Opción inválida! Inténtelo de nuevo o salga."
        echo "----------------------------------------------------------"
        sleep 2
    fi
done