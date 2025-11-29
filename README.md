# ez-hpc

**ez-hpc** is a collection of robust, portable Bash scripts to streamline job submission and Jupyter Lab management on SLURM clusters. It provides intelligent defaults, partition-based profiles, and easy Jupyter integration without requiring complex Python dependencies.

Most of this code was written using AI, albeit with significant human input and guidance.

## Features
- **Smart Defaults**: Automatically detects file types (.py, .R, .sh, .nf) and applies appropriate submission commands.
- **Profile Management**: Define named profiles (e.g., `gpu`, `big_mem`) in a simple Bash config file.
- **Partition Rules**: Automatically apply specific settings (like accounts or time limits) based on the chosen partition.
- **Jupyter Integration**: One-command launch of Jupyter Lab on a compute node with automatic connection info.

## Installation

### 1. Clone the Repository
Clone this repository to your home directory (or any preferred location).
```bash
git clone https://github.com/yourusername/ez-hpc.git
cd ez-hpc
```

### 2. Setup

The included script sets up your configuration, adds the tools to your path, and optionally creates the Jupyter environment.
Note: if you have a config file somewhere on your server you'd like to use, copy it first as follows:
```bash
cp PATH/TO/YOUR/CONFIG/FILE config/user_configs.sh
```

If you don't have one already, don't worry, as the script will use the default one which you will later edit and customize.

Next, run the installation script:
```bash
./install.sh
```
Follow the on-screen prompts.

### Manual Installation (Alternative)
If you prefer to set things up manually:
1.  **Config**: `cp config/default_configs.sh config/user_configs.sh`
2.  **Path**: Add `export PATH="$PATH:$HOME/ez-hpc/src"` to your `.bashrc`.
3.  **Jupyter**: `conda env create -f jupyter_env/environment.yml`

## Usage

### Submit a Script
Submit a Python, R, or Bash script to the cluster.
```bash
submit-job --script analysis.py --partition=YOUR_PARTITION
```

### Apply a Profile
Use a pre-defined profile from your config (e.g., for extra memory).
```bash
submit-job --script analysis.R --partition=YOUR_PARTITION --profiles "big_mem"
```

### Launch Jupyter Lab
Start a Jupyter Lab instance on a compute node.
```bash
submit-job --jupyter --partition=YOUR_PARTITION
```
Once running, get the connection URL:
```bash
get-jupyter-url
```

### Launch Nextflow Tower Agent
Start a specific Nextflow Tower (Seqera Platform) agent on a compute node.
```bash
submit-job --nf-tower --partition=YOUR_PARTITION
```
*Requires Tower configuration in `config/user_configs.sh`.*

### Pass Arguments
Pass arguments to your script.
```bash
submit-job --script train.py --partition=YOUR_PARTITION --args "--epochs 50 --batch-size 32"
```

## Configuration
The configuration is a standard Bash script located at `config/user_configs.sh`. You can define:
- **SBATCH_DEFAULTS**: Default memory, time, etc.
- **PROFILES**: Named sets of parameters (e.g., `gpu="gpus=1 cpus-per-task=4"`).
- **PARTITION_RULES**: Automatically apply profiles based on partition name patterns (e.g., `*gpu*` -> `gpu`).
- **TOWER_SETTINGS**: Set `TOWER_ACCESS_TOKEN`, `TOWER_CONNECTION_ID`, etc. for Seqera Platform integration.
