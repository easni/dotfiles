#!/usr/bin/env bash

set -u

ACTION="${1:-}"
HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
GENERATED_CONFIG="${XDG_RUNTIME_DIR:-/tmp}/luci-hyprlock.conf"

active_hyprlock_path() {
    [[ -f "$HYPRLOCK_CONFIG" ]] || return 1

    awk -F '=' '
        /^[[:space:]]*path[[:space:]]*=/ {
            value = $2
            sub(/^[[:space:]]*/, "", value)
            sub(/[[:space:]]*$/, "", value)
            if (value != "" && value != "screenshot") {
                print value
                exit
            }
        }
    ' "$HYPRLOCK_CONFIG"
}

awww_query_wallpaper_path() {
    command -v awww >/dev/null 2>&1 || return 1

    awww query 2>/dev/null | awk '
        match($0, /currently displaying: image: /) {
            value = substr($0, RSTART + RLENGTH)
            sub(/[[:space:]]*$/, "", value)
            if (value != "") {
                print value
                exit
            }
        }
    '
}

build_hyprlock_config() {
    local wallpaper_path="$1"

    [[ -f "$HYPRLOCK_CONFIG" ]] || return 1
    [[ -n "$wallpaper_path" && -f "$wallpaper_path" ]] || return 1

    awk -v wallpaper_path="$wallpaper_path" '
        /^[[:space:]]*background[[:space:]]*\{/ {
            in_background = 1
            inserted = 0
            print
            next
        }

        in_background && /^[[:space:]]*\}/ {
            if (!inserted) {
                print "    path = " wallpaper_path
            }
            in_background = 0
            print
            next
        }

        in_background && /^[[:space:]]*#?[[:space:]]*path[[:space:]]*=/ {
            if (!inserted) {
                print "    path = " wallpaper_path
                inserted = 1
            }
            next
        }

        {
            print
        }
    ' "$HYPRLOCK_CONFIG" > "$GENERATED_CONFIG"
}

hyprlock_args() {
    local configured_path wallpaper_path

    configured_path="$(active_hyprlock_path || true)"

    if [[ -n "$configured_path" && -f "$configured_path" ]]; then
        printf '%s\n' "--config"
        printf '%s\n' "$HYPRLOCK_CONFIG"
        return 0
    fi

    wallpaper_path="$(awww_query_wallpaper_path || true)"

    if build_hyprlock_config "$wallpaper_path"; then
        printf '%s\n' "--config"
        printf '%s\n' "$GENERATED_CONFIG"
        return 0
    fi

    if [[ -f "$HYPRLOCK_CONFIG" ]]; then
        printf '%s\n' "--config"
        printf '%s\n' "$HYPRLOCK_CONFIG"
    fi
}

lock() {
    local background="${1:-false}"

    if pidof hyprlock >/dev/null 2>&1; then
        return 0
    fi

    if command -v hyprlock >/dev/null 2>&1; then
        mapfile -t args < <(hyprlock_args)

        if [[ "$background" == "true" ]]; then
            hyprlock "${args[@]}" &
        else
            hyprlock "${args[@]}"
        fi

        return 0
    fi

    loginctl lock-session
}

case "$ACTION" in
    lock)
        lock
        ;;

    suspend)
        lock true
        sleep 1
        systemctl suspend
        ;;

    *)
        echo "Usage: $0 {lock|suspend}" >&2
        exit 2
        ;;
esac
