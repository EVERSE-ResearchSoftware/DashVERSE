# Database tools

This folder contains code to prepare and test the database. It contains SQL scripts to create a database schema and query data.

## Starting and stopping the database

To start run:

```shell
cd server
docker compose up
```

To stop run:

```shell
docker compose down --volumes --remove-orphans
```

## Connecting the database

Install the `postresql` package provided for your sytstem.

To connect to the PostgreSQL server run:

```shell
psql --username root --port 5432 --host 0.0.0.0 everse
```

## Adding the tables to the database

The SQL scripts to create the tables are in `schema` folder. These scripts will create the tables and columns alligned with the schemas defined in <https://github.com/EVERSE-ResearchSoftware/schemas> repository.

## Adding mock data

See [Sample_data.md](Sample_data.md)
