FROM postgres:15.2-alpine AS pgvector-builder

RUN apk add --no-cache git build-base clang llvm15-dev

WORKDIR /home

RUN git clone --branch v0.4.4 https://github.com/pgvector/pgvector.git

WORKDIR /home/pgvector

RUN make

RUN make install

FROM postgres:15.2-alpine

COPY --from=pgvector-builder /usr/local/lib/postgresql/bitcode/vector.index.bc /usr/local/lib/postgresql/bitcode/vector.index.bc
COPY --from=pgvector-builder /usr/local/lib/postgresql/vector.so /usr/local/lib/postgresql/vector.so
COPY --from=pgvector-builder /usr/local/share/postgresql/extension /usr/local/share/postgresql/extension

COPY init.sql /docker-entrypoint-initdb.d/
COPY setup_db.sh /docker-entrypoint-initdb.d/
COPY set_pg_hba.sh /docker-entrypoint-initdb.d/

RUN chmod +x /docker-entrypoint-initdb.d/setup_db.sh
RUN chmod +x /docker-entrypoint-initdb.d/set_pg_hba.sh

# UTF-8 encoding
ENV POSTGRES_INITDB_ARGS="--encoding=UTF8"

ENV USER_IALAB_PASSWORD=$USER_IALAB_PASSWORD

ENV POSTGRES_PASSWORD=$POSTGRES_PASSWORD
ENV POSTGRES_USER=$POSTGRES_USER
ENV POSTGRES_HOST=$POSTGRES_HOST
ENV POSTGRES_DB=$POSTGRES_DB
ENV POSTGRES_PORT=5432

EXPOSE 5432

