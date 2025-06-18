SELECT 'Starting JSONB restoration' as status;

\! pg_restore -v /docker-entrypoint-initdb.d/pagila-data-apt-jsonb.backup -U postgres -d pagila
\! pg_restore -v /docker-entrypoint-initdb.d/pagila-data-yum-jsonb.backup -U postgres -d pagila

SELECT 'Completed JSONB restoration' as status;