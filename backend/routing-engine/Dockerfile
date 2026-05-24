FROM rust:1-bookworm AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY routing-engine ./routing-engine
RUN cargo build --release -p routing-engine

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/routing-engine /usr/local/bin/routing-engine
EXPOSE 8080
CMD ["routing-engine"]
