SET search_path TO api, public;

-- software table
CREATE TABLE IF NOT EXISTS software (
  id SERIAL PRIMARY KEY,
  identifier VARCHAR NOT NULL UNIQUE,
  name VARCHAR NOT NULL,
  description TEXT,
  version VARCHAR,
  license VARCHAR,
  repository_url VARCHAR,
  homepage_url VARCHAR,
  programming_language VARCHAR[],
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- dimensions table
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

-- indicators table
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

-- base table for assessment storage (resqui compatible)
CREATE TABLE IF NOT EXISTS assessment_raw (
  id SERIAL PRIMARY KEY,
  payload JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- view for resqui compatibility
-- PostgREST exposes this as /assessment endpoint
CREATE OR REPLACE VIEW assessment AS
SELECT
  id,
  payload->>'@context' AS "@context",
  payload->>'@type' AS "@type",
  payload->>'@id' AS "@id",
  payload->>'dateCreated' AS "dateCreated",
  payload->>'license' AS license,
  payload->'author' AS author,
  payload->'assessedSoftware' AS "assessedSoftware",
  payload->'checks' AS checks,
  created_at
FROM assessment_raw;
