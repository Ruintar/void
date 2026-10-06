#!/bin/bash
# Automount script without vfat or ntfs partitions, only partitions with a non-vfat/ntfs filesystem are mounted
# Script de automount sem partições vfat ou ntfs, apenas partições com um sistema de arquivos que não seja vfat ou ntfs são montadas

echo "Starting the automount script... / Iniciando o script de automount..."

# Find all partitions with a filesystem (only check 'part' and 'fstype')
# Encontrar todas as partições com um sistema de arquivos (verificar apenas 'part' e 'fstype')
for dev in $(lsblk -lnpo NAME,FSTYPE,TYPE | awk '$2 && $3 == "part" {print $1}'); do
    echo "Checking device: $dev / Verificando dispositivo: $dev"

    # Check if the filesystem is vfat or ntfs
    # Verificar se o sistema de arquivos é vfat ou ntfs
    fstype=$(lsblk -no FSTYPE "$dev")
    
    # Skip vfat and ntfs partitions
    # Pular partições vfat e ntfs
    if [[ "$fstype" == "vfat" || "$fstype" == "ntfs" ]]; then
        echo "Skipping partition with $fstype: $dev / Pulando partição com $fstype: $dev"
        continue
    fi

    # Check if the partition is already mounted
    # Verificar se a partição já está montada
    if ! mount | grep -q "$dev"; then
        echo "Mounting $dev... / Montando $dev..."
        udisksctl mount -b "$dev" || echo "Error mounting $dev / Erro ao montar $dev"
    else
        echo "$dev is already mounted. / $dev já está montado."
    fi
done

echo "Automount script finished. / Script de automount finalizado."