# Getting Started

## Requirements

You must have a working Kubernetes cluster with `kubectl` configured to communicate with it.

This script was written and tested against microk8s but the commands involve should be
generally applicable to any Kubernetes cluster.

## Execution

From this folder, execute `./00-init.sh` to bootstrap the cluster.

From the repo root, call `make init` to run the same script.

## Operation

On execution, the script will provide a list of options. Choosing option 0 will
run every bootstrapping step in sequence, ensuring that all necessary cluster
components are installed and properly configured. 

The script is designed to be self-documenting and idempotent. If it detects that
a component is already installed, it will prompt you to determine whether it should
update or skip the installation of that component.

