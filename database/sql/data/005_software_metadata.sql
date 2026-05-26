SET search_path TO api, public;


INSERT INTO software_metadata (identifier, programming_language, description, homepage_url) VALUES
  ('cffinit',        ARRAY['TypeScript'], 'CITATION.cff initializer web app.',                          'https://citation-file-format.github.io/cff-initializer-javascript/'),
  ('apptainer',      ARRAY['Go'],         'Container platform for HPC and research.',                   'https://apptainer.org/'),
  ('howfairis',      ARRAY['Python'],     'Compliance check for the fair-software.eu recommendations.', NULL),
  ('ossf-scorecard', ARRAY['Go'],         'Automated open-source software health checks.',              'https://scorecard.dev/'),
  ('pyani',          ARRAY['Python'],     'Average nucleotide identity for prokaryotic genomes.',       NULL),
  ('projectalpha',   ARRAY['Python'],     'Demo project: early-stage research tool.',                   NULL),
  ('simulab',        ARRAY['C++'],        'Demo project: simulation framework.',                        NULL),
  ('datapipe',       ARRAY['Rust'],       'Demo project: data processing pipeline.',                    NULL),
  ('terragen',       ARRAY['Python'],     'Demo project: terrain generation library.',                  NULL)
ON CONFLICT (identifier) DO UPDATE SET
  programming_language = EXCLUDED.programming_language,
  description          = EXCLUDED.description,
  homepage_url         = EXCLUDED.homepage_url,
  updated_at           = CURRENT_TIMESTAMP;
