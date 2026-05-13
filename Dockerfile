FROM docker.io/library/alpine:latest

RUN set -ex;\
    addgroup -g 1001 dockerstack;\
    adduser -D -H -S -s /usr/sbin/nologin -u 1001 -G dockerstack dockeruser;\
    mkdir -vp /var/lib/confsmanager/input /var/lib/confsmanager/output;\
    chown -vR 1001:1001 /var/lib/confsmanager/

COPY --chown=1001:1001 ./input/ /var/lib/confsmanager/input/
COPY --chown=1001:1001 --chmod=0750 ./confsmanager.sh /usr/local/bin/

RUN ls -al /var/lib/confsmanager/* /usr/local/bin/

VOLUME /var/lib/confsmanager/output

USER 1001:1001

ENTRYPOINT ["/usr/local/bin/confsmanager.sh"]

# TODO: HEALTHCHECK certificates
