#!/bin/bash


###################### PATHS ######################

DOWNLOAD_FOLDER="$HOME/Downloads";

SYSTEM_BINARIES_FOLDER="/usr/bin";

SYSTEM_SHARED_RESSOURCE_FOLDER="/usr/share";
SYSTEM_SHARED_GPG_KEYS_FOLDER="/usr/share/keyrings";
SYSTEM_SHARED_FONT_FOLDER="/usr/share/fonts";

USER_BINARIES_FOLDER="/usr/local/bin";

VS_CODE_CUSTOM_CONFIG_FOLDER="$HOME/.config/Code/User";

SSH_KEYS_FOLDER="$HOME/.ssh";

###################### UTILS ######################

function CheckScriptEnvironmentVariables()
{
    function ImportEnvironmentVariables()
    {
        local environment_file="$1";

        if [[ ! -f "$environment_file" ]];
        then
            return 1;
        fi

        source "$environment_file";
    };

    local environment_file=".env";
    local required_environment_variables=(
        'GIT_USERNAME'
        'GIT_EMAIL'
        'GIT_SSH_KEY_FILE'
    );

    if ! ImportEnvironmentVariables "$environment_file";
    then
        return 1;
    fi

    for required_environment_variable in "${required_environment_variables[@]}";
    do
        if [[ -z "${!required_environment_variable}" ]];
        then
            return 1;
        fi
    done

    return 0;
};

function IncreaseSudoEffectiveness()
{
    echo "Defaults timestamp_timeout=120" | sudo tee -a /etc/sudoers.d/custom_sudo_timeout;
};
function RemoveIncreaseSudoEffectiveness()
{
    sudo rm /etc/sudoers.d/custom_sudo_timeout;
};

# Check if a command exist in the system
#
#   $1 : command name
function IsCommandExists()
{
    command -v "$1" >/dev/null 2>&1;
};

# Add config into .zshrc (config file for zsh shell)
#
#   $1 : command lines
#   $2 : number of indentation (space) removed from result
#   $3 : .zshrc section in which to write the command lines
function SetZshConfigFile() 
{
    local content="$1";
    local indentation="${2:-0}";
    local formatted_content="\n$(echo -e "$content" | sed -E "s/^[[:space:]]{$indentation}//")";
    local section="$3";
    local zshrc_file="$PWD/.zshrc";

    if [[ -z "$section" ]];
    then
        return 1;
    fi

    if ! grep -q "###################### $section ######################" "$zshrc_file";
    then
        return 1;
    fi

    sudo sed -i "/###################### $section ######################/a\\$formatted_content" "$zshrc_file";
};
function SetZshConfigFile_Source              () { SetZshConfigFile $1 $2 "SOURCE"                ; } ;
function SetZshConfigFile_Export              () { SetZshConfigFile $1 $2 "EXPORT"                ; } ;
function SetZshConfigFile_Alias               () { SetZshConfigFile $1 $2 "ALIAS"                 ; } ;
function SetZshConfigFile_EnvironmentVariables() { SetZshConfigFile $1 $2 "ENVIRONMENT_VARIABLES" ; } ;
function SetZshConfigFile_Function            () { SetZshConfigFile $1 $2 "FUNCTION"              ; } ;

###################### SCRIPT ######################

function InstallGnomeUIUtilities()
{
    function InstallTweaks()
    {
        echo "Installing GNOME Tweaks...";

        sudo apt install -y gnome-tweaks;
    };

    InstallTweaks;
};

function InstallApps()
{
    function InstallSteam()
    {
        function InstallSoftware()
        {
            sudo add-apt-repository multiverse -y;
            sudo apt install -y steam;
        };

        function LaunchFirstUpdate()
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

            nohup steam steam://open/install &> /dev/null & KillSteamOnLoginWindow;
        };

        echo "Installing Steam...";
        
        InstallSoftware   ;
        LaunchFirstUpdate ;
    };

    function InstallDiscord()
    {
        function InstallSoftware()
        {
            local temp_download_file="discord.deb";

            # Download .deb package file
            sudo wget -O "$DOWNLOAD_FOLDER/$temp_download_file" "https://discord.com/api/download?platform=linux&format=deb";
            # Install .deb package
            sudo dpkg -i "$DOWNLOAD_FOLDER/$temp_download_file";
            # Install possible missing dependencies
            sudo apt install -f -y;
            # Remove .deb package file
            sudo rm "$DOWNLOAD_FOLDER/$temp_download_file";
        };

        function LaunchFirstUpdate()
        {
            function KillDiscordOnLoginWindow()
            {
                local is_login_window_visible=false;

                while true;
                do
                    if [ "$is_login_window_visible" = false ];
                    then 
                        local window_ids=$(xdotool search --onlyvisible --name "");

                        for window_id in $window_ids;
                        do
                            local window_name=$(xdotool getwindowname "$window_id" 2>/dev/null);
                            
                            if [[ -n "$window_name" && "$window_name" =~ discordapp\.com/app\?_=([0-9]+)\ -\ Discord ]];
                            then
                                is_login_window_visible=true;
                                break;
                            fi
                        done
                    else
                        pkill -f discord;
                        break;
                    fi

                    sleep 2;
                done
            };

            discord &> /dev/null & disown;
            KillDiscordOnLoginWindow;
        };

        echo "Installing Discord...";

        InstallSoftware   ;
        LaunchFirstUpdate ;
    };

    function InstallVsCode()
    {
        function InstallSoftware()
        {
            function AddVsCodeRepository()
            {
                local temp_download_file="packages.microsoft.gpg";

                # Download gpg key
                sudo wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$DOWNLOAD_FOLDER/$temp_download_file";
                # Move gpg key into standard location
                sudo install -o root -g root -m 644 "$DOWNLOAD_FOLDER/$temp_download_file" "$SYSTEM_SHARED_GPG_KEYS_FOLDER/";
                # Add VsCode repository in system
                echo "deb [arch=amd64 signed-by=$SYSTEM_SHARED_GPG_KEYS_FOLDER/$temp_download_file] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list;
            };

            AddVsCodeRepository;
            sudo apt install -y code;
        };

        function InstallExtensions()
        {
            extensions=(
                ms-vscode.cpptools
                ms-vscode.cpptools-extension-pack
                ms-vscode.cpptools-themes
                twxs.cmake
                ms-vscode.cmake-tools
                formulahendry.code-runner
                # ms-vscode-devcontainers
                ms-azuretools.vscode-docker
                GitHub.vscode-pull-request-github
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

            for extension in "${extensions[@]}";
            do
                code --install-extension "$extension";
            done
        };

        function SettingKeyboardShortcuts()
        {
            function ConfigKeyboardShortcut()
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

            local keyboard_shortcut_file='keybindings.json';

            sudo mkdir -p "$VS_CODE_CUSTOM_CONFIG_FOLDER";
            ConfigKeyboardShortcut "$VS_CODE_CUSTOM_CONFIG_FOLDER/$keyboard_shortcut_file";
        };
        
        echo "Installing VsCode...";

        InstallSoftware          ;
        InstallExtensions        ;
        SettingKeyboardShortcuts ;
    };

    function InstallVirtualMachine()
    {
        function InstallSoftware()
        {
            sudo apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager;
        };

        function ConfigVirtualMachineCommands()
        {
            SetZshConfigFile_Alias '
                alias vm_disk_create="bash $SETUP/virtual_machine/functions.sh vm_disk_create";

                alias vm_os_install="bash $SETUP/virtual_machine/functions.sh vm_os_install";

                alias vm_run="bash $SETUP/virtual_machine/functions.sh vm_run";
            ' 16;
        };

        echo "Installing VirtualMachine...";
        
        InstallSoftware              ;
        ConfigVirtualMachineCommands ;
    };

    InstallSteam          ;
    InstallDiscord        ;
    InstallVsCode         ;
    InstallVirtualMachine ;
};

function InstallCodingEcosystem()
{
    function InstallGit()
    {
        function InstallSoftware()
        {
            sudo apt install -y git;
        };

        function ConfigLocalGit()
        {
            sudo git config --global user.name  "$GIT_USERNAME" ;
            sudo git config --global user.email "$GIT_EMAIL"    ;
        };

        function CreateSSLKeyForGit()
        {
            local ssh_key_file="'$GIT_SSH_KEY_FILE'_ed25519";

            sudo ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEYS_FOLDER/$ssh_key_file" -N "";
            sudo eval "$(ssh-agent -s)";
            sudo ssh-add "$SSH_KEYS_FOLDER/$ssh_key_file";
        };

        echo "Installing Git...";

        InstallSoftware    ;
        ConfigLocalGit     ;
        CreateSSLKeyForGit ;
    };

    function InstallNvm()
    {
        function InstallSoftware()
        {
            # Download and install nvm
            sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash;
            # Install NodeJs and npm version
            sudo nvm install --lts;
        };

        function ConfigNvmPath()
        {
            SetZshConfigFile_Export '
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
                [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
            ' 16;
        };

        echo "Installing Nvm toolchain (including nodeJS and npm)..."
        
        InstallSoftware ;
        ConfigNvmPath   ;
    };

    function InstallPython()
    {
        function InstallSoftware()
        {
            sudo apt install -y python3 python3-pip python3-venv;
        };

        function InstallDevelopmentTools()
        {
            sudo pip3 install pipenv;
        };

        echo "Installing Python...";

        InstallSoftware         ;
        InstallDevelopmentTools ;
    };

    function InstallKotlin()
    {
        function InstallJVM()
        {
            function InstallSoftware()
            {
                sudo apt install -y openjdk-17-jdk;
            };

            function ConfigJvmPath()
            {
                SetZshConfigFile_Export '
                    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
                    export PATH=$JAVA_HOME/bin:$PATH
                ' 20;
            };

            InstallSoftware ;
            ConfigJvmPath   ;
        };

        function InstallKotlinToolchain()
        {
            function InstallSoftware()
            {
                sudo curl -s "https://get.sdkman.io" | bash;
                sudo sdk install kotlin 1.8.20;
                sudo sdk install gradle 8.12;
            };

            function ConfigSdkManPath()
            {
                SetZshConfigFile_Export '
                    #THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
                    export SDKMAN_DIR="$HOME/.sdkman"
                    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
                ' 20;
            };

            InstallSoftware  ;
            ConfigSdkManPath ;
        };

        echo "Installing Kotlin toolchain...";

        InstallJVM             ;
        InstallKotlinToolchain ;
    };

    InstallGit    ;
    InstallNvm    ;
    InstallPython ;
    InstallKotlin ;
};

function ConfigSystemSettings()
{
    function SettingPowerBehavior()
    {
        function SettingPowerBehaviors_Dconf()
        {
            dconf write /org/gnome/settings-daemon/plugins/power/idle-dim                       false       ;
            dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type         "'nothing'" ;
            dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-type    "'nothing'" ;
            dconf write /org/gnome/desktop/session/idle-delay                                   0           ;
            dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-timeout      0           ;
            dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-timeout 0           ;
        };

        function SettingPowerBehaviors_GSettings()
        {
            gsettings set org.gnome.settings-daemon.plugins.power idle-dim                       false     ;
            gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type         'nothing' ;
            gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type    'nothing' ;
            gsettings set org.gnome.desktop.session               idle-delay                     0         ;
            gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout      0         ;
            gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0         ;
        };

        SettingPowerBehaviors_Dconf     ;
        SettingPowerBehaviors_GSettings ;
    };

    function SettingScreenBehavior()
    {
        function SettingScreenBehaviors_Dconf()
        {
            dconf write /org/gnome/desktop/screensaver/ubuntu-lock-on-suspend false ;
            dconf write /org/gnome/desktop/notifications/show-in-lock-screen  false ;
            dconf write /org/gnome/desktop/screensaver/lock-enabled           false ;
        };

        function SettingScreenBehaviors_GSettings()
        {
            gsettings set org.gnome.desktop.screensaver   ubuntu-lock-on-suspend false ;
            gsettings set org.gnome.desktop.notifications show-in-lock-screen    false ;
            gsettings set org.gnome.desktop.screensaver   lock-enabled           false ;
        };

        SettingScreenBehaviors_Dconf     ;
        SettingScreenBehaviors_GSettings ;
    };

    function SettingDesktopDock()
    {
        function SettingDesktopDock_Dconf()
        {
            dconf write /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size 35                       ;
            dconf write /org/gnome/shell/extensions/dash-to-dock/manualhide         false                    ;
            dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed         false                    ;
            dconf write /org/gnome/shell/extensions/dash-to-dock/intellihide        true                     ;
            dconf write /org/gnome/shell/extensions/dash-to-dock/extend-height      false                    ;
            dconf write /org/gnome/shell/extensions/dash-to-dock/click-action       "'minimize-or-previews'" ;
            dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position      "'BOTTOM'"               ;
            dconf write /org/gnome/shell/extensions/dash-to-dock/dock-alignment     "'CENTER'"               ;

            dconf write /org/gnome/shell/favorite-apps "$1";
        };

        function SettingDesktopDock_GSettings()
        {
            gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 35                     ;
            gsettings set org.gnome.shell.extensions.dash-to-dock manualhide         false                  ;
            gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed         false                  ;
            gsettings set org.gnome.shell.extensions.dash-to-dock intellihide        true                   ;
            gsettings set org.gnome.shell.extensions.dash-to-dock extend-height      false                  ;
            gsettings set org.gnome.shell.extensions.dash-to-dock click-action       'minimize-or-previews' ;
            gsettings set org.gnome.shell.extensions.dash-to-dock dock-position      'BOTTOM'               ;
            gsettings set org.gnome.shell.extensions.dash-to-dock dock-alignment     'CENTER'               ;

            gsettings set org.gnome.shell favorite-apps "$1";
        };

        function FormatGSettingIconsList()
        {
            local array=("$@");
            
            printf -v formatted "'%s'," "${array[@]}";
            echo "[${formatted%,}]";
        };

        local dock_icons=(
            'pop-cosmic-applications.desktop'
            'firefox.desktop'
            'org.gnome.Terminal.desktop'
            'code.desktop'
            'steam.desktop'
            'discord.desktop'
            'gnome-control-center.desktop'
        );
        local formatted_icons=$(FormatGSettingIconsList "${dock_icons[@]}");

        SettingDesktopDock_Dconf     "$formatted_icons" ;
        SettingDesktopDock_GSettings "$formatted_icons" ;
    };

    function SettingDesktop()
    {
        function SettingDesktop_Dconf()
        {
            dconf write /org/gnome/shell/extensions/pop-cosmic/show-workspaces-button   false      ;
            dconf write /org/gnome/shell/extensions/pop-cosmic/show-applications-button false      ;
            dconf write /org/gnome/shell/extensions/pop-cosmic/clock-alignment          "'CENTER'" ;

            dconf write /org/gnome/desktop/wm/preferences/button-layout "'appmenu:minimize,maximize,close'";
        };

        function SettingDesktop_GSettings()
        {
            gsettings set org.gnome.shell.extensions.pop-cosmic show-workspaces-button   false    ;
            gsettings set org.gnome.shell.extensions.pop-cosmic show-applications-button false    ;
            gsettings set org.gnome.shell.extensions.pop-cosmic clock-alignment          'CENTER' ;

            gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close';
        };

        SettingDesktop_Dconf     ;
        SettingDesktop_GSettings ;
    };

    function SettingDesktopTheme()
    {
        function SettingDesktopTheme_Dconf()
        {
            dconf write /org/gnome/desktop/background/picture-uri-dark "'file:///usr/share/backgrounds/pop/nick-nazzaro-ice-cave.png'" ;
            dconf write /org/gnome/desktop/screensaver/picture-uri     "'file:///usr/share/backgrounds/pop/nick-nazzaro-ice-cave.png'" ;
            
            dconf write /org/gnome/desktop/interface/color-scheme  "'prefer-dark'" ;
            dconf write /org/gnome/desktop/interface/gtk-theme     "'Pop-dark'"    ;
            dconf write /org/gnome/gedit/preferences/editor/scheme "'pop-dark'"    ;
        };

        function SettingDesktopTheme_GSettings()
        {
            gsettings set org.gnome.desktop.background  picture-uri-dark 'file:///usr/share/backgrounds/pop/nick-nazzaro-ice-cave.png' ;
            gsettings set org.gnome.desktop.screensaver picture-uri      'file:///usr/share/backgrounds/pop/nick-nazzaro-ice-cave.png' ;

            gsettings set org.gnome.desktop.interface        color-scheme 'prefer-dark' ;
            gsettings set org.gnome.desktop.interface        gtk-theme    'Pop-dark'    ;
            gsettings set org.gnome.gedit.preferences.editor scheme       'pop-dark'    ;
        };

        SettingDesktopTheme_Dconf     ;
        SettingDesktopTheme_GSettings ;
    };

    function InstallGPUDRivers()
    {
        function InstallNvidiaDrivers()
        {
            function InstallSoftware()
            {
                function FindMatchingGPUDriver()
                {
                    local matching_driver=$(ubuntu-drivers devices | awk '/recommended/ {print $3}');  

                    if [[ -z "$matching_driver" ]];
                    then
                        matching_driver=$(ubuntu-drivers devices | grep -oP 'nvidia-driver-\d+' | head -n 1);
                    fi

                    echo "$matching_driver";
                };

                local nvidia_driver=$(FindMatchingGPUDriver);

                if [[ -n "$nvidia_driver" ]];
                then
                    sudo apt install -y "$nvidia_driver";
                fi
            };

            function UpdateGPUInSystem
            {
                sudo prime-select nvidia ;
                sudo update-initramfs -u ;
            };

            sudo add-apt-repository -y ppa:graphics-drivers/ppa;

            InstallSoftware   ;
            UpdateGPUInSystem ;
        };

        function InstallAMDDrivers()
        {
            function InstallSoftware()
            {
                function FindMatchingGPUDriver()
                {
                    echo "$(ubuntu-drivers devices | awk '/recommended/ {print $3}')";
                };

                local amd_driver=$(FindMatchingGPUDriver);

                if [[ -z "$amd_driver" ]];
                then
                    sudo apt install -y mesa-utils mesa-vulkan-drivers xserver-xorg-video-amdgpu;
                else
                    sudo apt install -y "$amd_driver";
                fi
            };

            function UpdateGPUInSystem
            {
                local current_gpu=$(glxinfo | grep "OpenGL renderer string" | awk -F': ' '{print $2}');

                if [[ "$current_gpu" == *"llvmpipe"* ]];
                then    
                    sudo modprobe amdgpu;
                    echo 'export DRI_PRIME=1' | sudo tee -a /etc/environment > /dev/null;            
                fi
            };

            sudo apt -y install mesa-utils;

            InstallSoftware   ;
            UpdateGPUInSystem ;
        };

        local gpu_vendor=$(lspci -v | egrep -i 'vga|3d|2d' | awk '{print $5}' | head -n 1);

        if [[ -z "$gpu_vendor" ]];
        then
            return 1;
        fi

        if [[ "$gpu_vendor" =~ .*NVIDIA.* ]];
        then
            InstallNvidiaDrivers;
        elif [[ "$gpu_vendor" =~ .*AMD.* ]];
        then
            InstallAMDDrivers;
        else
            return 1;
        fi
    };

    echo "Config system settings..."

    SettingPowerBehavior  ;
    SettingScreenBehavior ;
    SettingDesktopDock    ;
    SettingDesktop        ;
    SettingDesktopTheme   ;
    InstallGPUDRivers     ;
};

function InstallTerminalUtilities()
{
    function InstallZsh()
    {
        echo "Installing Zsh...";

        sudo apt install -y zsh;
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
        function InstallSoftware()
        {
            local zip_download_file="yazi.zip";
            local target_extraction_folder="yazi-temp";

            sudo wget -qO "$DOWNLOAD_FOLDER/$zip_download_file" https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip;
            sudo unzip -q "$DOWNLOAD_FOLDER/$zip_download_file" -d "$DOWNLOAD_FOLDER/$target_extraction_folder";
            sudo mv "$temp_download_folder/$target_extraction_folder/*/yazi" "$USER_BINARIES_FOLDER";
            sudo rm -rf "$temp_download_folder/$target_extraction_folder" "$DOWNLOAD_FOLDER/$zip_download_file";
        };

        function ConfigYazi()
        {
            SetZshConfigFile_Alias 'alias nav=yazi' 0;
        };

        echo "Installing Yazi...";

        InstallSoftware ;
        ConfigYazi      ;
    };

    function InstallPalette()
    {
        echo "Installing Palette...";

        SetZshConfigFile_Alias 'alias palette="for i in {0..255}; do printf "\e[48;5;%sm %03d " $i $i; [ $(( (i+1) % 6 )) -eq 0 ] && echo ""; done; echo -e "\e[0m""' 0;
    };

    function InstallOhMyZsh()
    {
        function InstallSoftware()
        {
            CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)";
        };

        function ConfigOhMyZsh()
        {
            SetZshConfigFile_Export 'export ZSH="$HOME/.oh-my-zsh"' 0 ;
            SetZshConfigFile_Source 'source $ZSH/oh-my-zsh.sh'      0 ;
        };

        function InstallPlugins()
        {
            function InstallSoftware()
            {
                sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git     $HOME/.oh-my-zsh/plugins/zsh-autosuggestions     ;
                sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting ;
            };

            function ConfigZshPlugins()
            {
                SetZshConfigFile_Source '
                    source $HOME/.oh-my-zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

                    source $HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
                ' 20;
            
                SetZshConfigFile_EnvironmentVariables "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" 0;
            };

            InstallSoftware  ;
            ConfigZshPlugins ;
        };

        function ModifyZSHConfigFileInSystem()
        {
            function LinkZshrc()
            {
                if [ -f "$HOME/.zshrc" ];
                then
                    sudo rm "$HOME/.zshrc";
                fi

                sudo ln -s $PWD/.zshrc $HOME/.zshrc;
            };

            function ConfigSetupPath()
            {
                SetZshConfigFile_Export 'export SETUP="$HOME/Documents/Perso/Setup"' 0;
            };

            LinkZshrc       ;
            ConfigSetupPath ;
        };

        echo "Installing Oh-My-Zsh...";

        InstallSoftware             ;
        ConfigOhMyZsh               ;
        InstallPlugins              ;
        ModifyZSHConfigFileInSystem ;
    };

    function InstallOhMyPosh()
    {
        function InstallSoftware()
        {
            sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O "$USER_BINARIES_FOLDER/oh-my-posh";
            sudo chmod +x "$USER_BINARIES_FOLDER/oh-my-posh";
        };

        function ConfigOhMyPosh()
        {
            SetZshConfigFile_Source "eval \"\$(oh-my-posh init zsh --config $PWD/oh_my_posh/custom.omp.json)\"" 0;
        };

        function InstallNerdFont()
        {
            function DownloadFontToSystem()
            {
                local system_nerd_font_folder="$SYSTEM_SHARED_FONT_FOLDER/NerdFonts";
                local nerd_font_names=(
                    '0xProto'
                    'DepartureMono'
                    'ShareTechMono'
                    '3270'
                    'DroidSansMono'
                    'JetBrainsMono'  
                    'SourceCodePro'
                    'Agave'
                    'EnvyCodeR'
                    'Lekton'
                    'Terminus'
                    'AnonymousPro'
                    'FantasqueSansMono'
                    'LiberationMono'
                    'UbuntuSans'
                    'CascadiaMono'
                    'Mononoki'
                    'FiraCode'
                    'Lilex'
                    'Ubuntu'
                    'CodeNewRoman'
                    'FiraMono'
                    'Meslo'
                    'VictorMono'
                    'CommitMono'
                    'GeistMono'
                    'Monaspace'
                    'Cousine'
                    'Gohu'
                    'Monoid'
                    'D2Coding'
                    'IBMPlexMono'
                    'MPlus'
                );

                mkdir -p "$system_nerd_font_folder";

                for nerd_font_name in "${nerd_font_names[@]}";
                do                
                    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$nerd_font_name.zip";
                    
                    wget -q --show-progress "$font_url" -O "$DOWNLOAD_FOLDER/$nerd_font_name.zip";
                    
                    if [ $? -eq 0 ];
                    then
                        unzip -o "$DOWNLOAD_FOLDER/$nerd_font_name.zip" -d "$system_nerd_font_folder";
                    fi
                    
                    rm "$DOWNLOAD_FOLDER/$nerd_font_name.zip";
                done
            };

            function UpdateFontCache()
            {
                sudo fc-cache -fv;
            };

            function ModifyGnomeTerminalFont()
            {
                function SettingGnomeFont_Dconf()
                {
                    local user_profile_id="$1";
                    local font_name="$2";
                    local font_size="$3";

                    dconf write /org/gnome/terminal/legacy/profiles:/:$user_profile_id/font "'$font_name $font_size'";
                };

                function SettingGnomeFont_GSettings()
                {
                    local user_profile_id="$1";
                    local font_name="$2";
                    local font_size="$3";

                    gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$user_profile_id/ font "$font_name $font_size";
                };

                local user_profile_id=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'");
                local font_name="${1:-Monospace}";
                local font_size="${2:-12}";

                if [ -z "$user_profile_id" ]; 
                then
                    return 1;
                fi

                SettingGnomeFont_Dconf     "$user_profile_id" "$font_name" "$font_size" ;
                SettingGnomeFont_GSettings "$user_profile_id" "$font_name" "$font_size" ;
            };

            DownloadFontToSystem ;
            UpdateFontCache      ;
            ModifyGnomeTerminalFont "$FONT_NAME" "$FONT_SIZE";
        };

        echo "Installing Oh-My-Posh...";
        
        InstallSoftware ;
        ConfigOhMyPosh  ;
        InstallNerdFont ;
    };

    function ChangeDefaultShellToZsh()
    {
        sudo chsh -s "$(which zsh)" "$USER";
    };

    InstallZsh              ;
    InstallFzf              ;
    InstallTheFuck          ;
    InstallTree             ;
    InstallBTop             ;
    InstallNeofetch         ;
    InstallYazi             ;
    InstallPalette          ;
    InstallOhMyZsh          ;
    InstallOhMyPosh         ;
    ChangeDefaultShellToZsh ;
};

sudo -v;

if CheckScriptEnvironmentVariables;
then
    IncreaseSudoEffectiveness;

    sudo apt update ;

    InstallGnomeUIUtilities  ;
    InstallApps              ;
    InstallCodingEcosystem   ;
    ConfigSystemSettings     ;
    InstallTerminalUtilities ;

    RemoveIncreaseSudoEffectiveness;
    
    gnome-session-quit --logout --no-prompt;
fi
