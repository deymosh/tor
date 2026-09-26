# tor

A small, maintained Tor container image: **Tor from the Tor Project's own
Debian repository** on a digest-pinned `debian:trixie-slim`, published for
`linux/amd64` and `linux/arm64`.

```
ghcr.io/deymosh/tor:0.4.9.13     # a Tor release (rebuilt weekly with base-image fixes)
ghcr.io/deymosh/tor:0.4.9        # latest build of that minor line
ghcr.io/deymosh/tor:latest
```

Pin a digest in anything that matters: `ghcr.io/deymosh/tor:0.4.9.13@sha256:…`.
The weekly rebuild produces a new digest under the same tag.

## Drop-in for `lncm/tor`

`lncm/tor` is unmaintained. Its last image ships Tor 0.4.7 on Debian 11, and
both are end-of-life. This image keeps the same runtime contract, so switching
means changing only the `image:` line:

| | |
|---|---|
| User | `toruser`, uid/gid **1000**, home `/data` |
| Data dir | `/data/.tor`, pre-created `1000:1000`, mode `0750`, so a named volume seeds with that ownership |
| Entrypoint | `tor`, which reads `/etc/tor/torrc` (bind-mount your own) |
| Tools | `bash`, coreutils `timeout` (for healthchecks) |

Set `DataDirectory /data/.tor` explicitly in your torrc. It is also Tor's
default for this user (`~/.tor`), but being explicit is safer.

For sharing the control cookie with other gid-1000 containers:

```
CookieAuthentication 1
CookieAuthFile /data/.tor/control_auth_cookie
CookieAuthFileGroupReadable 1
DataDirectoryGroupReadable 1
```

## Example

```yaml
services:
  tor:
    image: ghcr.io/deymosh/tor:0.4.9.13@sha256:<digest>
    restart: unless-stopped
    volumes:
      - ./torrc:/etc/tor/torrc:ro
      - tor-data:/data/.tor
    healthcheck:
      test: ["CMD", "timeout", "5", "bash", "-c", "cat < /dev/null > /dev/tcp/127.0.0.1/9050"]
      interval: 30s
volumes:
  tor-data:
```

## Supply chain

- The base image is pinned by digest, and Tor is pinned to an exact package
  version (`TOR_VERSION` in the `Dockerfile`).
- The Tor Project archive key is trusted only if its fingerprint matches the
  published one (`A3C4 F0F9 79CA A22C DBA8 F512 EE8C BC9E 886D DD89`).
- Images are built by GitHub Actions and carry build provenance and an SBOM.
- Before pushing, CI checks the Tor version and the uid/home/data-dir
  contract, and bootstraps Tor against the live network.

## Updating

- **New Tor release:** set `TOR_VERSION` to the version in
  `https://deb.torproject.org/torproject.org/dists/trixie/main/binary-amd64/Packages`
  and merge. CI publishes the new tags.
- **Base image and actions:** Dependabot opens monthly PRs.
- **Debian security fixes:** picked up by the weekly rebuild, with no change
  needed.

MIT licensed.
