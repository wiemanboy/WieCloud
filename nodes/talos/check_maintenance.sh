#!/bin/bash
NODE="$1"

if talosctl get disks --insecure --nodes "$NODE" >/dev/null 2>&1; then
    echo '{"maintenance":"true"}'
else
    echo '{"maintenance":"false"}'
fi
