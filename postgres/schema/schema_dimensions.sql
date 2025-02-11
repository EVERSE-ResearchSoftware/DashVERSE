-- https://github.com/EVERSE-ResearchSoftware/schemas/tree/main/quality_dimensions

CREATE SEQUENCE IF NOT EXISTS dimensions_id_seq;

CREATE TABLE IF NOT EXISTS dimensions (
  id bigint NOT NULL PRIMARY KEY DEFAULT nextval('dimensions_id_seq'),
  identifier text NOT NULL UNIQUE,
  name text NOT NULL,
  description text NOT NULL,
  source text[] UNIQUE
);
