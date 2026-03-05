# Fedora Atomic - BlueBuild Config

Configuração de imagem Fedora Atomic com Hyprland + NVIDIA.

## Estrutura

```
atomic-config/
├── recipe.yml          # BlueBuild - pacotes do sistema
├── ks.cfg              # Kickstart - instalação automatizada
├── bootstrap.py        # Post-install - setup do usuário
├── distrobox.ini       # Container Arch para dev
├── scripts/
│   ├── copr-repos.sh   # COPRs (build time)
│   └── setup-system.sh # Sistema (build time)
└── system/etc/
    ├── greetd/config.toml
    ├── environment.d/wayland.conf
    └── sysctl.d/99-custom.conf
```

## Build time vs Runtime

| Fase | Arquivos | Quando roda |
|------|----------|-------------|
| Build | recipe.yml, scripts/, system/ | CI (GitHub Actions) |
| Runtime | bootstrap.py, distrobox.ini | Usuário pós-install |

## Instalação

### 1. Build da imagem

```bash
# Fork https://github.com/blue-build/template
# Copia arquivos para o fork
# Push - GitHub Actions builda
```

### 2. Instala Fedora + Rebase

```bash
# Instala Fedora Silverblue/Kinoite
rpm-ostree rebase ostree-unverified-registry:ghcr.io/r0naldoom/r0naldoom:latest
reboot
```

### 3. Bootstrap

```bash
cd ~/atomic-config
chmod +x bootstrap.py

./bootstrap.py all
sudo ./bootstrap.py nerdfonts
```

## Bootstrap

```
./bootstrap.py <comando>

verify        Verifica sistema
nerdfonts     Nerd Fonts [sudo]
flatpaks      Vesktop
distrobox     Container Arch
exports       Exporta binários
dotfiles      Git bare setup
shell         Fish como padrão
directories   Cria diretórios
git           Configura git
ssh           Gera chave SSH
services      Habilita mpd
all           Tudo (exceto nerdfonts)
```

## Dotfiles

Gerenciados via Git Bare:

```bash
dot status
dot add ~/.config/nvim
dot commit -m "update"
dot push
```

## Componentes

| Camada | Stack |
|--------|-------|
| Base | ublue-os/silverblue-nvidia |
| WM | Hyprland + hypridle + hyprlock |
| Bar | noctalia-shell |
| Terminal | Ghostty + tmux |
| Shell | Fish + starship + zoxide |
| Editor | Neovim (Distrobox) |
| Dev | Distrobox Arch |

## COPRs

- solopasha/hyprland
- zhangyi6324/noctalia-shell
- scottames/ghostty
- sneexy/zen-browser
- sentry/swww
- varlad/yazi
