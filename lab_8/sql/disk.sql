SET search_path = lab1, public;

DROP TABLE IF EXISTS employment_disk_enc;

CREATE TABLE employment_disk_enc
TABLESPACE secure_space
AS
SELECT * FROM employment_big;

