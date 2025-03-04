#!/bin/bash

BLENDER_DIR="$HOME/.Applications/Blender/stable/blender-stable-baseline"
BLENDER_EXEC="$BLENDER_DIR/blender"
DESKTOP_ENTRY="$HOME/.local/share/applications/blender.desktop"
SYMLINK="/usr/local/bin/blender"

# Check if Blender directory exists
if [ -d "$BLENDER_DIR" ]; then
  echo "Removing Blender directory: $BLENDER_DIR"
  rm -rf "$BLENDER_DIR"
else
  echo "Blender directory does not exist: $BLENDER_DIR"
fi

# Check if symbolic link exists
if [ -L "$SYMLINK" ]; then
  echo "Removing symbolic link: $SYMLINK"
  sudo rm "$SYMLINK"
else
  echo "Symbolic link does not exist: $SYMLINK"
fi

# Check if desktop entry exists
if [ -f "$DESKTOP_ENTRY" ]; then
  echo "Removing desktop entry: $DESKTOP_ENTRY"
  rm "$DESKTOP_ENTRY"
else
  echo "Desktop entry does not exist: $DESKTOP_ENTRY"
fi

echo "Blender uninstallation complete."
