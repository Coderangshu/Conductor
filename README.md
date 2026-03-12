# CS695 - Linux Containerization from Scratch

This repository contains assignments focused on understanding the underlying mechanisms of Linux containers. By progressing through four structured tasks, the project practically demonstrates how modern container engines (like Docker) work behind the scenes relying on primitive Linux capabilities such as **namespaces**, **cgroups**, **chroot**, **overlayfs**, and **iptables**.

## Project Overview

The project is divided into four progressively complex tasks, culminating in a custom shell-based container orchestrator called **Conductor** capable of building, running, and natively networking multi-container applications.

### Task 1: Namespaces in C (`task1/`)
Explores Linux namespaces using native system calls in C.
* Uses the `clone()` system call to create a new child process with isolated `UTS` and `PID` namespaces.
* Uses `setns()` to allow a parent process to join specific namespaces of its child, effectively changing the operational context of subsequent forks.
* Demonstrates hostname isolation, process ID virtualization, and IPC via pipes between namespaced boundaries.

### Task 2: Basic Chroot, Unshare, and cgroups Container (`task2/`)
Demonstrates how to manually constrain and isolate an environment utilizing utilities like `chroot`, `unshare`, and control groups.
* Copies dynamically linked libraries (using `ldd`) into a rudimentary isolated root filesystem.
* Restricts process visibility to the new root using `chroot`.
* Achieves process, hostname, and IPC isolation using the `unshare` utility.
* Implements resource constraints by creating a custom `cgroup` limiting maximum CPU utilization for the containerized process (e.g., 50% CPU execution time).

### Task 3: The "Conductor" Container Engine (`task3/`)
A from-scratch, Docker-like container manager script (`conductor.sh`) written entirely in Bash. Features include:
* **Image Bootstrapping:** Capable of fetching generating OS base images (Debian, Ubuntu, Arch Linux) using `debootstrap`.
* **Layered Filesystem (OverlayFS):** Parses a custom image specification file (a `Conductorfile` supporting directives like `FROM`, `RUN`, `COPY`) and implements efficient image layers and metadata caching via Linux `overlay` filesystems.
* **Container Lifecycle Management:** Can spin up, stop, cleanly remove, and list cleanly isolated containers.
* **In-Container Execution:** Supports "executing" ad-hoc commands within the active namespaces of running isolated containers via `nsenter`.
* **Advanced Networking:** Automatically bridges container virtual ethernet interfaces (`veth` pairs) with Linux network namespaces. Configures IP forwarding, local subnet addressing, NAT via `iptables` for container WAN access, exposes mapped container ports to the host (e.g., `8080` -> `3000`), and establishes dedicated peer-to-peer networks allowing specific containers to freely communicate.

### Task 4: Multi-Container Service Orchestration (`task4/`)
A practical deployment exercise (`service-orchestrator.sh`) demonstrating a multi-container microservice architecture strictly relying on the custom `conductor.sh` tool. 
* Employs unique build manifests (`csfile` and `esfile`) fetching dependencies to compile a C-based `counter-service` and prepare a Python Flask-based `external-service`.
* Seamlessly orchestrates background execution (`sleep infinity` entrypoints) of both isolated containers.
* Deploys realistic infrastructure networking: directly exposes the frontend service mapped to physical host ports, fully isolating the database backend service—which remains accessible only to the frontend through a dedicated peer-to-peer network linkage.
* Dynamically extracts and injects container IP configurations to seamlessly bridge application state.

## Prerequisites & Constraints

* A modern Linux distribution natively supporting `overlayfs`, `cgroups v2`, and user/process namespaces.
* Core system tools must be installed: `debootstrap`, `iproute2` (`ip`), `iptables`, and `unshare`.
* Because these scripts perform direct low-level kernel abstractions and filesystem mounts, they must fundamentally be run with `root` privileges (e.g., prefixed with `sudo`).
