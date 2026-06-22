SET search_path TO api, public;

DROP VIEW IF EXISTS software_languages;

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

DROP VIEW IF EXISTS assessment_checks;
CREATE VIEW assessment_checks AS
SELECT
  a.id                                                     AS assessment_id,
  a.payload->>'@context'                                   AS context_url,
  a.payload->>'@type'                                      AS assessment_type,
  CASE
    WHEN a.payload->>'dateCreated' IS NOT NULL
         AND a.payload->>'dateCreated' <> ''
    THEN (a.payload->>'dateCreated')::TIMESTAMP
    ELSE NULL
  END                                                      AS assessed_at,
  a.created_at                                             AS ingested_at,

  a.payload->'assessedSoftware'->>'@type'                  AS software_type,
  COALESCE(a.payload->'assessedSoftware'->>'name',
           '(unknown software)')                           AS software_name,
  a.payload->'assessedSoftware'->>'softwareVersion'        AS software_version,
  a.payload->'assessedSoftware'->>'url'                    AS software_url,
  a.payload->'assessedSoftware'->'schema:identifier'->>'@id'
                                                           AS software_doi,

  COALESCE(
    a.payload->'author'->>'name',
    a.payload->'creator'->>'name'
  )                                                        AS author_name_raw,
  COALESCE(
    a.payload->'author'->>'email',
    a.payload->'creator'->>'email'
  )                                                        AS author_email_raw,
  COALESCE(
    a.payload->'author'->>'@type',
    a.payload->'creator'->>'@type'
  )                                                        AS author_type,

  a.created_by                                             AS author_user_id,
  u.username                                               AS author_username,
  u.email                                                  AS author_email,
  COALESCE(
    a.payload->'author'->>'name',
    a.payload->'creator'->>'name',
    u.username
  )                                                        AS author_full_name,

  a.project_id                                             AS project_id,
  p.name                                                   AS project_name,
  p.owner_user_id                                          AS project_owner_user_id,
  p.visibility                                             AS project_visibility,

  COALESCE(sv.visibility, p.visibility, 'public')          AS effective_visibility,

  a.payload->'license'->>'@id'                             AS assessment_license,

  check_idx                                                AS check_ordinal,
  check_item->>'@type'                                     AS check_type,
  check_item->'assessesIndicator'->>'@id'                  AS indicator_url,
  check_item->>'process'                                   AS check_process,
  check_item->>'output'                                    AS output_raw,
  check_item->>'evidence'                                  AS evidence,
  check_item->'status'->>'@id'                             AS status_url,

  check_item->'checkingSoftware'->>'name'                  AS tool_name,
  check_item->'checkingSoftware'->>'version'               AS tool_version,

  i.id                                                     AS indicator_id,
  i.identifier                                             AS indicator_identifier,
  COALESCE(i.name, '(unmapped indicator)')                 AS indicator_name,
  i.description                                            AS indicator_description,
  d.id                                                     AS dimension_id,
  d.identifier                                             AS dimension_identifier,
  COALESCE(d.name, '(unmapped dimension)')                 AS dimension_name,
  d.description                                            AS dimension_description,
  CASE
    WHEN d.identifier IS NOT NULL
    THEN 'https://everse.software/RSQKit/' || d.identifier
    ELSE NULL
  END                                                      AS dimension_rsqkit_url,

  check_outcome(check_item)                                AS outcome
FROM assessment_raw a
CROSS JOIN LATERAL jsonb_array_elements(a.payload->'checks')
            WITH ORDINALITY AS t(check_item, check_idx)
LEFT JOIN indicators i
       ON split_part(check_item->'assessesIndicator'->>'@id', '/', -1) = i.identifier
       OR ('software_has_' || split_part(check_item->'assessesIndicator'->>'@id', '/', -1))
           = i.identifier
LEFT JOIN dimensions d
       ON d.identifier = resolve_dimension_id(i.quality_dimension)
LEFT JOIN auth.users u
       ON u.id = a.created_by
LEFT JOIN auth.projects p
       ON p.id = a.project_id
LEFT JOIN auth.software_visibility sv
       ON sv.owner_user_id = a.created_by
      AND sv.software_name = a.payload->'assessedSoftware'->>'name';


DROP VIEW IF EXISTS catalog_coverage_breakdown;
CREATE VIEW catalog_coverage_breakdown AS
WITH dim_tested AS (
  SELECT DISTINCT ac.dimension_id AS item_id
  FROM assessment_checks ac WHERE ac.dimension_id IS NOT NULL
),
ind_tested AS (
  SELECT DISTINCT ac.indicator_id AS item_id
  FROM assessment_checks ac WHERE ac.indicator_id IS NOT NULL
)
SELECT
  'Dimensions' AS category,
  CASE WHEN t.item_id IS NOT NULL THEN 'Tested' ELSE 'Untested' END AS status,
  COUNT(*) AS items
FROM dimensions d
LEFT JOIN dim_tested t ON t.item_id = d.id
GROUP BY 1, 2
UNION ALL
SELECT
  'Indicators',
  CASE WHEN t.item_id IS NOT NULL THEN 'Tested' ELSE 'Untested' END,
  COUNT(*)
FROM indicators i
LEFT JOIN ind_tested t ON t.item_id = i.id
GROUP BY 1, 2;

DROP VIEW IF EXISTS catalog_coverage;
CREATE VIEW catalog_coverage AS
SELECT
  ac.software_name,
  'Dimensions' AS category,
  ac.dimension_id AS item_id,
  (SELECT COUNT(*) FROM dimensions) AS catalog_total
FROM assessment_checks ac
WHERE ac.dimension_id IS NOT NULL
UNION ALL
SELECT
  ac.software_name,
  'Indicators',
  ac.indicator_id,
  (SELECT COUNT(*) FROM indicators)
FROM assessment_checks ac
WHERE ac.indicator_id IS NOT NULL;

CREATE OR REPLACE VIEW projects AS
SELECT
  id,
  name,
  name AS project_name,
  owner_user_id,
  visibility,
  created_at,
  updated_at
FROM auth.projects;
ALTER VIEW catalog_coverage SET (security_invoker = true);
ALTER VIEW catalog_coverage_breakdown SET (security_invoker = true);
ALTER VIEW assessment_checks SET (security_invoker = true);
ALTER VIEW projects SET (security_invoker = true);
