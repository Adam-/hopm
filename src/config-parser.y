/*
 * Copyright (C) 2002-2003  Erik Fears
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to
 *
 *       The Free Software Foundation, Inc.
 *       59 Temple Place - Suite 330
 *       Boston, MA  02111-1307, USA.
 *
 *
 */


%{
#include <stdio.h>
#include <string.h>
#include "malloc.h"
#include "config.h"

int yylex(void);

int yydebug=0;
void *tmp;        /* Variable to temporarily hold nodes before insertion to list */

%}

%token AWAY
%token BAN_UNKNOWN
%token BLACKLIST
%token BYTES KBYTES MBYTES
%token CHANNEL
%token CONNREGEX
%token DNS_FDLIMIT
%token DNSBL_FROM
%token DNSBL_TO
%token EXEMPT
%token FD
%token INVITE
%token IRC
%token KLINE
%token KEY
%token MASK
%token MAX_READ
%token MODE
%token NAME
%token NEGCACHE
%token NICK
%token NICKSERV
%token OPER
%token OPM
%token OPTIONS
%token PASSWORD
%token PERFORM
%token PIDFILE
%token PORT
%token PROTOCOL
%token READTIMEOUT
%token REALNAME
%token REPLY
%token SCANLOG
%token SCANNER
%token SECONDS MINUTES HOURS DAYS WEEKS MONTHS YEARS
%token SENDMAIL
%token SERVER
%token TARGET_IP
%token TARGET_PORT
%token TARGET_STRING
%token TIMEOUT
%token TYPE
%token USERNAME
%token USER
%token VHOST

%union 
{
        int number;
        char *string;
}

%token <number> NUMBER
%token <string> STRING
%token <number> PROTOCOLTYPE
%type  <number> timespec
%type  <number> timespec_
%type  <number> sizespec
%type  <number> sizespec_

%%

config:
          | config config_items
          ;

config_items: irc_entry     |
              options_entry |
              opm_entry     |
              user_entry    |
              scanner_entry |
              exempt_entry;

timespec_: { $$ = 0; } | timespec;
timespec:  NUMBER timespec_         { $$ = $1 + $2; } |
           NUMBER SECONDS timespec_ { $$ = $1 + $3; } |
           NUMBER MINUTES timespec_ { $$ = $1 * 60 + $3; } |
           NUMBER HOURS timespec_   { $$ = $1 * 60 * 60 + $3; } |
           NUMBER DAYS timespec_    { $$ = $1 * 60 * 60 * 24 + $3; } |
           NUMBER WEEKS timespec_   { $$ = $1 * 60 * 60 * 24 * 7 + $3; } |
           NUMBER MONTHS timespec_  { $$ = $1 * 60 * 60 * 24 * 7 * 4 + $3; } |
           NUMBER YEARS timespec_   { $$ = $1 * 60 * 60 * 24 * 365 + $3; }
           ;

sizespec_:  { $$ = 0; } | sizespec;
sizespec:   NUMBER sizespec_ { $$ = $1 + $2; } |
            NUMBER BYTES sizespec_ { $$ = $1 + $3; } |
            NUMBER KBYTES sizespec_ { $$ = $1 * 1024 + $3; } |
            NUMBER MBYTES sizespec_ { $$ = $1 * 1024 * 1024 + $3; }
            ;

/*************************** OPTIONS BLOCK ***********************/

options_entry: OPTIONS '{' options_items '}' ';';

options_items: options_items options_item |
               options_item;

options_item: options_negcache |
              options_pidfile |
              options_dns_fdlimit |
              options_scanlog |
              error;

options_negcache: NEGCACHE '=' timespec ';'
{
   OptionsItem->negcache = $3;
};

options_pidfile: PIDFILE '=' STRING ';'
{
   MyFree(OptionsItem->pidfile);
   OptionsItem->pidfile = xstrdup($3);
};

options_dns_fdlimit: DNS_FDLIMIT '=' NUMBER ';'
{
   OptionsItem->dns_fdlimit = $3;
};

options_scanlog: SCANLOG '=' STRING ';'
{
   MyFree(OptionsItem->scanlog);
   OptionsItem->scanlog = xstrdup($3);
};

/*************************** IRC BLOCK ***************************/

irc_entry: IRC '{' irc_items  '}' ';';

irc_items: irc_items irc_item |
           irc_item;

irc_item: irc_away        |
          irc_connregex   |
          irc_kline       |
          irc_nick        |
          irc_nickserv    |
          irc_mode        |
          irc_oper        |
          irc_password    |
          irc_port        | 
          irc_readtimeout |
          irc_realname    |
          irc_server      |
          irc_username    |
          irc_vhost       |
          irc_perform     |
          channel_entry   |
          error;

irc_away: AWAY '=' STRING ';'
{
   MyFree(IRCItem->away);
   IRCItem->away = xstrdup($3);
};

irc_kline: KLINE '=' STRING ';'
{
   MyFree(IRCItem->kline);
   IRCItem->kline = xstrdup($3);
};

irc_mode: MODE '=' STRING ';'
{
   MyFree(IRCItem->mode);
   IRCItem->mode = xstrdup($3);
};

irc_nick: NICK '=' STRING ';'
{
   MyFree(IRCItem->nick);
   IRCItem->nick = xstrdup($3);
};

irc_nickserv: NICKSERV '=' STRING ';'
{
   MyFree(IRCItem->nickserv);
   IRCItem->nickserv = xstrdup($3);
};

irc_oper: OPER '=' STRING ';'
{
   MyFree(IRCItem->oper);
   IRCItem->oper = xstrdup($3);
};

irc_password: PASSWORD '=' STRING ';'
{
   MyFree(IRCItem->password);
   IRCItem->password = xstrdup($3);
};

irc_perform: PERFORM '=' STRING ';'
{
   node_t *node;
   node = node_create(xstrdup($3));

   list_add(IRCItem->performs, node);
};

irc_port: PORT '=' NUMBER ';'
{
   IRCItem->port = $3;
};

irc_readtimeout: READTIMEOUT '=' timespec ';'
{
   IRCItem->readtimeout = $3;
};

irc_realname: REALNAME '=' STRING ';'
{
   MyFree(IRCItem->realname);
   IRCItem->realname = xstrdup($3);
};

irc_server: SERVER '=' STRING ';'
{
   MyFree(IRCItem->server);
   IRCItem->server = xstrdup($3);
};

irc_username: USERNAME '=' STRING ';'
{
   MyFree(IRCItem->username);
   IRCItem->username = xstrdup($3);
};

irc_vhost: VHOST '=' STRING ';'
{
   MyFree(IRCItem->vhost);
   IRCItem->vhost = xstrdup($3);
};

irc_connregex: CONNREGEX '=' STRING ';'
{
   MyFree(IRCItem->connregex);
   IRCItem->connregex = xstrdup($3);
};


/************************** CHANNEL BLOCK *************************/

channel_entry: 
{
   node_t *node;
   struct ChannelConf *item;

   item = MyMalloc(sizeof *item);

   item->name = xstrdup("");
   item->key = xstrdup("");
   item->invite = xstrdup("");

   node = node_create(item);
   list_add(IRCItem->channels, node);

   tmp = item;
}
CHANNEL '{' channel_items '}' ';';

channel_items: channel_items channel_item |
               channel_item;

channel_item:  channel_name  |
               channel_key   |
               channel_invite;

channel_name: NAME '=' STRING ';'
{
   struct ChannelConf *item = tmp;

   MyFree(item->name);
   item->name = xstrdup($3);
};

channel_key: KEY '=' STRING ';'
{
   struct ChannelConf *item = tmp;

   MyFree(item->key);
   item->key = xstrdup($3);
};

channel_invite: INVITE '=' STRING ';'
{
   struct ChannelConf *item = tmp;

   MyFree(item->invite);
   item->invite = xstrdup($3);
};

/*************************** USER BLOCK ***************************/

user_entry: 
{
   node_t *node;
   struct UserConf *item;

   item = MyMalloc(sizeof *item);

   item->masks = list_create();
   item->scanners = list_create();

   node = node_create(item);
   list_add(UserItemList, node);

   tmp = item; 
} 
USER '{' user_items  '}' ';' ;

user_items: user_items user_item |
           user_item;

user_item: user_mask     |
           user_scanner  |
          error;

user_mask: MASK '=' STRING ';'
{
   struct UserConf *item = tmp;
   node_t *node;

   node = node_create(xstrdup($3));

   list_add(item->masks, node);
};

user_scanner: SCANNER '=' STRING ';'
{
   struct UserConf *item = tmp;
   node_t *node;

   node = node_create(xstrdup($3));

   list_add(item->scanners, node);
};

/*************************** SCANNER BLOCK ***************************/

scanner_entry:
{
   node_t *node;
   struct ScannerConf *item, *olditem;

   item = MyMalloc(sizeof *item);

   /* Setup ScannerConf defaults */
   item->name = xstrdup("undefined");

	if(LIST_SIZE(ScannerItemList) > 0)
	{
	   olditem = ScannerItemList->tail->data;

		item->vhost = xstrdup(olditem->vhost);
		item->fd = olditem->fd;
		item->target_ip = xstrdup(olditem->target_ip);
		item->target_port = olditem->target_port;
		item->timeout = olditem->timeout;
		item->max_read = olditem->max_read;

		item->target_string = olditem->target_string;
		item->target_string_created = 0;
	}
	else
	{
	   item->vhost = xstrdup("0.0.0.0");
      item->fd = 512;
      item->target_ip = xstrdup("127.0.0.1");
      item->target_port = 6667;
      item->timeout = 30;
      item->max_read = 4096;
		
		item->target_string = list_create();
		item->target_string_created = 1;
	}
	
   item->protocols = list_create();

   node = node_create(item);

   list_add(ScannerItemList, node);
   tmp = item;
}
SCANNER '{' scanner_items  '}' ';' ;

scanner_items: scanner_items scanner_item |
               scanner_item;

scanner_item: scanner_name          |
              scanner_vhost         |
              scanner_fd            |
              scanner_target_ip     |
              scanner_target_port   |
              scanner_target_string |
              scanner_protocol      |
              scanner_timeout       |
              scanner_max_read      |
              error;

scanner_name: NAME '=' STRING ';'
{
   struct ScannerConf *item = tmp;
   MyFree(item->name);
   item->name = xstrdup($3);
};

scanner_vhost: VHOST '=' STRING ';'
{
   struct ScannerConf *item = tmp;
   MyFree(item->vhost);
   item->vhost = xstrdup($3);
};

scanner_target_ip: TARGET_IP '=' STRING ';'
{
   struct ScannerConf *item = tmp;
   MyFree(item->target_ip);
   item->target_ip = xstrdup($3);
};

scanner_target_string: TARGET_STRING '=' STRING ';'
{
   struct ScannerConf *item = tmp;

   node_t *node;
   node = node_create($3);

	if(item->target_string_created == 0)
	{
	   item->target_string = list_create();
		item->target_string_created = 1;
	}

   list_add(item->target_string, node);
};

scanner_fd: FD '=' NUMBER ';'
{
   struct ScannerConf *item = tmp;
   item->fd = $3;
};

scanner_target_port: TARGET_PORT '=' NUMBER ';'
{
   struct ScannerConf *item = tmp;
   item->target_port = $3;
};

scanner_timeout: TIMEOUT '=' timespec ';'
{
   struct ScannerConf *item = tmp;
   item->timeout = $3;
};

scanner_max_read: MAX_READ '=' sizespec ';'
{
   struct ScannerConf *item = tmp;
   item->max_read = $3;
};

scanner_protocol: PROTOCOL '=' PROTOCOLTYPE ':' NUMBER ';'
{
   struct ProtocolConf *item;
   struct ScannerConf  *item2;

   node_t *node;
 
   item = MyMalloc(sizeof *item);
   item->type = $3;
   item->port = $5;

   item2 = tmp;

   node = node_create(item);
   list_add(item2->protocols, node);
};

/*************************** OPM BLOCK ***************************/

opm_entry: OPM '{' opm_items  '}' ';' ;

opm_items: opm_items opm_item |
           opm_item;

opm_item: opm_dnsbl_from      |
          opm_dnsbl_to        |
          opm_sendmail        |
          opm_blacklist_entry |
          error;

opm_dnsbl_from: DNSBL_FROM '=' STRING ';'
{
   MyFree(OpmItem->dnsbl_from);
   OpmItem->dnsbl_from = xstrdup($3);
};

opm_dnsbl_to: DNSBL_TO '=' STRING ';'
{
   MyFree(OpmItem->dnsbl_to);
   OpmItem->dnsbl_to = xstrdup($3);
};

opm_sendmail: SENDMAIL '=' STRING ';'
{
   MyFree(OpmItem->sendmail);
   OpmItem->sendmail = xstrdup($3);
};

/************************** BLACKLIST BLOCK *************************/

opm_blacklist_entry:
{
   node_t *node;
   struct BlacklistConf *item;

   item = MyMalloc(sizeof *item);

   item->name = xstrdup("");
   item->kline = xstrdup("");
   item->ban_unknown = 0;
   item->type = A_BITMASK;
   item->reply = list_create();

   node = node_create(item);
   list_add(OpmItem->blacklists, node);

   tmp = item;
}
BLACKLIST '{' blacklist_items '}' ';';

blacklist_items: blacklist_items blacklist_item |
                 blacklist_item;

blacklist_item: blacklist_name        |
                blacklist_type        |
                blacklist_kline       |
                blacklist_ban_unknown |
                blacklist_reply       |
                error;

blacklist_name: NAME '=' STRING ';' {
   struct BlacklistConf *item = tmp;

   MyFree(item->name);
   item->name = xstrdup($3);
};

blacklist_kline: KLINE '=' STRING ';' {
   struct BlacklistConf *item = tmp;

   MyFree(item->kline);
   item->kline = xstrdup($3);
};

blacklist_type: TYPE '=' STRING ';' {
   struct BlacklistConf *item = tmp;
   
   if(strcmp("A record bitmask", $3) == 0)
      item->type = A_BITMASK;
   else if(strcmp("A record reply", $3) == 0)
      item->type = A_REPLY;
   else
      yyerror("Unknown blacklist type defined");
};

blacklist_ban_unknown: BAN_UNKNOWN '=' NUMBER ';' {
   struct BlacklistConf *item = tmp;

   item->ban_unknown = $3;
};

blacklist_reply: REPLY '{' blacklist_reply_items '}' ';';

blacklist_reply_items: blacklist_reply_items blacklist_reply_item |
                       blacklist_reply_item;

blacklist_reply_item: NUMBER '=' STRING ';'
{
   struct BlacklistReplyConf *item;
   struct BlacklistConf *blacklist = tmp;
   node_t *node;

   item = MyMalloc(sizeof *item);

   item->number = $1;
   item->type = xstrdup($3);

   node = node_create(item);
   list_add(blacklist->reply, node);
};

/*************************** EXEMPT BLOCK ***************************/


exempt_entry: EXEMPT '{' exempt_items  '}' ';' ;

exempt_items: exempt_items exempt_item |
              exempt_item;

exempt_item: exempt_mask  |
             error;

exempt_mask: MASK '=' STRING ';'
{
   node_t *node;
   node = node_create(xstrdup($3));

   list_add(ExemptItem->masks, node);
};

%%
