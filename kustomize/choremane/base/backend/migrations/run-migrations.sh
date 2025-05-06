#!/bin/bash

# Wait for PostgreSQL to be ready
until pg_isready -h "$POSTGRES_HOST" -p 5432; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
done

echo "PostgreSQL is ready. Running migrations..."

# Create migrations table if it doesn't exist
PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" << 'EOSQL'
CREATE TABLE IF NOT EXISTS schema_versions (
    version INT PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);
EOSQL

# Function to get migration version from filename
get_version() {
    echo "$1" | sed -n 's/V\([0-9]\+\)__.*/\1/p'
}

# Function to get migration description from filename
get_description() {
    echo "$1" | sed -n 's/V[0-9]\+__\(.*\)\.sql/\1/p'
}

# Run each migration file if it hasn't been applied yet
for migration in /migrations/V*__*.sql; do
    version=$(get_version "$(basename "$migration")")
    description=$(get_description "$(basename "$migration")")
    
    # Check if migration has been applied
    if ! PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc \
        "SELECT 1 FROM schema_versions WHERE version = $version;" | grep -q 1; then
        echo "Applying migration $version: $description"
        
        # Start transaction
        PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" << EOSQL
        BEGIN;
        \i $migration
        INSERT INTO schema_versions (version, description) VALUES ($version, '$description');
        COMMIT;
EOSQL
        
        if [ $? -eq 0 ]; then
            echo "Successfully applied migration $version"
        else
            echo "Failed to apply migration $version"
            exit 1
        fi
    else
        echo "Migration $version already applied"
    fi
done

echo "All migrations completed successfully"
