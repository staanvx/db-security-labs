DROP SCHEMA IF EXISTS lab1 CASCADE;
CREATE SCHEMA lab1;
SET search_path = lab1;

-- таблицы
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

-- роли
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


