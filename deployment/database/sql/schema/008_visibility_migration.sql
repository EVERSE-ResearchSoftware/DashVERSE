
SET search_path TO auth, api, public;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema = 'auth' AND table_name = 'projects') THEN

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'auth' AND table_name = 'projects'
                     AND column_name = 'visibility') THEN
      ALTER TABLE auth.projects ADD COLUMN visibility TEXT;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'auth' AND table_name = 'projects'
                 AND column_name = 'is_public') THEN
      UPDATE auth.projects
         SET visibility = CASE WHEN is_public THEN 'public' ELSE 'private' END
       WHERE visibility IS NULL;
    END IF;

    UPDATE auth.projects SET visibility = 'private' WHERE visibility IS NULL;

    ALTER TABLE auth.projects ALTER COLUMN visibility SET NOT NULL;
    ALTER TABLE auth.projects ALTER COLUMN visibility SET DEFAULT 'public';

    IF NOT EXISTS (SELECT 1 FROM information_schema.check_constraints
                   WHERE constraint_schema = 'auth'
                     AND constraint_name = 'projects_visibility_check') THEN
      ALTER TABLE auth.projects
        ADD CONSTRAINT projects_visibility_check
        CHECK (visibility IN ('private','authenticated','public'));
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'auth' AND table_name = 'projects'
                 AND column_name = 'is_public') THEN
      ALTER TABLE auth.projects DROP COLUMN is_public;
    END IF;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema = 'auth' AND table_name = 'software_visibility') THEN

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'auth' AND table_name = 'software_visibility'
                     AND column_name = 'visibility') THEN
      ALTER TABLE auth.software_visibility ADD COLUMN visibility TEXT;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'auth' AND table_name = 'software_visibility'
                 AND column_name = 'is_public') THEN
      UPDATE auth.software_visibility
         SET visibility = CASE WHEN is_public THEN 'public' ELSE 'private' END
       WHERE visibility IS NULL;
    END IF;

    UPDATE auth.software_visibility SET visibility = 'private' WHERE visibility IS NULL;

    ALTER TABLE auth.software_visibility ALTER COLUMN visibility SET NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM information_schema.check_constraints
                   WHERE constraint_schema = 'auth'
                     AND constraint_name = 'software_visibility_visibility_check') THEN
      ALTER TABLE auth.software_visibility
        ADD CONSTRAINT software_visibility_visibility_check
        CHECK (visibility IN ('private','authenticated','public'));
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'auth' AND table_name = 'software_visibility'
                 AND column_name = 'is_public') THEN
      ALTER TABLE auth.software_visibility DROP COLUMN is_public;
    END IF;
  END IF;
END
$$;
