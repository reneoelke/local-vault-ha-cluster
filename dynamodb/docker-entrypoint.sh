#!/bin/bash
set -e

exec java -Djava.library.path=. -jar DynamoDBLocal.jar -dbPath ${DYNAMODB_DB_PATH} -sharedDb -port 8000
