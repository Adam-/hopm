#ifndef IRC_H
#define IRC_H

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define MSGLENMAX 512 + 1


struct bopm_sockaddr
{
  struct sockaddr_in sa4;
};

struct bopm_ircaddr
{
  struct in_addr in4;
};

struct UserInfo
{
  char *irc_nick;
  char *irc_username;
  char *irc_hostname;
};

struct CommandHash
{
  const char *command;
  void (*handler)(char **, unsigned int, char *, struct UserInfo *);
};

extern void irc_send(const char *, ...);
extern void irc_send_channels(const char *, ...);
extern void irc_cycle(void);
extern void irc_timer(void);
#endif
