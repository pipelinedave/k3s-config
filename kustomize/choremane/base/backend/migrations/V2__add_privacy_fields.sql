-- Add owner_email and is_private columns
ALTER TABLE chores 
ADD COLUMN owner_email VARCHAR(255),
ADD COLUMN is_private BOOLEAN DEFAULT FALSE;

-- Set default values for existing records
UPDATE chores 
SET is_private = FALSE
WHERE is_private IS NULL;
