#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

static volatile FILE *fp;

void noop(){
}

int main(){

  char *cmd = (char *)"/opt/vpnserver execsvc";
  sigset_t mask;
  int sig;

  if(!(fp = (FILE *)popen(cmd, "re"))){

    printf("popen failed");
    exit(-1);

  }else{

    signal(SIGINT, noop);

    sigfillset(&mask);
    sigwait(&mask, &sig);

    psignal(sig, "");
    printf("Caught signal, closing\n");

    pclose((FILE *)fp);
 
  }

}

