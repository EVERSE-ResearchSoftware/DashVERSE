SET search_path TO api, public;

CREATE OR REPLACE VIEW software AS
SELECT
  COALESCE(
    a.payload->'assessedSoftware'->'schema:identifier'->>'@id',
    a.payload->'assessedSoftware'->>'name'
  ) AS identifier,
  a.payload->'assessedSoftware'->>'name' AS name,
  MAX(a.payload->'assessedSoftware'->>'softwareVersion') AS latest_version,
  MAX(a.payload->'assessedSoftware'->>'url') AS url,
  a.payload->'assessedSoftware'->'schema:identifier'->>'@id' AS doi,
  MIN(a.created_at) AS first_seen,
  MAX(a.created_at) AS last_seen,
  COUNT(DISTINCT a.id) AS assessment_count,
  m.programming_language,
  m.description,
  m.homepage_url
FROM assessment_raw a
LEFT JOIN software_metadata m
  ON m.identifier = COALESCE(
       a.payload->'assessedSoftware'->'schema:identifier'->>'@id',
       a.payload->'assessedSoftware'->>'name'
     )
GROUP BY 1, 2, 5, m.programming_language, m.description, m.homepage_url;

CREATE OR REPLACE VIEW assessments_detailed AS
SELECT
  a.id,
  a.payload->>'dateCreated' AS date_created,
  a.payload->'assessedSoftware'->>'name' AS software_name,
  COALESCE(
    a.payload->'assessedSoftware'->'schema:identifier'->>'@id',
    a.payload->'assessedSoftware'->>'name'
  ) AS software_id,
  jsonb_array_length(a.payload->'checks') AS total_checks,
  a.created_at,
  COALESCE(a.payload->'creator'->>'name', a.payload->'author'->>'name') AS creator_name,
  a.payload->'license'->>'@id' AS license_id
FROM assessment_raw a;

CREATE OR REPLACE VIEW checks_detailed AS
SELECT
  a.id AS assessment_id,
  a.payload->'assessedSoftware'->>'name' AS software_name,
  COALESCE(
    a.payload->'assessedSoftware'->'schema:identifier'->>'@id',
    a.payload->'assessedSoftware'->>'name'
  ) AS software_id,
  CASE
    WHEN a.payload->>'dateCreated' IS NOT NULL AND a.payload->>'dateCreated' != ''
    THEN (a.payload->>'dateCreated')::TIMESTAMP
    ELSE NULL
  END AS assessment_dttm,
  check_item->'checkingSoftware'->>'name' AS checking_software,
  check_item->'status'->>'@id' AS status,
  check_item->>'output' AS output,
  check_item->>'evidence' AS evidence,
  i.name AS indicator_name,
  d.name AS dimension_name,
  d.identifier AS dimension_id,
  COALESCE(a.payload->'creator'->>'name', a.payload->'author'->>'name') AS creator_name,
  check_outcome(check_item) AS outcome
FROM assessment_raw a
CROSS JOIN LATERAL jsonb_array_elements(a.payload->'checks') AS check_item
LEFT JOIN indicators i ON split_part(check_item->'assessesIndicator'->>'@id', '/', -1) = i.identifier
LEFT JOIN dimensions d ON d.identifier = resolve_dimension_id(i.quality_dimension);


CREATE OR REPLACE VIEW dimension_coverage AS
SELECT
  cd.dimension_name,
  cd.dimension_id,
  COUNT(*) FILTER (WHERE cd.outcome = 'pass') AS passed,
  ROUND(100.0 * COUNT(*) FILTER (WHERE cd.outcome = 'pass')
                / NULLIF(COUNT(*), 0), 2) AS pass_rate
FROM checks_detailed cd
WHERE cd.dimension_name IS NOT NULL
GROUP BY cd.dimension_name, cd.dimension_id;

CREATE OR REPLACE VIEW software_quality_scores AS
SELECT
  cd.software_name,
  cd.software_id,
  cd.dimension_name,
  ROUND(100.0 * COUNT(*) FILTER (WHERE cd.outcome = 'pass')
                / NULLIF(COUNT(*), 0), 2) AS score,
  MAX(cd.assessment_dttm) AS last_assessed_date
FROM checks_detailed cd
WHERE cd.dimension_name IS NOT NULL
GROUP BY cd.software_name, cd.software_id, cd.dimension_name;

CREATE OR REPLACE VIEW assessment_trends AS
SELECT
  date_trunc('month', (a.payload->>'dateCreated')::timestamp) AS month,
  COUNT(DISTINCT a.id) AS assessments
FROM assessment_raw a
GROUP BY date_trunc('month', (a.payload->>'dateCreated')::timestamp)
ORDER BY month;

CREATE OR REPLACE VIEW dimension_trend AS
SELECT
  date_trunc('month', cd.assessment_dttm) AS month,
  cd.dimension_name,
  cd.dimension_id,
  COUNT(*) AS total_checks,
  COUNT(*) FILTER (WHERE cd.outcome = 'pass') AS passed,
  ROUND(100.0 * COUNT(*) FILTER (WHERE cd.outcome = 'pass')
                / NULLIF(COUNT(*), 0), 2) AS pass_rate
FROM checks_detailed cd
WHERE cd.dimension_name IS NOT NULL
GROUP BY 1, 2, 3;

CREATE OR REPLACE VIEW software_history AS
SELECT
  cd.software_name,
  cd.software_id,
  date_trunc('month', cd.assessment_dttm) AS month,
  COUNT(DISTINCT cd.assessment_id) AS assessments_in_month,
  COUNT(*) AS total_checks,
  COUNT(*) FILTER (WHERE cd.outcome = 'pass') AS passed,
  COUNT(DISTINCT cd.dimension_name) AS dimensions_covered,
  ROUND(100.0 * COUNT(*) FILTER (WHERE cd.outcome = 'pass')
                / NULLIF(COUNT(*), 0), 2) AS pass_rate
FROM checks_detailed cd
GROUP BY cd.software_name, cd.software_id, 3;

CREATE OR REPLACE VIEW tool_reliability AS
SELECT
  cd.checking_software,
  COUNT(*) AS total_checks,
  COUNT(*) FILTER (WHERE cd.outcome = 'pass') AS passed,
  COUNT(*) FILTER (WHERE cd.outcome = 'fail') AS failed,
  COUNT(*) FILTER (WHERE cd.outcome NOT IN ('pass', 'fail')) AS other,
  ROUND(100.0 * COUNT(*) FILTER (WHERE cd.outcome = 'pass')
                / NULLIF(COUNT(*), 0), 2) AS success_rate
FROM checks_detailed cd
WHERE cd.checking_software IS NOT NULL
GROUP BY cd.checking_software;

CREATE OR REPLACE VIEW compliance_status AS
SELECT
  sqs.software_name,
  sqs.software_id,
  sqs.dimension_name,
  sqs.score AS pass_rate,
  (sqs.score >= 75) AS above_threshold
FROM software_quality_scores sqs;

DROP VIEW IF EXISTS software_languages;
CREATE VIEW software_languages AS
SELECT
  sm.identifier AS software_identifier,
  lang AS language
FROM software_metadata sm, UNNEST(sm.programming_language) AS lang
WHERE sm.programming_language IS NOT NULL;

CREATE OR REPLACE VIEW common_issues AS
SELECT
  cd.indicator_name,
  cd.dimension_name,
  COUNT(*) AS failure_count,
  i.description AS what_to_improve,
  i.source->>'@id' AS indicator_url,
  'https://everse.software/RSQKit/' || COALESCE(d.identifier, '') AS rsqkit_url
FROM checks_detailed cd
LEFT JOIN indicators i ON i.name = cd.indicator_name
LEFT JOIN dimensions d ON d.name = cd.dimension_name
WHERE cd.outcome = 'fail'
  AND cd.indicator_name IS NOT NULL
GROUP BY cd.indicator_name, cd.dimension_name, i.description, i.source, d.identifier
ORDER BY failure_count DESC;
