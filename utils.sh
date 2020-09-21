#!/bin/bash
# Author : Matt Flax <flatmax@flatmax.com>
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

# define the codec
CODEC=pcm_alaw

# check that the target host was supplied
if [ $# -lt 1 ]; then
    echo usage:
    for msg in $usage_msg; do
    	echo $0 $msg
    done
    exit 1
fi


# find the local IP and define the streaming port
LOCAL_IP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
PORT=48111

# get the remote hostname/ip
REMOTE_HOST=`echo $REMOTE_URL | sed 's/^.*\@//'`

# define the audio device for this architecture
PULSE_PRESENT=`ps ax | grep pulse | grep -c pulseaudio`
if [ "$PULSE_PRESENT" -gt 1 ]; then
	DEVICE=pulse
	INPUT=default
else
	DEVICE=alsa
	INPUT=plughw
fi

#check screen is installed
SCREEN=`which screen`
if [ -z $SCREEN ]; then
	echo please install screen; echo sudo apt-get install screen
	exit 3
fi

# check ffmpeg is installed
FFMPEG=`which ffmpeg`
if [ -z $FFMPEG ]; then
	FFMPEG=`which avconv`
	if [ -z $FFMPEG ]; then
		echo please install ffmpeg; echo sudo apt-get install ffmpeg
		echo OR please install avconv; echo sudo apt-get install libav-tools
		exit 2
	fi
fi

# check ffplay | avplay is installed
FFPLAY=`which ffplay`
if [ -z $FFPLAY ]; then
	FFPLAY=`which avplay`
	if [ -z $FFPLAY ]; then
		echo please install ffmpeg; echo sudo apt-get install ffmpeg
		echo OR please install avconv; echo sudo apt-get install libav-tools
		exit 1
	fi
fi
FFPLAY_CMD=`basename $FFPLAY`

get_ffplay_pid(){
	FFPLAY_PID=`ps cax | grep $FFPLAY_CMD | awk '{print $1}'`
}

get_ffplay_pid
if [ ! -z $FFPLAY_PID ]; then
	echo WARNING: $FFPLAY is already on this host, I will clobber it as part of my startup
	kill -9 $FFPLAY_PID
fi

check_half_duplex (){
HALFDUPLEX=`basename $0`
HALFDUPLEX_CNT=$(ps cax | grep -c $HALFDUPLEX)
if [ $HALFDUPLEX_CNT -gt '2' ]; then
	echo $0 is only meant to run once on each of two hosts.
	echo please close any processes mentioning $HALFDUPLEX in the command ps, i.e. :
	ps ax | grep $HALFDUPLEX | grep -v grep
	exit 1
fi
}

clobber_encoders(){
FFMPEG_PID=`ps cax | grep $FFMPEG | awk '{print $1}'`
if [ ! -z $FFMPEG_PID ]; then
	echo previous ffmpeg running, killing
	kill -9 $FFMPEG_PID
fi
}
