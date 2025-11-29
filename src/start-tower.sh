#!/bin/bash
# ----------------------------------------
# start_tower_agent.sh
# Automatically read Nextflow workDir from .config
# and start the Seqera Tower Agent safely
# ----------------------------------------

# === Source settings ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
source "$CONFIG_DIR/tower_settings.sh"

# Create the work directory if missing
if [ -z "$WORK_DIR" ]; then
    echo "[ERROR] WORK_DIR is not set in the configuration."
    exit 1
fi
mkdir -p "$WORK_DIR"

# Optional: create a log directory nearby
LOG_DIR="$SCRIPT_DIR/sbatch_logs"
mkdir -p "$LOG_DIR"

# === Download agent if missing ===
if [ ! -x "$AGENT_BIN" ]; then
    echo "[INFO] Downloading Tower Agent binary..."
    mkdir -p "$(dirname "$AGENT_BIN")"
    curl -fsSL https://github.com/seqeralabs/tower-agent/releases/latest/download/tw-agent-linux-x86_64 -o "$AGENT_BIN"
    chmod +x "$AGENT_BIN"
fi

# === Start agent in the foreground ===
echo "[INFO] Launching Tower Agent..."
export TOWER_AGENT_LOG_FILE="$LOG_DIR/tower_agent.log"
TOWER_ACCESS_TOKEN=$TOWER_ACCESS_TOKEN $AGENT_BIN --work-dir "$WORK_DIR" "$CONNECTION_ID" &
AGENT_PID=$!
echo "[INFO] Tower Agent started with PID $AGENT_PID"
echo "[INFO] Agent log: $TOWER_AGENT_LOG_FILE"

# === Graceful shutdown on signal ===
# When the batch system sends a termination signal (like SIGTERM), this trap will catch it,
# kill the agent process, and wait for it to clean up before the script exits.
trap 'echo "Caught signal, terminating agent..."; kill $AGENT_PID; wait $AGENT_PID' SIGINT SIGTERM

# === Wait for agent to exit ===
# This `wait` command is crucial. It pauses the script here, keeping the job alive,
# until the AGENT_PID process (the tower agent) finishes.
wait $AGENT_PID
echo "[INFO] Tower Agent has stopped."
