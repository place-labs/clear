FROM crystallang/crystal:1.0.0-alpine

WORKDIR /

COPY shard.yml /
RUN shards install --ignore-crystal-version

COPY spec /spec
COPY src /src

ENTRYPOINT crystal spec -Dquiet --warnings=all