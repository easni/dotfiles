#!/bin/sh

case "$1" in
    cpu)
        for hwmon in /sys/class/hwmon/hwmon*; do
            [ "$(cat "$hwmon/name" 2>/dev/null)" = "coretemp" ] || continue

            for label in "$hwmon"/temp*_label; do
                [ "$(cat "$label" 2>/dev/null)" = "Package id 0" ] || continue
                input=${label%_label}_input
                temperature=$(cat "$input" 2>/dev/null) || continue
                printf 'cpu: %d°C\n' "$((temperature / 1000))"
                exit 0
            done
        done

        printf 'cpu: N/A\n'
        ;;
    gpu)
        temperature=$(nvidia-smi --query-gpu=temperature.gpu \
            --format=csv,noheader,nounits 2>/dev/null | head -n 1)

        case "$temperature" in
            ''|*[!0-9]*) printf 'gpu: N/A\n' ;;
            *) printf 'gpu: %s°C\n' "$temperature" ;;
        esac
        ;;
esac
