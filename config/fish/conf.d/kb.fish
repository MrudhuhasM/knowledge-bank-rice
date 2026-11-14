# Knowledge Bank: shell setup (fish)
if status is-interactive
    set -g fish_greeting
    command -q starship; and starship init fish | source
    alias notes kv
    alias today kb-daily
end
fish_add_path -g ~/.local/bin
