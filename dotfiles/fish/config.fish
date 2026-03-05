# Auto-tmux
if not set -q TMUX; and not set -q NOTMUX
    set -l session_name "term-"(date +%s)
    exec tmux new-session -s $session_name
end

# Vi mode
fish_vi_key_bindings

# XDG
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx LESSHISTFILE /tmp/less-hist

# PATH
fish_add_path -p ~/.local/bin
fish_add_path -p ~/scripts
if test -d ~/.local/share/fnm
    fish_add_path -p ~/.local/share/fnm
end

# Environment
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx LIBVIRT_DEFAULT_URI "qemu:///system"
set -gx DOCKER_HOST "unix://$XDG_RUNTIME_DIR/podman/podman.sock"

# Code directories
set -gx CODE_DIR $HOME/c

# Go
set -gx GOPATH $HOME/go
set -gx GOBIN $GOPATH/bin
fish_add_path -p $GOBIN

# Rust
set -gx CARGO_HOME $HOME/.cargo
fish_add_path -p $CARGO_HOME/bin

# Python / UV
set -gx PYTHONDONTWRITEBYTECODE 1
set -gx PYTHONIOENCODING utf-8
set -gx UV_PYTHON_PREFERENCE system

# FZF
set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always {} || cat {}'"
fzf --fish | source

# Starship
set -gx STARSHIP_CONFIG $XDG_CONFIG_HOME/starship/starship.toml
set -gx STARSHIP_CACHE $XDG_CACHE_HOME/starship
starship init fish | source

# Zoxide
zoxide init fish | source

# Aliases - Tools
alias v nvim
alias cc claude
alias yy yazi

# Aliases - eza
alias l 'eza -lh --icons=auto'
alias ls 'eza -1 --icons=auto'
alias ll 'eza -lha --icons=auto --sort=name --group-directories-first'
alias ld 'eza -lhD --icons=auto'
alias lt 'eza --icons=auto --tree'

# Aliases - Common
alias mkdir 'mkdir -p'
alias cat bat

# Abbreviations - expand visually before running
abbr -a g git
abbr -a gs 'git status -sb'
abbr -a gl 'git log --oneline --graph -20'

# Code navigation
abbr -a cw 'cd $CODE_DIR/work'
abbr -a cp 'cd $CODE_DIR/projects'
abbr -a cs 'cd $CODE_DIR/study'

# New project: new <template> <name>
# Ex: new python meu-app
function new
    set -l template $argv[1]
    set -l name $argv[2]
    set -l templates_dir ~/.config/templates

    if test -z "$template" -o -z "$name"
        echo "Uso: new <template> <nome>"
        echo "Templates: python, go, rust, node, c, clang, dotnet"
        return 1
    end

    if not test -d "$templates_dir/$template"
        echo "Template '$template' não encontrado em $templates_dir"
        return 1
    end

    mkdir -p $name
    cp -r $templates_dir/$template/* $name/
    cd $name
    direnv allow 2>/dev/null || true
    echo "Projeto '$name' criado com template '$template'"
end
