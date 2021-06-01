FROM maxmindinc/geoipupdate:latest

COPY ./GeoIP.conf /sentry/GeoIP.conf
COPY ./GeoLite2-City.mmdb.empty /sentry/GeoLite2-City.mmdb

ENTRYPOINT ["/usr/bin/geoipupdate", "-d", "/sentry", "-f", "/sentry/GeoIP.conf"]
