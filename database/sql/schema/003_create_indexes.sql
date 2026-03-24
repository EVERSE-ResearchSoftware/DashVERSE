SET search_path TO api, public;

-- software indexes
CREATE INDEX IF NOT EXISTS idx_software_identifier ON software(identifier);
CREATE INDEX IF NOT EXISTS idx_software_name ON software(name);

-- dimensions indexes
CREATE INDEX IF NOT EXISTS idx_dimensions_identifier ON dimensions(identifier);

-- indicators indexes
CREATE INDEX IF NOT EXISTS idx_indicators_identifier ON indicators(identifier);
CREATE INDEX IF NOT EXISTS idx_indicators_dimension ON indicators(quality_dimension);

-- assessment indexes
CREATE INDEX IF NOT EXISTS idx_assessment_payload ON assessment_raw USING GIN (payload);
CREATE INDEX IF NOT EXISTS idx_assessment_created ON assessment_raw(created_at);

-- jsonb path indexes for common queries
CREATE INDEX IF NOT EXISTS idx_assessment_software ON assessment_raw USING GIN ((payload->'assessedSoftware'));
CREATE INDEX IF NOT EXISTS idx_assessment_checks ON assessment_raw USING GIN ((payload->'checks'));
