cat("=== R Test Job Running ===\n")
cat(sprintf("R Version: %s\n", R.version.string))
cat(sprintf("Host: %s\n", Sys.info()[["nodename"]]))
cat(sprintf("SLURM_JOB_ID: %s\n", Sys.getenv("SLURM_JOB_ID", "Not set")))
cat(sprintf("SLURM_CPUS_PER_TASK: %s\n", Sys.getenv("SLURM_CPUS_PER_TASK", "Not set")))
cat(sprintf("SLURM_MEM_PER_NODE: %s\n", Sys.getenv("SLURM_MEM_PER_NODE", "Not set")))
cat(sprintf("CUDA_VISIBLE_DEVICES: %s\n", Sys.getenv("CUDA_VISIBLE_DEVICES", "Not set")))
cat("==========================\n")

