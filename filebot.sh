#!/bin/bash
PRG="$0"

#-----------------------------------------------------------------------------------------------------------------------

function ts {
  echo [`date '+%Y-%m-%d %T'`] filebot.sh:
}

#-----------------------------------------------------------------------------------------------------------------------

# resolve relative symlinks
while [ -h "$PRG" ] ; do
	ls=`ls -ld "$PRG"`
	link=`expr "$ls" : '.*-> \(.*\)$'`
	if expr "$link" : '/.*' > /dev/null; then
		PRG="$link"
	else
		PRG="`dirname "$PRG"`/$link"
	fi
done

# get canonical path
WORKING_DIR=`pwd`
PRG_DIR=`dirname "$PRG"`
APP_ROOT=`cd "$PRG_DIR" && pwd`

#************************************************************************
APP_ROOT='/filebot'
#************************************************************************

# add package lib folder to library path
PACKAGE_LIBRARY_PATH="$APP_ROOT/lib/$(uname -m)"

# restore original working dir
cd "$WORKING_DIR"

# make sure required environment variables are set
if [ -z "$USER" ]; then
	export USER=`whoami`
fi

# force JVM language and encoding settings
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# add APP_ROOT and PACKAGE_LIBRARY_PATH to LD_LIBRARY_PATH
if [ ! -z "$LD_LIBRARY_PATH" ]; then
	export LD_LIBRARY_PATH="$APP_ROOT:$PACKAGE_LIBRARY_PATH:$LD_LIBRARY_PATH"
else
	export LD_LIBRARY_PATH="$APP_ROOT:$PACKAGE_LIBRARY_PATH"
fi

# choose extractor
EXTRACTOR="ApacheVFS"					# use Apache Commons VFS2 with junrar plugin
# EXTRACTOR="SevenZipExecutable"		# use the 7z executable
# EXTRACTOR="SevenZipNativeBindings"	# use the lib7-Zip-JBinding.so native library

# select application data folder
APP_DATA="$APP_ROOT/data"

#************************************************************************

# Used to detect old versions of this script
VERSION=3
# Specify the URLs of any scripts that you need. They will be downloaded into /config/scripts
SCRIPTS_TO_DOWNLOAD=(
# Example:
# https://raw.githubusercontent.com/filebot/scripts/devel/cleaner.groovy
)

QUOTE_FIXER='replaceAll(/[\`\u00b4\u2018\u2019\u02bb]/, "'"'"'").replaceAll(/[\u201c\u201d]/, '"'"'""'"'"')'

# Customize the renaming format here. For info on formatting: https://www.filebot.net/naming.html

MUSIC_FORMAT="Music/{n.$QUOTE_FIXER}/{album.$QUOTE_FIXER}/{media.TrackPosition.pad(2)} - {t.$QUOTE_FIXER}"
MOVIE_FORMAT="Movies/{n.$QUOTE_FIXER} - {y} - {vf}"
SERIES_FORMAT="TV Shows/{n}/S{s.pad(2)}_{vf}/{n} - {S00E00} - {t.${QUOTE_FIXER}}"
ANIME_FORMAT="Anime/{n}/{n} - {absolute} - {t.${QUOTE_FIXER}}"

if [ "$SUBTITLE_LANG" == "" ];then
  SUBTITLE_OPTION=""
else
  SUBTITLE_OPTION="subtitles=$SUBTITLE_LANG"
fi

#************************************************************************

echo "$(ts) *** FileBot AMC script ***"
# start filebot
export JAVA_OPTIONS="$JAVA_OPTIONS -Dunixfs=false \
		-DuseGVFS=false \
		-DuseExtendedFileAttributes=true \
		-DuseCreationDate=false \
		-Djava.net.useSystemProxies=false \
		-Dapplication.deployment=portable \
		-Dfile.encoding=""UTF-8"" \
		-Dsun.jnu.encoding=""UTF-8"" \
		-Djna.nosys=false \
		-Djna.nounpack=true \
		-Dnet.filebot.Archive.extractor=""$EXTRACTOR"" \
		-Dnet.filebot.AcoustID.fpcalc=""fpcalc"" \
		-Dapplication.dir=""$APP_DATA"" \
		-Duser.home=""$APP_DATA"" \
		-Djava.io.tmpdir=""$APP_DATA/tmp"" \
		-Djava.util.prefs.PreferencesFactory=net.filebot.util.prefs.FilePreferencesFactory \
		-Dnet.filebot.util.prefs.file=""$APP_DATA/prefs.properties"""

java 	$JAVA_OPTS \
		-jar "$APP_ROOT/FileBot.jar" \
		-script fn:amc --output $OUTPUT_DIR --log all --log-file $CONFIG_DIR/filebot.log --action move --lang fr --conflict skip -non-strict \
		--def ut_dir=${WATCH_DIR} ut_kind=multi music=y skipExtract=y unsorted=y artwork=n excludeList=$CONFIG_DIR/excludeList.txt reportError=y kodi=192.168.1.3:8080 $SUBTITLE_OPTION \
		movieFormat="$MOVIE_FORMAT" musicFormat="$MUSIC_FORMAT" seriesFormat="$SERIES_FORMAT" animeFormat="$ANIME_FORMAT"
rc=$?
echo "$(ts) *** Done ***"
#************************************************************************
echo "$(ts) *** FileBot Cleaner script ***"
echo "$(ts) *** FileBot Cleaner script ***" >> $CONFIG_DIR/filebot.log
java 	$JAVA_OPTS \
		-jar "$APP_ROOT/FileBot.jar" \
		-script fn:cleaner "$WATCH_DIR" >> $CONFIG_DIR/filebot.log
echo "$(ts) *** Done ***"
#************************************************************************
if [ -f $CONFIG_DIR/muttrc ]
then
	TO=`grep -oP '(?<=to=).*' $CONFIG_DIR/muttrc`
	cat $CONFIG_DIR/muttrc | head -n -1 > $CONFIG_DIR/muttrc1
	if [ $rc -ne 0 ]; then
		echo "$(ts) *** Filebot Error ***"
		cat $CONFIG_DIR/filebot.log | mutt -F $CONFIG_DIR/muttrc1 -s 'Filebot Error' $TO
	else
		if ! grep -q "No files selected for processing" $CONFIG_DIR/filebot.log ; then
			echo "$(ts) *** Filebot successfully ended ***"
			cat $CONFIG_DIR/filebot.log | mutt -F $CONFIG_DIR/muttrc1 -s 'Filebot successfully ended' $TO
		fi
	fi
	rm -rf $CONFIG_DIR/filebot.log $CONFIG_DIR/muttrc1 $CONFIG_DIR/excludeList.txt
else
	echo "$(ts) Unable to find $CONFIG_DIR/muttrc file. Disable email notification.">>$CONFIG_DIR/filebot.log
	echo "$(ts) Unable to find $CONFIG_DIR/muttrc file. Disable email notification."
fi