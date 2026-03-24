SET search_path TO api, public;

-- updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- apply to tables with updated_at
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

-- assessment view insert trigger (for resqui)
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
