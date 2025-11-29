# ez-hpc

**ez-hpc** is a collection of robust, portable Bash scripts to streamline job submission and Jupyter Lab management on SLURM clusters. It provides intelligent defaults, partition-based profiles, and easy Jupyter integration without requiring complex Python dependencies.

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

### 2. Customize Configuration
Copy the default configuration to a user-specific file. This file is ignored by git, so your custom settings (accounts, partition names) will be safe from updates.
```bash
cp config/default_configs.sh config/user_configs.sh
```
Edit `config/user_configs.sh` to set your cluster's specific defaults.

### 3. Add to Path
Add the `src` directory to your `$PATH` in your `.bashrc` file so you can run the scripts from anywhere.
```bash
echo 'export PATH="$PATH:$HOME/ez-hpc/src"' >> ~/.bashrc
source ~/.bashrc
```
*(Note: Adjust the path `$HOME/ez-hpc/src` if you cloned the repo somewhere else.)*

### 4. Set up Jupyter Environment (Optional)
To use the Jupyter features, create a compatible environment using the provided files in `jupyter_env`.

**Using Conda (Recommended):**
```bash
conda env create -f jupyter_env/environment.yml
```

## Usage

### Submit a Script
Submit a Python, R, or Bash script to the cluster.
```bash
submit-job --script analysis.py --partition=general
```

### Apply a Profile
Use a pre-defined profile from your config (e.g., for extra memory).
```bash
submit-job --script analysis.R --partition=general --profiles "big_mem"
```

### Launch Jupyter Lab
Start a Jupyter Lab instance on a compute node.
```bash
submit-job --jupyter --partition=gpu_partition
```
Once running, get the connection URL:
```bash
get-jupyter-url
```

### Pass Arguments
Pass arguments to your script.
```bash
submit-job --script train.py --partition=gpu --args "--epochs 50 --batch-size 32"
```

## Configuration
The configuration is a standard Bash script located at `config/user_configs.sh`. You can define:
- **SBATCH_DEFAULTS**: Default memory, time, etc.
- **PROFILES**: Named sets of parameters (e.g., `gpu="gpus=1 cpus-per-task=4"`).
- **PARTITION_RULES**: Automatically apply profiles based on partition name patterns (e.g., `*gpu*` -> `gpu`).
