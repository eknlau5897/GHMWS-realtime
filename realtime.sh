#!/bin/bash
set -e

BRANCH="main"
githubUser="eknlau5897"
githubRepo="GHMWS-realtime"

echo "=================================================================="
echo "   REAL-TIME METEOROLOGICAL ENGINE (SOFT RESET FLOW - NO ORPHAN) "
echo "=================================================================="

while true; do
    echo "--- 任務開始: $(date) ---"

    # ==============================================================================
    # 1. RUN CORE METEOROLOGICAL DATA PROCESSORS
    # ==============================================================================
    echo "📈 Running core weather processing matrix..."
    python3.11 hk-temperature.py || echo "⚠️ hk-temperature.py encountered an issue"
    python3.11 hk-wind.py || echo "⚠️ hk-wind.py encountered an issue"
    
    # ==============================================================================
    # 2. PLUMBING & CONNECTION SAFEGUARDS
    # ==============================================================================
    # If the .git directory is ever completely missing, re-initialize it cleanly
    if [ ! -d ".git" ]; then
        echo "[Repo Guard] Initializing Git plumbing layer..."
        git init
        git checkout -b "$BRANCH"
    fi

    # Explicitly enforce the remote target link so it can never be lost
    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/${githubUser}/${githubRepo}.git"

    # ==============================================================================
    # 3. HISTORY COLLAPSE PIPELINE (SOFT-RESET METHOD)
    # ==============================================================================
    echo "⚠️ Collapsing execution tracking layers down to 1 single commit..."
    
    # Create an initial commit if this repository is completely empty
    if ! git rev-parse --git-dir > /dev/null 2>&1 || [ -z "$(git log -1 --pretty=format:"%h" 2>/dev/null)" ]; then
        git add realtime.sh
        git commit -m "Initial setup placeholder" --allow-empty
    fi

    # Wipe out all previous commit history tracking from the local timeline, leaving files intact
    git update-ref -d refs/heads/"$BRANCH"

    # Stage the exact files matching your repository layout tree
    echo "📦 Packaging current layout structure..."
    git add realtime.sh 
    git add hk-temperature.py
    git add hk-wind.py
    git add synoptic/real-time-temp.png
    git add synoptic/real-time-precip.png
    git add synoptic/real-time.png

    if [ -f "./index.html" ]; then git add index.html; fi
    if [ -f "./GHMWS.png" ]; then git add GHMWS.png; fi
    if [ -f "./abc" ]; then git add abc; fi
    
    if [ -d "./HK" ]; then git add ./HK/*; fi
    if [ -d "./.vscode" ]; then git add ./.vscode/*; fi

    # Seal everything into a single, clean baseline commit
    git commit -m "Auto update: Weather data baseline $(date) [History Cleared]"

    # ==============================================================================
    # 4. FORCE REMOTE PUBLISHING
    # ==============================================================================
    echo "🚀 Force-pushing zero-overhead stream to GitHub..."
    git push --set-upstream origin "$BRANCH" --force

    echo "💤 Execution frame completed successfully. Sleeping for 30 minutes..."
    sleep 600
done