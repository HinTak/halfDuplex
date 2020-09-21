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

# target host usage message
usage_msg="user@hostName user@ipAdd"

# do some basic setup
REMOTE_URL=$1
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/utils.sh"

# test that only one instance is running on this host
check_half_duplex

# cleanup residual encoders
clobber_encoders

echo starting streaming on host $LOCAL_IP port $PORT

echo copying scripts over to /tmp on the remote host then executing button handler
scp listenAndPlay.sh utils.sh $1:/tmp
ssh $1 /tmp/listenAndPlay.sh $LOCAL_IP:$PORT `whoami`@$LOCAL_IP $FFPLAY_CMD
