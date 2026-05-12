FROM debian:bullseye-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG TEMPORAL_CLI_VERSION=1.4.0
ENV TEMPORAL_CLI_VERSION=${TEMPORAL_CLI_VERSION}
ENV DB_FILE=/data/temporal_file.db
ENV UI_PORT=8080
ENV HEADLESS=false

# Download and install Temporal CLI
ARG TARGETPLATFORM
RUN case ${TARGETPLATFORM} in \
        "linux/amd64") ARCH="amd64" ;; \
        "linux/arm64") ARCH="arm64" ;; \
    esac \
    && curl -L https://github.com/temporalio/cli/releases/download/v${TEMPORAL_CLI_VERSION}/temporal_cli_${TEMPORAL_CLI_VERSION}_linux_${ARCH}.tar.gz \
    -o /tmp/temporal.tar.gz && \
    tar -xzf /tmp/temporal.tar.gz -C /usr/local/bin && \
    rm /tmp/temporal.tar.gz

# Create directory for DB (to support volumes)
RUN mkdir -p /data

# Expose Temporal gRPC port and UI port
EXPOSE 7233
EXPOSE ${UI_PORT}

# Add entrypoint script using EOF syntax
RUN cat << 'EOF' > /entrypoint.sh
#!/bin/sh
set -e

# Build optional flags
FLAGS="--ip 0.0.0.0 --db-filename ${DB_FILE} --ui-port ${UI_PORT}"

if [ "${HEADLESS}" = "true" ]; then
FLAGS="${FLAGS} --headless"
fi

# Start Temporal dev server
temporal server start-dev ${FLAGS} &

# Keep container alive with server process
wait
EOF

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
