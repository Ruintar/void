#!/bin/bash
# Automount script without vfat or ntfs partitions, only partitions with a non-vfat/ntfs filesystem are mounted
# Script de automount sem partições vfat ou ntfs, apenas partições com um sistema de arquivos que não seja vfat ou ntfs são montadas

echo "Starting the automount script... / Iniciando o script de automount..."

for dev in $(lsblk -lnpo NAME,FSTYPE,TYPE | awk '$2 && $3 == "part" {print $1}'); do
    echo "Checking device: $dev / Verificando dispositivo: $dev"

    fstype=$(lsblk -no FSTYPE "$dev")

    if [[ "$fstype" == "vfat" || "$fstype" == "ntfs" ]]; then
        echo "Skipping partition with $fstype: $dev / Pulando partição com $fstype: $dev"
        continue
    fi

    # findmnt: exact match on mount source (avoids false positives like sda1 matching sda10)
    # findmnt: correspondência exata na origem (evita falso positivo tipo sda1 casando com sda10)
    if ! findmnt -rn -S "$dev" > /dev/null; then
        echo "Mounting $dev... / Montando $dev..."
        udisksctl mount -b "$dev" || echo "Error mounting $dev / Erro ao montar $dev"
    else
        echo "$dev is already mounted. / $dev já está montado."
    fi
done

echo "Automount script finished. / Script de automount finalizado."