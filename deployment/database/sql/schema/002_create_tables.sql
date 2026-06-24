SET search_path TO api, public;


CREATE TABLE IF NOT EXISTS dimensions (
  id SERIAL PRIMARY KEY,
  identifier VARCHAR NOT NULL UNIQUE,
  name VARCHAR NOT NULL,
  description TEXT,
  status VARCHAR,
  source JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS indicators (
  id SERIAL PRIMARY KEY,
  identifier VARCHAR NOT NULL UNIQUE,
  name VARCHAR NOT NULL,
  description TEXT,
  status VARCHAR,
  quality_dimension VARCHAR,
  contact JSONB,
  source JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS assessment_raw (
  id SERIAL PRIMARY KEY,
  payload JSONB NOT NULL,
  created_by BIGINT,
  project_id BIGINT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE assessment_raw ADD COLUMN IF NOT EXISTS project_id BIGINT;
CREATE INDEX IF NOT EXISTS idx_assessment_raw_project_id ON assessment_raw(project_id);

DROP VIEW IF EXISTS software_languages;
DROP TABLE IF EXISTS software_metadata CASCADE;

DROP VIEW IF EXISTS assessment;
CREATE VIEW assessment AS
SELECT
  id,
  payload->>'@context' AS "@context",
  payload->>'@type' AS "@type",
  payload->>'@id' AS "@id",
  payload->>'dateCreated' AS "dateCreated",
  payload->>'license' AS license,
  payload->'author' AS author,
  payload->'creator' AS creator,
  payload->'assessedSoftware' AS "assessedSoftware",
  payload->'checks' AS checks,
  created_at
FROM assessment_raw;
