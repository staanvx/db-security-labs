CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP SCHEMA IF EXISTS lab9 CASCADE;
CREATE SCHEMA lab9;
SET search_path = lab9;

CREATE TABLE sellers (
    seller_id serial PRIMARY KEY,
    seller_fio text NOT NULL UNIQUE,
    activity_area text NOT NULL CHECK (activity_area IN (
        'Электроника', 'Смартфоны', 'Компьютеры', 'Бытовая техника',
        'Одежда', 'Обувь', 'Аксессуары', 'Книги', 'Канцтовары',
        'Спорт', 'Товары для дома', 'Косметика'
    )),
    experience_years integer NOT NULL CHECK (experience_years BETWEEN 0 AND 40),
    seller_rating numeric(3,2) NOT NULL CHECK (seller_rating BETWEEN 1 AND 5),
    works_with_delivery boolean NOT NULL
);

CREATE TABLE buyers (
    buyer_id serial PRIMARY KEY,
    buyer_fio text NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id serial PRIMARY KEY,
    product_name text NOT NULL,
    product_category text NOT NULL,
    product_rating numeric(3,2) NOT NULL CHECK (product_rating BETWEEN 1 AND 5)
);

CREATE TABLE deals (
    deal_id serial PRIMARY KEY,
    seller_id integer NOT NULL REFERENCES sellers(seller_id) ON DELETE CASCADE,
    buyer_id integer NOT NULL REFERENCES buyers(buyer_id) ON DELETE CASCADE,
    product_id integer NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    deal_cost numeric(12,2) NOT NULL CHECK (deal_cost > 0),
    delivery_used boolean NOT NULL,
    deal_ts timestamp NOT NULL DEFAULT now()
);

INSERT INTO sellers (seller_fio, activity_area, experience_years, seller_rating, works_with_delivery) VALUES
('Александров Иван Петрович', 'Смартфоны', 1, 4.81, true),
('Белов Сергей Николаевич', 'Электроника', 2, 4.66, true),
('Васильева Анна Игоревна', 'Компьютеры', 3, 4.72, true),
('Громов Максим Андреевич', 'Бытовая техника', 4, 4.43, false),
('Денисова Мария Олеговна', 'Одежда', 5, 4.35, true),
('Егоров Павел Дмитриевич', 'Обувь', 6, 4.52, false),
('Жукова Ирина Сергеевна', 'Аксессуары', 7, 4.21, true),
('Зайцев Кирилл Романович', 'Книги', 8, 4.10, true),
('Ильина Ольга Викторовна', 'Канцтовары', 9, 4.18, false),
('Козлов Артем Михайлович', 'Спорт', 10, 4.59, true),
('Лебедева Елена Павловна', 'Товары для дома', 11, 4.37, true),
('Морозов Никита Алексеевич', 'Косметика', 12, 4.74, false),
('Новикова Дарья Денисовна', 'Смартфоны', 13, 4.93, true),
('Орлов Роман Евгеньевич', 'Электроника', 14, 4.49, false),
('Павлова Светлана Юрьевна', 'Компьютеры', 15, 4.56, true),
('Романов Андрей Ильич', 'Бытовая техника', 16, 4.05, true),
('Соколова Наталья Ивановна', 'Одежда', 17, 4.61, false),
('Титов Виктор Олегович', 'Обувь', 18, 4.32, true),
('Ушакова Алиса Константиновна', 'Аксессуары', 19, 4.28, true),
('Федоров Дмитрий Сергеевич', 'Книги', 20, 4.17, false),
('Харитонова Ксения Вадимовна', 'Канцтовары', 21, 4.46, true),
('Цветков Георгий Борисович', 'Спорт', 22, 4.64, true),
('Чернова Валерия Матвеевна', 'Товары для дома', 23, 4.24, false),
('Широков Евгений Аркадьевич', 'Косметика', 24, 4.70, true),
('Щербакова Полина Игоревна', 'Смартфоны', 25, 4.88, true),
('Юдин Лев Александрович', 'Электроника', 26, 4.41, false),
('Яковлева Вероника Петровна', 'Компьютеры', 27, 4.54, true),
('Андреева Софья Максимовна', 'Бытовая техника', 28, 4.13, true),
('Борисов Михаил Валерьевич', 'Одежда', 29, 4.68, false),
('Волкова Екатерина Романовна', 'Обувь', 30, 4.39, true),
('Гаврилов Степан Денисович', 'Аксессуары', 31, 4.27, true),
('Давыдова Лидия Павловна', 'Книги', 32, 4.16, false),
('Ефимов Руслан Артемович', 'Канцтовары', 33, 4.31, true),
('Захарова Виктория Ильинична', 'Спорт', 34, 4.57, false),
('Крылов Олег Никитич', 'Товары для дома', 35, 4.22, true),
('Мельникова Алина Юрьевна', 'Косметика', 36, 4.76, true);

INSERT INTO buyers (buyer_fio) VALUES
('Абрамов Петр Иванович'), ('Баранова Надежда Олеговна'),
('Виноградов Семен Павлович'), ('Гордеева Тамара Ильинична'),
('Дроздов Антон Сергеевич'), ('Елисеева Жанна Романовна'),
('Зимин Федор Алексеевич'), ('Исаева Лариса Денисовна'),
('Комаров Игорь Викторович'), ('Лукина Юлия Максимовна'),
('Макаров Тимур Андреевич'), ('Нестерова Оксана Борисовна'),
('Поляков Глеб Константинович'), ('Семенова Кира Михайловна'),
('Тарасов Матвей Дмитриевич'), ('Фомина Диана Евгеньевна'),
('Шестаков Руслан Петрович'), ('Яшина Вера Николаевна');

INSERT INTO products (product_name, product_category, product_rating) VALUES
('Смартфон Nova X', 'Смартфоны', 4.70),
('Наушники AirBeat', 'Электроника', 4.42),
('Ноутбук WorkPro', 'Компьютеры', 4.65),
('Пылесос CleanMax', 'Бытовая техника', 4.21),
('Куртка Storm', 'Одежда', 4.35),
('Кроссовки Urban', 'Обувь', 4.48),
('Рюкзак City', 'Аксессуары', 4.28),
('Роман Север', 'Книги', 4.12),
('Набор маркеров', 'Канцтовары', 4.19),
('Гантели 10 кг', 'Спорт', 4.58),
('Органайзер Loft', 'Товары для дома', 4.31),
('Крем Aqua', 'Косметика', 4.62);

INSERT INTO deals (seller_id, buyer_id, product_id, deal_cost, delivery_used, deal_ts)
SELECT
    s.seller_id,
    ((s.seller_id + g.n - 2) % 18) + 1 AS buyer_id,
    ((s.seller_id + g.n - 2) % 12) + 1 AS product_id,
    900 + s.seller_id * 137 + g.n * 615 AS deal_cost,
    CASE WHEN g.n = 1 THEN s.works_with_delivery ELSE NOT s.works_with_delivery END,
    timestamp '2026-03-01 10:00:00' + ((s.seller_id * 2 + g.n) || ' hours')::interval
FROM sellers s
CROSS JOIN generate_series(1, 2) AS g(n);

CREATE OR REPLACE VIEW v_seller_activity AS
SELECT
    s.seller_fio,
    s.activity_area,
    s.experience_years,
    s.seller_rating,
    s.works_with_delivery,
    count(d.deal_id)::integer AS total_deals
FROM sellers s
LEFT JOIN deals d ON d.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_fio, s.activity_area, s.experience_years,
         s.seller_rating, s.works_with_delivery;

CREATE OR REPLACE VIEW v_buyer_deals AS
SELECT
    b.buyer_fio,
    p.product_name,
    d.deal_cost,
    p.product_rating,
    d.delivery_used
FROM deals d
JOIN buyers b ON b.buyer_id = d.buyer_id
JOIN products p ON p.product_id = d.product_id;

CREATE OR REPLACE FUNCTION generalize_area(src text, level integer)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN level <= 0 THEN src
        WHEN level = 1 THEN CASE
            WHEN src IN ('Электроника', 'Смартфоны', 'Компьютеры', 'Бытовая техника') THEN 'Техника'
            WHEN src IN ('Одежда', 'Обувь', 'Аксессуары') THEN 'Мода'
            WHEN src IN ('Книги', 'Канцтовары') THEN 'Книги и офис'
            WHEN src IN ('Спорт', 'Товары для дома', 'Косметика') THEN 'Дом, спорт и уход'
            ELSE 'Другое'
        END
        ELSE '*'
    END;
$$;

CREATE OR REPLACE FUNCTION generalize_experience(src integer, level integer)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN level <= 0 THEN src::text
        WHEN level = 1 THEN
            ((src / 5) * 5)::text || '-' || (((src / 5) * 5) + 4)::text
        WHEN level = 2 THEN
            CASE
                WHEN src BETWEEN 0 AND 9 THEN '0-9'
                WHEN src BETWEEN 10 AND 19 THEN '10-19'
                WHEN src BETWEEN 20 AND 29 THEN '20-29'
                ELSE '30-40'
            END
        ELSE '*'
    END;
$$;

CREATE OR REPLACE FUNCTION generalize_rating(src numeric, level integer)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN level <= 0 THEN to_char(src, 'FM9.00')
        WHEN level = 1 THEN trunc(src, 1)::text || '-' || (trunc(src, 1) + 0.09)::text
        WHEN level = 2 THEN
            CASE
                WHEN src < 4.30 THEN '4.00-4.29'
                WHEN src < 4.60 THEN '4.30-4.59'
                ELSE '4.60-5.00'
            END
        ELSE '*'
    END;
$$;

CREATE OR REPLACE FUNCTION generalize_delivery(src boolean, level integer)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN level <= 0 THEN CASE WHEN src THEN 'Да' ELSE 'Нет' END
        ELSE '*'
    END;
$$;

CREATE OR REPLACE FUNCTION seller_activity_generalized(
    area_level integer,
    exp_level integer,
    rating_level integer,
    delivery_level integer
)
RETURNS TABLE (
    seller_fio text,
    activity_area text,
    experience_years text,
    seller_rating text,
    works_with_delivery text,
    total_deals integer,
    eq_class_size bigint
)
LANGUAGE sql
STABLE
AS $$
    WITH generalized AS (
        SELECT
            v.seller_fio,
            lab9.generalize_area(v.activity_area, area_level) AS activity_area,
            lab9.generalize_experience(v.experience_years, exp_level) AS experience_years,
            lab9.generalize_rating(v.seller_rating, rating_level) AS seller_rating,
            lab9.generalize_delivery(v.works_with_delivery, delivery_level) AS works_with_delivery,
            v.total_deals
        FROM lab9.v_seller_activity v
    )
    SELECT
        g.*,
        count(*) OVER (
            PARTITION BY g.activity_area, g.experience_years,
                         g.seller_rating, g.works_with_delivery
        ) AS eq_class_size
    FROM generalized g;
$$;

CREATE OR REPLACE VIEW v_k_lattice_nodes AS
SELECT
    area_level,
    exp_level,
    rating_level,
    delivery_level,
    min(eq_class_size) AS min_k,
    (area_level::numeric / 2
     + exp_level::numeric / 3
     + rating_level::numeric / 3
     + delivery_level::numeric / 1) / 4 AS normalized_loss
FROM generate_series(0, 2) AS area_level
CROSS JOIN generate_series(0, 3) AS exp_level
CROSS JOIN generate_series(0, 3) AS rating_level
CROSS JOIN generate_series(0, 1) AS delivery_level
CROSS JOIN LATERAL lab9.seller_activity_generalized(area_level, exp_level, rating_level, delivery_level)
GROUP BY area_level, exp_level, rating_level, delivery_level;

CREATE TABLE seller_activity_masked (
    seller_fio text PRIMARY KEY,
    activity_area text NOT NULL,
    experience_years text NOT NULL,
    seller_rating text NOT NULL,
    works_with_delivery text NOT NULL,
    total_deals integer NOT NULL,
    eq_class_size bigint NOT NULL,
    masked_at timestamp NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION refresh_seller_activity_masked()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE lab9.seller_activity_masked;

    INSERT INTO lab9.seller_activity_masked (
        seller_fio,
        activity_area,
        experience_years,
        seller_rating,
        works_with_delivery,
        total_deals,
        eq_class_size
    )
    SELECT
        encode(public.digest(seller_fio, 'sha256'), 'hex') AS seller_fio,
        activity_area,
        experience_years,
        seller_rating,
        works_with_delivery,
        total_deals,
        eq_class_size
    FROM lab9.seller_activity_generalized(1, 3, 3, 0);
END;
$$;

CREATE OR REPLACE FUNCTION trg_refresh_seller_activity_masked()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM lab9.refresh_seller_activity_masked();
    RETURN NULL;
END;
$$;

CREATE TRIGGER sellers_refresh_mask_after_change
AFTER INSERT OR UPDATE OR DELETE ON sellers
FOR EACH STATEMENT EXECUTE FUNCTION trg_refresh_seller_activity_masked();

CREATE TRIGGER deals_refresh_mask_after_change
AFTER INSERT OR UPDATE OR DELETE ON deals
FOR EACH STATEMENT EXECUTE FUNCTION trg_refresh_seller_activity_masked();

SELECT refresh_seller_activity_masked();

CREATE OR REPLACE VIEW v_seller_activity_masked AS
SELECT
    seller_fio,
    activity_area,
    experience_years,
    seller_rating,
    works_with_delivery,
    total_deals
FROM seller_activity_masked;

CREATE OR REPLACE FUNCTION laplace_noise(scale numeric)
RETURNS numeric
LANGUAGE sql
VOLATILE
AS $$
    SELECT
        CASE WHEN u < 0.5
            THEN scale * ln(2 * u)
            ELSE -scale * ln(2 * (1 - u))
        END
    FROM (SELECT greatest(least(random(), 0.999999), 0.000001)::numeric AS u) r;
$$;

CREATE OR REPLACE FUNCTION randomized_response_bool(src boolean, epsilon numeric)
RETURNS boolean
LANGUAGE sql
VOLATILE
AS $$
    SELECT CASE
        WHEN random() < (exp(epsilon::double precision) /
                         (exp(epsilon::double precision) + 1))
            THEN src
        ELSE NOT src
    END;
$$;

CREATE OR REPLACE VIEW v_buyer_deals_dp AS
SELECT
    encode(public.digest(buyer_fio, 'sha256'), 'hex') AS buyer_fio,
    product_name,
    greatest(0, round(deal_cost + laplace_noise(3000), 2)) AS deal_cost,
    least(5, greatest(1, round(product_rating + laplace_noise(0.20), 2))) AS product_rating,
    randomized_response_bool(delivery_used, 1.0) AS delivery_used
FROM v_buyer_deals;

CREATE OR REPLACE VIEW v_utility_k_anonymity AS
SELECT
    count(*) AS rows_total,
    min(eq_class_size) AS achieved_k,
    round(avg(
        1.0 / 2
        + 3.0 / 3
        + 3.0 / 3
        + 0.0 / 1
    ) / 4, 4) AS normalized_certainty_penalty
FROM seller_activity_masked;

CREATE OR REPLACE VIEW v_utility_dp_euclidean AS
WITH randomized AS MATERIALIZED (
    SELECT
        d.deal_id,
        d.deal_cost AS original_cost,
        greatest(0, round(d.deal_cost + lab9.laplace_noise(3000), 2)) AS randomized_cost,
        p.product_rating AS original_rating,
        least(5, greatest(1, round(p.product_rating + lab9.laplace_noise(0.20), 2))) AS randomized_rating,
        d.delivery_used AS original_delivery,
        lab9.randomized_response_bool(d.delivery_used, 1.0) AS randomized_delivery
    FROM lab9.deals d
    JOIN lab9.products p ON p.product_id = d.product_id
),
bounds AS (
    SELECT
        nullif(max(original_cost) - min(original_cost), 0) AS cost_range
    FROM randomized
)
SELECT
    count(*) AS rows_total,
    round(sqrt(sum(power((randomized_cost - original_cost)::double precision, 2)))::numeric, 4) AS deal_cost_euc,
    round(sqrt(sum(power((randomized_rating - original_rating)::double precision, 2)))::numeric, 4) AS product_rating_euc,
    round(sqrt(sum(
        CASE WHEN randomized_delivery = original_delivery THEN 0 ELSE 1 END
    ))::numeric, 4) AS delivery_used_euc,
    round(sqrt(avg(
        power(((randomized_cost - original_cost) / cost_range)::double precision, 2)
        + power(((randomized_rating - original_rating) / 4.0)::double precision, 2)
        + CASE WHEN randomized_delivery = original_delivery THEN 0 ELSE 1 END
    ))::numeric, 4) AS normalized_euclidean_loss
FROM randomized, bounds;
