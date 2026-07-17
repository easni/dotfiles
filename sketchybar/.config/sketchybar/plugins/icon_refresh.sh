#!/bin/bash
PLUGIN_DIR="$CONFIG_DIR/plugins"
BAR_WORKSPACES="1 2 3 4 5 6"
CACHE_DIR="${TMPDIR:-/tmp}/sketchybar-space-icons"

mkdir -p "$CACHE_DIR"

is_bar_workspace() {
    case " $BAR_WORKSPACES " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
    esac
}

refresh_workspace() {
    sid="$1"
    is_bar_workspace "$sid" || return 0

    apps=$(printf '%s\n' "$WINDOWS" | awk -F'|' -v workspace="$sid" '$1 == workspace {gsub(/^ *| *$/, "", $2); print $2}')

    icon_strip=" "
    if [ "${apps}" != "" ]; then
        while read -r app; do
            icon_strip+=" $($PLUGIN_DIR/icon_map_fn.sh "$app")"
        done <<<"${apps}"
    else
        icon_strip=""
    fi

    cache_file="$CACHE_DIR/space.$sid.label"
    previous_icon_strip="$(cat "$cache_file" 2>/dev/null)"

    if [ ! -f "$cache_file" ] || [ "$icon_strip" != "$previous_icon_strip" ]; then
        sketchybar --set "space.$sid" drawing=on label="$icon_strip"
        printf '%s' "$icon_strip" >"$cache_file"
    fi
}

refresh_all_workspaces() {
    for sid in $BAR_WORKSPACES; do
        refresh_workspace "$sid"
    done
}

if ! WINDOWS="$(aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)"; then
    exit 0
fi

refresh_all_workspaces
