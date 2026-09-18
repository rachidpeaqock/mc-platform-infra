-- ============================================================
-- Sprint 24 — a load-shaped project: 5,000 milestones
-- ============================================================
-- The plan's risk register named the number; this puts it in a database.
-- 10 phases × 10 work packages × 50 milestones, dated across two years
-- from the project start, one in three slipping five calendar days and
-- one in seven slipping fourteen, so the RAG mix is not all green.
--
-- Against the compose stack, after the migrate profile:
--
--   docker compose exec -T postgres psql -U milestone_svc -d milestone_db < load/seed-5000.sql
--
-- Idempotent: re-running deletes and recreates LOAD-5K. Never run against
-- a shared environment — it is a fixture, and the audit trail it
-- generates when k6 writes to it is noise.

BEGIN;

DELETE FROM project WHERE code = 'LOAD-5K';   -- cascades to phase, work_package, milestone

INSERT INTO project (id, code, name, client, contractor, location, timezone,
                     scheduled_start, scheduled_finish, calendar_id, amber_threshold, red_threshold)
VALUES ('a0000000-0000-4000-8000-00000000f5e0', 'LOAD-5K', 'Load test — 5,000 milestones',
        'k6', 'k6', 'a laptop', 'UTC',
        DATE '2026-01-05', DATE '2027-12-31',
        (SELECT id FROM work_calendar ORDER BY name LIMIT 1), 8, 12);

INSERT INTO phase (id, project_id, name, sort)
SELECT ('b0000000-0000-4000-8000-1' || lpad(to_hex(p), 11, '0'))::uuid,
       'a0000000-0000-4000-8000-00000000f5e0', 'Phase ' || (p + 1), p
FROM generate_series(0, 9) AS p;

INSERT INTO work_package (id, phase_id, name, sort)
SELECT ('c0000000-0000-4000-8000-2' || lpad(to_hex(p * 10 + w), 11, '0'))::uuid,
       ('b0000000-0000-4000-8000-1' || lpad(to_hex(p), 11, '0'))::uuid,
       'WP ' || (p + 1) || '.' || (w + 1), w
FROM generate_series(0, 9) AS p, generate_series(0, 9) AS w;

INSERT INTO milestone (id, project_id, work_package_id, name, area, scheduled_date, real_date, status, critical)
SELECT ('d0000000-0000-4000-8000-3' || lpad(to_hex(n), 11, '0'))::uuid,
       'a0000000-0000-4000-8000-00000000f5e0',
       ('c0000000-0000-4000-8000-2' || lpad(to_hex((n - 1) / 50), 11, '0'))::uuid,
       'Milestone #' || n,
       'Area ' || (100 + ((n - 1) / 50)),
       DATE '2026-01-05' + ((n - 1) * 725 / 5000),
       DATE '2026-01-05' + ((n - 1) * 725 / 5000)
         + CASE WHEN n % 7 = 0 THEN 14 WHEN n % 3 = 0 THEN 5 ELSE 0 END,
       CASE WHEN n % 11 = 0 THEN 'done'::milestone_status ELSE 'pending'::milestone_status END,
       n % 25 = 0
FROM generate_series(1, 5000) AS n;

COMMIT;

SELECT count(*) AS milestones FROM milestone WHERE project_id = 'a0000000-0000-4000-8000-00000000f5e0';
