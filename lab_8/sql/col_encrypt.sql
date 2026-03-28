SET search_path = lab1, public;

DROP TABLE IF EXISTS employment_col_enc;

CREATE TABLE employment_col_enc (
    fio text NOT NULL,
    dept_name text NOT NULL,
    dept_no integer NOT NULL,
    share bytea NOT NULL,
    position bytea NOT NULL,
    descriptor bytea NOT NULL
);

INSERT INTO employment_col_enc
SELECT
    fio,
    dept_name,
    dept_no,
    pgp_sym_encrypt(share::text, 'key_share'),
    pgp_sym_encrypt(position, 'key_position'),
    pgp_sym_encrypt(descriptor, 'key_descriptor')
FROM employment_big;
