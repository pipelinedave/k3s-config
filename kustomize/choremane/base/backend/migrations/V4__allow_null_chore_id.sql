-- Allow NULL for chore_id in chore_logs for system-level operations like import/export
ALTER TABLE chore_logs ALTER COLUMN chore_id DROP NOT NULL;

-- Update the schema version
INSERT INTO schema_versions (version, description) 
VALUES (4, 'Allow NULL for chore_id in chore_logs table for system-level operations')
ON CONFLICT (version) DO UPDATE SET description = EXCLUDED.description;
