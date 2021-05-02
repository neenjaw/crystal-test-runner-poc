FROM crystallang/crystal:1.0.0-alpine

# install packages required to run the tests
RUN apk add --no-cache bash jq coreutils

WORKDIR /opt/test-runner
COPY . .

RUN ./bin/build.sh

ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
