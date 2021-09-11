## builder
FROM crystallang/crystal:1.1.1-alpine as builder

WORKDIR /app

COPY ./shard.yml ./shard.lock /app/
RUN shards install --production -v

COPY . /app/
RUN shards build --static --no-debug --release --production -v

## final
FROM nginx:1.21-alpine
WORKDIR /app
COPY --from=builder /app/bin/* /app/app
ENTRYPOINT ["/app/app"]
