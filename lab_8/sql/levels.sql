SET search_path = lab1, public;

DROP TABLE IF EXISTS employment_levels CASCADE;

CREATE TABLE employment_levels (
    fio text NOT NULL,
    dept_name text NOT NULL,
    dept_no integer NOT NULL,
    share numeric(6,2) NOT NULL,
    descriptor text NOT NULL,
    position bytea NOT NULL,
    confidentiality_level integer NOT NULL CHECK (confidentiality_level IN (1, 2))
);

INSERT INTO employment_levels (
    fio,
    dept_name,
    dept_no,
    share,
    descriptor,
    position,
    confidentiality_level
)
SELECT
    fio,
    dept_name,
    dept_no,
    share,
    descriptor,
    CASE
        WHEN dept_no <= 5 THEN pgp_sym_encrypt(position, 'key_level_1')
        ELSE pgp_sym_encrypt(position, 'key_level_2')
    END AS position,
    CASE
        WHEN dept_no <= 5 THEN 1
        ELSE 2
    END AS confidentiality_level
FROM employment_big;

