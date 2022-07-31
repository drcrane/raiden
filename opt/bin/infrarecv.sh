#!/bin/sh
# Allow updates to be sent over ssh in compressed tar file then
# script executed on host to perform required actions
# deployonhost.sh should be present and executable in the delivered
# update.
# Example execution
# cat deployarchive.tar.bz2 |ssh -i id_ed25519 -p ${RHOSTPORT} \
#     ${RUSERNAME}@${RHOSTNAME} /opt/bin/infrarecv.sh
cd /tmp
if [ -d deploy ] ; then
	rm -r deploy
fi
if [ -f deploy ] ; then
	rm deploy
fi
mkdir deploy
cd deploy
tar -xjv
./deployonhost.sh
