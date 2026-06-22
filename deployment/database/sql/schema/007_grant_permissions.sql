SET search_path TO api, public;

GRANT SELECT ON ALL TABLES IN SCHEMA api TO web_anon;
GRANT SELECT ON assessment TO web_anon;

GRANT ALL ON ALL TABLES IN SCHEMA api TO web_user;
GRANT INSERT, SELECT ON assessment TO web_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA api TO web_user;

GRANT SELECT ON catalog_coverage TO web_anon, web_user;
GRANT SELECT ON catalog_coverage_breakdown TO web_anon, web_user;
GRANT SELECT ON indicators_flat TO web_anon, web_user;
GRANT SELECT ON dimensions_with_links TO web_anon, web_user;
GRANT SELECT ON assessment_checks TO web_anon, web_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT SELECT ON TABLES TO web_anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT ALL ON TABLES TO web_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT USAGE, SELECT ON SEQUENCES TO web_user;

GRANT USAGE ON SCHEMA auth TO web_anon, web_user;
GRANT SELECT ON auth.projects TO web_anon, web_user;
GRANT SELECT ON projects TO web_anon, web_user;
GRANT SELECT (id, username) ON auth.users TO web_anon, web_user;

GRANT EXECUTE ON FUNCTION current_user_id() TO web_anon, web_user;
GRANT EXECUTE ON FUNCTION is_authenticated() TO web_anon, web_user;
GRANT EXECUTE ON FUNCTION check_outcome(jsonb) TO web_anon, web_user;
GRANT EXECUTE ON FUNCTION resolve_dimension_id(VARCHAR) TO web_anon, web_user;
GRANT EXECUTE ON FUNCTION project_visibility(BIGINT) TO web_anon, web_user;
GRANT EXECUTE ON FUNCTION assessment_visibility(TEXT, BIGINT) TO web_anon, web_user;
