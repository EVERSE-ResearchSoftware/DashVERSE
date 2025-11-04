-- create api schema for PostgREST
CREATE SCHEMA IF NOT EXISTS api;

-- set schema description for PostgREST OpenAPI
COMMENT ON SCHEMA api IS 'DashVERSE API - REST interface for research software quality assessments. Provides access to software metadata, quality indicators, dimensions, and assessment results from the EVERSE framework.';

-- create auth schema for authentication service
CREATE SCHEMA IF NOT EXISTS auth;

SET search_path TO api, public;

-- roles for PostgREST
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'web_anon') THEN
    CREATE ROLE web_anon NOLOGIN;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'web_user') THEN
    CREATE ROLE web_user NOLOGIN;
  END IF;
END
$$;

GRANT USAGE ON SCHEMA api TO web_anon;
GRANT USAGE ON SCHEMA api TO web_user;
