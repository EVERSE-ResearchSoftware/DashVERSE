SET search_path TO api, public;

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_dimensions_updated ON dimensions;
CREATE TRIGGER tr_dimensions_updated
  BEFORE UPDATE ON dimensions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS tr_indicators_updated ON indicators;
CREATE TRIGGER tr_indicators_updated
  BEFORE UPDATE ON indicators
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE FUNCTION assessment_insert_fn()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO assessment_raw (payload) VALUES (
    jsonb_strip_nulls(jsonb_build_object(
      '@context', NEW."@context",
      '@type', NEW."@type",
      '@id', NEW."@id",
      'dateCreated', NEW."dateCreated",
      'license', NEW.license,
      'author', NEW.author,
      'creator', NEW.creator,
      'assessedSoftware', NEW."assessedSoftware",
      'checks', NEW.checks
    ))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS assessment_insert_trigger ON assessment;
CREATE TRIGGER assessment_insert_trigger
INSTEAD OF INSERT ON assessment
FOR EACH ROW EXECUTE FUNCTION assessment_insert_fn();

CREATE OR REPLACE FUNCTION resolve_dimension_id(quality_dim VARCHAR) RETURNS VARCHAR AS $$
DECLARE
  qd_jsonb jsonb;
  raw_ref  TEXT;
BEGIN
  IF quality_dim IS NULL THEN
    RETURN NULL;
  END IF;
  qd_jsonb := quality_dim::jsonb;
  raw_ref := CASE jsonb_typeof(qd_jsonb)
    WHEN 'string' THEN qd_jsonb #>> '{}'
    WHEN 'array'  THEN qd_jsonb->0->>'@id'
    WHEN 'object' THEN qd_jsonb->>'@id'
    ELSE NULL
  END;
  RETURN split_part(raw_ref, '/', -1);
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION check_outcome(check_item jsonb) RETURNS TEXT AS $$
DECLARE
  out_val   TEXT := check_item->>'output';
  status_id TEXT := check_item->'status'->>'@id';
BEGIN
  IF status_id LIKE '%FailedActionStatus%' THEN
    RETURN 'Fail';
  END IF;

  IF out_val IN ('true', 'valid', 'pass', 'Pass', 'passed') THEN
    RETURN 'Pass';
  ELSIF out_val IN ('false', 'invalid', 'fail', 'Fail', 'failed') THEN
    RETURN 'Fail';
  ELSIF out_val IN ('n/a', 'na', 'not_applicable', 'NotApplicable', 'NA',
                    'error', 'Error', 'ERROR') THEN
    RETURN 'Not applicable';
  END IF;

  IF status_id LIKE '%Pass%' THEN
    RETURN 'Pass';
  ELSIF status_id LIKE '%Fail%' THEN
    RETURN 'Fail';
  ELSIF status_id LIKE '%NotApplicable%' THEN
    RETURN 'Not applicable';
  END IF;

  RETURN 'Unknown';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION validate_assessment_payload() RETURNS TRIGGER AS $$
DECLARE
  err TEXT;
  i INTEGER;
  check_item jsonb;
  checks_arr jsonb;
BEGIN
  IF jsonb_typeof(NEW.payload) <> 'object' THEN
    err := 'payload must be a JSON object';
  ELSIF (NEW.payload->>'@context') IS NULL OR (NEW.payload->>'@context') NOT LIKE '%rsqa/%' THEN
    err := '@context is required and must reference the EVERSE rsqa schema';
  ELSIF (NEW.payload->>'@type') <> 'SoftwareQualityAssessment' THEN
    err := '@type must be "SoftwareQualityAssessment"';
  ELSIF (NEW.payload->'assessedSoftware'->>'name') IS NULL THEN
    err := 'assessedSoftware.name is required';
  ELSIF (NEW.payload->'creator'->>'name') IS NULL
     AND (NEW.payload->'author'->>'name') IS NULL THEN
    err := 'creator.name (or legacy author.name) is required';
  ELSIF (NEW.payload->>'dateCreated') IS NULL THEN
    err := 'dateCreated is required';
  ELSIF jsonb_typeof(NEW.payload->'checks') <> 'array' THEN
    err := 'checks must be a JSON array';
  ELSIF jsonb_array_length(NEW.payload->'checks') = 0 THEN
    err := 'checks must not be empty';
  ELSE
    checks_arr := NEW.payload->'checks';
    FOR i IN 0 .. jsonb_array_length(checks_arr) - 1 LOOP
      check_item := checks_arr->i;
      IF (check_item->'assessesIndicator'->>'@id') IS NULL THEN
        err := format('check[%s] requires assessesIndicator.@id', i);
        EXIT;
      ELSIF (check_item->'status'->>'@id') IS NULL THEN
        err := format('check[%s] requires status.@id', i);
        EXIT;
      ELSIF (check_item->>'output') IS NULL THEN
        err := format('check[%s] requires output', i);
        EXIT;
      END IF;
    END LOOP;
  END IF;

  IF err IS NOT NULL THEN
    RAISE EXCEPTION 'invalid assessment payload: %', err
      USING HINT = 'see https://github.com/EVERSE-ResearchSoftware/schemas for the rsqa schema';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_validate_assessment_payload ON assessment_raw;
CREATE TRIGGER tr_validate_assessment_payload
  BEFORE INSERT ON assessment_raw
  FOR EACH ROW EXECUTE FUNCTION validate_assessment_payload();

CREATE OR REPLACE FUNCTION capture_assessment_identity() RETURNS TRIGGER AS $$
DECLARE
  claims JSON;
  uid BIGINT;
  tok_project BIGINT;
BEGIN
  claims := current_setting('request.jwt.claims', true)::json;
  uid := (claims->>'sub')::bigint;
  NEW.created_by := uid;

  IF NEW.project_id IS NULL THEN
    tok_project := (claims->>'project_id')::bigint;
    IF tok_project IS NOT NULL THEN
      SELECT id INTO NEW.project_id
      FROM auth.projects
      WHERE id = tok_project AND owner_user_id = uid
      LIMIT 1;
    END IF;
  END IF;

  IF NEW.project_id IS NULL AND uid IS NOT NULL THEN
    SELECT id INTO NEW.project_id
    FROM auth.projects
    WHERE owner_user_id = uid
    ORDER BY id
    LIMIT 1;
  END IF;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_capture_assessment_identity ON assessment_raw;
CREATE TRIGGER tr_capture_assessment_identity
  BEFORE INSERT ON assessment_raw
  FOR EACH ROW EXECUTE FUNCTION capture_assessment_identity();
