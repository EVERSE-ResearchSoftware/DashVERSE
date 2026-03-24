SET search_path TO api, public;

-- detailed assessment view
CREATE OR REPLACE VIEW assessments_detailed AS
SELECT
  a.id,
  a.payload->>'@context' AS context,
  a.payload->>'@type' AS type,
  a.payload->>'dateCreated' AS date_created,
  a.payload->'assessedSoftware'->>'name' AS software_name,
  a.payload->'assessedSoftware'->>'softwareVersion' AS software_version,
  a.payload->'assessedSoftware'->>'url' AS software_url,
  jsonb_array_length(a.payload->'checks') AS total_checks,
  a.payload->'checks' AS checks,
  a.created_at
FROM assessment_raw a;

-- checks detailed view (unnested)
CREATE OR REPLACE VIEW checks_detailed AS
SELECT
  a.id AS assessment_id,
  a.payload->'assessedSoftware'->>'name' AS software_name,
  a.payload->>'dateCreated' AS assessment_date,
  check_item->>'@type' AS check_type,
  check_item->'assessesIndicator'->>'@id' AS indicator_id,
  check_item->'checkingSoftware'->>'name' AS checking_software,
  check_item->>'process' AS process,
  check_item->'status'->>'@id' AS status,
  check_item->>'output' AS output,
  check_item->>'evidence' AS evidence,
  i.name AS indicator_name,
  i.quality_dimension,
  d.name AS dimension_name
FROM assessment_raw a
CROSS JOIN LATERAL jsonb_array_elements(a.payload->'checks') AS check_item
LEFT JOIN indicators i ON (check_item->'assessesIndicator'->>'@id') = i.identifier
LEFT JOIN dimensions d ON d.identifier = split_part(
  CASE WHEN jsonb_typeof(i.quality_dimension::jsonb) = 'array'
       THEN i.quality_dimension::jsonb->0->>'@id'
       ELSE i.quality_dimension::jsonb->>'@id'
  END, '/', -1);

-- assessment summary per software
CREATE OR REPLACE VIEW assessment_summary AS
SELECT
  a.payload->'assessedSoftware'->>'name' AS software_name,
  a.payload->'assessedSoftware'->>'url' AS software_url,
  COUNT(DISTINCT a.id) AS assessment_count,
  MAX(a.payload->>'dateCreated') AS latest_assessment,
  AVG(jsonb_array_length(a.payload->'checks'))::numeric(10,2) AS avg_checks,
  COUNT(DISTINCT check_item->'assessesIndicator'->>'@id') AS unique_indicators
FROM assessment_raw a
CROSS JOIN LATERAL jsonb_array_elements(a.payload->'checks') AS check_item
GROUP BY
  a.payload->'assessedSoftware'->>'name',
  a.payload->'assessedSoftware'->>'url';

-- dimension coverage (pass/fail per dimension)
CREATE OR REPLACE VIEW dimension_coverage AS
SELECT
  d.name AS dimension_name,
  d.identifier AS dimension_id,
  COUNT(*) AS total_checks,
  SUM(CASE WHEN check_item->'status'->>'@id' LIKE '%Pass%' THEN 1 ELSE 0 END) AS passed,
  SUM(CASE WHEN check_item->'status'->>'@id' LIKE '%Fail%' THEN 1 ELSE 0 END) AS failed,
  SUM(CASE WHEN check_item->'status'->>'@id' NOT LIKE '%Pass%'
           AND check_item->'status'->>'@id' NOT LIKE '%Fail%' THEN 1 ELSE 0 END) AS other,
  ROUND(100.0 * SUM(CASE WHEN check_item->'status'->>'@id' LIKE '%Pass%' THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*), 0), 2) AS pass_rate
FROM assessment_raw a
CROSS JOIN LATERAL jsonb_array_elements(a.payload->'checks') AS check_item
LEFT JOIN indicators i ON (check_item->'assessesIndicator'->>'@id') = i.identifier
LEFT JOIN dimensions d ON d.identifier = split_part(
  CASE WHEN jsonb_typeof(i.quality_dimension::jsonb) = 'array'
       THEN i.quality_dimension::jsonb->0->>'@id'
       ELSE i.quality_dimension::jsonb->>'@id'
  END, '/', -1)
WHERE d.name IS NOT NULL
GROUP BY d.name, d.identifier;

-- indicator results with status
CREATE OR REPLACE VIEW indicator_results AS
SELECT
  i.identifier AS indicator_id,
  i.name AS indicator_name,
  i.quality_dimension,
  d.name AS dimension_name,
  check_item->'status'->>'@id' AS status,
  COUNT(*) AS occurrences,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY i.identifier), 2) AS percentage
FROM assessment_raw a
CROSS JOIN LATERAL jsonb_array_elements(a.payload->'checks') AS check_item
LEFT JOIN indicators i ON (check_item->'assessesIndicator'->>'@id') = i.identifier
LEFT JOIN dimensions d ON d.identifier = split_part(
  CASE WHEN jsonb_typeof(i.quality_dimension::jsonb) = 'array'
       THEN i.quality_dimension::jsonb->0->>'@id'
       ELSE i.quality_dimension::jsonb->>'@id'
  END, '/', -1)
WHERE i.identifier IS NOT NULL
GROUP BY i.identifier, i.name, i.quality_dimension, d.name, check_item->'status'->>'@id';

-- software quality scores
CREATE OR REPLACE VIEW software_quality_scores AS
SELECT
  a.payload->'assessedSoftware'->>'name' AS software_name,
  d.name AS dimension_name,
  COUNT(*) AS total_checks,
  SUM(CASE WHEN check_item->'status'->>'@id' LIKE '%Pass%' THEN 1 ELSE 0 END) AS passed,
  ROUND(100.0 * SUM(CASE WHEN check_item->'status'->>'@id' LIKE '%Pass%' THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*), 0), 2) AS score
FROM assessment_raw a
CROSS JOIN LATERAL jsonb_array_elements(a.payload->'checks') AS check_item
LEFT JOIN indicators i ON (check_item->'assessesIndicator'->>'@id') = i.identifier
LEFT JOIN dimensions d ON d.identifier = split_part(
  CASE WHEN jsonb_typeof(i.quality_dimension::jsonb) = 'array'
       THEN i.quality_dimension::jsonb->0->>'@id'
       ELSE i.quality_dimension::jsonb->>'@id'
  END, '/', -1)
WHERE d.name IS NOT NULL
GROUP BY a.payload->'assessedSoftware'->>'name', d.name;

-- assessment trends over time
CREATE OR REPLACE VIEW assessment_trends AS
SELECT
  date_trunc('month', (a.payload->>'dateCreated')::timestamp) AS month,
  COUNT(DISTINCT a.id) AS assessments,
  COUNT(DISTINCT a.payload->'assessedSoftware'->>'name') AS software_count,
  AVG(jsonb_array_length(a.payload->'checks'))::numeric(10,2) AS avg_checks
FROM assessment_raw a
GROUP BY date_trunc('month', (a.payload->>'dateCreated')::timestamp)
ORDER BY month;

-- software by programming language
CREATE OR REPLACE VIEW software_languages AS
SELECT
  s.id,
  s.name AS software_name,
  s.programming_language AS language
FROM software s
WHERE s.programming_language IS NOT NULL;

-- common issues (frequently failing indicators)
CREATE OR REPLACE VIEW common_issues AS
SELECT
  i.identifier AS indicator_id,
  i.name AS indicator_name,
  d.name AS dimension_name,
  COUNT(*) AS failure_count,
  array_agg(DISTINCT a.payload->'assessedSoftware'->>'name') AS affected_software
FROM assessment_raw a
CROSS JOIN LATERAL jsonb_array_elements(a.payload->'checks') AS check_item
LEFT JOIN indicators i ON (check_item->'assessesIndicator'->>'@id') = i.identifier
LEFT JOIN dimensions d ON d.identifier = split_part(
  CASE WHEN jsonb_typeof(i.quality_dimension::jsonb) = 'array'
       THEN i.quality_dimension::jsonb->0->>'@id'
       ELSE i.quality_dimension::jsonb->>'@id'
  END, '/', -1)
WHERE check_item->'status'->>'@id' LIKE '%Fail%'
  AND i.identifier IS NOT NULL
GROUP BY i.identifier, i.name, d.name
ORDER BY failure_count DESC;
