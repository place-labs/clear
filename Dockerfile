FROM crystallang/crystal:0.36.1-alpine

WORKDIR /

COPY shard.yml /
RUN shards install --ignore-crystal-version

COPY spec /spec
COPY src /src

ENTRYPOINT crystal spec -Dquiet --warnings=all