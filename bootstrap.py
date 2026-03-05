#!/usr/bin/env python3
"""
Fedora Atomic post-install bootstrap
Usage: ./bootstrap.py <command>
"""

import subprocess
import sys
import os
from pathlib import Path
from functools import wraps
from typing import Callable

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────
HOME = Path.home()
CONFIG_DIR = HOME / ".config"
LOCAL_BIN = HOME / ".local/bin"
DOTFILES_REPO = HOME / ".dotfiles"
ATOMIC_DOTS = Path(__file__).parent / "dotfiles"

NERD_FONTS = ["JetBrainsMono", "NerdFontsSymbolsOnly", "Iosevka", "FiraCode"]
NERD_FONTS_VERSION = "v3.3.0"
FONTS_DIR = Path("/usr/local/share/fonts/nerd-fonts")

FLATPAKS = ["dev.vencord.Vesktop"]

DISTROBOX_EXPORTS = [
    "nvim", "starship", "zoxide", "fzf", "bat", "eza",
    "btop", "fastfetch", "rg", "fd", "duf", "tldr", "jq", "yq",
    "gh", "lazygit", "sesh", "rmpc", "yazi",
    "lua-language-server", "bash-language-server", "yaml-language-server",
    "stylua", "shfmt", "direnv",
]

DOTFILES = [
    "fish", "ghostty", "hypr", "nvim", "noctalia",
    "rmpc", "tmux", "yazi", "btop", "fastfetch", "sesh",
    "claude",
]

DIRECTORIES = [
    HOME / "Projects",
    HOME / "Pictures/Wallpapers",
    HOME / "Pictures/Screenshots",
    HOME / "Music",
    HOME / ".local/bin",
    HOME / ".local/share",
]

MSVC_DIR = HOME / "msvc"
MSVC_WINE_REPO = "https://github.com/mstorsjo/msvc-wine.git"

GIT_CONFIG = {
    "user.name": "r0naldoom",
    "user.email": "49367540+r0naldoom@users.noreply.github.com",
    "user.signingkey": "~/.ssh/id_ed25519.pub",
    "init.defaultBranch": "main",
    "core.editor": "nvim",
    "gpg.format": "ssh",
    "gpg.ssh.allowedSignersFile": "~/.ssh/allowed_signers",
    "commit.gpgsign": "true",
    "push.autoSetupRemote": "true",
}

# ─────────────────────────────────────────────────────────────────────────────
# DECORATORS
# ─────────────────────────────────────────────────────────────────────────────
COMMANDS: dict[str, Callable] = {}


def command(name: str, sudo: bool = False):
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            if sudo and os.geteuid() != 0:
                print(f"[ERROR] '{name}' requires sudo")
                sys.exit(1)
            print(f"\n:: {name}")
            try:
                return func(*args, **kwargs)
            except subprocess.CalledProcessError as e:
                print(f"[ERRO] {e}")
                sys.exit(1)

        wrapper._sudo = sudo
        COMMANDS[name] = wrapper
        return wrapper
    return decorator


def run(cmd: str | list, check: bool = True, capture: bool = False):
    if isinstance(cmd, str):
        cmd = cmd.split()
    return subprocess.run(cmd, check=check, capture_output=capture, text=True)


# ─────────────────────────────────────────────────────────────────────────────
# COMMANDS
# ─────────────────────────────────────────────────────────────────────────────
@command("verify")
def verify():
    if not Path("/run/ostree-booted").exists():
        print("[WARN] Does not appear to be Fedora Atomic")

    result = run("ping -c 1 github.com", check=False, capture=True)
    if result.returncode != 0:
        print("[ERROR] No internet connection")
        sys.exit(1)

    print("OK")


@command("nerdfonts", sudo=True)
def nerdfonts():
    FONTS_DIR.mkdir(parents=True, exist_ok=True)
    url = f"https://github.com/ryanoasis/nerd-fonts/releases/download/{NERD_FONTS_VERSION}"

    for font in NERD_FONTS:
        print(f"  {font}")
        run(f"curl -fsSL -o /tmp/{font}.zip {url}/{font}.zip")
        (FONTS_DIR / font).mkdir(exist_ok=True)
        run(f"unzip -o -q /tmp/{font}.zip -d {FONTS_DIR}/{font}")
        Path(f"/tmp/{font}.zip").unlink()

    run("fc-cache -fv", capture=True)


@command("flatpaks")
def flatpaks():
    run("flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo", check=False)
    for app in FLATPAKS:
        print(f"  {app}")
        run(f"flatpak install -y flathub {app}", check=False)


@command("distrobox")
def distrobox():
    config = Path(__file__).parent / "distrobox.ini"
    if not config.exists():
        print(f"[ERROR] {config} not found")
        sys.exit(1)

    run(f"distrobox assemble create --file {config}")


@command("exports")
def exports():
    LOCAL_BIN.mkdir(parents=True, exist_ok=True)
    for binary in DISTROBOX_EXPORTS:
        result = run(
            f"distrobox enter arch -- distrobox-export --bin /usr/bin/{binary} --export-path {LOCAL_BIN}",
            check=False
        )
        status = "ok" if result.returncode == 0 else "failed"
        print(f"  {binary}: {status}")


@command("dotfiles")
def dotfiles():
    if not DOTFILES_REPO.exists():
        run(f"git init --bare {DOTFILES_REPO}")

    def dot(*args):
        return run(["git", f"--git-dir={DOTFILES_REPO}", f"--work-tree={HOME}"] + list(args), check=False)

    dot("config", "status.showUntrackedFiles", "no")

    CONFIG_DIR.mkdir(exist_ok=True)
    for name in DOTFILES:
        src, dest = ATOMIC_DOTS / name, CONFIG_DIR / name
        if src.exists() and not dest.exists():
            print(f"  {name}")
            run(f"cp -r {src} {dest}")
            dot("add", str(dest))

    dot("commit", "-m", "initial dotfiles")

    # Alias no fish
    fish_config = CONFIG_DIR / "fish/config.fish"
    if fish_config.exists() and "alias dot=" not in fish_config.read_text():
        with open(fish_config, "a") as f:
            f.write("\nalias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'\n")


@command("shell")
def shell():
    current = os.environ.get("SHELL", "")
    if "fish" not in current:
        run("chsh -s /usr/bin/fish", check=False)
        print("Shell changed to fish (requires new login)")


@command("directories")
def directories():
    for d in DIRECTORIES:
        d.mkdir(parents=True, exist_ok=True)
        print(f"  {d}")


@command("git")
def git():
    for key, value in GIT_CONFIG.items():
        run(f"git config --global {key} {value}")
        print(f"  {key}={value}")


@command("ssh")
def ssh():
    ssh_dir = HOME / ".ssh"
    key = ssh_dir / "id_ed25519"
    allowed_signers = ssh_dir / "allowed_signers"

    ssh_dir.mkdir(mode=0o700, exist_ok=True)

    if not key.exists():
        run(f'ssh-keygen -t ed25519 -f {key} -N ""')
        print(f"Key generated: {key}")
        print(f"Public: {key}.pub")
    else:
        print("SSH key already exists")

    # Create allowed_signers for commit verification
    if key.exists() and not allowed_signers.exists():
        pubkey = (ssh_dir / "id_ed25519.pub").read_text().strip()
        email = GIT_CONFIG["user.email"]
        allowed_signers.write_text(f"{email} {pubkey}\n")
        print(f"Created: {allowed_signers}")


@command("services")
def services():
    user_services = ["mpd.service"]
    for svc in user_services:
        run(f"systemctl --user enable --now {svc}", check=False)
        print(f"  {svc}")


@command("groups", sudo=True)
def groups():
    """Add user to virtualization groups"""
    import pwd
    username = pwd.getpwuid(os.getuid()).pw_name

    groups_to_add = ["libvirt", "kvm", "qemu"]
    for group in groups_to_add:
        result = run(f"usermod -aG {group} {username}", check=False)
        status = "ok" if result.returncode == 0 else "failed"
        print(f"  {group}: {status}")

    print("\nRequires logout/login to apply")


@command("templates")
def templates():
    """Copy dev templates to ~/.config/templates"""
    src = Path(__file__).parent / "templates"
    dest = CONFIG_DIR / "templates"

    if not src.exists():
        print(f"[WARN] {src} not found")
        return

    dest.mkdir(parents=True, exist_ok=True)
    for template in src.iterdir():
        if template.is_dir():
            target = dest / template.name
            if not target.exists():
                run(f"cp -r {template} {target}")
                print(f"  {template.name}")
            else:
                print(f"  {template.name} (already exists)")


@command("restore-secrets")
def restore_secrets():
    """Restore secrets from HDEX backup"""
    backup_path = Path("/home/HDEX/PC-2026.2/atomic-config/secrets")
    dest_path = Path(__file__).parent / "secrets"

    if dest_path.exists():
        print("  secrets already exists locally")
        return

    if not backup_path.exists():
        print(f"[ERROR] Backup not found: {backup_path}")
        print("  Make sure HDEX is mounted")
        sys.exit(1)

    run(f"cp {backup_path} {dest_path}")
    dest_path.chmod(0o600)
    print(f"  Restored from {backup_path}")


@command("claude")
def claude():
    """Install Claude Code CLI and restore credentials"""
    import shutil

    # Install if not present
    if not shutil.which("claude"):
        print("  Installing Claude Code...")
        run("curl -fsSL https://claude.ai/install.sh | sh", check=False)

    # Restore credentials from secrets
    secrets_file = Path(__file__).parent / "secrets"
    claude_dir = HOME / ".claude"
    creds_file = claude_dir / ".credentials.json"

    if creds_file.exists():
        print("  Credentials already exist")
        run("claude --version", check=False)
        return

    if not secrets_file.exists():
        print("  No secrets file - run 'claude' to authenticate manually")
        return

    # Parse credentials from secrets
    for line in secrets_file.read_text().splitlines():
        if line.startswith("CLAUDE_CREDENTIALS="):
            creds = line.split("=", 1)[1].strip().strip("'\"")
            if creds:
                claude_dir.mkdir(parents=True, exist_ok=True)
                creds_file.write_text(creds)
                creds_file.chmod(0o600)
                print("  Credentials restored")
                break
    else:
        print("  No credentials in secrets - run 'claude' to authenticate manually")


@command("kickstart")
def kickstart():
    """Generate ks.cfg from template + secrets"""
    template = Path(__file__).parent / "ks.cfg.template"
    secrets_file = Path(__file__).parent / "secrets"
    output = Path(__file__).parent / "ks.cfg"

    if not template.exists():
        print(f"[ERROR] {template} not found")
        sys.exit(1)

    if not secrets_file.exists():
        print(f"[ERROR] {secrets_file} not found")
        print("Create it from secrets.example:")
        print("  cp secrets.example secrets")
        print("  # Edit secrets and add your password hash")
        sys.exit(1)

    # Read secrets
    secrets = {}
    for line in secrets_file.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            secrets[key.strip()] = value.strip()

    if not secrets.get("PASSWORD_HASH"):
        print("[ERROR] PASSWORD_HASH not set in secrets file")
        sys.exit(1)

    # Generate ks.cfg
    content = template.read_text()
    content = content.replace("TROCAR_PELO_HASH", secrets["PASSWORD_HASH"])
    output.write_text(content)
    print(f"Generated: {output}")
    print("Upload to GitHub Gist or serve locally for installation")


@command("paru")
def paru():
    """Install paru and AUR packages (run inside arch container)"""
    import shutil

    # Check if running inside arch container
    if not Path("/etc/arch-release").exists():
        print("[ERROR] Not inside Arch container. Run:")
        print("  distrobox enter arch")
        print("  ./bootstrap.py paru")
        sys.exit(1)

    if shutil.which("paru"):
        print("paru already installed")
    else:
        print("  Installing paru...")
        run("git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin")
        run("bash -c 'cd /tmp/paru-bin && makepkg -si --noconfirm'")
        run("rm -rf /tmp/paru-bin")

    # AUR packages
    aur_packages = ["nomachine"]
    print("  Installing AUR packages...")
    for pkg in aur_packages:
        result = run(f"paru -S --noconfirm --needed {pkg}", check=False)
        status = "ok" if result.returncode == 0 else "failed"
        print(f"    {pkg}: {status}")


@command("msvc")
def msvc():
    """Install msvc-wine for Windows builds (run inside msvc container)"""
    import tempfile
    import shutil

    # Check if running inside msvc container
    if not shutil.which("wine"):
        print("[ERROR] Wine not found. Run inside msvc container:")
        print("  distrobox enter msvc")
        print("  ./bootstrap.py msvc")
        sys.exit(1)

    if MSVC_DIR.exists() and (MSVC_DIR / "bin").exists():
        print(f"[WARN] {MSVC_DIR} already exists. Remove before reinstalling.")
        return

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        print("  Clonando msvc-wine...")
        run(f"git clone --depth 1 {MSVC_WINE_REPO} {tmpdir}/msvc-wine")

        print("  Baixando MSVC e Windows SDK (~2-3GB)...")
        run(f"python3 {tmpdir}/msvc-wine/vsdownload.py --dest {MSVC_DIR}")

        print("  Installing wrappers...")
        run(f"bash {tmpdir}/msvc-wine/install.sh {MSVC_DIR}")

    # Inicializar wine
    print("  Inicializando Wine...")
    run("wineserver -k", check=False)
    run("wine64 wineboot --init", check=False)

    print(f"\nmsvc-wine instalado em {MSVC_DIR}")
    print("\nUsage:")
    print("  cmake -B build -DCMAKE_TOOLCHAIN_FILE=toolchain-linux-msvc-x86.cmake")
    print("  cmake --build build")


@command("all")
def all_commands():
    verify()
    restore_secrets()
    directories()
    dotfiles()
    templates()
    shell()
    git()
    ssh()
    distrobox()
    exports()
    flatpaks()
    services()
    claude()
    print("\n:: Done")
    print("Run separately:")
    print("  sudo ./bootstrap.py nerdfonts   # Install Nerd Fonts")
    print("  sudo ./bootstrap.py groups      # Add to libvirt/kvm groups")
    print("  distrobox enter arch && ./bootstrap.py paru  # Install paru + AUR packages")
    print("  distrobox enter msvc && ./bootstrap.py msvc  # Install MSVC")


@command("help")
def help_cmd():
    print("Usage: ./bootstrap.py <command>\n")
    print("Comandos:")
    for name, func in COMMANDS.items():
        sudo = " [sudo]" if func._sudo else ""
        print(f"  {name}{sudo}")


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    if len(sys.argv) < 2:
        help_cmd()
        sys.exit(0)

    cmd = sys.argv[1]
    if cmd not in COMMANDS:
        print(f"Comando desconhecido: {cmd}")
        sys.exit(1)

    COMMANDS[cmd]()
