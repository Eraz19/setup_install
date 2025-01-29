# Setup list

## Prerequisit

### Installation Script

If the ```install.sh``` script is used to install this Debian distro setup :

- Modify the file ```.env_template``` to ```.env``` and fill the environement variables. If some variable are not set, the script will exit without running
- Download a iso file of a bootable Os in the ```Setup```>```virtual_machine``` 
- The font installation is manage in the script, there is just a need to download ```.zip``` font archive files in the folder ```Setup```>```font```  


## Gnome

| Name   | Command                                  | Comment           |
|--------|------------------------------------------|------------------ |
| Tweak  | sudo apt install gnome-tweaks            | *Modify gnome UI* |

## Steam

```sh
sudo add-apt-repository multiverse
sudo apt update

sudo apt install steam
```

To enable **Proton** for game compatibility with linux system, open the **Steam** platform and go to ```Steam``` > ```Settings``` > ```Compatibility```

## VsCode

```sh
# Import the Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/

# Add the Visual Studio Code repository
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# Install Visual Studio Code
sudo apt install code
```

### Extension

| Name                                      | Creator           | Command                                                   |
|-------------------------------------------|-------------------|-----------------------------------------------------------|
| C/C++                                     |  Microsoft        | code --install-extension ms-vscode.cpptools               | 
| C/C++ Extension Pack                      |  Microsoft        | code --install-extension ms-vscode.cpptools-pack          | 
| C/C++ Themes                              |  Microsoft        | code --install-extension ms-vscode.cpptools-themes        | 
| CMake                                     |  twxs             | code --install-extension twxs.cmake                       | 
| CMake Tools                               |  Microsoft        | code --install-extension ms-vscode.cmake-tools            | 
| Code Runner                               |  Jun Han          | code --install-extension formulahendry.code-runner        | 
| Dev Containers                            |  Microsoft        | code --install-extension ms-vscode-devcontainers          | 
| Docker                                    |  Microsoft        | code --install-extension ms-azuretools.vscode-docker      | 
| GitHub Pull Requests                      |  GitHub           | code --install-extension ms-vscode.github                 | 
| Gradle for Java                           |  Microsoft        | code --install-extension ms-vscode.gradle                 | 
| Highlight                                 |  Fabio spampinato | code --install-extension fabiospampinato.vscode-highlight | 
| Ionic                                     |  Ionic            | code --install-extension Ionic.ionic                      | 
| Jupiter                                   |  Microsoft        | code --install-extension ms-toolsai.jupyter               | 
| Jupiter Keymap                            |  Microsoft        | code --install-extension ms-toolsai.jupyter-keymap        | 
| Kotlin                                    |  fwcd             | code --install-extension fwcd.kotlin                      | 
| Kotlin Language                           |  mathiasfrohlich  | code --install-extension mathiasfrohlich.kotlin           | 
| Markdown Code Blocks                      |  Yantao Shang     | code --install-extension yantao.vscode-markdown           | 
| Material Icon Theme                       |  Philipp Kief     | code --install-extension pkief.material-icon-theme        | 
| Pylance                                   |  Microsoft        | code --install-extension ms-python.vscode-pylance         | 
| Python                                    |  Microsoft        | code --install-extension ms-python.python                 | 
| Remote - SSH                              |  Microsoft        | code --install-extension ms-vscode.remote-ssh             | 
| Remote - SSH: Editing Configuration Files |  Microsoft        | code --install-extension ms-vscode.remote-ssh-edit        | 
| Run on Save                               |  emeraldwalk      | code --install-extension emeraldwalk.runonsave            | 
| Todo Tree                                 |  Gruntfuggly      | code --install-extension gruntfuggly.todo-tree            | 
| WGSL                                      |  PolyMeitex       | code --install-extension PolyMeitex.wgsl                  | 

### Keyboard shortcut

```sh
mkdir -p ~/.config/Code/User
echo '
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
]' >> ~/.config/Code/User/keybindings.json
```

## Vitual Machine

```sh
# Install VirtualMachine software 
sudo apt install qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager -y

#---------------------------- USAGE ----------------------------#

# Create a VirtualMachine Disk (use alias vm_disk_create in .zshrc if provided)
qemu-img create -f qcow2 ...path_to_desired_vm_disk_location/disk.qcow2 40G

# Install OS in VirtualMachine (use alias vm_install in .zshrc if provided)
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -cpu host \
    -smp 2 \
    -cdrom ...path_to_desired_iso_os_file_image \
    -drive file=...path_to_desired_vm_disk_file,format=qcow2 \
    -boot d \
    -vga virtio \
    -display sdl

# Run VirtualMachine with snapshot mode to have a clean session at every boot (use alias vm_run in .zshrc if provided)
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -cpu host \
    -smp 2 \
    -drive file=...path_to_desired_vm_disk_file,format=qcow2,snapshot=on \
    -vga virtio \
    -display sdl \
    -spice port=5900,disable-ticketing=on \
    -device virtio-serial \
    -chardev spicevmc,id=spicechannel0,name=main \
    -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0
```

*.zshrc* :
```sh
# Change file path for vm disk location
alias vm_disk_create='qemu-img create -f qcow2 ...path_to_vm_disk_location/disk.qcow2 40G'
# Change file path for vm disk location and os iso file
alias vm_install='
    qemu-system-x86_64 \
        -enable-kvm \
        -m 4096 \
        -cpu host \
        -smp 2 \
        -cdrom ...path_to_desired_iso_os_file_image \
        -drive file=...path_to_desired_vm_disk_file,format=qcow2 \
        -boot d \
        -vga virtio \
        -display sdl
'
# Change file path for vm disk location
alias vm_run='
    qemu-system-x86_64 \
        -enable-kvm \
        -m 4096 \
        -cpu host \
        -smp 2 \
        -drive file=...path_to_desired_vm_disk_file,format=qcow2,snapshot=on \
        -vga virtio \
        -display sdl \
        -spice port=5900,disable-ticketing=on \
        -device virtio-serial \
        -chardev spicevmc,id=spicechannel0,name=main \
        -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0
'
```

## Coding

### Git

```sh
# Install Git
sudo apt install git -y

# Set git config file
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"

# Generate ssh key
ssh-keygen -t ed25519 -C "your-email@example.com"
# Start the SSH agent
eval "$(ssh-agent -s)"
# Add your SSH private key to the agent
ssh-add "path to private key"

# Copy SSH public key in Git platform
cat "path to private key".pub
```

### NodeJS

```sh
# Install nvm for node version management
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Install last version of nodeJS
nvm install --lts
```

*.zshrc* :
```sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
```

### Kotlin

```sh
# Install the JVM used to run Java/Kotlin code
sudo apt install openjdk-17-jdk

# Install sdkman to help install all the Kotlin toolchain
curl -s "https://get.sdkman.io" | bash

sdk install kotlin 1.8.20
sdk install gradle 8.12
```

*.zshrc* :
```sh
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
```

## Terminal

| Name     | Command                   | Comment                                                     |
|----------|---------------------------|-------------------------------------------------------------|
| zsh      | sudo apt install zsh      |                                                             | 
| fzf      | sudo apt install fzf      | *FuzzySearch into file system*                              |
| thefuck  | sudo apt install thefuck  | *Correct command line by understanding what was the intent* |
| tree     | sudo apt install tree     |                                                             |
| btop     | sudo atp install btop     | *Display system monitor*                                    |
| neofetch | sudo atp install neofetch | *Dislay about*                                              |

### YAZI

install Yazi:
```sh
# Download the latest release of Yazi from GitHub:
wget -qO yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip

# Extract files to temporary directory
unzip -q yazi.zip -d yazi-temp
sudo mv yazi-temp/*/yazi /usr/local/bin

# Remove temporary directory and downloaded archive
rm -rf yazi-temp yazi.zip
```

Uninstall Yazi:
```sh
sudo rm -rf /usr/local/bin/yazi
```

### Oh-My-Posh

Install font with set of icons (eq. https://www.nerdfonts.com/font-downloads to download sets of fonts with icons)

```sh
sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
sudo chmod +x /usr/local/bin/oh-my-posh
```

*.zshrc* :
```sh
# If the .zshrc is not already provided
eval "$(oh-my-posh init zsh --config ...path_to_oh_my_posh_config_location/custom.omp.json)"
```

### Oh-My-Zsh

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
```

*.zshrc* :
```sh
# If the .zshrc is not already provided
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
```




