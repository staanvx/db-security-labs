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

-- представления --
-- сотрудники --

-- свои строки занятости
CREATE OR REPLACE VIEW lab2.v_employment_self AS
SELECT e.fio, e.dept_name, e.dept_no, e.share, e.position, e.descriptor
FROM lab2.employment e
WHERE EXISTS (
  SELECT 1
  FROM lab2.auth_user a
  WHERE a.login_name = current_user
    AND a.fio = e.fio
);

-- отделы где работают без фондов и ставок
CREATE OR REPLACE VIEW lab2.v_departments_for_employee AS
SELECT d.dept_name, d.dept_no, d.head_fio
FROM lab2.departments d
WHERE EXISTS (
  SELECT 1
  FROM lab2.auth_user a
  JOIN lab2.employment em
    ON em.fio = a.fio
   AND em.dept_name = d.dept_name
   AND em.dept_no   = d.dept_no
  WHERE a.login_name = current_user
);

-- только себя в списке сотрудников
CREATE OR REPLACE VIEW lab2.v_employees_self AS
SELECT e.fio
FROM lab2.employees e
WHERE EXISTS (
  SELECT 1
  FROM lab2.auth_user a
  WHERE a.login_name = current_user
    AND a.fio = e.fio
);

-- руководители --
-- занятость своего отдела
CREATE OR REPLACE VIEW lab2.v_employment_head_edit AS
SELECT e.fio, e.dept_name, e.dept_no, e.share, e.position, e.descriptor
FROM lab2.employment e
WHERE EXISTS (
  SELECT 1
  FROM lab2.auth_user a
  JOIN lab2.departments d
    ON d.dept_name = e.dept_name
   AND d.dept_no   = e.dept_no
  WHERE a.login_name = current_user
    AND d.head_fio   = a.fio
);

-- сотрудники своего отдела
CREATE OR REPLACE VIEW lab2.v_employees_for_head AS
SELECT DISTINCT em.fio
FROM lab2.employment em
JOIN lab2.departments d
  ON d.dept_name = em.dept_name
 AND d.dept_no   = em.dept_no
WHERE EXISTS (
  SELECT 1
  FROM lab2.auth_user a
  WHERE a.login_name = current_user
    AND d.head_fio   = a.fio
);

-- свой отдел со всеми полями
CREATE OR REPLACE VIEW lab2.v_departments_for_head AS
SELECT d.*
FROM lab2.departments d
WHERE EXISTS (
  SELECT 1
  FROM lab2.auth_user a
  WHERE a.login_name = current_user
    AND a.fio = d.head_fio
);

-- обновление представлений --
CREATE OR REPLACE FUNCTION lab2.v_employment_head_edit_iud()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = lab2, pg_temp
AS $$
DECLARE
  v_me_fio text;
BEGIN
  SELECT a.fio INTO v_me_fio
  FROM lab2.auth_user a
  WHERE a.login_name = session_user;

  IF v_me_fio IS NULL THEN
    RAISE EXCEPTION 'Пользователь % не найден.', session_user;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    IF NOT EXISTS (
      SELECT 1
      FROM lab2.departments d
      WHERE d.dept_name = NEW.dept_name
        AND d.dept_no   = NEW.dept_no
        AND d.head_fio  = v_me_fio
    ) THEN
      RAISE EXCEPTION 'Нельзя изменять записи не своего отдела.';
    END IF;

    UPDATE lab2.employment t
       SET position   = NEW.position,
           descriptor = NEW.descriptor
     WHERE (t.fio, t.dept_no, t.dept_name, t.position)
           = (OLD.fio, OLD.dept_no, OLD.dept_name, OLD.position);

    RETURN NEW;

  ELSIF TG_OP = 'INSERT' THEN
    IF NOT EXISTS (
      SELECT 1
      FROM lab2.departments d
      WHERE d.dept_name = NEW.dept_name
        AND d.dept_no   = NEW.dept_no
        AND d.head_fio  = v_me_fio
    ) THEN
      RAISE EXCEPTION 'Нельзя добавлять записи в чужой отдел.';
    END IF;

    INSERT INTO lab2.employment(fio, dept_name, dept_no, share, position, descriptor)
    VALUES (NEW.fio, NEW.dept_name, NEW.dept_no, NEW.share, NEW.position, NEW.descriptor);

    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    IF NOT EXISTS (
      SELECT 1
      FROM lab2.departments d
      WHERE d.dept_name = OLD.dept_name
        AND d.dept_no   = OLD.dept_no
        AND d.head_fio  = v_me_fio
    ) THEN
      RAISE EXCEPTION 'Нельзя удалять записи чужого отдела.';
    END IF;

    DELETE FROM lab2.employment t
     WHERE (t.fio, t.dept_no, t.dept_name, t.position)
           = (OLD.fio, OLD.dept_no, OLD.dept_name, OLD.position);

    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

ALTER FUNCTION lab2.v_employment_head_edit_iud() OWNER TO stan;

DROP TRIGGER IF EXISTS trg_v_employment_head_edit ON lab2.v_employment_head_edit;
CREATE TRIGGER trg_v_employment_head_edit
INSTEAD OF INSERT OR UPDATE OR DELETE
ON lab2.v_employment_head_edit
FOR EACH ROW
EXECUTE FUNCTION lab2.v_employment_head_edit_iud();

-- гранты --
-- доступ к схеме
GRANT USAGE ON SCHEMA lab2 TO role_head, role_employee;

-- дать доступ к auth_user
GRANT SELECT ON lab2.auth_user TO role_head, role_employee;

-- сотрудники
GRANT SELECT ON lab2.v_employment_self,
               lab2.v_departments_for_employee,
               lab2.v_employees_self
TO role_employee;

-- начальники
GRANT SELECT ON lab2.v_employment_head_edit,
               lab2.v_employees_for_head,
               lab2.v_departments_for_head
TO role_head;

GRANT UPDATE (position, descriptor)
ON lab2.v_employment_head_edit
TO role_head;

-- забираем у PUBLIC
REVOKE ALL ON SCHEMA lab2 FROM PUBLIC;
REVOKE ALL ON lab2.auth_user FROM PUBLIC;

REVOKE ALL ON lab2.v_employment_self,
              lab2.v_departments_for_employee,
              lab2.v_employees_self,
              lab2.v_employment_head_edit,
              lab2.v_employees_for_head,
              lab2.v_departments_for_head
FROM PUBLIC;

-- аудит --
DROP TABLE IF EXISTS lab2.audit_log;

CREATE TABLE lab2.audit_log (
  id         bigserial PRIMARY KEY,
  username   text NOT NULL,
  action     text NOT NULL,
  change     text NOT NULL,
  changed_on timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION lab2.audit_row()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    pk text;
    change_text text := '';
    key text;
    old_row jsonb;
    new_row jsonb;
    old_val text;
    new_val text;
BEGIN
    old_row := COALESCE(to_jsonb(OLD), '{}'::jsonb);
    new_row := COALESCE(to_jsonb(NEW), '{}'::jsonb);

    IF TG_OP IN ('UPDATE','DELETE') THEN
        pk := format('(%s,%s,%s)', OLD.fio, OLD.dept_no, OLD.position);
    ELSE
        pk := format('(%s,%s,%s)', NEW.fio, NEW.dept_no, NEW.position);
    END IF;

    FOR key IN
        SELECT DISTINCT k FROM (
            SELECT jsonb_object_keys(old_row) AS k
            UNION
            SELECT jsonb_object_keys(new_row) AS k
        ) s
    LOOP
        old_val := old_row ->> key;
        new_val := new_row ->> key;

        IF old_val IS DISTINCT FROM new_val THEN
            change_text :=
                change_text ||
                format('%s: ''%s'' -> ''%s''; ', key, COALESCE(old_val,''), COALESCE(new_val,''));
        END IF;
    END LOOP;

    change_text := regexp_replace(change_text, '; $', '');

    INSERT INTO lab2.audit_log(username, action, change, changed_on)
    VALUES (
        session_user,
        lower(TG_OP),
        format('%s %s', pk, change_text),
        now()
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_employment ON lab2.employment;

CREATE TRIGGER trg_audit_employment
AFTER INSERT OR UPDATE OR DELETE ON lab2.employment
FOR EACH ROW
EXECUTE FUNCTION lab2.audit_row();
