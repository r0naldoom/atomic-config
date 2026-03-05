#!/usr/bin/env bash
set -euo pipefail

FEDORA_VERSION=$(rpm -E %fedora)

add_copr() {
    local repo=$1
    local name=${repo//\//-}
    echo "Adding COPR: ${repo}"
    curl -fsSL -o "/etc/yum.repos.d/_copr-${name}.repo" \
        "https://copr.fedorainfracloud.org/coprs/${repo}/repo/fedora-${FEDORA_VERSION}/${name}-fedora-${FEDORA_VERSION}.repo"
}

# ─────────────────────────────────────────────────────────────────────────────
# NOCTALIA SHELL (Bar + Theme manager)
# ─────────────────────────────────────────────────────────────────────────────
add_copr "zhangyi6324/noctalia-shell"

# ─────────────────────────────────────────────────────────────────────────────
# GHOSTTY (Terminal)
# ─────────────────────────────────────────────────────────────────────────────
add_copr "scottames/ghostty"

# ─────────────────────────────────────────────────────────────────────────────
# HYPRLAND ECOSYSTEM (latest versions)
# ─────────────────────────────────────────────────────────────────────────────
add_copr "solopasha/hyprland"

# ─────────────────────────────────────────────────────────────────────────────
# SWWW (Animated wallpaper daemon)
# ─────────────────────────────────────────────────────────────────────────────
add_copr "agonie/swww"

# ─────────────────────────────────────────────────────────────────────────────
# YAZI (File manager)
# ─────────────────────────────────────────────────────────────────────────────
add_copr "varlad/yazi"

# ─────────────────────────────────────────────────────────────────────────────
# SATTY (Screenshot annotation)
# ─────────────────────────────────────────────────────────────────────────────
add_copr "errornointernet/packages"

# ─────────────────────────────────────────────────────────────────────────────
# ZEN BROWSER
# ─────────────────────────────────────────────────────────────────────────────
add_copr "sneexy/zen-browser"

echo "=== COPR repositories added successfully ==="
