# Paper & ink shell setup (fish), readable on a light terminal
fish_add_path -g ~/.local/bin

# Paper & ink syntax colours (global vars override any dark-theme universals)
set -g fish_color_normal 575279
set -g fish_color_command 286983
set -g fish_color_keyword b4637a
set -g fish_color_quote b0700f
set -g fish_color_redirection 56949f
set -g fish_color_end 907aa9
set -g fish_color_error b4637a
set -g fish_color_param 575279
set -g fish_color_option 907aa9
set -g fish_color_comment 7f7a93
set -g fish_color_operator bb625e
set -g fish_color_escape bb625e
set -g fish_color_autosuggestion 7f7a93
set -g fish_color_valid_path --underline
set -g fish_color_selection --background=dfdad9
set -g fish_color_search_match --background=f2e9e1
set -g fish_color_cancel b4637a
set -g fish_pager_color_progress 797593
set -g fish_pager_color_prefix bb625e --bold
set -g fish_pager_color_completion 575279
set -g fish_pager_color_description 797593
set -g fish_pager_color_selected_background --background=f2e9e1

# Light-friendly colours for common tools
set -gx BAT_THEME "OneHalfLight"
set -gx FZF_DEFAULT_OPTS "--color=fg:#575279,bg:-1,hl:#bb625e,fg+:#575279,bg+:#f2e9e1,hl+:#b4637a,info:#9893a5,prompt:#bb625e,pointer:#b4637a,marker:#b0700f,spinner:#907aa9,header:#286983,border:#dfdad9,gutter:-1"

if status is-interactive
    set -g fish_greeting
    command -q starship; and starship init fish | source
    alias rl rl-status
end
