#!/bin/bash
# Configuration for submit-job script
# This file is sourced by the main script. No parsing required.

# --- General Settings ---
DEFAULT_CONDA_ENV="jupyter"
SOURCE_FILE="$HOME/.bashrc"
# Use a safe default, users can override in their own ~/.config version
DEFAULT_LOG_FOLDER="$HOME/sbatch_logs" 

# --- Execution Commands ---
# Maps file extensions to the command used to run them
declare -A EXECUTION_COMMANDS
EXECUTION_COMMANDS[py]="python"
EXECUTION_COMMANDS[R]="Rscript"
EXECUTION_COMMANDS[sh]="bash"
EXECUTION_COMMANDS[nf]="nextflow run"

# --- Jupyter Settings ---
JUPYTER_CONDA_ENV="jupyter"
JUPYTER_ROOT_DIR="$HOME"

# --- Nextflow Tower Settings ---
TOWER_ACCESS_TOKEN=""
TOWER_CONNECTION_ID=""
TOWER_WORK_DIR="$HOME/nextflow/work"
TOWER_AGENT_BIN="$HOME/tw-agent"

# --- SBATCH Defaults (Base) ---
# Applied to every job unless overridden
declare -A SBATCH_DEFAULTS
SBATCH_DEFAULTS[mem]="128G"
SBATCH_DEFAULTS[nodes]="1"
SBATCH_DEFAULTS[ntasks]="1"
SBATCH_DEFAULTS[time]="24:00:00"

# --- Profiles ---
# Named sets of sbatch parameters.
# Format: "key=value key2=value2" (space separated)
declare -A PROFILES
PROFILES[cpu]="cpus-per-task=16"
PROFILES[gpu]="cpus-per-task=4 gpus=a10:1"
PROFILES[big_mem]="mem=256G"
PROFILES[long_run]="time=48:00:00"
PROFILES[cao_account]="account=cao_condo_bank"

# --- Partition Rules ---
# Automatically apply profiles based on partition name (glob patterns allowed)
# Format: "profile1 profile2" or "profile1,profile2"
# Multiple profiles are applied in order.
declare -A PARTITION_RULES
PARTITION_RULES["cao*"]="cao_account"
PARTITION_RULES["*a10*"]="gpu"
PARTITION_RULES["*v100*"]="gpu"
PARTITION_RULES["*l40*"]="gpu"
