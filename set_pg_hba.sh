#!/bin/bash
set -e

# Emplacement de pg_hba.conf
PG_HBA="/var/lib/postgresql/data/pg_hba.conf"

# Remplacez le contenu de pg_hba.conf avec votre configuration
echo "local   all             all                                     trust" > $PG_HBA
echo "host    all             all             0.0.0.0/0               trust" >> $PG_HBA
echo "host    all             all             ::/0                    trust" >> $PG_HBA
echo "local   replication     all                                     trust" >> $PG_HBA
echo "host    replication     all             127.0.0.1/32            trust" >> $PG_HBA
echo "host    replication     all             ::1/128                 trust" >> $PG_HBA