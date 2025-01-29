#!/bin/bash


source "$(dirname "$0")/font/install.sh"


function CheckEnvVariables()
{
    local env_file=".env";

    if [[ ! -f $env_file ]];
    then
        echo "Error: $env_file file not found.";
        
        return (1);
    fi

    source "$(dirname "$0")/$env_file"

    local required_vars=(
        PROJECT_ROOT
        VM_ISO_FILE
        GIT_USERNAME
        GIT_EMAIL
        FONT_DIR
    );

    for var in "${required_vars[@]}";
    do
        if [[ -z "${!var}" ]];
        then
            echo "Error: $var is not set or is empty in $env_file.";
            
            return (1);
        fi
    done

    return (0);
};

function SetConfigFile()
{
    echo "\n$1" >> $2;
};


function InstallGnomeUIUtilities()
{
    function InstallTweaks()
    {
        echo "Installing GNOME Tweaks...";

        apt install -y gnome-tweaks;
    };

    InstallTweaks;
};

function InstallSteam()
{
    echo "Installing Steam...";
    
    add-apt-repository multiverse -y;
    apt install -y steam;
};

function InstallVsCode()
{
    function InstallSoftware()
    {
        echo "Installing VsCode...";

        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg;
        install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/;
        sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list';
        apt install -y code;
    };

    function InstallExtensions()
    {
        echo "Installing VsCode Extensions...";

        extensions=(
            ms-vscode.cpptools
            ms-vscode.cpptools-pack
            ms-vscode.cpptools-themes
            twxs.cmake
            ms-vscode.cmake-tools
            formulahendry.code-runner
            ms-vscode-devcontainers
            ms-azuretools.vscode-docker
            ms-vscode.github
            ms-vscode.gradle
            fabiospampinato.vscode-highlight
            Ionic.ionic
            ms-toolsai.jupyter
            ms-toolsai.jupyter-keymap
            fwcd.kotlin
            mathiasfrohlich.kotlin
            yantao.vscode-markdown
            pkief.material-icon-theme
            ms-python.vscode-pylance
            ms-python.python
            ms-vscode.remote-ssh
            ms-vscode.remote-ssh-edit
            emeraldwalk.runonsave
            gruntfuggly.todo-tree
            PolyMeitex.wgsl
        );

        for ext in "${extensions[@]}";
        do
            code --install-extension $ext;
        done
    };

    function SettingKeyboardShortcuts()
    {
        local keyboard_shortcut_folder="$HOME/.config/Code/User";
        local keyboard_shortcut_file='keybindings.json';
        local keyboard_shortcuts='
            [
                {
                    "key": "ctrl+alt+u",
                    "command": "editor.action.transformToUppercase",
                    "when": "editorTextFocus"
                },
                {
                    "key": "ctrl+alt+l",
                    "command": "editor.action.transformToLowercase",
                    "when": "editorTextFocus"
                }
            ]
        ';

        echo "Setting VsCode keyboard shortcuts...";

        mkdir -p $keyboard_shortcut_folder;
        SetConfigFile $keyboard_shortcuts "$keyboard_shortcut_folder/$keyboard_shortcut_file";
    };

    InstallSoftware          ;
    InstallExtensions        ;
    SettingKeyboardShortcuts ;
};

function InstallVirtualMachine()
{
    local create_vm_command="qemu-img create -f qcow2 $PROJECT_VIRTUAL_MACHINE_FOLDER/$VIRTUAL_MACHINE_DISK_FILE 40G";
    local install_vm_disk_command="
        qemu-system-x86_64 \
            -enable-kvm \
            -m 4096 \
            -cpu host \
            -smp 2 \
            -cdrom $PROJECT_VIRTUAL_MACHINE_FOLDER/$VIRTUAL_MACHINE_ISO_FILE \
            -drive file=$PROJECT_VIRTUAL_MACHINE_FOLDER/$VIRTUAL_MACHINE_DISK_FILE,format=qcow2 \
            -boot d \
            -vga virtio \
            -display sdl
    ";
    local vm_run_command="
        qemu-system-x86_64 \
            -enable-kvm \
            -m 4096 \
            -cpu host \
            -smp 2 \
            -drive file="$PWD/virtual_machine/disk.qcow2",format=qcow2,snapshot=on \
            -vga virtio \
            -display sdl \
            -spice port=5900,disable-ticketing=on \
            -device virtio-serial \
            -chardev spicevmc,id=spicechannel0,name=vdagent \
            -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0
    ";

    echo "Installing VirtualMachine...";
    
    apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager;
    
    SetConfigFile "alias vm_disk_create='$create_vm_command'" "$PROJECT_ROOT/.zshrc";
    SetConfigFile "alias vm_install='$create_vm_command'" "$PROJECT_ROOT/.zshrc";
    SetConfigFile "alias vm_run='$vm_run_command'" "$PROJECT_ROOT/.zshrc";
};

function InstallCodingEcosystem()
{
    function InstallGit()
    {
        echo "Installing Git...";

        apt install -y git;
        
        git config --global user.name $GIT_USERNAME;
        git config --global user.email $GIT_EMAIL;

        ssh-keygen -t ed25519 -C $GIT_EMAIL;
        eval "$(ssh-agent -s)";
        ssh-add ~/.ssh/$GIT_SSl_KEY_FILE;
    }:

    function InstallNvm()
    {
        local nvm_environment_variables="
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
        ";

        echo "Installing Nvm toolchain (including nodeJS and npm)..."
        
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash;
        nvm install --lts;

        SetConfigFile $nvm_environment_variables "$PROJECT_ROOT/.zshrc";
    };

    function InstallKotlin()
    {
        function InstallJVM()
        {
            local jvm_environment_variables="
                export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
                export PATH=$JAVA_HOME/bin:$PATH
            ";

            echo "Installing Jvm...";

            apt install -y openjdk-17-jdk;
            SetConfigFile $jvm_environment_variables "$PROJECT_ROOT/.zshrc";
        };

        function InstallKotlinToolchain()
        {
            local sdk_environment_variables="
                #THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
                export SDKMAN_DIR="$HOME/.sdkman"
                [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
            ";

            echo "Installing Sdk...";

            curl -s "https://get.sdkman.io" | bash;
            sdk install kotlin 1.8.20;
            sdk install gradle 8.12;

            SetConfigFile $sdk_environment_variables "$PROJECT_ROOT/.zshrc";
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

        apt install -y zsh;
        ln -s $PROJECT_ROOT/.zshrc $HOME/.zshrc;
    };
    
    function InstallFzf()
    {
        echo "Installing Fzf...";

        apt install -y fzf;
    };
    
    function InstallTheFuck()
    {
        echo "Installing TheFuck...";
        
        apt install -y thefuck;
    };
    
    function InstallTree()
    {
        echo "Installing Tree...";

        apt install -y tree;
    };
    
    function InstallBTop()
    {
        echo "Installing BTop...";

        apt install -y btop;
    };

    function InstallNeofetch()
    {
        echo "Installing Neofetch...";

        apt install -y neofetch;
    };

    function InstallYazi()
    {
        echo "Installing Yazi...";

        wget -qO yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip;
        unzip -q yazi.zip -d yazi-temp;
        mv yazi-temp/*/yazi /usr/local/bin;
        rm -rf yazi-temp yazi.zip;

        SetZshrc "alias nav='yazi'";
    };

    function InstallOhMyPosh()
    {
        echo "Installing Oh-My-Posh...";
        
        wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh;
        chmod +x /usr/local/bin/oh-my-posh;
    
        SetZshrc "eval "$(oh-my-posh init zsh --config $PROJECT_OH_MY_POSH_FOLDER/custom.omp.json)"";
    
        InstallFontNerd ;
        SetFont         ;
    };

    function InstallOhMyZsh()
    {
        function InstallPlugins()
        {
            git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions;
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting;

            SetZshrc "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)";
        };

        echo "Installing Oh-My-Zsh...";

        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)";
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
    InstallOhMyZsh  ;
};

if CheckEnvVariables;
then
    InstallGnomeUIUtilities  ;
    InstallSteam             ;
    InstallVsCode            ;
    InstallVirtualMachine    ;
    InstallCodingEcosystem   ;
    InstallTerminalUtilities ;
fi
