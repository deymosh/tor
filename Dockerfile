# deymosh/tor - Tor from the Tor Project's own Debian repository.
#
# A maintained, drop-in replacement for lncm/tor (unmaintained; last image
# Tor 0.4.7 on Debian 11, both EOL). Same runtime contract:
#   - runs as toruser, uid/gid 1000, home /data
#   - DataDirectory /data/.tor exists, owned 1000:1000, mode 0750, so a named
#     volume mounted there seeds with that ownership, and a group-readable
#     control cookie (CookieAuthFileGroupReadable) works for gid-1000 readers
#   - entrypoint `tor`, which reads /etc/tor/torrc (bind-mount your own)
#   - bash + coreutils (timeout) available for healthchecks
#
# Build args are pinned; bump TOR_VERSION (and the base digest) together with
# a new tag. The Tor Project repo keeps only the current release, so a stale
# pin fails the build loudly instead of silently installing something else.
FROM debian:trixie-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a

ARG TOR_VERSION=0.4.9.13-1~d13.trixie+1
# Tor Project archive signing key (https://support.torproject.org/apt/tor-deb-repo/).
# The downloaded key is trusted only if its fingerprint matches this.
ARG TOR_KEY_FPR=A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gpg; \
    curl -fsSL "https://deb.torproject.org/torproject.org/${TOR_KEY_FPR}.asc" -o /tmp/tor.asc; \
    gpg --show-keys --with-colons /tmp/tor.asc | awk -F: '$1=="fpr"{print $10; exit}' | grep -qx "$TOR_KEY_FPR"; \
    gpg --dearmor < /tmp/tor.asc > /usr/share/keyrings/tor-archive-keyring.gpg; \
    . /etc/os-release; \
    echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org ${VERSION_CODENAME} main" \
        > /etc/apt/sources.list.d/tor.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends "tor=${TOR_VERSION}"; \
    apt-get purge -y --auto-remove curl gpg; \
    rm -rf /var/lib/apt/lists/* /tmp/tor.asc

RUN groupadd -g 1000 toruser \
    && useradd -u 1000 -g 1000 -d /data -s /usr/sbin/nologin toruser \
    && mkdir -p /data/.tor \
    && chown 1000:1000 /data/.tor \
    && chmod 0750 /data/.tor

USER toruser
ENTRYPOINT ["tor"]
