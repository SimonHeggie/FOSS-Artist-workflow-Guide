#!/bin/bash

# Define paths
INSTALL_DIR="$HOME/.Applications/Krita"
PYKRITA_DIR="$INSTALL_DIR/squashfs-root/usr/share/krita/pykrita"
DESKTOP_FILE="$HOME/.local/share/applications/krita.desktop"
LOG_FILE="$INSTALL_DIR/uninstall_log.txt"
SETTINGS_FILE="$HOME/.local/share/krita-ai-diffusion/settings.json"
KRITARC_FILE="$HOME/.config/kritarc"

# Ensure log file exists
mkdir -p "$INSTALL_DIR"
touch "$LOG_FILE"

echo "Starting Krita uninstallation..." | tee -a "$LOG_FILE"

# Remove AI Diffusion plugin
if [ -d "$PYKRITA_DIR/ai_diffusion" ]; then
    echo "Removing AI Diffusion plugin..." | tee -a "$LOG_FILE"
    rm -rf "$PYKRITA_DIR/ai_diffusion"
else
    echo "AI Diffusion plugin not found." | tee -a "$LOG_FILE"
fi

# Remove Blender Layer plugin
if [ -d "$PYKRITA_DIR/BlenderLayer" ]; then
    echo "Removing Blender Layer plugin..." | tee -a "$LOG_FILE"
    rm -rf "$PYKRITA_DIR/BlenderLayer"
else
    echo "Blender Layer plugin not found." | tee -a "$LOG_FILE"
fi

# Remove Krita AppImage and extracted files
echo "Removing Krita installation..." | tee -a "$LOG_FILE"
rm -rf "$INSTALL_DIR"

# Remove the desktop shortcut
if [ -f "$DESKTOP_FILE" ]; then
    echo "Removing Krita desktop shortcut..." | tee -a "$LOG_FILE"
    rm -f "$DESKTOP_FILE"
fi

# Remove kritarc file
if [ -f "$KRITARC_FILE" ]; then
    echo "Removing kritarc settings..." | tee -a "$LOG_FILE"
    rm -f "$KRITARC_FILE"
fi

# Ask the user if they want to keep or delete Krita AI-Diffusion settings
read -p "Do you want to remove Krita AI-Diffusion settings? (Y/N): " REMOVE_SETTINGS
if [[ "$REMOVE_SETTINGS" =~ ^[Yy]$ ]]; then
    echo "Removing AI-Diffusion settings..." | tee -a "$LOG_FILE"
    rm -f "$SETTINGS_FILE"
else
    echo "Keeping AI-Diffusion settings." | tee -a "$LOG_FILE"
fi

echo "Krita uninstallation completed." | tee -a "$LOG_FILE"
