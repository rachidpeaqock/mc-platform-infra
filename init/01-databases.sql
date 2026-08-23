-- One database per service, with a login per service and no cross-database
-- grants. This is the architecture's hardest rule (platform-architecture.md
-- §6) made real in development: if a service could reach another service's
-- data locally, it would eventually do so in code, and the boundary would
-- exist only in the documentation.
--
-- Runs once, on first `docker compose up`, via the Postgres init hook.

CREATE DATABASE milestone_db;
CREATE DATABASE activity_db;
CREATE DATABASE template_db;
CREATE DATABASE identity_db;

CREATE USER milestone_svc WITH PASSWORD 'milestone_svc';
CREATE USER activity_svc  WITH PASSWORD 'activity_svc';
CREATE USER template_svc  WITH PASSWORD 'template_svc';
CREATE USER identity_svc  WITH PASSWORD 'identity_svc';

GRANT ALL PRIVILEGES ON DATABASE milestone_db TO milestone_svc;
GRANT ALL PRIVILEGES ON DATABASE activity_db  TO activity_svc;
GRANT ALL PRIVILEGES ON DATABASE template_db  TO template_svc;
GRANT ALL PRIVILEGES ON DATABASE identity_db  TO identity_svc;

-- Each service owns its own schema; PUBLIC gets nothing, so a wrong
-- connection string fails immediately rather than silently working.
\connect milestone_db
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO milestone_svc;

\connect activity_db
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO activity_svc;

\connect template_db
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO template_svc;

\connect identity_db
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO identity_svc;
