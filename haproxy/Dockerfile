FROM haproxy:1.6.9
MAINTAINER René Oelke <rene.oelke@foobugs.com>

RUN rm -fv /usr/local/etc/haproxy/haproxy.cfg
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

EXPOSE 8200
