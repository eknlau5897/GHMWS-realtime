#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
PYTHON_EXEC="/opt/anaconda3/bin/python3.11"
SCRIPT_PATH="/Users/eknlau/Desktop/personal/realtime-GD.py"

echo "🚀 2-hour UTC runner started..."

# ==============================================================================
# CONTINUOUS DAEMON LOOP
# ==============================================================================
while true; do
    # Fetch current UTC time components
    HOUR=$(date -u +%-H)
    MIN=$(date -u +%-M)
    SEC=$(date -u +%-S)

    # Calculate hours and seconds to wait for the next even UTC hour (0, 2, 4, 6...)
    HOURS_TO_WAIT=$(( 1 - (HOUR % 2) ))
    SECONDS_TO_WAIT=$(( HOURS_TO_WAIT * 3600 + (59 - MIN) * 60 + (60 - SEC) ))

    # Calculate and display next execution time in UTC
    if date -u -v+1S >/dev/null 2>&1; then
        # macOS / BSD
        NEXT_RUN=$(date -u -v+"${SECONDS_TO_WAIT}"S '+%Y-%m-%d %H:%M:%SZ')
    else
        # Linux / GNU
        NEXT_RUN=$(date -u -d "+${SECONDS_TO_WAIT} seconds" '+%Y-%m-%d %H:%M:%SZ')
    fi

    echo "⏳ Next execution scheduled for: $NEXT_RUN (sleeping for ${SECONDS_TO_WAIT}s)"
    
    # Wait until the target time
    sleep "$SECONDS_TO_WAIT"

    # ==========================================================================
    # EXECUTION PIPELINE
    # ==========================================================================
    echo "[$(date -u '+%Y-%m-%d %H:%M:%SZ')] Executing Python script..."
    
    if "$PYTHON_EXEC" "$SCRIPT_PATH"; then
        echo "✅ Python script completed. Staging and committing images to Git..."
        
        git add /Users/eknlau/VS_code/GHMWS-realtime/synoptic/real-time-temp.png
        git add /Users/eknlau/VS_code/GHMWS-realtime/synoptic/real-time-precip.png
        git add /Users/eknlau/VS_code/GHMWS-realtime/synoptic/real-time.png
        git commit -m "Update synoptic data at $(date -u '+%Y-%m-%d %H:%M:%SZ')" || echo "No changes to commit."
        git push origin main
    else
        echo "❌ Python script failed with exit code $?. Skipping Git commit."
    fi

    # Small 10-second safety buffer to ensure we've crossed into the next second block
    sleep 10
done