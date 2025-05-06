-- Add chore logs table
CREATE TABLE IF NOT EXISTS chore_logs (
    id SERIAL PRIMARY KEY,
    chore_id INT NOT NULL,
    done_by VARCHAR(255),
    done_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action_type VARCHAR(50) NOT NULL,
    action_details JSON DEFAULT NULL,
    FOREIGN KEY (chore_id) REFERENCES chores (id) ON DELETE CASCADE
);
