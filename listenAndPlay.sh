#!/bin/bash
# Copyright (c) 2016-2020 The Half Duplex Authors. All rights reserved.
#
#  This licence relates to source code for the Battery Controller outined below ("Source Code").
#
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are
#  met:
#
#     * Redistributions of Source Code must retain the above copyright
#  notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#  copyright notice, this list of conditions and the following disclaimer
#  in the documentation and/or other materials provided with the
#  distribution.
#     * Neither the name of Flatmax Pty. Ltd. nor the names of its
#  contributors may be used to endorse or promote products derived from
#  this software without specific prior written permission.
#
#  THIS Source Code IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS Source Code, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# check that the source host was supplied
usage_msg="ipAddress:port hostName:port"

# basic setup ...
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/utils.sh"

export TERM=dumb

# loop listening for commands ...
MSG="Remember : b for button, r for release, x to exit"
echo $MSG

while read line; do
case $line in
"b")
	echo button pressed :
	# test if we are already listening to someone else
	alreadyPlaying=`ssh $2 ps cax | grep -c $3`
	if [ "$alreadyPlaying" -eq 0 ]; then
		if [ -z $FFPLAY_PID ]; then
			# start remote stream

			ssh $2 "screen -d -m $FFMPEG -f $DEVICE -ac 1 -ar 8000 -i $INPUT -acodec $CODEC -f rtp rtp://$LOCAL_IP:$PORT"
			$FFPLAY -showmode 0 rtp://$1 2> /dev/null &
			FFPLAY_PID=$!
			sleep 0.5
			echo $LOCAL_IP is playing from $1
			echo $MSG
		else
			echo already playing, can\'t request button push
		fi
	else
		echo already listening to someone else, can\'t request button push
	fi
;;
"r")
		if [ ! -z $FFPLAY_PID ]; then
			echo button release
			kill -9 $FFPLAY_PID
			FFPLAY_PID=
			ssh $2 "killall screen"
			sleep 0.5
		else
			echo can\'t release the button, not pressed
		fi
;;
"x")
	echo exiting
break
;;
esac
 done < /dev/stdin

ssh $2 "killall screen"

echo listenAndPlay exited loop
kill -SIGHUP $PPID
