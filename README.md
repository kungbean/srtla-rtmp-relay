# SRTLA & RTMP Relay

Create SRT, SRTLA, and RTMP endpoints to relay your streams.

Stats for SRT streams are availabe from SRT-Live-Server (SLS) via Nginx. Stats for RTMP streams are available via Nginx. Both stats endpoints are behind Nginx, use HTTPS, and require basic authenication.

## Quickstart

These steps are meant to run on a server with a public IP address.

Here we:
* Get SSL certificates through [Certbot](https://certbot.eff.org/) and [LetsEncrypt](https://letsencrypt.org/)
* Deploy SRT, SRTLA, and RTMP endpoints
* Set up SSL auto-renewal

Create a file named `.env` in the repo root with the following environment variables. These values will change things such as the relay ports, stats routes, domain, and basic authenication password.
```bash
# SLS configs
SLS_PORT=30000
SLS_STATS_PORT=8181
SLS_LATENCY=1000
SLS_DOMAIN_PLAYER=play
SLS_DOMAIN_PUBLISHER=publish
SLS_APP_PLAYER=app
SLS_APP_PUBLISHER=app
# SRTLA configs
SRTLA_PORT=30001
# Nginx configs
RTMP_APP=live
SRT_STATS_ROUTE=/srt/stat
RTMP_STATS_ROUTE=/rtmp/stat
RTMP_XSL_STATS_ROUTE=/rtmp/statxsl
# Definitely change these
DOMAIN=localhost
USERNAME=stats
PASSWORD=mySecureStatsPassword
```

Do one of the following
```bash
# Pull public images from Dockerhub
docker compose pull
# Build images locally. Use if you have any code changes
docker compose build
```

Get SSL certificates for the Nginx stats endpoints. You should only need to do this once.
```bash
docker compose up certbot-init
```

Start all services in the background.
```bash
docker compose up -d
```

It's worth checking the logs to see if all the services have started correctly.
```bash
docker compose logs -f
```

Setup certbot to attempt renewing SSL certs every 6 hours in a cronjob. Make sure to change the `cd` to the location where you have the repo.
```bash
crontab -l | { cat; echo "0 */6 * * * cd ~/srtla-rtmp-relay && docker compose run --rm certbot && docker compose exec nginx nginx -s reload"; } | crontab -
```

## URLs

Replace the `ALL_CAPS` values with those from your copy of the `.env` file.
`SOME_ID_FOR_THIS_STREAM` can be replaced with whatever you want. You can relay multiple streams by setting different IDs for each.

The relay ingest urls will be available at the following routes. Use these to stream video to.
* SRT:
  * `url`: `srt://DOMAIN:SLS_PORT`
  * `streamid`: `SLS_DOMAIN_PUBLISHER/SLS_APP_PUBLISHER/SOME_ID_FOR_THIS_STREAM`
* SRTLA:
  * `url`: `srtla://DOMAIN:SRTLA_PORT`
  * `streamid`: `SLS_DOMAIN_PUBLISHER/SLS_APP_PUBLISHER/SOME_ID_FOR_THIS_STREAM`
* RTMP:
  * `url`: `rtmp://DOMAIN/RTMP_APP/SOME_ID_FOR_THIS_STREAM`

The relay playback urls will be available at the following routes. Use these to playback streams in your streaming software.
* SRT/SRTLA: `srt://DOMAIN:SLS_PORT?streamid=SLS_DOMAIN_PLAYER/SLS_APP_PLAYER/SOME_ID_FOR_THIS_STREAM`
* NGINX: `rtmp://DOMAIN/RTMP_APP/SOME_ID_FOR_THIS_STREAM`

The stats urls will be available at the following routes.
* SRT/SRTLA: `https://USERNAME@PASSWORD:DOMAIN/SRT_STATS_ROUTE`
* RTMP: `https://USERNAME@PASSWORD:DOMAIN/RTMP_STATS_ROUTE`

## Teardown

This will stop all the services
```bash
docker compose down
```

If you want to completely uninstall this repo or destory the server, revoke your SSL certs. Also remember to disable the auto-renewal cronjob.
```bash
docker compose run --rm certbot revoke --cert-name ${DOMAIN}
```

# Credits
This project makes use a couple of other projects:
* [Certbot](https://github.com/certbot/certbot)
* [Nginx](https://github.com/nginx/nginx)
* [Nginx RTMP](https://github.com/arut/nginx-rtmp-module)
* [SLS](https://github.com/b3ck/sls-b3ck-edit)
* [SRT](https://github.com/Haivision/srt)
* [SRTLA](https://github.com/BELABOX/srtla)
