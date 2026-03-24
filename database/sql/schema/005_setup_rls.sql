SET search_path TO api, public;

-- jwt helper functions
CREATE OR REPLACE FUNCTION current_user_id()
RETURNS INTEGER AS $$
BEGIN
  RETURN NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::INTEGER;
EXCEPTION
  WHEN OTHERS THEN RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_authenticated()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN current_user_id() IS NOT NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- enable RLS on tables
ALTER TABLE software ENABLE ROW LEVEL SECURITY;
ALTER TABLE dimensions ENABLE ROW LEVEL SECURITY;
ALTER TABLE indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_raw ENABLE ROW LEVEL SECURITY;

-- public read policies
DROP POLICY IF EXISTS read_software ON software;
CREATE POLICY read_software ON software FOR SELECT TO web_anon, web_user USING (true);

DROP POLICY IF EXISTS read_dimensions ON dimensions;
CREATE POLICY read_dimensions ON dimensions FOR SELECT TO web_anon, web_user USING (true);

DROP POLICY IF EXISTS read_indicators ON indicators;
CREATE POLICY read_indicators ON indicators FOR SELECT TO web_anon, web_user USING (true);

DROP POLICY IF EXISTS read_assessment ON assessment_raw;
CREATE POLICY read_assessment ON assessment_raw FOR SELECT TO web_anon, web_user USING (true);

-- authenticated write policies
DROP POLICY IF EXISTS write_software ON software;
CREATE POLICY write_software ON software FOR ALL TO web_user
  USING (is_authenticated()) WITH CHECK (is_authenticated());

DROP POLICY IF EXISTS write_dimensions ON dimensions;
CREATE POLICY write_dimensions ON dimensions FOR ALL TO web_user
  USING (is_authenticated()) WITH CHECK (is_authenticated());

DROP POLICY IF EXISTS write_indicators ON indicators;
CREATE POLICY write_indicators ON indicators FOR ALL TO web_user
  USING (is_authenticated()) WITH CHECK (is_authenticated());

DROP POLICY IF EXISTS write_assessment ON assessment_raw;
CREATE POLICY write_assessment ON assessment_raw FOR ALL TO web_user
  USING (is_authenticated()) WITH CHECK (is_authenticated());
