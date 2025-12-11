#!/bin/bash
NODE="$1"

#!/bin/bash
NODE="$1"

OUTPUT=$(talosctl get disks --insecure --nodes "$NODE" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo '{"status":"maintenance"}'
    exit 0 
fi

# Command failed, check error messages
if echo "$OUTPUT" | grep -q "tls: certificate required"; then
    echo '{"status":"running"}'
    exit 0
fi

echo '{"status":"unknown"}'
