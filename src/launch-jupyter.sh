#!/usr/bin/env bash
# jupyter_job.sh — run Jupyter Lab inside an sbatch allocation (GPU-ready)

set -eo pipefail

# --- User knobs -------------------------------------------------------------
CONDA_ENV="${JUPYTER_CONDA_ENV:-jupyter}"                     # conda env to activate
LOGDIR="${JUPYTER_LOGDIR:-$HOME/sbatch_logs}"   # where to drop a JSON with URL/port
JUPYTER_ROOT="${JUPYTER_ROOT:-$HOME}"                  # Jupyter working dir (notebooks open here)
# ---------------------------------------------------------------------------

# 1) Environment
if [ -f "${HOME}/.bashrc" ]; then
  # shellcheck source=/dev/null
  source "${HOME}/.bashrc"
fi
if command -v conda >/dev/null 2>&1; then
  conda activate "${CONDA_ENV}"
fi

mkdir -p "${LOGDIR}"

# 2) Pick a free TCP port
PORT="$(python - <<'PY'
import socket
s = socket.socket()
s.bind(('',0))
print(s.getsockname()[1])
s.close()
PY
)"

# 3) Make a deterministic token (or comment this and let Jupyter auto-generate)
TOKEN="$(python - <<'PY'
import secrets; print(secrets.token_urlsafe(32))
PY
)"

# 4) Runtime info
NODE="$(hostname -f || hostname)"
JOBID="${SLURM_JOB_ID:-unknown}"
NOW="$(date -Is)"

# 5) Prepare connection details
JSON="${LOGDIR}/jupyter_${JOBID}.json"
URL="http://${NODE}:${PORT}/?token=${TOKEN}"

echo "==============================================="
echo " Jupyter Lab starting"
echo "   Job ID: ${JOBID}"
echo "   Node:   ${NODE}"
echo "   Port:   ${PORT}"
echo "   CWD:    ${JUPYTER_ROOT}"
echo "==============================================="

# 6) Launch Jupyter in background (bind to all ifaces so login node / Remote-SSH can reach it)
cd "${JUPYTER_ROOT}"

# Jupyter 7+/jupyter_server flags use ServerApp.*; NotebookApp.* kept for compat
jupyter lab \
  --no-browser \
  --ip=0.0.0.0 \
  --port="${PORT}" \
  --ServerApp.token="${TOKEN}" \
  --NotebookApp.token="${TOKEN}" \
  --ServerApp.allow_remote_access=True &

JUPYTER_PID=$!

# 7) Wait for Jupyter to actually start listening
echo "Waiting for Jupyter to start listening on port ${PORT}..."
MAX_WAIT=60
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
  if nc -z localhost "${PORT}" 2>/dev/null; then
    echo "Jupyter is ready!"
    break
  fi
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
  echo "WARNING: Timeout waiting for Jupyter to start. Continuing anyway..."
fi

# 8) NOW emit connection details (after Jupyter is ready)
cat > "${JSON}" <<EOF
{
  "job_id": "${JOBID}",
  "node": "${NODE}",
  "port": ${PORT},
  "token": "${TOKEN}",
  "url": "${URL}",
  "time": "${NOW}",
  "cuda_visible_devices": "${CUDA_VISIBLE_DEVICES:-}"
}
EOF

# Best-effort: stick the URL into the Slurm Job Comment for quick discovery
if [ -n "${SLURM_JOB_ID:-}" ] && command -v scontrol >/dev/null 2>&1; then
  scontrol update JobId="${SLURM_JOB_ID}" Comment="JUPYTER_URL:${URL}"
fi

echo "==============================================="
echo " Jupyter Lab is ready!"
echo "   URL:    ${URL}"
echo "   Log:    ${JSON}"
echo "   CUDA_VISIBLE_DEVICES: ${CUDA_VISIBLE_DEVICES:-}"
echo "==============================================="

# Wait for Jupyter process to complete
wait $JUPYTER_PID
