DROP SCHEMA IF EXISTS lab2 CASCADE;
CREATE SCHEMA lab2;
SET search_path = lab2;

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

CREATE TABLE auth_user(
  login_name text PRIMARY KEY,
  fio        text NOT NULL UNIQUE REFERENCES lab2.employees(fio)
    ON UPDATE CASCADE ON DELETE CASCADE
);

-- данные из прошлой лабы
INSERT INTO lab2.employees(fio) VALUES
  ('Alice'), ('Bob'), ('Cristian'), ('Denis');

INSERT INTO lab2.departments(dept_name, dept_no, head_fio, positions_total, wage_fund, positions_occupied) VALUES
  ('Отдел 1', 1, 'Alice', 5.00, 1000000.00, 4.00),
  ('Отдел 2', 2, 'Bob',   7.00, 2500000.00, 6.00);

INSERT INTO lab2.employment(fio, dept_name, dept_no, share, position, descriptor) VALUES
  ('Cristian','Отдел 1', 1, 0.60, 'Инженер',          'Backend'),
  ('Cristian','Отдел 2', 2, 0.40, 'QA-аналитик',      'Автотесты'),
  ('Alice',   'Отдел 1', 1, 1.00, 'Начальник отдела', 'Руководство'),
  ('Bob',     'Отдел 2', 2, 1.00, 'Начальник отдела', 'Руководство'),
  ('Denis',   'Отдел 1', 1, 1.00, 'Инженер',          'Frontend');

INSERT INTO lab2.auth_user(login_name, fio) VALUES
  ('alice',   'Alice'),
  ('bob',     'Bob'),
  ('cristian','Cristian'),
  ('denis',   'Denis');

-- ограничение и триггер--
-- функция проверки
CREATE OR REPLACE FUNCTION lab2.check_share_limit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_is_head   boolean;
  v_sum_share numeric(8,2);
  v_limit     numeric(8,2);
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM lab2.departments d WHERE d.head_fio = NEW.fio
  )
  INTO v_is_head;

  v_limit := CASE WHEN v_is_head THEN 1.00 ELSE 1.50 END;

  SELECT COALESCE(SUM(e.share), 0)
    INTO v_sum_share
    FROM lab2.employment e
   WHERE e.fio = NEW.fio
     AND (e.fio, e.dept_no, e.position)
         <> (COALESCE(OLD.fio, '§'), COALESCE(OLD.dept_no, -1), COALESCE(OLD.position, '§'));

  v_sum_share := v_sum_share + COALESCE(NEW.share, 0);

  IF v_sum_share > v_limit THEN
    RAISE EXCEPTION
      'у % суммарная ставка = %, лимит = %',
      NEW.fio, v_sum_share, v_limit
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

-- триггер
DROP TRIGGER IF EXISTS trg_check_share_limit ON lab2.employment;
CREATE TRIGGER trg_check_share_limit
BEFORE INSERT OR UPDATE OF fio, share
ON lab2.employment
FOR EACH ROW
EXECUTE FUNCTION lab2.check_share_limit();
