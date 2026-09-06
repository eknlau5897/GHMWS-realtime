#!/bin/bash

PYTHON_EXEC="/opt/anaconda3/bin/python3.11"
SCRIPT_PATH="/Users/eknlau/Desktop/personal/realtime-GD.py"

echo "2-hour UTC runner started..."

while true; do
    # -u forces UTC (Z-time)
    HOUR=$(date -u +%-H)
    MIN=$(date -u +%-M)
    SEC=$(date -u +%-S)

    # Calculate hours to wait for the next even UTC hour (0, 2, 4, 6...)
    HOURS_TO_WAIT=$(( 1 - (HOUR % 2) ))
    SECONDS_TO_WAIT=$(( HOURS_TO_WAIT * 3600 + (59 - MIN) * 60 + (60 - SEC) ))

    # Calculate next execution time in UTC
    if date -u -v+1S >/dev/null 2>&1; then
        # macOS / BSD
        NEXT_RUN=$(date -u -v+"${SECONDS_TO_WAIT}"S '+%Y-%m-%d %H:%M:%SZ')
    else
        # Linux / GNU
        NEXT_RUN=$(date -u -d "+${SECONDS_TO_WAIT} seconds" '+%Y-%m-%d %H:%M:%SZ')
    fi

    echo "[$(date -u '+%Y-%m-%d %H:%M:%SZ')] Sleeping for $SECONDS_TO_WAIT seconds (next run at $NEXT_RUN)..."
    sleep "$SECONDS_TO_WAIT"

    echo "[$(date -u '+%Y-%m-%d %H:%M:%SZ')] Executing Python script..."
    "$PYTHON_EXEC" "$SCRIPT_PATH"
    git add synoptic/real-time-temp.png
    git add synoptic/real-time-precip.png
    git add synoptic/real-time.png
    git commit -m "Update synoptic data at $(date -u '+%Y-%d %H:%M:%SZ')"
    git push origin main
done