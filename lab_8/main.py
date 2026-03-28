import os
import json
import base64
import time
from decimal import Decimal, ROUND_HALF_UP
from collections import defaultdict
from typing import Any

import psycopg2
from psycopg2.extensions import connection as PGConnection
from cryptography.hazmat.primitives.ciphers.aead import AESGCM


DB_CONFIG = {
    "host": "127.0.0.1",
    "port": 5432,
    "dbname": "lab8",
    "user": "postgres",
    "password": "postgres",
}

SECRET_KEY = b"0123456789abcdef0123456789abcdef"


def encrypt_text(value: str) -> bytes:
    aesgcm = AESGCM(SECRET_KEY)
    nonce = os.urandom(12)
    ciphertext = aesgcm.encrypt(nonce, value.encode("utf-8"), None)

    payload = {
        "nonce": base64.b64encode(nonce).decode("ascii"),
        "ciphertext": base64.b64encode(ciphertext).decode("ascii"),
    }
    return json.dumps(payload, ensure_ascii=False).encode("utf-8")


def decrypt_text(blob: bytes) -> str:
    payload = json.loads(blob.decode("utf-8"))
    nonce = base64.b64decode(payload["nonce"])
    ciphertext = base64.b64decode(payload["ciphertext"])

    aesgcm = AESGCM(SECRET_KEY)
    plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    return plaintext.decode("utf-8")


def get_connection() -> PGConnection:
    return psycopg2.connect(**DB_CONFIG)


def create_schema_and_table(conn: PGConnection) -> None:
    with conn.cursor() as cur:
        cur.execute("""
            CREATE SCHEMA IF NOT EXISTS lab1;

            CREATE TABLE IF NOT EXISTS lab1.employment_e2e (
                record_id      bigserial PRIMARY KEY,
                fio_enc        bytea NOT NULL,
                dept_name_enc  bytea NOT NULL,
                dept_no_enc    bytea NOT NULL,
                share_enc      bytea NOT NULL,
                position_enc   bytea NOT NULL,
                descriptor_enc bytea NOT NULL
            );
        """)
    conn.commit()


def truncate_e2e_table(conn: PGConnection) -> None:
    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE lab1.employment_e2e RESTART IDENTITY;")
    conn.commit()


def count_rows(conn: PGConnection, table_name: str) -> int:
    with conn.cursor() as cur:
        cur.execute(f"SELECT COUNT(*) FROM {table_name};")
        result = cur.fetchone()
    if result is None:
        return 0
    return int(result[0])


def fill_e2e_from_plain(conn: PGConnection) -> None:
    with conn.cursor() as cur:
        cur.execute("""
            SELECT fio, dept_name, dept_no, share, position, descriptor
            FROM lab1.employment_big
            ORDER BY dept_no, fio, position
        """)
        rows = cur.fetchall()

    print(f"Найдено строк в employment_big: {len(rows)}")

    t0 = time.perf_counter()

    insert_sql = """
        INSERT INTO lab1.employment_e2e
        (fio_enc, dept_name_enc, dept_no_enc, share_enc, position_enc, descriptor_enc)
        VALUES (%s, %s, %s, %s, %s, %s)
    """

    with conn.cursor() as cur:
        for fio, dept_name, dept_no, share, position, descriptor in rows:
            cur.execute(
                insert_sql,
                (
                    psycopg2.Binary(encrypt_text(str(fio))),
                    psycopg2.Binary(encrypt_text(str(dept_name))),
                    psycopg2.Binary(encrypt_text(str(dept_no))),
                    psycopg2.Binary(encrypt_text(str(share))),
                    psycopg2.Binary(encrypt_text(str(position))),
                    psycopg2.Binary(encrypt_text(str(descriptor))),
                ),
            )

    conn.commit()
    t1 = time.perf_counter()

    print(f"Таблица employment_e2e заполнена за {t1 - t0:.4f} с")


def show_one_raw_row(conn: PGConnection) -> None:
    with conn.cursor() as cur:
        cur.execute("""
            SELECT record_id, fio_enc, dept_name_enc, dept_no_enc,
                   share_enc, position_enc, descriptor_enc
            FROM lab1.employment_e2e
            ORDER BY record_id
            LIMIT 1
        """)
        row = cur.fetchone()

    if row is None:
        print("В employment_e2e нет строк")
        return

    print("\nОдна зашифрованная строка из БД:")
    print("record_id:", row[0])
    print("fio_enc:", bytes(row[1]).decode("utf-8"))
    print("dept_name_enc:", bytes(row[2]).decode("utf-8"))
    print("dept_no_enc:", bytes(row[3]).decode("utf-8"))
    print("share_enc:", bytes(row[4]).decode("utf-8"))
    print("position_enc:", bytes(row[5]).decode("utf-8"))
    print("descriptor_enc:", bytes(row[6]).decode("utf-8"))


def show_one_decrypted_row(conn: PGConnection) -> None:
    with conn.cursor() as cur:
        cur.execute("""
            SELECT record_id, fio_enc, dept_name_enc, dept_no_enc,
                   share_enc, position_enc, descriptor_enc
            FROM lab1.employment_e2e
            ORDER BY record_id
            LIMIT 1
        """)
        row = cur.fetchone()

    if row is None:
        print("В employment_e2e нет строк")
        return

    decrypted: dict[str, Any] = {
        "record_id": row[0],
        "fio": decrypt_text(bytes(row[1])),
        "dept_name": decrypt_text(bytes(row[2])),
        "dept_no": int(decrypt_text(bytes(row[3]))),
        "share": Decimal(decrypt_text(bytes(row[4]))),
        "position": decrypt_text(bytes(row[5])),
        "descriptor": decrypt_text(bytes(row[6])),
    }

    print("\nРасшифрованная строка:")
    for key, value in decrypted.items():
        print(f"{key}: {value}")


def run_e2e_control_query(conn: PGConnection, verbose: bool = True) -> float:
    """
    Эквивалент контрольного запроса:
    SELECT dept_no, position, COUNT(*), ROUND(AVG(share), 2)
    FROM lab1.employment_big
    GROUP BY dept_no, position
    ORDER BY emp_count DESC, dept_no, position
    LIMIT 10;
    """
    t0 = time.perf_counter()

    with conn.cursor() as cur:
        cur.execute("""
            SELECT dept_no_enc, position_enc, share_enc
            FROM lab1.employment_e2e
        """)
        rows = cur.fetchall()

    t1 = time.perf_counter()

    groups: dict[tuple[int, str], dict[str, Any]] = defaultdict(
        lambda: {"count": 0, "sum_share": Decimal("0")}
    )

    for dept_no_enc, position_enc, share_enc in rows:
        dept_no = int(decrypt_text(bytes(dept_no_enc)))
        position = decrypt_text(bytes(position_enc))
        share = Decimal(decrypt_text(bytes(share_enc)))

        key = (dept_no, position)
        groups[key]["count"] += 1
        groups[key]["sum_share"] += share

    t2 = time.perf_counter()

    result: list[tuple[int, str, int, Decimal]] = []
    for (dept_no, position), data in groups.items():
        avg_share = (data["sum_share"] / data["count"]).quantize(
            Decimal("0.01"),
            rounding=ROUND_HALF_UP,
        )
        result.append((dept_no, position, data["count"], avg_share))

    result.sort(key=lambda x: (-x[2], x[0], x[1]))
    top10 = result[:10]

    t3 = time.perf_counter()

    if verbose:
        print("\nРезультат эквивалентного E2E-запроса:")
        print(f"{'dept_no':<8} {'position':<15} {'emp_count':<10} {'avg_share':<10}")
        for dept_no, position, emp_count, avg_share in top10:
            print(f"{dept_no:<8} {position:<15} {emp_count:<10} {avg_share:<10}")

        print("\nЭтапы выполнения:")
        print(f"Чтение ciphertext из БД: {t1 - t0:.4f} с")
        print(f"Расшифровка + агрегация: {t2 - t1:.4f} с")
        print(f"Сортировка + LIMIT:     {t3 - t2:.4f} с")
        print(f"Полный E2E-запрос:      {t3 - t0:.4f} с")

    return t3 - t0


def measure_e2e_n_times(conn: PGConnection, n: int = 10) -> None:
    times: list[float] = []

    print(f"\nЗапуск {n} замеров E2E-запроса")
    for i in range(n):
        elapsed = run_e2e_control_query(conn, verbose=False)
        times.append(elapsed)
        print(f"Замер {i + 1}: {elapsed:.4f} с")

    avg_time = sum(times) / len(times)
    min_time = min(times)
    max_time = max(times)

    print("\nИтоги замеров:")
    print(f"Среднее время: {avg_time:.4f} с")
    print(f"Минимум:       {min_time:.4f} с")
    print(f"Максимум:      {max_time:.4f} с")


def print_sizes(conn: PGConnection) -> None:
    with conn.cursor() as cur:
        cur.execute("""
            SELECT pg_size_pretty(pg_total_relation_size('lab1.employment_big'));
        """)
        big_size = cur.fetchone()

        cur.execute("""
            SELECT pg_size_pretty(pg_total_relation_size('lab1.employment_e2e'));
        """)
        e2e_size = cur.fetchone()

    print("\nРазмеры таблиц:")
    print("employment_big:", big_size[0] if big_size else "N/A")
    print("employment_e2e:", e2e_size[0] if e2e_size else "N/A")


def main() -> None:
    conn = get_connection()
    try:
        create_schema_and_table(conn)

        print("Количество строк до заполнения:")
        print("employment_big:", count_rows(conn, "lab1.employment_big"))
        print("employment_e2e:", count_rows(conn, "lab1.employment_e2e"))

        truncate_e2e_table(conn)
        fill_e2e_from_plain(conn)

        print("\nКоличество строк после заполнения:")
        print("employment_big:", count_rows(conn, "lab1.employment_big"))
        print("employment_e2e:", count_rows(conn, "lab1.employment_e2e"))

        show_one_raw_row(conn)
        show_one_decrypted_row(conn)

        run_e2e_control_query(conn, verbose=True)
        measure_e2e_n_times(conn, n=10)

        print_sizes(conn)

    finally:
        conn.close()


if __name__ == "__main__":
    main()
