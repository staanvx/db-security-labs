DROP SCHEMA IF EXISTS lab1 CASCADE;
CREATE SCHEMA lab1;
SET search_path = lab1;

--- таблицы ---
CREATE TABLE employees(
    fio TEXT PRIMARY KEY
);

CREATE TABLE departments(
    dept_name TEXT NOT NULL,
    dept_no   INTEGER NOT NULL,
    head_fio  TEXT NOT NULL REFERENCES employees(fio),
    positions_total NUMERIC(6,2) NOT NULL,
    wage_fund       NUMERIC(14,2) NOT NULL,
    positions_occupied NUMERIC(6,2) NOT NULL,
    CONSTRAINT pk_departments PRIMARY KEY (dept_name),
    CONSTRAINT ak1_departments UNIQUE (dept_no, head_fio)
);

ALTER TABLE departments ADD CONSTRAINT ak_dept_name_no UNIQUE (dept_name, dept_no);

CREATE TABLE employment(
    fio        TEXT NOT NULL REFERENCES employees(fio),
    dept_name  TEXT NOT NULL,
    dept_no    INTEGER NOT NULL,
    share      NUMERIC(6,2) NOT NULL CHECK (share > 0 AND share <= 1),
    position   TEXT NOT NULL,
    descriptor TEXT NOT NULL,
    CONSTRAINT fk1_employment FOREIGN KEY (dept_name, dept_no)
        REFERENCES departments(dept_name, dept_no),
    CONSTRAINT pk_employment PRIMARY KEY (fio, dept_no, position)
);

--- права ---
REVOKE ALL ON SCHEMA lab1 FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA lab1 FROM PUBLIC;

GRANT USAGE ON SCHEMA lab1 TO role_head, role_employee;

-- справочник сотрудников для всех, отфильтруем политикой
GRANT SELECT ON lab1.employees TO role_head, role_employee;

-- сотрудник не видит фонды и ставки
REVOKE ALL ON lab1.departments FROM role_employee;
GRANT SELECT (dept_name, dept_no, head_fio) ON lab1.departments TO role_employee; 

-- начальник видит все
GRANT SELECT ON lab1.departments TO role_head;

-- пока все разрешено, фильтруем политикой
GRANT SELECT ON lab1.employment TO role_head, role_employee;
-- Начальник отдела может корректировать должность и характеристику сотрудника, отфильтруем политикой
GRANT UPDATE (position, descriptor) ON lab1.employment TO role_head;

--- базовые тестовые данные (как в 1-й лабе) ---
INSERT INTO lab1.employees (fio) VALUES
    ('Alice'), ('Bob'), ('Cristian'), ('Denis');

INSERT INTO lab1.departments (dept_name, dept_no, head_fio, positions_total, wage_fund, positions_occupied) VALUES
    ('Холдинг 1', 1, 'Alice',    5.00, 1000000.00, 4.00),
    ('Холдинг 2', 2, 'Bob',      7.00, 2500000.00, 6.00);

INSERT INTO lab1.employment (fio, dept_name, dept_no, share, position, descriptor) VALUES
    ('Cristian','Холдинг 1', 1, 0.60, 'Инженер',          'Backend'),
    ('Cristian','Холдинг 2', 2, 0.40, 'QA-аналитик',      'Автотесты'),
    ('Alice',   'Холдинг 1', 1, 1.00, 'Начальник отдела', 'Руководство'),
    ('Bob',     'Холдинг 2', 2, 1.00, 'Начальник отдела', 'Руководство'),
    ('Denis',   'Холдинг 1', 1, 1.00, 'Инженер',          'Frontend');

CREATE TABLE lab1.auth_user(
    login_name text PRIMARY KEY,
    fio        text NOT NULL UNIQUE REFERENCES lab1.employees(fio)
        ON UPDATE CASCADE ON DELETE CASCADE
);

GRANT SELECT ON lab1.auth_user TO role_head, role_employee;

INSERT INTO lab1.auth_user(login_name, fio) VALUES
    ('alice',   'Alice'),
    ('bob',     'Bob'),
    ('cristian','Cristian'),
    ('denis',   'Denis')
ON CONFLICT (login_name) DO NOTHING;

--- политики ---

-- departments
ALTER TABLE lab1.departments ENABLE ROW LEVEL SECURITY;

-- начальник видит только свой отдел
CREATE POLICY p_dept_head_select ON lab1.departments
FOR SELECT TO role_head
USING (
    EXISTS (
        SELECT 1
        FROM lab1.auth_user a
        WHERE a.login_name = current_user
          AND a.fio = lab1.departments.head_fio
    )
);

-- сотрудник видит только отделы, где у него есть занятость
CREATE POLICY p_dept_emp_select ON lab1.departments
FOR SELECT TO role_employee
USING (
    EXISTS (
        SELECT 1
        FROM lab1.auth_user a
        JOIN lab1.employment e ON e.fio = a.fio
        WHERE a.login_name = current_user
          AND e.dept_no   = lab1.departments.dept_no
          AND e.dept_name = lab1.departments.dept_name
    )
);

--- employment ---
ALTER TABLE lab1.employment ENABLE ROW LEVEL SECURITY;

-- начальник видит строки занятости только в своём отделе
CREATE POLICY p_emp_head_select ON lab1.employment
FOR SELECT TO role_head
USING (
    EXISTS (
        SELECT 1
        FROM lab1.auth_user a
        JOIN lab1.departments d
          ON d.dept_no   = lab1.employment.dept_no
         AND d.dept_name = lab1.employment.dept_name
        WHERE a.login_name = current_user
          AND d.head_fio   = a.fio
    )
);

-- начальник может изменять строки только своего отдела
CREATE POLICY p_emp_head_update ON lab1.employment
FOR UPDATE TO role_head
USING (
    EXISTS (
        SELECT 1
        FROM lab1.auth_user a
        JOIN lab1.departments d
          ON d.dept_no   = lab1.employment.dept_no
         AND d.dept_name = lab1.employment.dept_name
        WHERE a.login_name = current_user
          AND d.head_fio   = a.fio
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM lab1.auth_user a
        JOIN lab1.departments d
          ON d.dept_no   = lab1.employment.dept_no
         AND d.dept_name = lab1.employment.dept_name
        WHERE a.login_name = current_user
          AND d.head_fio   = a.fio
    )
);

-- сотрудники: видят только свои строки
CREATE POLICY p_emp_employee_select ON lab1.employment
FOR SELECT TO role_employee
USING (
    EXISTS (
        SELECT 1
        FROM lab1.auth_user a
        WHERE a.login_name = current_user
          AND a.fio = lab1.employment.fio
    )
);

-- employees
ALTER TABLE lab1.employees ENABLE ROW LEVEL SECURITY;

-- сотрудник видит только себя
CREATE POLICY p_employees_emp_self ON lab1.employees
FOR SELECT TO role_employee
USING (
    EXISTS (
        SELECT 1
        FROM lab1.auth_user a
        WHERE a.login_name = current_user
          AND a.fio = lab1.employees.fio
    )
);

-- начальник видит сотрудников только своих отделов
CREATE POLICY p_employees_head_staff ON lab1.employees
FOR SELECT TO role_head
USING (
    EXISTS (
        SELECT 1
        FROM lab1.auth_user a
        JOIN lab1.employment em ON em.fio = lab1.employees.fio
        JOIN lab1.departments d
          ON d.dept_no   = em.dept_no
         AND d.dept_name = em.dept_name
        WHERE a.login_name = current_user
          AND d.head_fio = a.fio
    )
);

-- lab_3 --

ALTER TABLE lab1.departments
    DROP CONSTRAINT IF EXISTS pk_departments;

ALTER TABLE lab1.departments
    ADD CONSTRAINT pk_departments PRIMARY KEY (dept_name, dept_no);

INSERT INTO lab1.employees (fio) VALUES
    ('Karina'),
    ('Leonid'),
    ('Marina'),
    ('Nikita'),
    ('Olga'),
    ('Pavel'),
    ('Roman'),
    ('Svetlana'),
    ('Alex'),
    ('John'),
    ('Mark'),
    ('Paul'),
    ('Kevin'),
    ('Brian'),
    ('Victor'),
    ('Tim')
ON CONFLICT (fio) DO NOTHING;

INSERT INTO lab1.departments (dept_name, dept_no, head_fio, positions_total, wage_fund, positions_occupied) VALUES
    ('Холдинг 3', 3, 'Karina',  4.00, 1800000.00, 3.00),
    ('Холдинг 4', 4, 'Leonid',  6.00, 2200000.00, 4.00),
    ('Холдинг 5', 5, 'Marina',  5.00, 1400000.00, 4.00),
    ('Холдинг 6', 6, 'Nikita',  6.00, 1600000.00, 5.00),
    ('Холдинг 7', 7, 'Olga',    4.00, 1100000.00, 3.00),
    ('Холдинг 8', 8, 'Pavel',   3.00,  900000.00, 2.00)
ON CONFLICT DO NOTHING;

INSERT INTO lab1.employment (fio, dept_name, dept_no, share, position, descriptor) VALUES
    ('Karina',   'Холдинг 3', 3, 1.00, 'Начальник отдела', 'Руководство'),
    ('Leonid',   'Холдинг 4', 4, 1.00, 'Начальник отдела', 'Руководство'),
    ('Marina',   'Холдинг 5', 5, 1.00, 'Начальник отдела', 'Руководство'),
    ('Nikita',   'Холдинг 6', 6, 1.00, 'Начальник отдела', 'Руководство'),
    ('Olga',     'Холдинг 7', 7, 1.00, 'Начальник отдела', 'Руководство'),
    ('Pavel',    'Холдинг 8', 8, 1.00, 'Начальник отдела', 'Руководство'),
    ('Roman',    'Холдинг 3', 3, 1.00, 'Инженер',          'Backend'),
    ('Svetlana', 'Холдинг 4', 4, 1.00, 'Инженер',          'Frontend')
ON CONFLICT (fio, dept_no, position) DO NOTHING;

INSERT INTO lab1.departments (dept_name, dept_no, head_fio, positions_total, wage_fund, positions_occupied) VALUES
    ('Холдинг 9', 1, 'Alex',   3.00, 800000.00, 2.00),
    ('Холдинг 9', 2, 'John',   3.00, 800000.00, 2.00),
    ('Холдинг 9', 3, 'Mark',   3.00, 800000.00, 2.00),
    ('Холдинг 9', 4, 'Paul',   3.00, 800000.00, 2.00),
    ('Холдинг 9', 5, 'Kevin',  3.00, 800000.00, 2.00),
    ('Холдинг 9', 6, 'Brian',  3.00, 800000.00, 2.00),
    ('Холдинг 9', 7, 'Victor', 3.00, 800000.00, 2.00),
    ('Холдинг 9', 8, 'Tim',    3.00, 800000.00, 2.00)
ON CONFLICT (dept_name, dept_no) DO NOTHING;

INSERT INTO lab1.employment (fio, dept_name, dept_no, share, position, descriptor) VALUES
    ('Alex',   'Холдинг 9', 1, 1.00, 'Инженер',         'Legacy-системы'),
    ('John',   'Холдинг 9', 2, 1.00, 'Инженер',         'DevOps'),
    ('Mark',   'Холдинг 9', 3, 1.00, 'Бизнес-аналитик', 'Отчетность'),
    ('Paul',   'Холдинг 9', 4, 1.00, 'Инженер',         'Data'),
    ('Kevin',  'Холдинг 9', 5, 1.00, 'Инженер',         'Python'),
    ('Brian',  'Холдинг 9', 6, 1.00, 'Инженер',         'Cloud'),
    ('Victor', 'Холдинг 9', 7, 1.00, 'Инженер',         'Security'),
    ('Tim',    'Холдинг 9', 8, 1.00, 'Инженер',         'Frontend')
ON CONFLICT (fio, dept_no, position) DO NOTHING;


CREATE OR REPLACE FUNCTION query1(min_share NUMERIC)
RETURNS TABLE(job_position TEXT, total_share NUMERIC)
AS $$
    SELECT
        e.position AS job_position,
        SUM(e.share) AS total_share
    FROM lab1.employment AS e
    GROUP BY e.position
    HAVING SUM(e.share) > min_share;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION query2(pos_list TEXT[])
RETURNS TABLE(dept_no INTEGER)
AS $$
    SELECT DISTINCT d.dept_no
    FROM lab1.departments AS d
    WHERE NOT EXISTS (
        SELECT 1
        FROM lab1.employment AS e
        WHERE e.dept_name = d.dept_name
          AND e.dept_no   = d.dept_no
          AND e.position  = ANY (pos_list)
    );
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION query3(target_position TEXT)
RETURNS TABLE(dept_name TEXT)
AS $$
    SELECT d.dept_name
    FROM lab1.departments AS d
    GROUP BY d.dept_name
    HAVING
        COUNT(DISTINCT d.dept_no) = (
            SELECT COUNT(DISTINCT dept_no) FROM lab1.departments
        )
        AND NOT EXISTS (
            SELECT 1
            FROM lab1.employment AS e
            WHERE e.dept_name = d.dept_name
              AND e.position  = target_position
        );
$$ LANGUAGE sql;

