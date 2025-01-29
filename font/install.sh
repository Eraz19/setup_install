#!/bin/bash


source "$(dirname "$0")/.env"


function InstallFontNerd()
{
    echo "Installing Nerd Fonts...";
    
    for zip_file in "$PROJECT_FONT_FOLDER/*.zip";
    do
        if [ -f "$zip_file" ];
        then
            local temp_dir=$(mktemp -d);
            unzip -q "$zip_file" -d "$temp_dir";
            
            for font in "$temp_dir"/*.{ttf,otf};
            do
                if [ -f "$font" ];
                then
                    sudo mv "$font" "$PROJECT_SYSTEM_FONT_FOLDER";
                    echo "Installed: $font";
                fi
            done

            rm -rf "$temp_dir";
        else
            echo "No .zip files found in $PROJECT_FONT_FOLDER";
        fi
    done

    fc-cache -fv;
};

# Params
#   - $1 [default "Monospace"] : Font name
#   - $2 [default "12"]        : Font size
function SetFont()
{
    local font_name="${1:-Monospace}";
    local font_size="${2:-12}";

    dconf write /org/gnome/terminal/legacy/profiles:/<profile_id>/font "$font_name $font_size";
};