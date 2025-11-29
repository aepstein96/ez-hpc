#!/usr/bin/env nextflow

process printInfo {
    debug true

    script:
    """
    echo "=== Nextflow Test Job Running ==="
    echo "Host: \$(hostname)"
    echo "SLURM_JOB_ID: \$SLURM_JOB_ID"
    echo "SLURM_CPUS_PER_TASK: \$SLURM_CPUS_PER_TASK"
    echo "================================="
    """
}

workflow {
    printInfo()
}

