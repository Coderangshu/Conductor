#!/bin/bash
. /etc/os-release

SIMPLE_CONTAINER_ROOT=container_root

mkdir -p $SIMPLE_CONTAINER_ROOT

gcc -o container_prog container_prog.c

## Subtask 1: Execute in a new root filesystem

cp container_prog $SIMPLE_CONTAINER_ROOT/

# 1.1: Copy any required libraries to execute container_prog to the new root container filesystem 
ldd container_prog | awk '/=>/ {print $3} /ld-linux/ && !/=>/ {print $1}' | xargs -I '{}' cp -v --parents '{}' $SIMPLE_CONTAINER_ROOT/ > /dev/null 2>&1


echo -e "\n\e[1;32mOutput Subtask 2a\e[0m"
# 1.2: Execute container_prog in the new root filesystem using chroot. You should pass "subtask1" as an argument to container_prog
if [ "$ID" = "arch" ]; then
    sudo chroot $SIMPLE_CONTAINER_ROOT /usr/lib64/ld-linux-x86-64.so.2 /container_prog subtask1
elif [ "$ID" = "debian" ]; then
    sudo chroot $SIMPLE_CONTAINER_ROOT /lib64/ld-linux-x86-64.so.2 /container_prog subtask1
else
    echo "Unknown distribution: $ID"
fi



echo "__________________________________________"
echo -e "\n\e[1;32mOutput Subtask 2b\e[0m"
## Subtask 2: Execute in a new root filesystem with new PID and UTS namespace
# The pid of container_prog process should be 1
# You should pass "subtask2" as an argument to container_prog
if [ "$ID" = "arch" ]; then
    sudo unshare --fork --pid --uts --mount-proc chroot $SIMPLE_CONTAINER_ROOT /usr/lib64/ld-linux-x86-64.so.2 /container_prog subtask2
elif [ "$ID" = "debian" ]; then
    sudo unshare --fork --pid --uts --mount-proc chroot $SIMPLE_CONTAINER_ROOT /lib64/ld-linux-x86-64.so.2 /container_prog subtask2
else
    echo "Unknown distribution: $ID"
fi


echo -e "\nHostname in the host: $(hostname)"


## Subtask 3: Execute in a new root filesystem with new PID, UTS and IPC namespace + Resource Control
# Create a new cgroup and set the max CPU utilization to 50% of the host CPU. (Consider only 1 CPU core)
sudo mkdir -p /sys/fs/cgroup/container_group
echo "50000 100000" | sudo tee /sys/fs/cgroup/container_group/cpu.max > /dev/null 2>&1

# Move the current shell into the cgroup
echo $$ | sudo tee /sys/fs/cgroup/container_group/cgroup.procs > /dev/null 2>&1


echo "__________________________________________"
echo -e "\n\e[1;32mOutput Subtask 2c\e[0m"
# Assign pid to the cgroup such that the container_prog runs in the cgroup
# Run the container_prog in the new root filesystem with new PID, UTS and IPC namespace
# You should pass "subtask1" as an argument to container_prog
if [ "$ID" = "arch" ]; then
    sudo unshare --fork --pid --uts --ipc --mount-proc chroot $SIMPLE_CONTAINER_ROOT /usr/lib64/ld-linux-x86-64.so.2 /container_prog subtask3 &
elif [ "$ID" = "debian" ]; then
    sudo unshare --fork --pid --uts --ipc --mount-proc chroot $SIMPLE_CONTAINER_ROOT /lib64/ld-linux-x86-64.so.2 /container_prog subtask3 &
else
    echo "Unknown distribution: $ID"
fi

container_pid=$!
wait $container_pid

# Remove the cgroup
echo $$ | sudo tee /sys/fs/cgroup/cgroup.procs > /dev/null 2>&1
sudo rmdir /sys/fs/cgroup/container_group
sudo rm -rf $SIMPLE_CONTAINER_ROOT
sudo rm container_prog


# If mounted dependent libraries, unmount them, else ignore
