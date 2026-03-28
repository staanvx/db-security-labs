SET search_path = lab1, public;

DROP TABLE IF EXISTS employment_table_enc CASCADE;

CREATE TABLE employment_table_enc (
    fio bytea NOT NULL,
    dept_name bytea NOT NULL,
    dept_no bytea NOT NULL,
    share bytea NOT NULL,
    position bytea NOT NULL,
    descriptor bytea NOT NULL
);

INSERT INTO employment_table_enc
SELECT
    pgp_sym_encrypt(fio, 'key'),
    pgp_sym_encrypt(dept_name, 'key'),
    pgp_sym_encrypt(dept_no::text, 'key'),
    pgp_sym_encrypt(share::text, 'key'),
    pgp_sym_encrypt(position, 'key'),
    pgp_sym_encrypt(descriptor, 'key')
FROM employment_big;


SELECT
    (pgp_sym_decrypt(dept_no, 'key'))::int AS dept_no,
    pgp_sym_decrypt(position, 'key') AS position,
    COUNT(*) AS emp_count,
    ROUND(AVG((pgp_sym_decrypt(share, 'key'))::numeric), 2) AS avg_share
FROM employment_table_enc
GROUP BY
    (pgp_sym_decrypt(dept_no, 'key'))::int,
    pgp_sym_decrypt(position, 'key')
ORDER BY emp_count DESC
LIMIT 10;
