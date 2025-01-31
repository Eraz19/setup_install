#!/bin/bash


source "$(dirname "$0")/font/install.sh"


function IncreaseSudoEffectiveness()
{
    echo "Defaults timestamp_timeout=60" | sudo tee -a /etc/sudoers.d/custom_sudo_timeout;
};
function RemoveIncreaseSudoEffectiveness()
{
    sudo rm /etc/sudoers.d/custom_sudo_timeout;
};

function CheckEnvVariables()
{
    local env_file=".env";

    if [[ ! -f $env_file ]];
    then
        echo "Error: $env_file file not found.";
        
        return 1;
    fi

    source "$(dirname "$0")/$env_file";

    local required_vars=(
        PROJECT_ROOT_FOLDER
        PROJECT_SYSTEM_FONT_FOLDER
        VIRTUAL_MACHINE_DISK_FILE
        VIRTUAL_MACHINE_ISO_FILE
        GIT_USERNAME
        GIT_EMAIL
        GIT_SSl_KEY_FILE
    );

    for var in "${required_vars[@]}";
    do
        if [[ -z "${!var}" ]];
        then
            echo "Error: $var is not set or is empty in $env_file.";
            
            return 1;
        fi
    done

    return 0;
};

function SetZshConfigFile()
{
    sudo printf '\n%s' "$1" | sed -E "s/^[[:space:]]{${2:-0}}//" | sudo tee -a "$PROJECT_ROOT_FOLDER/.zshrc" > /dev/null;
};


function InstallGnomeUIUtilities()
{
    function InstallTweaks()
    {
        echo "Installing GNOME Tweaks...";

        sudo apt install -y gnome-tweaks;
    };

    InstallTweaks;
};

function InstallSteam()
{
    function KillSteamOnLoginWindow()
    {
        while true;
        do
            if pgrep -f steam-runtime-launcher-service >/dev/null;
            then
                pkill -f steam;
                break;
            fi
            
            sleep 2;
        done
    };

    echo "Installing Steam...";
    
    sudo add-apt-repository multiverse -y;
    sudo apt install -y steam;

    # Run first update in the background
    nohup steam steam://open/install &> /dev/null & KillSteamOnLoginWindow;
};

function InstallDiscord()
{
    function KillDiscordOnLoginWindow()
    {
        while true;
        do
            xdotool search --onlyvisible --name "" | while read WIN_ID;
            do
                WIN_NAME=$(xdotool getwindowname "$WIN_ID" 2>/dev/null);
                
                if [[ -n "$WIN_NAME" && "$WIN_NAME" =~ discordapp\.com/app\?_=([0-9]+)\ -\ Discord ]];
                then
                    pkill -f discord;
                    echo "kill discord"
                    #xdotool windowkill "$WIN_ID";
                    break 2;  # Exit both the inner and outer loops
                fi
            done

            sleep 2;
            echo "in loop"
        done
    };

    echo "Installing Discord...";

    sudo wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb";
    sudo dpkg -i discord.deb;
    sudo apt install -f -y;

    discord &> /dev/null & disown; KillDiscordOnLoginWindow;
};

function InstallVsCode()
{
    function InstallSoftware()
    {
        echo "Installing VsCode...";

        sudo wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg;
        sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/;
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list;
        sudo apt update && sudo apt install -y code;
    };

    function InstallExtensions()
    {
        echo "Installing VsCode Extensions...";

        extensions=(
            ms-vscode.cpptools
            ms-vscode.cpptools-extension-pack # no
            ms-vscode.cpptools-themes
            twxs.cmake
            ms-vscode.cmake-tools
            formulahendry.code-runner
            # ms-vscode-devcontainers
            ms-azuretools.vscode-docker
            GitHub.vscode-pull-request-github # no
            # ms-vscode.gradle
            fabiospampinato.vscode-highlight
            Ionic.ionic
            ms-toolsai.jupyter
            ms-toolsai.jupyter-keymap
            fwcd.kotlin
            mathiasfrohlich.kotlin
            # yantao.vscode-markdown
            pkief.material-icon-theme
            ms-python.vscode-pylance
            ms-python.python
            # ms-vscode.remote-ssh
            # ms-vscode.remote-ssh-edit
            emeraldwalk.runonsave
            gruntfuggly.todo-tree
            # PolyMeitex.wgsl
        );

        for ext in "${extensions[@]}";
        do
            code --install-extension $ext;
        done
    };

    function SettingKeyboardShortcuts()
    {
        function SetKeyboardShortcut()
        {
            sudo printf '[
                {
                    "key": "ctrl+alt+m",
                    "command": "editor.action.transformToUppercase",
                    "when": "editorTextFocus"
                },
                {
                    "key": "ctrl+alt+l",
                    "command": "editor.action.transformToLowercase",
                    "when": "editorTextFocus"
                }
            ]' | sed 's/^ \{12\}//' | sudo tee "$1" > /dev/null;
        };

        local keyboard_shortcut_folder="$HOME/.config/Code/User";
        local keyboard_shortcut_file='keybindings.json';

        echo "Setting VsCode keyboard shortcuts...";

        sudo mkdir -p $keyboard_shortcut_folder;
        SetKeyboardShortcut "$keyboard_shortcut_folder/$keyboard_shortcut_file";
    };

    InstallSoftware          ;
    InstallExtensions        ;
    SettingKeyboardShortcuts ;
};

function InstallVirtualMachine()
{
    function SettingVirtualMachineCommandAliases()
    {
        SetZshConfigFile '
            alias vm_disk_create="vm_disk_create";
            function vm_disk_create()
            {
                if [ -z "$1" ];
                then
                    echo "Error: No disk file name provided.";
                    echo "Usage: vm_disk_create <disk_filename>.qcow2"; # Escape single quotes
                    return 1;
                fi

                qemu-img create -f qcow2 "'"$PROJECT_ROOT_FOLDER"'/virtual_machine/$1" 40G;

                echo "Virtual disk $1 created in '"$PROJECT_ROOT_FOLDER"'/virtual_machine/";
            };

            alias vm_os_install="vm_os_install";
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
                    -drive file="'"$PROJECT_ROOT_FOLDER"'/virtual_machine/$2",format=qcow2 \
                    -boot d \
                    -vga virtio \
                    -display sdl;
            };

            alias vm_run="vm_run";
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
                    -drive file="'"$PROJECT_ROOT_FOLDER"'/virtual_machine/$1",format=qcow2,snapshot=on \
                    -vga virtio \
                    -display sdl \
                    -spice port=5900,disable-ticketing=on \
                    -device virtio-serial \
                    -chardev spicevmc,id=spicechannel0,name=vdagent \
                    -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0;
            };
        ' 12;
    };

    echo "Installing VirtualMachine...";
    
    sudo apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager;
    SettingVirtualMachineCommandAliases;
};

function InstallCodingEcosystem()
{
    function InstallGit()
    {
        echo "Installing Git...";

        sudo apt install -y git;
        
        sudo git config --global user.name $GIT_USERNAME;
        sudo git config --global user.email $GIT_EMAIL;

        sudo ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/$GIT_SSl_KEY_FILE" -N "";
        sudo eval "$(ssh-agent -s)";
        sudo ssh-add ~/.ssh/$GIT_SSl_KEY_FILE;
    };

    function InstallNvm()
    {
        function SettingNvmEnvironmentVariable()
        {
            SetZshConfigFile '
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
                [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
            ' 16;
        };

        echo "Installing Nvm toolchain (including nodeJS and npm)..."
        
        sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash;
        sudo nvm install --lts;
        SettingNvmEnvironmentVariable;
    };

    function InstallKotlin()
    {
        function InstallJVM()
        {
            function SettingJvmEnvironmentVariable()
            {
                SetZshConfigFile '
                    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
                    export PATH=$JAVA_HOME/bin:$PATH
                ' 20;
            };

            echo "Installing Jvm...";

            sudo apt install -y openjdk-17-jdk;
            SettingJvmEnvironmentVariable;
        };

        function InstallKotlinToolchain()
        {
            function SettingSdkEnvironmentVariable()
            {
                SetZshConfigFile '
                    #THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
                    export SDKMAN_DIR="$HOME/.sdkman"
                    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
                ' 20;
            };

            echo "Installing Sdk...";

            sudo curl -s "https://get.sdkman.io" | bash;
            sudo sdk install kotlin 1.8.20;
            sudo sdk install gradle 8.12;
            SettingSdkEnvironmentVariable;
        };

        echo "Installing Kotlin toolchain...";

        InstallJVM             ;
        InstallKotlinToolchain ;
    };

    InstallGit    ;
    InstallNvm    ;
    InstallKotlin ;
};

function InstallTerminalUtilities()
{
    function InstallZsh()
    {
        echo "Installing Zsh...";

        sudo apt install -y zsh;
        sudo ln -s $PROJECT_ROOT_FOLDER/.zshrc $HOME/.zshrc;
    };
    
    function InstallFzf()
    {
        echo "Installing Fzf...";

        sudo apt install -y fzf;
    };
    
    function InstallTheFuck()
    {
        echo "Installing TheFuck...";
        
        sudo apt install -y thefuck;
    };
    
    function InstallTree()
    {
        echo "Installing Tree...";

        sudo apt install -y tree;
    };
    
    function InstallBTop()
    {
        echo "Installing BTop...";

        sudo apt install -y btop;
    };

    function InstallNeofetch()
    {
        echo "Installing Neofetch...";

        sudo apt install -y neofetch;
    };

    function InstallYazi()
    {
        function SettingYaziAlias()
        {
            SetZshConfigFile 'alias nav=yazi' 0;
        };

        echo "Installing Yazi...";

        sudo wget -qO yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip;
        sudo unzip -q yazi.zip -d yazi-temp;
        sudo mv yazi-temp/*/yazi /usr/local/bin;
        sudo rm -rf yazi-temp yazi.zip;
        SettingYaziAlias;
    };

    function InstallOhMyPosh()
    {
        function SettingOhMyPoshLaunching()
        {
            SetZshConfigFile 'eval '$(oh-my-posh init zsh --config $PROJECT_ROOT_FOLDER/oh_my_posh/custom.omp.json)'' 0;
        };

        echo "Installing Oh-My-Posh...";
        
        sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh;
        sudo chmod +x /usr/local/bin/oh-my-posh;
        SettingOhMyPoshLaunching;
    
        InstallFontNerd ;
        SetFont         ;
    };

    function InstallOhMyZsh()
    {
        function InstallPlugins()
        {
            sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions;
            sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting;

            SetZshConfigFile "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" "$PROJECT_ROOT/.zshrc";
        };

        echo "Installing Oh-My-Zsh...";

        sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)";
        InstallPlugins;
    };

    InstallZsh      ;
    InstallFzf      ;
    InstallTheFuck  ;
    InstallTree     ;
    InstallBTop     ;
    InstallNeofetch ;
    InstallYazi     ;
    InstallOhMyPosh ;
    #InstallOhMyZsh  ;
};

sudo -v;

#if CheckEnvVariables;
#then
    IncreaseSudoEffectiveness;

    #InstallGnomeUIUtilities  ; # DONE
    #InstallSteam             ; # DONE
    InstallDiscord;
    #InstallVsCode            ; # DONE
    #InstallVirtualMachine    ; # DONE
    #InstallCodingEcosystem   ; # DONE
    #InstallTerminalUtilities ;

    RemoveIncreaseSudoEffectiveness;
#fi

