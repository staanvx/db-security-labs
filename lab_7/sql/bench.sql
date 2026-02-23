\set ON_ERROR_STOP on
\timing on
SET search_path = lab1;

SET ROLE alice;

-- выборка
BEGIN;
SELECT position, COUNT(*), SUM(share)
FROM employment
GROUP BY position
ORDER BY COUNT(*) DESC;
COMMIT;

-- выборка + обновление
BEGIN;
SELECT COUNT(*) FROM employment WHERE dept_no = 1 AND position = 'Инженер';
UPDATE employment
SET descriptor = 'Updated_' || (random()*1000000)::int::text
WHERE dept_no = 1 AND position = 'Инженер';
COMMIT;

-- вставка + удаление
BEGIN;

INSERT INTO employees(fio)
SELECT 'Temp_' || gs::text
FROM generate_series(1, 20000) gs
ON CONFLICT DO NOTHING;

INSERT INTO employment(fio, dept_name, dept_no, share, position, descriptor)
SELECT 'Temp_' || gs::text, 'Отдел 1', 1, 0.25, 'Инженер', 'Contractor'
FROM generate_series(1, 20000) gs
ON CONFLICT DO NOTHING;

DELETE FROM employment WHERE descriptor='Contractor';
DELETE FROM employees  WHERE fio LIKE 'Temp_%';

COMMIT;

RESET ROLE;
