# Build stage
FROM rust:1.85-bookworm as builder

WORKDIR /app

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Copy schema
COPY schema.sql ./

# Copy source code
COPY src ./src

# Build for release
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy the binary from builder
COPY --from=builder /app/target/release/backend /app/backend

# Create directory for database and photos with proper permissions
RUN mkdir -p /var/lib/personal-website/photos && \
    chmod -R 755 /var/lib/personal-website

# Expose port
EXPOSE 8080

# Run the binary
CMD ["/app/backend"]
