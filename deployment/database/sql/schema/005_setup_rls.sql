SET search_path TO api, public;

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

ALTER TABLE dimensions ENABLE ROW LEVEL SECURITY;
ALTER TABLE indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_raw ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS read_dimensions ON dimensions;
CREATE POLICY read_dimensions ON dimensions FOR SELECT TO web_anon, web_user USING (true);

DROP POLICY IF EXISTS read_indicators ON indicators;
CREATE POLICY read_indicators ON indicators FOR SELECT TO web_anon, web_user USING (true);

CREATE OR REPLACE FUNCTION is_project_public(pid BIGINT)
RETURNS BOOLEAN AS $$
  SELECT COALESCE(
    (SELECT is_public FROM auth.projects WHERE id = pid),
    false
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

DROP POLICY IF EXISTS read_assessment ON assessment_raw;
DROP POLICY IF EXISTS read_assessment_public ON assessment_raw;
CREATE POLICY read_assessment_public ON assessment_raw FOR SELECT TO web_anon, web_user
  USING (
    (project_id IS NULL AND created_by IS NULL)
    OR (project_id IS NOT NULL AND is_project_public(project_id))
  );

DROP POLICY IF EXISTS read_assessment_own ON assessment_raw;
CREATE POLICY read_assessment_own ON assessment_raw FOR SELECT TO web_user
  USING (created_by IS NOT NULL AND created_by = current_user_id());

ALTER TABLE auth.projects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS read_projects ON auth.projects;
CREATE POLICY read_projects ON auth.projects FOR SELECT TO web_anon, web_user
  USING (is_public OR (owner_user_id IS NOT NULL AND owner_user_id = api.current_user_id()));

DROP POLICY IF EXISTS write_dimensions ON dimensions;
CREATE POLICY write_dimensions ON dimensions FOR ALL TO web_user
  USING (is_authenticated()) WITH CHECK (is_authenticated());

DROP POLICY IF EXISTS write_indicators ON indicators;
CREATE POLICY write_indicators ON indicators FOR ALL TO web_user
  USING (is_authenticated()) WITH CHECK (is_authenticated());

DROP POLICY IF EXISTS write_assessment ON assessment_raw;
DROP POLICY IF EXISTS insert_assessment ON assessment_raw;
CREATE POLICY insert_assessment ON assessment_raw FOR INSERT TO web_user
  WITH CHECK (is_authenticated());
