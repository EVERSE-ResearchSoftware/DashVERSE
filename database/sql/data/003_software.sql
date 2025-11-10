SET search_path TO api, public;

-- sample software entries
INSERT INTO software (identifier, name, description, version, license, repository_url)
VALUES
  ('numpy', 'NumPy', 'Numerical computing library for Python', '1.26.4', 'BSD-3-Clause', 'https://github.com/numpy/numpy'),
  ('scipy', 'SciPy', 'Scientific computing library', '1.12.0', 'BSD-3-Clause', 'https://github.com/scipy/scipy'),
  ('pandas', 'pandas', 'Data analysis library', '2.2.1', 'BSD-3-Clause', 'https://github.com/pandas-dev/pandas'),
  ('astropy', 'Astropy', 'Astronomy library', '6.0.0', 'BSD-3-Clause', 'https://github.com/astropy/astropy')
ON CONFLICT (identifier) DO NOTHING;
