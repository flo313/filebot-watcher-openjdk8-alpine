![Filebot](https://www.filebot.net/images/filebot.logo.svg)

Filebot media management
 
# Usage
```
#!/bin/sh
CONTAINERNAME="Filebot"
IMAGE="flo313/filebot-watcher-openjdk8-alpine"
DOCKER_BIN="docker"
VOLUME_BIND="-v /etc/localtime:/etc/localtime:ro \
			-v /path/to/config:/config \
			-v /path/to/input:/input \
			-v /path/to/output:/output"
PORT_BIND=""
ENV_BIND=""
RESTART_OPTS="--restart unless-stopped"
OTHER_OPTS=""

docker_start() {
	$DOCKER_BIN run -d $VOLUME_BIND $PORT_BIND $ENV_BIND $RESTART_OPTS $OTHER_OPTS --name $CONTAINERNAME $IMAGE
}
docker_stop() {
	$DOCKER_BIN inspect --format="{{ .State.Running }}" $CONTAINERNAME > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		$DOCKER_BIN rm -f $CONTAINERNAME
	fi
}
case "$1" in
	start)
		docker_stop
		docker_start
		RETVAL=$?
		;;
	stop)
		docker_stop
		RETVAL=$?
		;;
	restart)
		docker_stop
		docker_start
		;;
	*)
		echo "start/stop/restart"
		exit 1
		;;
esac

exit $RETVAL
```
# /data/muttrc content
Here is the mutt configuration file used to allow mail notification.
Info: The line "to=" isn't a mutt directive but it is used to define 
the recipient of the mail.
```
set from = "UserMailAddress@gmail.com"
set realname = "Name SURNAME"
set imap_user = "UserMailAddress@gmail.com"
set imap_pass = "password"
set folder = "imaps://imap.gmail.com:993"
set spoolfile = "+INBOX"
set postponed ="+[Gmail]/Drafts"
set header_cache =~/.mutt/cache/headers
set message_cachedir =~/.mutt/cache/bodies
set certificate_file =~/.mutt/certificates
set smtp_url = "smtp://UserMailAddress@smtp.gmail.com:587/"
set smtp_pass = "password"
set move = no
set copy = no
set imap_keepalive = 900
to=UserMailAddress@gmail.com
```
