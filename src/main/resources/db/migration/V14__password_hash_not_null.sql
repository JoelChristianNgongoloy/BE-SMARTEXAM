-- V14: Ensure password_hash is NOT NULL (prevent passwordless accounts)
ALTER TABLE users ALTER COLUMN password_hash SET NOT NULL;
