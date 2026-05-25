FROM rust:1.81 as builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/cybertranspay-routing /usr/local/bin/
CMD ["cybertranspay-routing"]
