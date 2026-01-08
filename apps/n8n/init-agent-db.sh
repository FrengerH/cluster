#!/bin/bash
# Database initialization script for n8n PostgreSQL

set -e

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until kubectl exec -n n8n n8n-postgresql-0 -- pg_isready -U postgres -d postgres; do
  echo "PostgreSQL is not ready yet..."
  sleep 2
done

echo "PostgreSQL is ready!"

# Get the PostgreSQL password
POSTGRES_PASSWORD=$(kubectl get secret -n n8n n8n-postgresql -o jsonpath='{.data.password}' | base64 -d)

# Create agent_memory database if it doesn't exist
echo "Creating agent_memory database..."
kubectl exec -n n8n n8n-postgresql-0 -- bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres -d postgres -c 'SELECT 1 FROM pg_database WHERE datname = '\''agent_memory'\'';' | grep -q 1 || PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres -d postgres -c 'CREATE DATABASE agent_memory;'"

# Create agent_data table if it doesn't exist
echo "Creating agent_data table..."
kubectl exec -n n8n n8n-postgresql-0 -- bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres -d agent_memory -c 'CREATE TABLE IF NOT EXISTS agent_data (id SERIAL PRIMARY KEY, agent_name VARCHAR(100), memory_data TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);'"

# Create agent_user if it doesn't exist
echo "Creating agent_user..."
kubectl exec -n n8n n8n-postgresql-0 -- bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres -d agent_memory -c \"SELECT 1 FROM pg_roles WHERE rolname = 'agent_user';\" | grep -q 1 || PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres -d agent_memory -c 'CREATE USER agent_user WITH PASSWORD '\''hh3c4ZTpHb5Ld6S65V3IrKTGJ7uvsfLFkVzXNutjZGk='\'';'"

# Grant privileges
echo "Granting privileges..."
kubectl exec -n n8n n8n-postgresql-0 -- bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres -d agent_memory -c 'GRANT ALL PRIVILEGES ON DATABASE agent_memory TO agent_user;'"
kubectl exec -n n8n n8n-postgresql-0 -- bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres -d agent_memory -c 'GRANT ALL ON ALL TABLES IN SCHEMA public TO agent_user;'"
kubectl exec -n n8n n8n-postgresql-0 -- bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -U postgres -d agent_memory -c 'GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO agent_user;'"

echo "Database initialization completed successfully!"