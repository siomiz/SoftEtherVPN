#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

static volatile FILE *fp;

void quit(){
  pclose((FILE *)fp);
}

int main(){

  char *cmd = (char *)"/opt/vpnserver execsvc";
  sigset_t mask;
  int sig;

  if(!(fp = (FILE *)popen(cmd, "re"))){

    printf("popen failed\n");
    exit(-1);

  }else{

    signal(SIGINT, quit);
    signal(SIGTERM, quit);

    sigfillset(&mask);
    sigwait(&mask, &sig);

    psignal(sig, "");
    printf("Caught signal, closing\n");

    pclose((FILE *)fp);
 
  }

}

