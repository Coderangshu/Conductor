#define _GNU_SOURCE
#include <fcntl.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <sys/utsname.h>
#include <sys/wait.h>
#include <unistd.h>

#define errExit(msg)                                                           \
  do {                                                                         \
    perror(msg);                                                               \
    exit(EXIT_FAILURE);                                                        \
  } while (0)

#define CHILD_STACK_SIZE 0x800000

int child_function(void *arg) {

  int *pipefd = (int *)arg;

  close(pipefd[0]);

  const char *hostname = "Child1Hostname";
  char hostname_buf[32];
  if (sethostname(hostname, strlen(hostname)) == -1) {
    errExit("sethostname");
  }
  printf("Child1 Process PID: %d\n", getpid());
  gethostname(hostname_buf, 32);
  printf("Child1 Hostname: %s\n", hostname_buf);

  write(pipefd[1], "1", 1);
  close(pipefd[1]);

  while (1) {
    sleep(1);
  }

  return 0;
}

int child2_function() {

  char hostname_buf[32];
  printf("Child2 Process PID: %d\n", getpid());
  gethostname(hostname_buf, 32);
  printf("Child2 Hostname: %s\n", hostname_buf);

  return 0;
}

int main() {

  char hostname_buf[32];
  char buf[32];

  void *child_stack = malloc(CHILD_STACK_SIZE);

  int pipefd[2];

  pid_t child_pid;

  if (pipe(pipefd) == -1) {
    errExit("pipe");
  }

  if (!child_stack) {
    perror("malloc");
    exit(EXIT_FAILURE);
  }

  printf("----------------------------------------\n");
  printf("Parent Process PID: %d\n", getpid());
  gethostname(hostname_buf, 32);
  printf("Parent Hostname: %s\n", hostname_buf);
  printf("----------------------------------------\n");

  /**
   * 1. Create a new child process that runs child1_function
   * 2. The child process will have its own UTS and PID namespace
   * 3. You should pass the pointer to the pipefd array as an argument to the
   * child1_function
   * 4. PID of child1 should be assigned to child_pid variable
   */

  // ------------------ WRITE CODE HERE ------------------
  child_pid = clone(child_function, (char *)child_stack + CHILD_STACK_SIZE,
                    CLONE_NEWUTS | CLONE_NEWPID | SIGCHLD, pipefd);
  if (child_pid == -1)
    errExit("clone");

  // -----------------------------------------------------

  close(pipefd[1]);
  read(pipefd[0], buf, 1);
  close(pipefd[0]);

  /**
   * You can write any code here as per your requirement
   * Note: PID namespace of a process will only change the PID namespace of its
   * subsequent children, not the process itself. You are allowed to make
   * modifications to the parent process such that PID namespace of child2 is
   * same as that of child1
   */

  // ------------------ WRITE CODE HERE ------------------

  /*
   * Here, in the parent process we join child1's PID namespace so that
   * the subsequent fork will create a process in child1's PID namespace.
   * Since setns for a PID namespace affects only subsequent fork(2)s,
   * the parent's own PID and UTS (hostname) remain unchanged.
   */

  char ns_pid_path[256];
  int fd_pid;
  // defining the path of the PID namespace file
  snprintf(ns_pid_path, sizeof(ns_pid_path), "/proc/%d/ns/pid", child_pid);
  fd_pid = open(ns_pid_path, O_RDONLY);
  if (fd_pid == -1)
    errExit("open pid namespace");
  if (setns(fd_pid, 0) == -1)
    errExit("setns pid");
  close(fd_pid);

  // -----------------------------------------------------

  printf("----------------------------------------\n");
  printf("Parent Process PID: %d\n", getpid());
  gethostname(hostname_buf, 32);
  printf("Parent Hostname: %s\n", hostname_buf);
  printf("----------------------------------------\n");

  if (fork() == 0) {

    /**
     * 1. Join the existing UTS namespace and PID namespace
     */

    // ------------------ WRITE CODE HERE ------------------

    /*
     * In the forked child (child2) we join child1's UTS namespace so that the
     * hostname is changed to "Child1Hostname". (The PID namespace is already in
     * effect because the parent's setns call affects this fork.)
     */
    char ns_uts_path[256];
    int fd_uts;
    snprintf(ns_uts_path, sizeof(ns_uts_path), "/proc/%d/ns/uts", child_pid);
    fd_uts = open(ns_uts_path, O_RDONLY);
    if (fd_uts == -1)
      errExit("open uts namespace");
    if (setns(fd_uts, 0) == -1)
      errExit("setns uts");
    close(fd_uts);

    child2_function();
    exit(0);
    // -----------------------------------------------------

    child2_function();
    exit(0);
  }

  wait(NULL);
  kill(child_pid, SIGKILL);
  wait(NULL);

  printf("----------------------------------------\n");
  printf("Parent Process PID: %d\n", getpid());
  gethostname(hostname_buf, 32);
  printf("Parent Hostname: %s\n", hostname_buf);
  printf("----------------------------------------\n");

  free(child_stack);
  return 0;
}
