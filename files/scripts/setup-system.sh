#!/usr/bin/env bash
set -euo pipefail

echo "=== Configuring system ==="

# ─────────────────────────────────────────────────────────────────────────────
# LOCALE & TIMEZONE
# ─────────────────────────────────────────────────────────────────────────────
echo "Setting locale and timezone..."
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

cat > /etc/locale.conf << 'EOF'
LANG=pt_BR.UTF-8
LC_TIME=pt_BR.UTF-8
LC_COLLATE=pt_BR.UTF-8
LC_MESSAGES=pt_BR.UTF-8
EOF

# ─────────────────────────────────────────────────────────────────────────────
# HOSTNAME
# ─────────────────────────────────────────────────────────────────────────────
echo "actus-spei" > /etc/hostname

# ─────────────────────────────────────────────────────────────────────────────
# FISH SHELL
# ─────────────────────────────────────────────────────────────────────────────
echo "Adding fish to valid shells..."
grep -q /usr/bin/fish /etc/shells || echo /usr/bin/fish >> /etc/shells

# ─────────────────────────────────────────────────────────────────────────────
# HDEX MOUNT
# ─────────────────────────────────────────────────────────────────────────────
echo "Configuring HDEX mount..."
mkdir -p /home/HDEX
systemctl enable home-HDEX.mount

# ─────────────────────────────────────────────────────────────────────────────
# SERVICES
# ─────────────────────────────────────────────────────────────────────────────
echo "Enabling services..."
systemctl enable greetd.service
systemctl enable firewalld.service
systemctl enable bluetooth.service
systemctl enable libvirtd.service
systemctl enable upower.service
systemctl enable power-profiles-daemon.service

# ─────────────────────────────────────────────────────────────────────────────
# FIREWALL - OpenMU ports
# ─────────────────────────────────────────────────────────────────────────────
echo "Configuring firewall..."
firewall-offline-cmd --zone=public --add-port=44405/tcp || true
firewall-offline-cmd --zone=public --add-port=44406/tcp || true
firewall-offline-cmd --zone=public --add-port=55901/tcp || true
firewall-offline-cmd --zone=public --add-port=55902/tcp || true
firewall-offline-cmd --zone=public --add-port=55903/tcp || true
firewall-offline-cmd --zone=public --add-port=55904/tcp || true
firewall-offline-cmd --zone=public --add-port=55905/tcp || true
firewall-offline-cmd --zone=public --add-port=55906/tcp || true
firewall-offline-cmd --zone=public --add-port=55980/tcp || true

# ─────────────────────────────────────────────────────────────────────────────
# SUDOERS - nvidia-settings and podman without password
# ─────────────────────────────────────────────────────────────────────────────
echo "Configuring sudoers..."
cat > /etc/sudoers.d/custom << 'EOF'
# NVIDIA fan control
%wheel ALL=(ALL) NOPASSWD: /usr/bin/nvidia-settings

# Podman rootless
%wheel ALL=(ALL) NOPASSWD: /usr/bin/podman
EOF
chmod 440 /etc/sudoers.d/custom

# ─────────────────────────────────────────────────────────────────────────────
# NVIDIA - Coolbits para fan control
# ─────────────────────────────────────────────────────────────────────────────
echo "Configuring NVIDIA..."
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/20-nvidia.conf << 'EOF'
Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    Option         "Coolbits" "4"
EndSection
EOF

# ─────────────────────────────────────────────────────────────────────────────
# GREETD - already configured in /etc/greetd/config.toml via files
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# SKEL - default directories
# ─────────────────────────────────────────────────────────────────────────────
echo "Creating skel directories..."
mkdir -p /etc/skel/.config
mkdir -p /etc/skel/.local/bin
mkdir -p /etc/skel/.local/share

# ─────────────────────────────────────────────────────────────────────────────
# NETWORKMANAGER - connection permissions
# ─────────────────────────────────────────────────────────────────────────────
echo "Setting NetworkManager connection permissions..."
chmod 600 /etc/NetworkManager/system-connections/*.nmconnection 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────────────────
# LIBVIRT - permissions
# ─────────────────────────────────────────────────────────────────────────────
echo "Configuring libvirt..."
sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/' /etc/libvirt/libvirtd.conf || true
sed -i 's/#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/' /etc/libvirt/libvirtd.conf || true

# ─────────────────────────────────────────────────────────────────────────────
# CLEANUP
# ─────────────────────────────────────────────────────────────────────────────
echo "Cleaning up..."
rm -rf /var/cache/dnf/* || true

echo "=== System configuration complete ==="
