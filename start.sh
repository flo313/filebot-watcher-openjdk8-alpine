#!/bin/bash

function ts {
  echo [`date '+%Y-%m-%d %T'`]
}
#----------------------------------------------------------------------------------------------------
function initialize_configuration {
  if [ ! -f $CONFIG_DIR/filebot.conf ]
  then
    echo "$(ts) Creating default filebot.conf in User Dir"
    cp /files/filebot.conf $CONFIG_DIR/filebot.conf
    chmod a+w $CONFIG_DIR/filebot.conf
  fi

  if [ ! -f $CONFIG_DIR/filebot.sh ]
  then
    echo "$(ts) Creating default filebot.sh in User Dir"
    cp /files/filebot.sh $CONFIG_DIR/filebot.sh
  fi
}
#----------------------------------------------------------------------------------------------------
function check_filebot_sh_version {
  USER_VERSION=$(grep '^VERSION=' $CONFIG_DIR/filebot.sh 2>/dev/null | sed 's/VERSION=//')
  CURRENT_VERSION=$(grep '^VERSION=' /files/filebot.sh | sed 's/VERSION=//')

  echo "$(ts) Comparing user's filebot.sh at version $USER_VERSION versus current version $CURRENT_VERSION"

  if [ -z "$USER_VERSION" ] || [ "$USER_VERSION" -lt "$CURRENT_VERSION" ]
  then
    echo "$(ts)   Copying the new script to User Dir $CONFIG_DIR/filebot.sh.new"
    echo "$(ts)   Save filebot.sh to reset its timestamp, then restart the container."
    cp /files/filebot.sh $CONFIG_DIR/filebot.sh.new
    exit 1
  fi
}
#---------------------------------------------------------------------------------------------------
function setup_opensubtitles_account {
  . $CONFIG_DIR/filebot.conf

  if [ "$OPENSUBTITLES_USER" != "" ]; then
    echo "$(ts) Configuring for OpenSubtitles user \"$OPENSUBTITLES_USER\""
    echo -en "$OPENSUBTITLES_USER\n$OPENSUBTITLES_PASSWORD\n" | /files/runas.sh $USER_ID $GROUP_ID $UMASK filebot -script fn:configure
  else
    echo "$(ts) No OpenSubtitles user set. Skipping setup..."
  fi
}
#---------------------------------------------------------------------------------------------------
echo "$(ts) start.sh: Starting init ..."
# Create User and make Premissions on Folders
addgroup -g ${GROUP_ID} ${USER_NAME}
adduser -D -u ${USER_ID} -G ${USER_NAME} -h /home/${USER_NAME} -s /bin/sh ${USER_NAME}
mkdir -p ${WATCH_DIR} ${OUTPUT_DIR}
chown -R ${USER_NAME}:${USER_NAME} $WATCH_DIR $OUTPUT_DIR /files /filebot

# Removing potential useless filebot cache and mediainfo libraries that doesn't work on alpine linux.
rm -rf /home/filebot/.filebot/cache/0/github_stable_0.index ./usr/share/filebot/libmediainfo.so ./usr/share/filebot/libzen.so

initialize_configuration
check_filebot_sh_version
#. /files/pre-run.sh  # Download scripts and such.
/files/checkconfig.sh
#setup_opensubtitles_account
chown -R ${USER_NAME}:${USER_NAME} $CONFIG_DIR

#echo "$(ts) start.sh: Running FileBot on startup"
#/files/runas.sh $USER_ID $GROUP_ID $UMASK /files/filebot.sh &
umask $UMASK

exec su -pc "$CONFIG_DIR/filebot.sh" $USER_NAME &

echo "$(ts) start.sh: Starting Monitoring"
exec su -pc "/files/monitor.sh" $USER_NAME