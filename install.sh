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

function SetConfigFile()
{
    sudo echo "\n$1" >> $2;
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
    function WaitForSteamUpdate()
    {
        echo "Waiting for Steam to finish updating..."
        
        while pgrep -x "steam" > /dev/null; do
            sleep 5
        done
        
        echo "Steam update finished."
    }

    function CloseSteamLoginWindow()
    {
        echo "Checking for Steam login window..."

        while true; do
            # Detect Steam login window using xdotool
            WIN_ID=$(xdotool search --name "Steam" 2>/dev/null)

            if [[ ! -z "$WIN_ID" ]]; then
                echo "Steam login window detected. Closing it..."
                xdotool windowkill "$WIN_ID"
                break
            fi

            sleep 5
        done
    }

    echo "Installing Steam...";
    
    sudo add-apt-repository multiverse -y;
    sudo apt install -y steam;

    # Run first update in the background
    # Run first update in the background
    nohup steam steam://open/install &> /dev/null &

    # Wait for Steam update to complete
    WaitForSteamUpdate

    # Close Steam login window automatically
    CloseSteamLoginWindow
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
            sudo printf '%s\n' '
            [
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
            ]' | sudo tee "$1" > /dev/null;
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
    local create_vm_command="qemu-img create -f qcow2 $PROJECT_ROOT_FOLDER/virtual_machine/$VIRTUAL_MACHINE_DISK_FILE 40G";
    local install_vm_disk_command="
        qemu-system-x86_64 \
            -enable-kvm \
            -m 4096 \
            -cpu host \
            -smp 2 \
            -cdrom $PROJECT_ROOT_FOLDER/virtual_machine//$VIRTUAL_MACHINE_ISO_FILE \
            -drive file=$PROJECT_ROOT_FOLDER/virtual_machine//$VIRTUAL_MACHINE_DISK_FILE,format=qcow2 \
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
            -drive file=$PROJECT_ROOT_FOLDER/virtual_machine/disk.qcow2,format=qcow2,snapshot=on \
            -vga virtio \
            -display sdl \
            -spice port=5900,disable-ticketing=on \
            -device virtio-serial \
            -chardev spicevmc,id=spicechannel0,name=vdagent \
            -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0
    ";

    echo "Installing VirtualMachine...";
    
    sudo apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager;
    
    SetConfigFile "alias vm_disk_create=$create_vm_command" "$PROJECT_ROOT/.zshrc";
    SetConfigFile "alias vm_install=$create_vm_command" "$PROJECT_ROOT/.zshrc";
    SetConfigFile "alias vm_run=$vm_run_command" "$PROJECT_ROOT/.zshrc";
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
        local nvm_environment_variables="
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
        ";

        echo "Installing Nvm toolchain (including nodeJS and npm)..."
        
        sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash;
        sudo nvm install --lts;

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

            sudo apt install -y openjdk-17-jdk;
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

            sudo curl -s "https://get.sdkman.io" | bash;
            sudo sdk install kotlin 1.8.20;
            sudo sdk install gradle 8.12;

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

        sudo apt install -y zsh;
        sudo ln -s $PROJECT_ROOT/.zshrc $HOME/.zshrc;
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
        echo "Installing Yazi...";

        sudo wget -qO yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip;
        sudo unzip -q yazi.zip -d yazi-temp;
        sudo mv yazi-temp/*/yazi /usr/local/bin;
        sudo rm -rf yazi-temp yazi.zip;

        SetConfigFile "alias nav=yazi" "$PROJECT_ROOT/.zshrc";
    };

    function InstallOhMyPosh()
    {
        echo "Installing Oh-My-Posh...";
        
        sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh;
        sudo chmod +x /usr/local/bin/oh-my-posh;
    
        SetConfigFile "eval '$(oh-my-posh init zsh --config $PROJECT_ROOT_FOLDER/oh_my_posh/custom.omp.json)'" "$PROJECT_ROOT/.zshrc";
    
        InstallFontNerd ;
        SetFont         ;
    };

    function InstallOhMyZsh()
    {
        function InstallPlugins()
        {
            sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions;
            sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting;

            SetConfigFile "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" "$PROJECT_ROOT/.zshrc";
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
    InstallOhMyZsh  ;
};

sudo -v;

#if CheckEnvVariables;
#then
    IncreaseSudoEffectiveness;

    #InstallGnomeUIUtilities  ; # DONE
    InstallSteam             ; # DONE
    #InstallVsCode            ; # DONE
    #InstallVirtualMachine    ;
    #InstallCodingEcosystem   ;
    #InstallTerminalUtilities ;

    RemoveIncreaseSudoEffectiveness;
#fi
