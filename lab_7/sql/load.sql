SET search_path = lab1;

INSERT INTO employees(fio)
SELECT 'Emp_' || gs::text
FROM generate_series(1, 200000) gs
ON CONFLICT DO NOTHING;

INSERT INTO employment(fio, dept_name, dept_no, share, position, descriptor)
SELECT
  'Emp_' || gs::text,
  CASE WHEN gs % 2 = 0 THEN 'Отдел 1' ELSE 'Отдел 2' END,
  CASE WHEN gs % 2 = 0 THEN 1 ELSE 2 END,
  1.00,
  CASE WHEN gs % 3 = 0 THEN 'Инженер'
       WHEN gs % 3 = 1 THEN 'QA-аналитик'
       ELSE 'Аналитик' END,
  'AutoGen'
FROM generate_series(1, 200000) gs
ON CONFLICT DO NOTHING;
