#!/bin/bash

set -e

# Check if the user ialab already exist
USER_EXISTS=$(psql -d $POSTGRES_DB -tA --username "$POSTGRES_USER" -c "SELECT 1 FROM pg_roles WHERE rolname='ialab'")

if [ "$USER_EXISTS" = "1" ]; then
    echo "User ialab already exist, updating the password..."
    psql -d $POSTGRES_DB -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        ALTER USER ialab WITH PASSWORD '$USER_IALAB_PASSWORD';
EOSQL
else
    echo "Creating the user ialab..."
    psql -d $POSTGRES_DB -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        CREATE USER ialab WITH PASSWORD '$USER_IALAB_PASSWORD';
EOSQL
fi

psql -d $POSTGRES_DB -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    GRANT CONNECT ON DATABASE $POSTGRES_DB TO ialab;
    GRANT USAGE ON SCHEMA public TO ialab;
    GRANT SELECT ON my_table TO ialab;
EOSQL
