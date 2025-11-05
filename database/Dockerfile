FROM postgres:17

WORKDIR /app

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip

COPY requirements.txt .

# python scripts for ORM-based init
COPY *.py .
COPY everse_db ./everse_db

# sql schema files (applied in order by db-init job)
COPY sql/ ./sql/

CMD ["python3", "main.py"]
