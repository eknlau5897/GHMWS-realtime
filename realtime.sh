#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
PROJECT_DIR="/Users/eknlau/VS_code/GHMWS-realtime"
INTERVAL_SECONDS=600  # 10 minutes

BRANCH="main"
githubUser="eknlau5897"
githubRepo="GHMWS-realtime"

# Environment paths setup
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
export PATH

# Workspace directory enforcement
cd "$PROJECT_DIR" || { echo "❌ Failed to navigate to $PROJECT_DIR"; exit 1; }

# ==============================================================================
# PIPELINE EXECUTION FUNCTION
# ==============================================================================
run_pipeline() {
    echo "=================================================================="
    echo "   REAL-TIME METEOROLOGICAL ENGINE (SOFT RESET FLOW - NO ORPHAN) "
    echo "=================================================================="
    echo "--- 任務開始: $(date) ---"

    # 1. RUN CORE METEOROLOGICAL DATA PROCESSORS
    echo "📈 Running core weather processing matrix..."
    /opt/anaconda3/bin/python hk-temperature.py || echo "⚠️ hk-temperature.py encountered an issue"
    /opt/anaconda3/bin/python hk-wind.py || echo "⚠️ hk-wind.py encountered an issue"

    # 2. PLUMBING & CONNECTION SAFEGUARDS
    if [ ! -d ".git" ]; then
        echo "[Repo Guard] Initializing Git plumbing layer..."
        git init
        git checkout -b "$BRANCH"
    fi

    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/${githubUser}/${githubRepo}.git"

    # 3. HISTORY COLLAPSE PIPELINE (SOFT-RESET METHOD)
    echo "⚠️ Collapsing execution tracking layers down to 1 single commit..."

    if ! git rev-parse --git-dir > /dev/null 2>&1 || [ -z "$(git log -1 --pretty=format:"%h" 2>/dev/null)" ]; then
        git add "${PROJECT_DIR}/realtime.sh" 2>/dev/null || true
        git commit -m "Initial setup placeholder" --allow-empty
    fi

    git update-ref -d refs/heads/"$BRANCH"

    # Stage structure
    echo "📦 Packaging current layout structure..."
    git add -A
    if [ -f "${PROJECT_DIR}/index.html" ]; then git add "${PROJECT_DIR}/index.html"; fi
    if [ -f "${PROJECT_DIR}/GHMWS.png" ]; then git add "${PROJECT_DIR}/GHMWS.png"; fi
    if [ -f "${PROJECT_DIR}/abc" ]; then git add "${PROJECT_DIR}/abc"; fi

    if [ -d "${PROJECT_DIR}/HK" ]; then git add "${PROJECT_DIR}/HK/"*; fi
    if [ -d "${PROJECT_DIR}/.vscode" ]; then git add "${PROJECT_DIR}/.vscode/"*; fi

    git commit -m "Auto update: Weather data baseline $(date) [History Cleared]"

    # 4. FORCE REMOTE PUBLISHING
    echo "🚀 Force-pushing zero-overhead stream to GitHub..."
    if git push --set-upstream origin "$BRANCH" --force; then
        echo "✅ Pipeline update succeeded at $(date)"
    else
        echo "❌ Push failure encountered at $(date)"
    fi
}

export -f run_pipeline
export PROJECT_DIR INTERVAL_SECONDS BRANCH githubUser githubRepo

echo "=================================================================="
echo "   STARTING DAEMON MODE (LOOP EVERY 10 MINS WITH CAFFEINE)       "
echo "=================================================================="

# Keep macOS awake during all execution and sleep cycles
caffeinate -s bash -c '
while true; do
    run_pipeline
    echo "Sleeping for 10 minutes (600 seconds)..."
    sleep 600
done
'