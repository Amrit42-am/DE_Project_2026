-- =============================================================
-- CP4: Partitioning demonstration for booking_seats
-- PostgreSQL 15+
--
-- Design: HASH partitioning on show_id with 16 partitions.
-- A separate table is created so the original booking_seats
-- table and benchmark results remain unchanged.
-- =============================================================

SET search_path TO bms, public;

DROP TABLE IF EXISTS bms.booking_seats_partitioned CASCADE;

CREATE TABLE bms.booking_seats_partitioned (
    booking_id INTEGER NOT NULL,
    show_id INTEGER NOT NULL,
    seat_id INTEGER NOT NULL,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),

    -- The partition key must be included in the primary key.
    CONSTRAINT pk_booking_seats_partitioned
        PRIMARY KEY (show_id, seat_id),

    CONSTRAINT fk_booking_seats_partitioned_booking
        FOREIGN KEY (booking_id, show_id)
        REFERENCES bms.bookings(booking_id, show_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_booking_seats_partitioned_seat
        FOREIGN KEY (seat_id)
        REFERENCES bms.seats(seat_id)
        ON DELETE RESTRICT
) PARTITION BY HASH (show_id);


-- Create 16 hash partitions.

CREATE TABLE bms.booking_seats_part_00
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 0);

CREATE TABLE bms.booking_seats_part_01
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 1);

CREATE TABLE bms.booking_seats_part_02
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 2);

CREATE TABLE bms.booking_seats_part_03
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 3);

CREATE TABLE bms.booking_seats_part_04
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 4);

CREATE TABLE bms.booking_seats_part_05
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 5);

CREATE TABLE bms.booking_seats_part_06
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 6);

CREATE TABLE bms.booking_seats_part_07
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 7);

CREATE TABLE bms.booking_seats_part_08
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 8);

CREATE TABLE bms.booking_seats_part_09
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 9);

CREATE TABLE bms.booking_seats_part_10
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 10);

CREATE TABLE bms.booking_seats_part_11
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 11);

CREATE TABLE bms.booking_seats_part_12
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 12);

CREATE TABLE bms.booking_seats_part_13
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 13);

CREATE TABLE bms.booking_seats_part_14
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 14);

CREATE TABLE bms.booking_seats_part_15
    PARTITION OF bms.booking_seats_partitioned
    FOR VALUES WITH (MODULUS 16, REMAINDER 15);


-- Copy the large dataset into the partitioned table.

INSERT INTO bms.booking_seats_partitioned
    (booking_id, show_id, seat_id, price)
SELECT booking_id, show_id, seat_id, price
FROM bms.booking_seats;

ANALYZE bms.booking_seats_partitioned;


-- Verify row counts.

SELECT
    (SELECT COUNT(*) FROM bms.booking_seats) AS original_rows,
    (SELECT COUNT(*) FROM bms.booking_seats_partitioned)
        AS partitioned_rows;


-- Demonstrate partition pruning.
-- Only one partition should be scanned for this show_id.

EXPLAIN (ANALYZE, BUFFERS)
SELECT booking_id, seat_id, price
FROM bms.booking_seats_partitioned
WHERE show_id = 144446;


-- Display all partitions.

SELECT
    child.relname AS partition_name
FROM pg_inherits i
JOIN pg_class parent
    ON parent.oid = i.inhparent
JOIN pg_class child
    ON child.oid = i.inhrelid
JOIN pg_namespace n
    ON n.oid = parent.relnamespace
WHERE n.nspname = 'bms'
  AND parent.relname = 'booking_seats_partitioned'
ORDER BY child.relname;


-- =============================================================
-- End of partitioning demonstration
-- =============================================================