#!/bin/sh
# Fails the build if anything secret-shaped is left in the image.
set -eu
fail=0
for p in /opt/stackurity/secrets /opt/stackurity/.env /root/stackurity-setup.txt; do
  [ -e "$p" ] && { echo "FAIL: $p exists in the image"; fail=1; }
done
[ -z "$(docker ps -aq)" ] || { echo "FAIL: containers exist"; fail=1; }
[ -z "$(docker volume ls -q)" ] || { echo "FAIL: docker volumes exist"; fail=1; }
[ -s /root/.ssh/authorized_keys ] && { echo "FAIL: root authorized_keys not empty"; fail=1; }
exit $fail
