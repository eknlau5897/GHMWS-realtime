#!/bin/bash

# ==============================================================================
# CONFIGURATION & PATH SETUP
# ==============================================================================
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INTERVAL_SECONDS=600   # 10-minute sleep between runs
MAX_RUN_TIME=19800     # 5.5 hours (19,800 seconds) before loop renewal
BRANCH="main"
githubUser="eknlau5897"
githubRepo="GHMWS-realtime"

# Detect Mac Anaconda Python or system Python
if [ -x "/opt/anaconda3/bin/python" ]; then
    PYTHON_CMD="/opt/anaconda3/bin/python"
elif command -v python3 &>/dev/null; then
    PYTHON_CMD="$(command -v python3)"
else
    PYTHON_CMD="$(command -v python)"
fi

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
export PATH

cd "$PROJECT_DIR" || { echo "❌ Failed to navigate to $PROJECT_DIR"; exit 1; }

# ==============================================================================
# PIPELINE EXECUTION FUNCTION (SINGLE CYCLE)
# ==============================================================================
run_pipeline() {
    echo "=================================================================="
    echo "   REAL-TIME METEOROLOGICAL ENGINE (MAC HISTORY COLLAPSE)         "
    echo "=================================================================="
    echo "--- 任務開始: $(date) ---"

    # 1. RUN CORE PROCESSORS
    echo "📈 Running weather processing matrix..."
    "$PYTHON_CMD" hk-temperature.py || echo "⚠️ hk-temperature.py encountered an issue"
    "$PYTHON_CMD" hk-wind.py || echo "⚠️ hk-wind.py encountered an issue"

    # 2. REPO CONNECTIONS
    if [ ! -d ".git" ]; then
        echo "[Repo Guard] Initializing Git..."
        git init
        git checkout -b "$BRANCH"
    fi

    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/${githubUser}/${githubRepo}.git"

    # 3. HISTORY COLLAPSE (WIPE COMMITS DOWN TO 1)
    echo "⚠️ Collapsing execution tracking layers down to 1 single commit..."
    git update-ref -d refs/heads/"$BRANCH"
    git add -A
    git commit -m "Auto update: Weather data baseline $(date) [History Cleared]"

    # 4. FORCE REMOTE PUBLISHING
    echo "🚀 Force-pushing zero-overhead stream to GitHub..."
    if git push origin "$BRANCH" --force; then
        echo "✅ Pipeline update succeeded at $(date)"
    else
        echo "❌ Push failure encountered at $(date)"
    fi
}

# ==============================================================================
# 5.5-HOUR SELF-RENEWING LOOP
# ==============================================================================
loop_execution() {
    # Calculate target end time for this 5.5-hour block
    START_TIME=$(date +%s)
    END_TIME=$((START_TIME + MAX_RUN_TIME))

    echo "⚡ Starting 5.5-hour execution cycle. Will renew around $(date -r $END_TIME)."

    while [ $(date +%s) -lt $END_TIME ]; do
        run_pipeline
        echo "Sleeping for 10 minutes ($INTERVAL_SECONDS seconds)..."
        sleep "$INTERVAL_SECONDS"
    done

    echo "⌛ 5.5 hours elapsed. Renewing cycle loop..."
    # Self-renew by restarting the script in place
    exec "$0" "$@"
}

# Prevent Mac CPU/system sleep while executing
caffeinate -s bash -c "$(declare -f run_pipeline loop_execution); loop_execution"