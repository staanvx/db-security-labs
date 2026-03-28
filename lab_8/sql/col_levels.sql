SET search_path = lab1, public;

DROP TABLE IF EXISTS employment_column_levels CASCADE;

CREATE TABLE employment_column_levels AS
SELECT
    pgp_sym_encrypt(fio, 'common_key')           AS fio,
    pgp_sym_encrypt(dept_name, 'common_key')     AS dept_name,
    pgp_sym_encrypt(dept_no::text, 'common_key') AS dept_no,
    
    pgp_sym_encrypt(share::text, 'confidential_1')    AS share,
    pgp_sym_encrypt(position, 'confidential_2')       AS position,
    
    pgp_sym_encrypt(descriptor, 'common_key')    AS descriptor
FROM employment_big;

