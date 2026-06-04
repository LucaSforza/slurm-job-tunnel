# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- Install: `pip install -e .` (editable mode for development)
- Run: `python -m slurm_job_tunnel.main [init|run|reset|show]`
- No test suite, linter, or formatter configured

## Dependencies

- `pexpect` — spawns/controls SSH child processes
- `slurm-job-util` — external git dep, provides `SBatchCommand`, `SlurmJob`, `SSHConfig`, `SSHConfigEntry`, `execute_on_host`; installed from `git+https://github.com/wvdtoorn/slurm-job-util.git`
- `setuptools`

## Architecture

CLI tool that submits a SLURM job with requested resources and establishes an SSH tunnel to the allocated compute node via a Singularity container.

### Source layout

```
slurm_job_tunnel/
  main.py          — CLI entry point. argparse with subcommands: init, run, reset, show. Loads/saves config from ~/.slurm-job-tunnel/config.json.
  tunnel_config.py — TunnelConfig dataclass. Holds SLURM job params (time, cpus, mem, partition, qos, gpus, nodes, ntasks) and remote paths (sbatch, sif, bind path). Maps fields to SBatchCommand kwargs.
  run_tunnel.py    — Core orchestration. Two key classes:
                     - JobTunnel: submits SLURM sbatch, polls job output for PORT/NODE/termination_time.
                     - LocalTunnel: finds free local port, spawns ssh -L in a thread, writes SSH config entry.
  _version.py      — __version__ = "0.1.1"
tunnel.sbatch      — Shell script run on HPC node. Uses python to find random free port, writes PORT= / NODE= to stdout, starts sshd inside singularity container.
openssh.def        — Singularity def file. Bootstraps ubuntu:22.04, installs openssh-server with UsePAM=no.
```

### Flow: `slurm-job-tunnel run`

1. Build `SBatchCommand` from config, rsync tunnel path to remote
2. Submit sbatch via SSH to remote host (~/.ssh/config entry)
3. Poll `squeue` until job is running
4. Poll job output file for `PORT=`, `NODE=`, termination time
5. Add SSH config entry pointing to allocated node:port (via proxyjump through login node)
6. Start `LocalTunnel`: find free local port, spawn `ssh -N -L local:remote` in daemon thread, add SSH config entry for local port-forward host
7. SIGINT handler cleans up: cancel SLURM job, remove SSH config entries, stop local tunnel thread
8. Sleep until termination time — 1 minute before, then auto-cleanup

### Configuration

Stored as JSON at `~/.slurm-job-tunnel/config.json`. Set via `init`, used as defaults for `run`.

## Project goals

See [TODO.md](TODO.md) for planned features.
