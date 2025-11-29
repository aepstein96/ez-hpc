#!/bin/bash
# ----------------------------------------
# start_tower_agent.sh
# Starts the Seqera Tower Agent using environment variables provided by submit-job
# ----------------------------------------

# === Validate Environment Variables ===
if [ -z "$TOWER_ACCESS_TOKEN" ] || [ -z "$TOWER_CONNECTION_ID" ] || [ -z "$TOWER_WORK_DIR" ] || [ -z "$TOWER_AGENT_BIN" ]; then
    echo "[ERROR] Missing required Tower configuration."
    echo "Please ensure TOWER_ACCESS_TOKEN, TOWER_CONNECTION_ID, TOWER_WORK_DIR, and TOWER_AGENT_BIN are set in your config."
    exit 1
fi

# Create the work directory if missing
mkdir -p "$TOWER_WORK_DIR"

# Optional: create a log directory nearby (or use current directory's logs)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../sbatch_logs" # Use standard log dir
mkdir -p "$LOG_DIR"

# === Download agent if missing ===
if [ ! -x "$TOWER_AGENT_BIN" ]; then
    echo "[INFO] Downloading Tower Agent binary to $TOWER_AGENT_BIN..."
    mkdir -p "$(dirname "$TOWER_AGENT_BIN")"
    curl -fsSL https://github.com/seqeralabs/tower-agent/releases/latest/download/tw-agent-linux-x86_64 -o "$TOWER_AGENT_BIN"
    chmod +x "$TOWER_AGENT_BIN"
fi

# === Start agent in the foreground ===
echo "[INFO] Launching Tower Agent..."
export TOWER_AGENT_LOG_FILE="$LOG_DIR/tower_agent.log"

# Note: We export TOWER_ACCESS_TOKEN already in submit-job, so it's available to the binary
$TOWER_AGENT_BIN --work-dir "$TOWER_WORK_DIR" "$TOWER_CONNECTION_ID" &
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
