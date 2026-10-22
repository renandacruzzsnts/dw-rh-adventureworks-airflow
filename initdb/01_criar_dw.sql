
SELECT 'CREATE DATABASE dw'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'dw')\gexec
