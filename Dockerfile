FROM openjdk:8-alpine

ENV FILEBOT_VER="4.7.9" \
	CONFIG_DIR="/config" \
	CONFIG_FILE="/config/filebot.conf" \
	USER_ID="1000" \
	GROUP_ID="1000" \
	USER_NAME="filebot" \
	WATCH_DIR="/input" \
    OUTPUT_DIR="/output"

# Install bash inotify-tools mediainfo mutt procps grep
RUN 	echo http://dl-cdn.alpinelinux.org/alpine/edge/main>>/etc/apk/repositories && \ 
	echo http://dl-cdn.alpinelinux.org/alpine/edge/community>>/etc/apk/repositories && \
	apk add --no-cache \
		bash \
		mediainfo \
		inotify-tools \
		mutt \
		procps \
		grep && \
# Cleanning
    rm -rf /var/cache/apk/* /tmp/*

ADD https://sourceforge.net/projects/filebot/files/filebot/FileBot_${FILEBOT_VER}/FileBot_${FILEBOT_VER}-portable.tar.xz/download /filebot/filebot.tar.xz

RUN tar -xJf /filebot/filebot.tar.xz -C /filebot && \
	rm -f /filebot/filebot.tar.xz

# Add scripts. Make sure start.sh, and filebot.sh are executable by $USER_ID
ADD start.sh /start.sh
ADD filebot.sh /files/filebot.sh
ADD filebot.conf /files/filebot.conf
ADD monitor.sh /files/monitor.sh
ADD checkconfig.sh /files/checkconfig.sh

RUN \
    chmod a+x /start.sh \
    && chmod a+wx /files/filebot.sh \
    && chmod a+w /files/filebot.conf \
    && chmod +x /files/monitor.sh \
    && chmod +x /files/checkconfig.sh

ENTRYPOINT ["/start.sh"]
