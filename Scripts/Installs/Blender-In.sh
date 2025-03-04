#!/bin/bash

# Prompt for admin password at the beginning
if [ "$EUID" -ne 0 ]; then
  echo "This script requires administrative privileges. Please provide your password."
  sudo -v || { echo "Failed to obtain sudo privileges. Exiting."; exit 1; }
fi

# Define variables
BLENDER_DIR="$HOME/.Applications/Blender/stable/blender-stable-baseline"
BLENDER_EXEC="$BLENDER_DIR/blender"
DESKTOP_SHORTCUT="$BLENDER_DIR/blender.desktop"
VERSION_FILE="$BLENDER_DIR/version.txt"

# Function to fetch the latest Blender version number
get_latest_version() {
  curl -s https://www.blender.org/download/ | grep -oP 'blender-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1
}



# Function to fetch the current installed Blender version
get_current_version() {
  if [ -f "$BLENDER_EXEC" ]; then
    $BLENDER_EXEC --version | head -n 1 | awk '{print $2}'
  else
    echo "0.0.0"
  fi
}

# Function to detect GPU setup
detect_gpu_setup() {
  if command -v nvidia-smi &> /dev/null; then
    echo "proprietary"
  elif lspci | grep -i 'VGA' | grep -i 'NVIDIA' &> /dev/null; then
    echo "nouveau"
  elif lspci | grep -i 'VGA' | grep -i 'AMD' &> /dev/null; then
    echo "amd"
  else
    echo "unknown"
  fi
}

# Function to fetch the latest Gather Resources addon release URL from GitHub
get_latest_gather_resources_url() {
  curl -s https://api.github.com/repos/SimonHeggie/Blender-GatherResources/releases/latest | 
  grep "browser_download_url" | 
  grep ".zip" | 
  cut -d '"' -f 4
}

# Fetch the latest Blender version number
latest_version=$(get_latest_version)
current_version=$(get_current_version)

echo "Latest Blender version: $latest_version"
echo "Current Blender version: $current_version"

# Compare versions and download if necessary
if [ "$latest_version" != "$current_version" ]; then
  echo "Updating Blender to version $latest_version..."

  # Construct the download URL
  download_url="https://mirror.clarkson.edu/blender/release/Blender${latest_version%.*}/blender-$latest_version-linux-x64.tar.xz"

  # Download the latest Blender tarball
  wget -O blender-latest.tar.xz $download_url

  # Extract the downloaded tarball
  mkdir -p $BLENDER_DIR
  tar -xf blender-latest.tar.xz -C $HOME/.Applications/Blender/stable
  mv $HOME/.Applications/Blender/stable/blender-$latest_version-linux-x64/* $BLENDER_DIR

  # Clean up the tarball and temporary directory
  rm -rf blender-latest.tar.xz
  rm -rf $HOME/.Applications/Blender/stable/blender-$latest_version-linux-x64

  # Save the current version to the version file
  echo "$latest_version" > "$VERSION_FILE"
else
  echo "Blender is already up-to-date. Refreshing desktop shortcut..."
fi

# Create a symbolic link to make Blender accessible from anywhere
sudo ln -sf $BLENDER_EXEC /usr/local/bin/blender

# Detect GPU setup and determine the correct Exec command
GPU_SETUP=$(detect_gpu_setup)
echo "GPU Setup detected: $GPU_SETUP"

case "$GPU_SETUP" in
  "proprietary")
    EXEC_COMMAND="__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia $BLENDER_EXEC"
    ;;
  "nouveau"|"amd")
    EXEC_COMMAND="DRI_PRIME=1 $BLENDER_EXEC"
    ;;
  *)
    EXEC_COMMAND="$BLENDER_EXEC"
    ;;
esac

echo "Using Exec command: $EXEC_COMMAND"

# Update the Exec line in the existing desktop shortcut
if [ -f "$DESKTOP_SHORTCUT" ]; then
  sudo sed -i "s|^Exec=.*|Exec=$EXEC_COMMAND|" "$DESKTOP_SHORTCUT"
  echo "Updated the Exec line in the desktop shortcut: $DESKTOP_SHORTCUT"

  # Copy the .desktop file to ~/.local/share/applications for taskbar/menu use
  cp "$DESKTOP_SHORTCUT" ~/.local/share/applications/
  echo "Copied updated desktop shortcut to ~/.local/share/applications/"

  # Refresh the desktop database to ensure changes take effect
  sudo update-desktop-database ~/.local/share/applications
  sudo update-desktop-database /usr/share/applications
  echo "Desktop database refreshed."
else
  echo "Desktop shortcut not found at $DESKTOP_SHORTCUT. Skipping update."
fi

echo "Verifying the desktop shortcut content:"
echo "Blender $latest_version installation and desktop shortcut refresh complete."

# ---- Dynamic Addon Directory Handling ----

# Scan for Blender version folders
blender_versions=($(ls -d $BLENDER_DIR/[0-9]* 2>/dev/null | awk -F'/' '{print $NF}' | sort -V))

# Remove all but the highest version folder
if [ ${#blender_versions[@]} -gt 1 ]; then
  echo "Multiple Blender version directories detected: ${blender_versions[@]}"
  
  for ((i = 0; i < ${#blender_versions[@]} - 1; i++)); do
    echo "Removing old Blender version: ${blender_versions[i]}"
    rm -rf "$BLENDER_DIR/${blender_versions[i]}"
  done
fi

# Get the latest version directory
LATEST_BLENDER_VERSION="${blender_versions[-1]}"
echo "Using Blender version: $LATEST_BLENDER_VERSION"

# Construct the dynamic addons directory path
ADDONS_DIR="$BLENDER_DIR/$LATEST_BLENDER_VERSION/scripts/addons_core/"
mkdir -p "$ADDONS_DIR"
echo "Blender Addons Directory: $ADDONS_DIR"

# ---- Install Gather Resources Addon ----

# Get the latest release URL for Gather Resources
echo "Fetching latest Gather Resources addon..."
gather_resources_url=$(get_latest_gather_resources_url)

if [ -z "$gather_resources_url" ]; then
  echo "Failed to fetch the Gather Resources addon URL. Skipping installation."
else
  echo "Downloading Gather Resources from: $gather_resources_url"
  wget -O GatherResources.zip "$gather_resources_url"

  # Ensure the addons directory exists
  mkdir -p "$ADDONS_DIR"

  # Extract and install the addon
  echo "Installing Gather Resources addon..."
  unzip -o GatherResources.zip -d "$ADDONS_DIR"
  rm GatherResources.zip

  echo "Gather Resources addon installed successfully."
fi

echo "Installation complete! Blender is up to date, and Gather Resources addon is installed."
