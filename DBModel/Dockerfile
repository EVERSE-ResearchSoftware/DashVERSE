FROM postgres:17

WORKDIR /app

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip

COPY requirements.txt .

# Copy your Python scripts and submodules
COPY *.py *.json .
COPY everse_db ./everse_db

# Command to execute your Python script (this will be overridden by Kubernetes Job)
CMD ["python3", "main.py", "--config db_config.json"]
