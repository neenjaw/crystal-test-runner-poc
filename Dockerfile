FROM crystallang/crystal:1.0.0-alpine

# TODO: install packages required to run the tests
# RUN apk add --no-cache jq coreutils

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
