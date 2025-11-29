import os
import sys

print("=== Python Test Job Running ===")
print(f"Python Version: {sys.version}")
print(f"Host: {os.uname().nodename}")
print(f"SLURM_JOB_ID: {os.environ.get('SLURM_JOB_ID', 'Not set')}")
print(f"SLURM_CPUS_PER_TASK: {os.environ.get('SLURM_CPUS_PER_TASK', 'Not set')}")
print(f"SLURM_MEM_PER_NODE: {os.environ.get('SLURM_MEM_PER_NODE', 'Not set')}")
print(f"CUDA_VISIBLE_DEVICES: {os.environ.get('CUDA_VISIBLE_DEVICES', 'Not set')}")
print("===============================")

