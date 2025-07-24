#!/bin/bash

CACHE_FILE="/tmp/.gpu_type_cache"

# --- Cache GPU type ---
if [ -f "$CACHE_FILE" ]; then
    read -r GPU_TYPE < "$CACHE_FILE"
else
    if [ -e /sys/class/drm/card0/device/gpu_busy_percent ]; then
        GPU_TYPE="GENERIC"
    elif command -v nvidia-smi >/dev/null 2>&1; then
        GPU_TYPE="NVIDIA"
    else
        GPU_TYPE="NONE"
    fi
    echo "$GPU_TYPE" > "$CACHE_FILE"
fi

GPU_PERC=0

case "$GPU_TYPE" in
    GENERIC)
        # Read all values in one shot
        total=0
        count=0
        for f in /sys/class/drm/card*/device/gpu_busy_percent; do
            [ -r "$f" ] || continue
            val=$(<"$f")
            total=$((total + val))
            count=$((count + 1))
        done
        if [ "$count" -gt 0 ]; then
            GPU_PERC=$((total / count))
        fi
        ;;
    NVIDIA)
        # Run nvidia-smi minimally and extract first value only
        if output=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null); then
            GPU_PERC=${output%%,*}
            GPU_PERC=${GPU_PERC//[!0-9]/}  # Strip non-numeric if any
        fi
        ;;
    *)
        GPU_PERC=0
        ;;
esac

echo "${GPU_PERC}%"