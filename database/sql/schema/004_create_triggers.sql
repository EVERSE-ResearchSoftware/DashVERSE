SET search_path TO api, public;

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_software_updated ON software;
CREATE TRIGGER tr_software_updated
  BEFORE UPDATE ON software
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

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

CREATE OR REPLACE FUNCTION check_outcome(check_item jsonb) RETURNS TEXT AS $$
DECLARE
  out_val   TEXT := check_item->>'output';
  status_id TEXT := check_item->'status'->>'@id';
BEGIN
  IF status_id LIKE '%FailedActionStatus%' THEN
    RETURN 'fail';
  END IF;

  IF out_val IN ('true', 'valid', 'pass', 'Pass', 'passed') THEN
    RETURN 'pass';
  ELSIF out_val IN ('false', 'invalid', 'fail', 'Fail', 'failed') THEN
    RETURN 'fail';
  ELSIF out_val IN ('n/a', 'na', 'not_applicable', 'NotApplicable', 'NA') THEN
    RETURN 'not_applicable';
  END IF;

  IF status_id LIKE '%Pass%' THEN
    RETURN 'pass';
  ELSIF status_id LIKE '%Fail%' THEN
    RETURN 'fail';
  ELSIF status_id LIKE '%NotApplicable%' THEN
    RETURN 'not_applicable';
  END IF;

  RETURN 'unknown';
END;
$$ LANGUAGE plpgsql IMMUTABLE;
