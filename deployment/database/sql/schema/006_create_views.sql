SET search_path TO api, public;

CREATE OR REPLACE VIEW software AS
SELECT
  COALESCE(
    a.payload->'assessedSoftware'->'schema:identifier'->>'@id',
    a.payload->'assessedSoftware'->>'name'
  ) AS identifier,
  a.payload->'assessedSoftware'->>'name' AS name,
  a.payload->'assessedSoftware'->>'name' AS software_name,
  MAX(a.payload->'assessedSoftware'->>'softwareVersion') AS latest_version,
  MAX(a.payload->'assessedSoftware'->>'url') AS url,
  a.payload->'assessedSoftware'->'schema:identifier'->>'@id' AS doi,
  MIN(a.created_at) AS first_seen,
  MAX(a.created_at) AS last_seen,
  COUNT(DISTINCT a.id) AS assessment_count,
  a.project_id,
  p.name AS project_name
FROM assessment_raw a
LEFT JOIN auth.projects p ON p.id = a.project_id
GROUP BY identifier, name, software_name, doi, a.project_id, p.name;

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
  a.payload->'license'->>'@id' AS license_id,
  a.project_id,
  p.name AS project_name
FROM assessment_raw a
LEFT JOIN auth.projects p ON p.id = a.project_id;

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
  check_outcome(check_item) AS outcome,
  a.project_id,
  p.name AS project_name
FROM assessment_raw a
CROSS JOIN LATERAL jsonb_array_elements(a.payload->'checks') AS check_item
LEFT JOIN indicators i ON
     split_part(check_item->'assessesIndicator'->>'@id', '/', -1) = i.identifier
  OR ('software_has_' || split_part(check_item->'assessesIndicator'->>'@id', '/', -1)) = i.identifier
LEFT JOIN dimensions d ON d.identifier = resolve_dimension_id(i.quality_dimension)
LEFT JOIN auth.projects p ON p.id = a.project_id;


CREATE OR REPLACE VIEW dimension_coverage AS
SELECT
  cd.dimension_name,
  cd.dimension_id,
  cd.project_id,
  cd.project_name,
  COUNT(*) FILTER (WHERE cd.outcome = 'pass') AS passed,
  ROUND(100.0 * COUNT(*) FILTER (WHERE cd.outcome = 'pass')
                / NULLIF(COUNT(*), 0), 2) AS pass_rate
FROM checks_detailed cd
WHERE cd.dimension_name IS NOT NULL
GROUP BY cd.dimension_name, cd.dimension_id, cd.project_id, cd.project_name;

CREATE OR REPLACE VIEW software_quality_scores AS
SELECT
  cd.software_name,
  cd.software_id,
  cd.dimension_name,
  cd.project_id,
  cd.project_name,
  ROUND(100.0 * COUNT(*) FILTER (WHERE cd.outcome = 'pass')
                / NULLIF(COUNT(*), 0), 2) AS score,
  MAX(cd.assessment_dttm) AS last_assessed_date
FROM checks_detailed cd
WHERE cd.dimension_name IS NOT NULL
GROUP BY cd.software_name, cd.software_id, cd.dimension_name, cd.project_id, cd.project_name;

CREATE OR REPLACE VIEW assessment_trends AS
SELECT
  date_trunc('month', (a.payload->>'dateCreated')::timestamp) AS month,
  a.project_id,
  p.name AS project_name,
  COUNT(DISTINCT a.id) AS assessments
FROM assessment_raw a
LEFT JOIN auth.projects p ON p.id = a.project_id
GROUP BY 1, a.project_id, p.name
ORDER BY 1;

CREATE OR REPLACE VIEW dimension_trend AS
SELECT
  date_trunc('month', cd.assessment_dttm) AS month,
  cd.dimension_name,
  cd.dimension_id,
  cd.project_id,
  cd.project_name,
  COUNT(*) AS total_checks,
  COUNT(*) FILTER (WHERE cd.outcome = 'pass') AS passed,
  ROUND(100.0 * COUNT(*) FILTER (WHERE cd.outcome = 'pass')
                / NULLIF(COUNT(*), 0), 2) AS pass_rate
FROM checks_detailed cd
WHERE cd.dimension_name IS NOT NULL
GROUP BY 1, 2, 3, cd.project_id, cd.project_name;

CREATE OR REPLACE VIEW software_history AS
SELECT
  cd.software_name,
  cd.software_id,
  cd.project_id,
  cd.project_name,
  date_trunc('month', cd.assessment_dttm) AS month,
  COUNT(DISTINCT cd.assessment_id) AS assessments_in_month,
  COUNT(*) AS total_checks,
  COUNT(*) FILTER (WHERE cd.outcome = 'pass') AS passed,
  COUNT(DISTINCT cd.dimension_name) AS dimensions_covered,
  ROUND(100.0 * COUNT(*) FILTER (WHERE cd.outcome = 'pass')
                / NULLIF(COUNT(*), 0), 2) AS pass_rate
FROM checks_detailed cd
GROUP BY cd.software_name, cd.software_id, cd.project_id, cd.project_name, 5;

CREATE OR REPLACE VIEW tool_reliability AS
SELECT
  cd.checking_software,
  cd.project_id,
  cd.project_name,
  COUNT(*) AS total_checks,
  COUNT(*) FILTER (WHERE cd.outcome = 'pass') AS passed,
  COUNT(*) FILTER (WHERE cd.outcome = 'fail') AS failed,
  COUNT(*) FILTER (WHERE cd.outcome NOT IN ('pass', 'fail')) AS other,
  ROUND(100.0 * COUNT(*) FILTER (WHERE cd.outcome = 'pass')
                / NULLIF(COUNT(*), 0), 2) AS success_rate
FROM checks_detailed cd
WHERE cd.checking_software IS NOT NULL
GROUP BY cd.checking_software, cd.project_id, cd.project_name;

CREATE OR REPLACE VIEW compliance_status AS
SELECT
  sqs.software_name,
  sqs.software_id,
  sqs.dimension_name,
  sqs.project_id,
  sqs.project_name,
  sqs.score AS pass_rate,
  COALESCE(
    NULLIF(current_setting('app.compliance_threshold', true), ''),
    '75'
  )::numeric AS threshold_value,
  (sqs.score >= COALESCE(
    NULLIF(current_setting('app.compliance_threshold', true), ''),
    '75'
  )::numeric) AS above_threshold
FROM software_quality_scores sqs;

DROP VIEW IF EXISTS software_languages;

CREATE OR REPLACE VIEW common_issues AS
SELECT
  cd.indicator_name,
  cd.dimension_name,
  cd.project_id,
  cd.project_name,
  COUNT(*) AS failure_count,
  i.description AS what_to_improve,
  i.source->>'@id' AS indicator_url,
  'https://everse.software/RSQKit/' || COALESCE(d.identifier, '') AS rsqkit_url
FROM checks_detailed cd
LEFT JOIN indicators i ON i.name = cd.indicator_name
LEFT JOIN dimensions d ON d.name = cd.dimension_name
WHERE cd.outcome = 'fail'
  AND cd.indicator_name IS NOT NULL
GROUP BY cd.indicator_name, cd.dimension_name, cd.project_id, cd.project_name, i.description, i.source, d.identifier
ORDER BY failure_count DESC;

CREATE OR REPLACE VIEW per_software_issues AS
SELECT
  cd.software_name,
  cd.indicator_name,
  cd.dimension_name,
  cd.project_id,
  cd.project_name,
  COUNT(*) AS failure_count,
  i.description AS what_to_improve,
  i.source->>'@id' AS indicator_url,
  'https://everse.software/RSQKit/' || COALESCE(d.identifier, '') AS rsqkit_url
FROM checks_detailed cd
LEFT JOIN indicators i ON i.name = cd.indicator_name
LEFT JOIN dimensions d ON d.name = cd.dimension_name
WHERE cd.outcome = 'fail'
  AND cd.indicator_name IS NOT NULL
GROUP BY cd.software_name, cd.indicator_name, cd.dimension_name, cd.project_id, cd.project_name,
         i.description, i.source, d.identifier;

CREATE OR REPLACE VIEW indicators_flat AS
WITH unnested AS (
  SELECT
    i.identifier AS indicator_identifier,
    i.name AS indicator_name,
    i.description AS indicator_description,
    i.source->>'@id' AS indicator_url,
    TRIM(split_part((i.quality_dimension::jsonb)->>'@id', '/', -1)) AS dimension_slug
  FROM indicators i
  WHERE jsonb_typeof(i.quality_dimension::jsonb) = 'object'
  UNION ALL
  SELECT
    i.identifier,
    i.name,
    i.description,
    i.source->>'@id',
    TRIM(split_part(elem->>'@id', '/', -1))
  FROM indicators i
  CROSS JOIN LATERAL jsonb_array_elements(i.quality_dimension::jsonb) AS elem
  WHERE jsonb_typeof(i.quality_dimension::jsonb) = 'array'
)
SELECT
  u.indicator_identifier,
  u.indicator_name,
  u.indicator_description,
  u.indicator_url,
  u.dimension_slug,
  COALESCE(d.name, INITCAP(REPLACE(u.dimension_slug, '_', ' '))) AS dimension_name
FROM unnested u
LEFT JOIN dimensions d ON d.identifier = u.dimension_slug
WHERE u.dimension_slug IS NOT NULL AND u.dimension_slug <> '';

CREATE OR REPLACE VIEW dimensions_with_links AS
SELECT
  d.*,
  d.name AS dimension_name,
  'https://everse.software/RSQKit/' || d.identifier AS rsqkit_url
FROM dimensions d;

CREATE OR REPLACE VIEW tools_summary AS
SELECT
  cd.checking_software AS tool,
  cd.project_id,
  cd.project_name,
  COUNT(DISTINCT cd.dimension_name) AS dimensions_covered,
  COUNT(DISTINCT cd.indicator_name) AS indicators_covered,
  (SELECT COUNT(*) FROM indicators) AS catalog_indicators_total,
  ROUND(100.0 * COUNT(DISTINCT cd.indicator_name)
                / NULLIF((SELECT COUNT(*) FROM indicators), 0), 1) AS indicator_coverage_pct,
  COUNT(*) AS total_checks,
  COUNT(*) FILTER (WHERE cd.outcome = 'pass') AS passed,
  COUNT(*) FILTER (WHERE cd.outcome = 'fail') AS failed,
  ROUND(100.0 * COUNT(*) FILTER (WHERE cd.outcome = 'pass')
                / NULLIF(COUNT(*), 0), 1) AS success_rate
FROM checks_detailed cd
WHERE cd.checking_software IS NOT NULL
GROUP BY 1, cd.project_id, cd.project_name;

CREATE OR REPLACE VIEW tools_coverage AS
SELECT
  cd.checking_software AS tool,
  cd.dimension_name,
  cd.indicator_name,
  cd.project_id,
  cd.project_name,
  COUNT(*) AS checks,
  COUNT(*) FILTER (WHERE cd.outcome = 'pass') AS passed,
  COUNT(*) FILTER (WHERE cd.outcome = 'fail') AS failed
FROM checks_detailed cd
WHERE cd.checking_software IS NOT NULL
  AND cd.dimension_name IS NOT NULL
  AND cd.indicator_name IS NOT NULL
GROUP BY 1, 2, 3, cd.project_id, cd.project_name;

CREATE OR REPLACE VIEW catalog_coverage_breakdown AS
WITH dim_tested AS (
  SELECT DISTINCT cd.dimension_id AS item_id
  FROM checks_detailed cd WHERE cd.dimension_id IS NOT NULL
),
ind_tested AS (
  SELECT DISTINCT cd.indicator_name AS item_id
  FROM checks_detailed cd WHERE cd.indicator_name IS NOT NULL
)
SELECT
  'Dimensions' AS category,
  CASE WHEN t.item_id IS NOT NULL THEN 'Tested' ELSE 'Untested' END AS status,
  COUNT(*) AS items
FROM dimensions d
LEFT JOIN dim_tested t ON t.item_id = d.identifier
GROUP BY 1, 2
UNION ALL
SELECT
  'Indicators',
  CASE WHEN t.item_id IS NOT NULL THEN 'Tested' ELSE 'Untested' END,
  COUNT(*)
FROM indicators i
LEFT JOIN ind_tested t ON t.item_id = i.name
GROUP BY 1, 2;

CREATE OR REPLACE VIEW catalog_coverage AS
SELECT
  cd.software_name,
  'Dimensions' AS category,
  cd.dimension_id AS item_id,
  (SELECT COUNT(*) FROM dimensions) AS catalog_total
FROM checks_detailed cd
WHERE cd.dimension_id IS NOT NULL
UNION ALL
SELECT
  cd.software_name,
  'Indicators',
  cd.indicator_name,
  (SELECT COUNT(*) FROM indicators)
FROM checks_detailed cd
WHERE cd.indicator_name IS NOT NULL;

CREATE OR REPLACE VIEW software_vs_median AS
WITH med AS (
  SELECT dimension_name, project_id, project_name,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY score) AS median_score
  FROM software_quality_scores
  GROUP BY dimension_name, project_id, project_name
)
SELECT
  sqs.software_name,
  sqs.dimension_name,
  sqs.project_id,
  sqs.project_name,
  sqs.score AS sw_score,
  med.median_score
FROM software_quality_scores sqs
JOIN med
  ON med.dimension_name = sqs.dimension_name
  AND med.project_id IS NOT DISTINCT FROM sqs.project_id;

CREATE OR REPLACE VIEW projects AS
SELECT
  id,
  name,
  name AS project_name,
  owner_user_id,
  is_public,
  created_at,
  updated_at
FROM auth.projects;

ALTER VIEW assessments_detailed SET (security_invoker = true);
ALTER VIEW checks_detailed SET (security_invoker = true);
ALTER VIEW software SET (security_invoker = true);
ALTER VIEW dimension_coverage SET (security_invoker = true);
ALTER VIEW software_quality_scores SET (security_invoker = true);
ALTER VIEW assessment_trends SET (security_invoker = true);
ALTER VIEW dimension_trend SET (security_invoker = true);
ALTER VIEW software_history SET (security_invoker = true);
ALTER VIEW tool_reliability SET (security_invoker = true);
ALTER VIEW compliance_status SET (security_invoker = true);
ALTER VIEW common_issues SET (security_invoker = true);
ALTER VIEW per_software_issues SET (security_invoker = true);
ALTER VIEW tools_summary SET (security_invoker = true);
ALTER VIEW tools_coverage SET (security_invoker = true);
ALTER VIEW catalog_coverage SET (security_invoker = true);
ALTER VIEW catalog_coverage_breakdown SET (security_invoker = true);
ALTER VIEW software_vs_median SET (security_invoker = true);
ALTER VIEW projects SET (security_invoker = true);
