FROM crystallang/crystal:1.0.0-alpine

# TODO: install packages required to run the tests
RUN apk add --no-cache bash

WORKDIR /opt/test-runner
COPY . .

RUN ./bin/build.sh

ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
