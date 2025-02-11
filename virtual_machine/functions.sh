#!/bin/bash


function vm_disk_create()
{
    if [ -z "$1" ];
    then
        echo "Error: No disk file name provided.";
        echo "Usage: vm_disk_create <disk_filename>.qcow2";
        return 1;
    fi

    qemu-img create -f qcow2 "$PWD/$1" 40G;

    echo "Virtual disk $1 created in $PWD";
};

function vm_os_install()
{
    if [ -z "$1" ] || [ -z "$2" ];
    then
        echo "Error: Missing arguments.";
        echo "Usage: vm_os_install <iso_filepath> <disk_filename>.qcow2";
        return 1;
    fi

    qemu-system-x86_64 \
        -enable-kvm \
        -m 4096 \
        -cpu host \
        -smp 2 \
        -cdrom "$1" \
        -drive file="$PWD/$2",format=qcow2 \
        -boot d \
        -vga virtio \
        -display sdl;
};

function vm_run()
{
    if [ -z "$1" ];
    then
        echo "Error: No disk file name provided.";
        echo "Usage: vm_run <disk_filename>.qcow2";
        return 1;
    fi

    qemu-system-x86_64 \
        -enable-kvm \
        -m 4096 \
        -cpu host \
        -smp 2 \
        -drive file="$PWD/$1",format=qcow2,snapshot=on \
        -vga virtio \
        -display sdl \
        -spice port=5900,disable-ticketing=on \
        -device virtio-serial \
        -chardev spicevmc,id=spicechannel0,name=vdagent \
        -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0;
};

if [[ $# -gt 0 ]];
then
    "$@";
fi
