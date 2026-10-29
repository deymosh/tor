#!/bin/bash
# Run Tor as toruser (uid/gid 1000), whatever the data directory was mounted
# from.
#
# Tor refuses a data directory it does not own with mode 0700. A named volume
# seeds from the image with the right owner, but a bind-mounted host folder
# arrives owned by whoever created it on the host (root, on Docker Desktop).
# Started as root, this hands the data directory to toruser, then drops to
# toruser for good before Tor starts. Started as any other user
# (`--user 1000`), it runs Tor as is.
set -euo pipefail

if [ "$(id -u)" != 0 ]; then
    exec tor "$@"
fi

# The directory Tor will use: the last --DataDirectory on the command line,
# else the torrc's, else this user's default.
data_dir=$(sed -n 's/^[[:space:]]*DataDirectory[[:space:]]\+//p' /etc/tor/torrc 2>/dev/null | tail -n 1)
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
    if [ "${args[i]}" = "--DataDirectory" ] && [ $((i + 1)) -lt ${#args[@]} ]; then
        data_dir=${args[i + 1]}
    fi
done
data_dir=${data_dir:-/data/.tor}

mkdir -p "$data_dir"
if [ "$(stat -c %u:%g "$data_dir")" != "1000:1000" ]; then
    chown -R 1000:1000 "$data_dir"
fi
# Tor's own requirement; DataDirectoryGroupReadable relaxes it to 0750 itself.
chmod u+rwx,o-rwx "$data_dir"

exec setpriv --reuid=1000 --regid=1000 --init-groups tor "$@"
