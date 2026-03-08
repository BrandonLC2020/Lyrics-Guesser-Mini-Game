FROM python:3.14-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy application files
COPY pyproject.toml README.md ./

# Since poetry export is not available, we can just install directly from pyproject.toml
# Or we can just list the dependencies we need for the runtime.
RUN pip install --no-cache-dir \
    "fastapi>=0.128.0,<0.129.0" \
    "uvicorn>=0.40.0,<0.41.0" \
    "httpx>=0.28.1,<0.29.0" \
    "thefuzz>=0.22.1,<0.23.0" \
    "itsdangerous>=2.2.0,<3.0.0" \
    "python-multipart>=0.0.21,<0.0.22" \
    "mangum>=0.19.0,<0.20.0" \
    "awslambdaric"

FROM python:3.14-slim

WORKDIR /var/task

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.14/site-packages /usr/local/lib/python3.14/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY app ./app

# Set the handler
# For custom runtimes, we use the RIC as the entrypoint
ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "app.main.handler" ]
