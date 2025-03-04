#!/bin/bash

# Ensure required dependencies are installed
for cmd in curl wget unzip rsync grep sed sort jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed. Please install it and retry."
        exit 1
    fi
done

# Set installation directories
INSTALL_DIR="$HOME/.Applications/Krita"
LOG_FILE="$INSTALL_DIR/error_log.txt"
PYKRITA_DIR="$INSTALL_DIR/squashfs-root/usr/share/krita/pykrita"
EXTRACT_LOG="$INSTALL_DIR/extract_log.txt"
SETTINGS_FILE="$HOME/.local/share/krita-ai-diffusion/settings.json"
KRITARC_FILE="$HOME/.config/kritarc"
COMFYUI_SERVER_PATH="$HOME/.Applications/ComfyUI/server/"

mkdir -p "$INSTALL_DIR"
mkdir -p "$HOME/.config"
cd "$INSTALL_DIR" || { echo "Failed to change directory to $INSTALL_DIR" | tee -a "$LOG_FILE"; exit 1; }

# Fetch the latest Krita version
BASE_URL="https://download.kde.org/stable/krita/"
LATEST_VERSION=$(curl -s "$BASE_URL" | grep -oP '5\.[\d\.]+/' | sort -V | tail -n 1 | sed 's|/$||')

if [ -z "$LATEST_VERSION" ]; then
    echo "Error: Failed to find the latest Krita version." | tee -a "$LOG_FILE"
    exit 1
fi

FULL_KRITA_URL="${BASE_URL}${LATEST_VERSION}/krita-${LATEST_VERSION}-x86_64.appimage"

# Download Krita if not already present
if [ ! -f "$INSTALL_DIR/krita.appimage" ] || [ ! -s "$INSTALL_DIR/krita.appimage" ]; then
    wget -O "$INSTALL_DIR/krita.appimage" "$FULL_KRITA_URL" || { echo "Failed to download Krita." | tee -a "$LOG_FILE"; exit 1; }
fi

chmod +x "$INSTALL_DIR/krita.appimage"

# Extract Krita AppImage
echo "Extracting Krita AppImage..." | tee -a "$LOG_FILE"
sudo "$INSTALL_DIR/krita.appimage" --appimage-extract > "$EXTRACT_LOG" 2>&1
if [ $? -ne 0 ]; then
    echo "Failed to extract Krita." | tee -a "$LOG_FILE"
    exit 1
fi

sudo chmod +x "$INSTALL_DIR/squashfs-root/AppRun"

# Download and install AI Diffusion plugin
LATEST_AI_DIFFUSION=$(curl -s https://api.github.com/repos/Acly/krita-ai-diffusion/releases/latest | grep browser_download_url | grep zip | cut -d '"' -f 4)
wget -O "ai_diffusion.zip" "$LATEST_AI_DIFFUSION" || { echo "Failed to download AI Diffusion addon." | tee -a "$LOG_FILE"; exit 1; }
unzip -o "ai_diffusion.zip" -d "ai_diffusion_extracted" || { echo "Failed to extract AI Diffusion addon." | tee -a "$LOG_FILE"; exit 1; }
sudo rsync -av --delete "ai_diffusion_extracted/ai_diffusion/" "$PYKRITA_DIR/ai_diffusion/"
sudo mv "ai_diffusion_extracted/ai_diffusion.desktop" "$PYKRITA_DIR"
rm -rf "ai_diffusion_extracted" "ai_diffusion.zip"

# Update kritarc with the correct settings
if [ ! -f "$KRITARC_FILE" ]; then
    echo "Creating kritarc file..." | tee -a "$LOG_FILE"
    cat << EOF > "$KRITARC_FILE"
ResourceDirectory=$INSTALL_DIR/squashfs-root/usr/share/krita/

[python]
enable_ai_diffusion=true
enable_svg_merge_save=true

[Plugins]
Plugins=batch_exporter
EOF
else
    # Ensure batch_exporter is enabled in kritarc
    if ! grep -q "^Plugins=.*batch_exporter" "$KRITARC_FILE"; then
        if grep -q "^Plugins=" "$KRITARC_FILE"; then
            sed -i '/^Plugins=/ s/$/,batch_exporter/' "$KRITARC_FILE"
        else
            echo -e "\n[Plugins]" >> "$KRITARC_FILE"
            echo "Plugins=batch_exporter" >> "$KRITARC_FILE"
        fi
    fi
fi

# Update krita-ai-diffusion settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    cat << EOF > "$SETTINGS_FILE"
{
    "server_path": "$COMFYUI_SERVER_PATH"
}
EOF
else
    sed -i "s|\"server_path\":.*|\"server_path\": \"$COMFYUI_SERVER_PATH\",|" "$SETTINGS_FILE"
fi

# Create desktop shortcut for Krita
DESKTOP_FILE="$HOME/.local/share/applications/krita.desktop"
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=Krita
Icon=$INSTALL_DIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/krita.png
Exec=env APPDIR=$INSTALL_DIR/squashfs-root APPIMAGE=1 PYTHONPATH=$INSTALL_DIR/squashfs-root/usr/lib/krita-python-libs/krita $INSTALL_DIR/squashfs-root/AppRun
Terminal=false
Categories=Graphics;
StartupWMClass=krita
EOF

echo "Krita installation and AI-Diffusion setup completed." | tee -a "$LOG_FILE"
