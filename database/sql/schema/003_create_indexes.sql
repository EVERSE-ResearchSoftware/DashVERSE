SET search_path TO api, public;


CREATE INDEX IF NOT EXISTS idx_dimensions_identifier ON dimensions(identifier);

CREATE INDEX IF NOT EXISTS idx_indicators_identifier ON indicators(identifier);
CREATE INDEX IF NOT EXISTS idx_indicators_dimension ON indicators(quality_dimension);

CREATE INDEX IF NOT EXISTS idx_assessment_payload ON assessment_raw USING GIN (payload);
CREATE INDEX IF NOT EXISTS idx_assessment_created ON assessment_raw(created_at);

CREATE INDEX IF NOT EXISTS idx_assessment_software ON assessment_raw USING GIN ((payload->'assessedSoftware'));
CREATE INDEX IF NOT EXISTS idx_assessment_checks ON assessment_raw USING GIN ((payload->'checks'));
