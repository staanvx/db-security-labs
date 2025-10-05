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

--- роли ---
DROP ROLE IF EXISTS role_head;
DROP ROLE IF EXISTS role_employee;

DROP ROLE IF EXISTS alice;
DROP ROLE IF EXISTS bob;
DROP ROLE IF EXISTS cristian;

CREATE ROLE role_head NOINHERIT;
CREATE ROLE role_employee NOINHERIT;

CREATE ROLE alice LOGIN PASSWORD 'alice'; -- начальник отдела 1
CREATE ROLE bob LOGIN PASSWORD 'bob'; -- начальник отдела 2
CREATE ROLE cristian LOGIN PASSWORD 'cristian'; -- сотрудник отделов 1 и 2

GRANT role_head     TO alice, bob;
GRANT role_employee TO alice, bob, cristian;

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

-- пока все разрешено, фильруем политикой
GRANT SELECT ON lab1.employment TO role_head, role_employee;
-- Начальник отдела может корректировать должность и характеристику сотрудника, отфильтруем политикой
GRANT UPDATE (position, descriptor) ON lab1.employment TO role_head;

--- тестовые данные ---
INSERT INTO lab1.employees (fio) VALUES
    ('Alice'), ('Bob'), ('Cristian');

INSERT INTO lab1.departments (dept_name, dept_no, head_fio, positions_total, wage_fund, positions_occupied) VALUES
    ('Отдел 1', 1, 'Alice',    5.00, 1000000.00, 4.00),
    ('Отдел 2', 2, 'Bob',      7.00, 2500000.00, 6.00);

INSERT INTO lab1.employment (fio, dept_name, dept_no, share, position, descriptor) VALUES
    ('Cristian','Отдел 1', 1, 0.60, 'Инженер',          'Backend'),
    ('Cristian','Отдел 2', 2, 0.40, 'QA-аналитик',      'Автотесты'),
    ('Alice',   'Отдел 1', 1, 1.00, 'Начальник отдела', 'Руководство'),
    ('Bob',     'Отдел 2', 2, 1.00, 'Начальник отдела', 'Руководство');

CREATE TABLE lab1.auth_user_map(
      login_name text PRIMARY KEY,
      fio        text NOT NULL UNIQUE REFERENCES lab1.employees(fio)
          ON UPDATE CASCADE ON DELETE CASCADE
);

INSERT INTO lab1.auth_user_map(login_name, fio) VALUES
    ('alice',   'Alice'),
    ('bob',     'Bob'),
    ('cristian','Cristian')
ON CONFLICT (login_name) DO NOTHING;

