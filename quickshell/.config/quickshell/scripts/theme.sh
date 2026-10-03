#!/usr/bin/env bash

set -euo pipefail

THEME="${1:-}"
CONFIG_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
USER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

if [[ -z "$THEME" ]]; then
    echo "Usage: theme-switch.sh <theme>"
    exit 1
fi

[[ "$THEME" =~ ^[a-z0-9]+$ ]] || { echo "Invalid theme name" >&2; exit 1; }
THEMES_DIR="$CONFIG_DIR/styles/themes"
THEME_DIR="$THEMES_DIR/$THEME"

if [[ ! -d "$THEME_DIR" ]]; then
    echo "Theme '$THEME' not found."
    exit 1
fi

link_if_exists() {
    local source="$1"
    local target="$2"

    if [[ -f "$source" ]]; then
        mkdir -p "$(dirname "$target")"
        ln -sf "$source" "$target"
        echo "✓ $(basename "$target")"
    else
        echo "✗ Missing: $source"
    fi
}

# -------------------------
# Wallpapers
# -------------------------

case "$THEME" in
    monochrome)
        WP="art11.png"
        ;;

    githublight)
        WP="Totoro.png"
        ;;

    gruvbox)
        WP="gruvbox_astro.jpg"
        ;;

    gruvboxlight)
        WP="anime-girl3.jpg"
        ;;

    dracula)
        WP="art13.jpeg"
        ;;

    everforest)
        WP="foggy_valley_2.png"
        ;;

    catppuccin)
        WP="arch-black-4k.png"
        ;;

    catppuccinlatte)
        WP="7.jpg"
        ;;

    nord)
        WP="chainsaw-man.png"
        ;;

    rosepine)
        WP="dark-fantasy.jpg"
        ;;

    solarized)
        WP="sleeping.jpg"
        ;;

    tokyonight)
        WP="aesthetic-anime2.jpg"
        ;;

    *)
        WP="default.jpg"
        ;;
esac

# -------------------------
# Wallpaper
# -------------------------

# External changes are opt-in. Restoring the shell theme never invokes this script.
if [[ "${LUCI_SYNC_WALLPAPER:-0}" == 1 && -f "$HOME/Pictures/wallpapers/$WP" ]]; then
    awww img "$HOME/Pictures/wallpapers/$WP" --transition-type grow || echo "Could not apply wallpaper" >&2
fi

# Generate a palette include, never replace the user's kitty.conf.
if [[ "${LUCI_SYNC_KITTY:-0}" == 1 && -f "$THEME_DIR/kitty.conf" ]]; then
    mkdir -p "$USER_CONFIG_DIR/kitty"
    awk '$1 ~ /^(background|foreground|selection_background|selection_foreground|cursor|cursor_text_color|active_tab_background|active_tab_foreground|inactive_tab_background|inactive_tab_foreground|color[0-9]+)$/ { print }' \
        "$THEME_DIR/kitty.conf" > "$USER_CONFIG_DIR/kitty/luci-colors.conf"
fi

if [[ "${LUCI_SYNC_HYPRLAND:-0}" == 1 ]]; then
    link_if_exists "$THEME_DIR/HyprTheme.lua" "$USER_CONFIG_DIR/hypr/current-theme/theme.lua"
fi

printf '%s\n' "$THEME" > "$CONFIG_DIR/.current_theme.tmp"
mv -- "$CONFIG_DIR/.current_theme.tmp" "$CONFIG_DIR/.current_theme"
