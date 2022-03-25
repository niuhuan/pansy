#include "my_application.h"

#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <string.h>

#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

int main(int argc, char** argv) {

  struct passwd *pw = getpwuid(getuid());
  const char *homedir = pw->pw_dir;
  char root[8192];
  strcpy(root, homedir);
  strcat(root, "/.pansy");

  void *handle = dlopen("libnative.so", RTLD_LAZY);
  if (!handle) {
    fprintf(stderr, "%s\n", dlerror());
    exit(EXIT_FAILURE);
  }
  dlerror();

  void (*sr)(const char*);
  *(void **)(&sr) = dlsym(handle, "set_root");
  char *error;
  if ((error = dlerror()) != NULL) {
    fprintf(stderr, "%s\n", error);
    exit(EXIT_FAILURE);
  }

  sr(root);
  dlclose(handle);

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
