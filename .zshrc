###################### EXPORT ######################

export ZSH="$HOME/.oh-my-zsh"

###################### SOURCE ######################

source $ZSH/oh-my-zsh.sh

eval "$(oh-my-posh init zsh --config /home/eraz/Documents/setup_install/oh_my_posh/custom.omp.json)"

###################### ALIAS ######################

alias palette='for i in {0..255}; do printf "\e[48;5;%sm %03d " $i $i; [ $(( (i+1) % 6 )) -eq 0 ] && echo ""; done; echo -e "\e[0m"'
alias vm_disk_create="vm_disk_create"
alias vm_os_install="vm_os_install"
alias vm_run="vm_run"

###################### ENVIRONMENT VARIABLES ######################

ZSH_THEME=""

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

###################### FUNCTION ######################

function vm_disk_create()
{
    if [ -z "$1" ];
    then
        echo "Error: No disk file name provided.";
        echo "Usage: vm_disk_create <disk_filename>.qcow2"; # Escape single quotes
        return 1;
    fi

    qemu-img create -f qcow2 "/home/eraz/Documents/Perso/Setup/virtual_machine/$1" 40G;

    echo "Virtual disk $1 created in /home/eraz/Documents/Perso/Setup/virtual_machine/";
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
        -cdrom $1 \
        -drive file="/home/eraz/Documents/Perso/Setup/virtual_machine/$2",format=qcow2 \
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
        -drive file="/home/eraz/Documents/Perso/Setup/virtual_machine/$1",format=qcow2,snapshot=on \
        -vga virtio \
        -display sdl \
        -spice port=5900,disable-ticketing=on \
        -device virtio-serial \
        -chardev spicevmc,id=spicechannel0,name=vdagent \
        -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0;
};
