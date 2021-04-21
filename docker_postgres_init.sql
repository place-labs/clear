CREATE USER root WITH PASSWORD 'password';
CREATE DATABASE root;

CREATE USER spec WITH PASSWORD 'spec' CREATEDB;
CREATE DATABASE clear_secondary_spec
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE TABLE clear_secondary_spec.models_post_stats (id serial PRIMARY KEY, post_id INTEGER);