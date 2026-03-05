#!/usr/bin/env bash
# Sync wallpaper with Noctalia theme

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
SETTINGS="$HOME/.config/noctalia/settings.json"

# Find quickshell and noctalia-shell
# Fedora: /usr/bin e /usr/share
# NixOS: /nix/store
if [[ -x /usr/bin/quickshell ]]; then
    QUICKSHELL="/usr/bin/quickshell"
    QS_PATH="/usr/share/noctalia-shell"
else
    QUICKSHELL=$(ls /nix/store/*quickshell*/bin/quickshell 2>/dev/null | head -1)
    QS_PATH=$(ls -d /nix/store/*noctalia-shell-*/share/noctalia-shell 2>/dev/null | head -1)
fi

if [[ -z "$QUICKSHELL" ]] || [[ -z "$QS_PATH" ]]; then
    exit 1
fi

# Read current theme
THEME=$(grep -o '"predefinedScheme": *"[^"]*"' "$SETTINGS" | cut -d'"' -f4)

# Theme -> wallpaper mapping
case "$THEME" in
    "Thorn")
        WALLPAPER="allef-vinicius-cross-everforest.jpg"
        ;;
    "Gruvbox-Material")
        WALLPAPER="gabi-repaska-cross-gruvbox.jpg"
        ;;
    "EfCherie")
        WALLPAPER="aaron-burden-cross-cherie.jpg"
        ;;
    "Tokyo Night")
        WALLPAPER="aaron-burden-cross-tokyo.jpg"
        ;;
    *)
        exit 0
        ;;
esac

FULL_PATH="$WALLPAPER_DIR/$WALLPAPER"

if [[ -f "$FULL_PATH" ]]; then
    "$QUICKSHELL" ipc -p "$QS_PATH" call wallpaper set "$FULL_PATH" "" 2>/dev/null || true
fi
