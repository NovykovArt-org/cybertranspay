FROM rust:1.81 as builder
WORKDIR /app

# Копіюємо workspace файли
COPY ../../Cargo.toml ../../Cargo.lock* ../..

# Копіюємо код сервісу
COPY backend/routing-engine ./backend/routing-engine

# Будуємо
RUN cargo build --release -p routing-engine

# === Runtime stage ===
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/routing-engine /usr/local/bin/cybertranspay-routing

CMD ["cybertranspay-routing"]
