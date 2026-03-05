#!/usr/bin/env bash
# Reading Mode Toggle - Gruvbox Material E-Ink
# Toggles screen shader and disables visual effects for focused reading.

STATE_FILE="$HOME/.cache/reading-mode-active"
SHADER="$HOME/.config/hypr/shaders/gruvbox-eink.glsl"

if [[ -f "$STATE_FILE" ]]; then
    # --- DEACTIVATE ---
    rm -f "$STATE_FILE"

    # Remove shader
    hyprctl keyword decoration:screen_shader ""

    # Reload config to restore all original settings
    hyprctl reload
else
    # --- ACTIVATE ---
    touch "$STATE_FILE"

    # Apply e-ink shader
    hyprctl keyword decoration:screen_shader "$SHADER"

    # Disable visual effects for clean reading
    hyprctl --batch "\
        keyword animations:enabled false; \
        keyword decoration:blur:enabled false; \
        keyword decoration:shadow:enabled false; \
        keyword decoration:rounding 0; \
        keyword decoration:active_opacity 1.0; \
        keyword decoration:inactive_opacity 1.0; \
        keyword decoration:dim_inactive false; \
        keyword general:gaps_in 0; \
        keyword general:gaps_out 0; \
        keyword general:border_size 1; \
        keyword general:col.active_border rgba(1d2021ff); \
        keyword general:col.inactive_border rgba(1d202188)"
fi
