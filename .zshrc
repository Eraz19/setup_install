export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

source $ZSH/oh-my-zsh.sh

###################### PERSONAL CONFIG ######################

alias palette='for i in {0..255}; do printf "\e[48;5;%sm %03d " $i $i; [ $(( (i+1) % 6 )) -eq 0 ] && echo ""; done; echo -e "\e[0m"'


