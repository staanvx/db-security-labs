SET search_path = lab1;

DROP TABLE IF EXISTS employment_big CASCADE;

CREATE TABLE employment_big (
    fio text NOT NULL,
    dept_name text NOT NULL,
    dept_no integer NOT NULL,
    share numeric(6,2) NOT NULL,
    position text NOT NULL,
    descriptor text NOT NULL
);

INSERT INTO employment_big (fio, dept_name, dept_no, share, position, descriptor)
SELECT
    'Emp_' || gs::text AS fio,
    'Отдел ' || ((gs % 10) + 1)::text AS dept_name,
    ((gs % 10) + 1) AS dept_no,
    (ARRAY[0.25, 0.50, 0.75, 1.00])[(gs % 4) + 1]::numeric(6,2) AS share,
    (ARRAY[
        'Инженер',
        'Аналитик',
        'Разработчик',
        'Тестировщик',
        'Администратор'
    ])[(gs % 5) + 1] AS position,
    (ARRAY[
        'Backend',
        'Frontend',
        'DevOps',
        'Автотесты',
        'Поддержка'
    ])[(gs % 5) + 1] AS descriptor
FROM generate_series(1, 100000) AS gs;
