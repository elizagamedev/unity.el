#include <errno.h>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "error: no arguments provided\n");
    return 1;
  }
  execvp(argv[1], &argv[1]);
  perror("execvp() failed");
  return errno;
}
