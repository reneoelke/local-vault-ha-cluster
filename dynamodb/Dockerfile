FROM peopleperhour/dynamodb:latest
MAINTAINER René Oelke <rene.oelke@foobugs.com>

ENV DYNAMODB_ROOT_PATH /var/dynamodb_wd
ENV DYNAMODB_DB_PATH ${DYNAMODB_ROOT_PATH}/db

RUN mkdir -p ${DYNAMODB_ROOT_PATH} && \
    mkdir -p ${DYNAMODB_DB_PATH}

WORKDIR ${DYNAMODB_ROOT_PATH}

VOLUME ${DYNAMODB_DB_PATH}

EXPOSE 8000

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
