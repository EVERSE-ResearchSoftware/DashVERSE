SET search_path TO api, public;

-- read access for anonymous users
GRANT SELECT ON ALL TABLES IN SCHEMA api TO web_anon;
GRANT SELECT ON assessment TO web_anon;

-- full access for authenticated users
GRANT ALL ON ALL TABLES IN SCHEMA api TO web_user;
GRANT INSERT, SELECT ON assessment TO web_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA api TO web_user;

-- dashboard views
GRANT SELECT ON assessments_detailed TO web_anon, web_user;
GRANT SELECT ON checks_detailed TO web_anon, web_user;
GRANT SELECT ON assessment_summary TO web_anon, web_user;
GRANT SELECT ON dimension_coverage TO web_anon, web_user;
GRANT SELECT ON indicator_results TO web_anon, web_user;
GRANT SELECT ON software_quality_scores TO web_anon, web_user;
GRANT SELECT ON assessment_trends TO web_anon, web_user;
GRANT SELECT ON common_issues TO web_anon, web_user;

-- default privileges for new objects
ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT SELECT ON TABLES TO web_anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT ALL ON TABLES TO web_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT USAGE, SELECT ON SEQUENCES TO web_user;

-- function permissions
GRANT EXECUTE ON FUNCTION current_user_id() TO web_anon, web_user;
GRANT EXECUTE ON FUNCTION is_authenticated() TO web_anon, web_user;
