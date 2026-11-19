-- =============================================================
-- CP3: Query Optimization Indexes
-- Database: BookMyShow
-- Schema: bms
-- PostgreSQL 15+
-- =============================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;

SET search_path TO bms, public;


-- =============================================================
-- 1. SHOWS TABLE
-- =============================================================

-- Used by:
-- R01, R07, R08, R10, R16, R17, R18, R25
--
-- Helps queries that filter shows using a date/time range.
-- starts_at is first because these queries search a time range.
CREATE INDEX IF NOT EXISTS idx_shows_starts_at
ON shows (starts_at)
INCLUDE (show_id, screen_id, movie_id);


-- Used by:
-- R02, R19, W05
--
-- movie_id is first because these queries filter by a movie.
-- starts_at is second because they also filter by a date range.
CREATE INDEX IF NOT EXISTS idx_shows_movie_starts_at
ON shows (movie_id, starts_at)
INCLUDE (show_id, screen_id, format);


-- Used by:
-- R01, R07, R10
--
-- screen_id is first because these queries find shows belonging
-- to a particular screen.
-- starts_at helps find shows in the required time range and
-- helps the self-join in R10.
CREATE INDEX IF NOT EXISTS idx_shows_screen_starts_at
ON shows (screen_id, starts_at)
INCLUDE (show_id, ends_at, movie_id);


-- =============================================================
-- 2. BOOKINGS TABLE
-- =============================================================

-- Used by:
-- R08, R12, R16, R18, R19
--
-- These queries connect bookings with shows using show_id.
-- status is also used to filter or calculate booking information.
-- Included columns help retrieve booking details from the index.
CREATE INDEX IF NOT EXISTS idx_bookings_show_status
ON bookings (show_id, status)
INCLUDE (booking_id, customer_id, ticket_amount, num_tickets);


-- Used by:
-- R05
--
-- R05 searches confirmed bookings for one customer.
-- customer_id and status are the filtering conditions.
-- show_id is used to join with the shows table.
CREATE INDEX IF NOT EXISTS idx_bookings_customer_show_confirmed
ON bookings (customer_id, show_id)
INCLUDE (booking_code, num_tickets)
WHERE status = 'CONFIRMED';


-- Used by:
-- R20, R21
--
-- These queries filter confirmed bookings using booked_at.
-- The partial index stores only confirmed bookings.
CREATE INDEX IF NOT EXISTS idx_bookings_confirmed_booked_at
ON bookings (booked_at)
INCLUDE (customer_id, total_amount, show_id)
WHERE status = 'CONFIRMED';


-- Used by:
-- W02, W03
--
-- These queries find the pending booking with the smallest
-- booking_id. The partial index contains only pending bookings.
CREATE INDEX IF NOT EXISTS idx_bookings_pending_booking_id
ON bookings (booking_id)
WHERE status = 'PENDING';


-- Used by:
-- R09, W04
--
-- These queries find pending bookings using booked_at.
-- The partial index avoids storing rows with other statuses.
CREATE INDEX IF NOT EXISTS idx_bookings_pending_booked_at
ON bookings (booked_at)
INCLUDE (booking_id, show_id, num_tickets)
WHERE status = 'PENDING';


-- Used by:
-- R22
--
-- R22 displays bookings ordered by newest booked_at first.
-- Included columns can help PostgreSQL retrieve the selected
-- page directly from the index.
CREATE INDEX IF NOT EXISTS idx_bookings_booked_at_desc
ON bookings (booked_at DESC)
INCLUDE (booking_id, booking_code, customer_id, show_id, status);


-- Used by:
-- R13
--
-- R13 checks whether an offer code has been used by any booking.
-- NULL offer codes are not needed for this lookup.
CREATE INDEX IF NOT EXISTS idx_bookings_offer_code
ON bookings (offer_code)
WHERE offer_code IS NOT NULL;


-- =============================================================
-- 3. BOOKING_SEATS TABLE
-- =============================================================

-- Used by:
-- W04
--
-- W04 deletes seat rows belonging to expired pending bookings.
-- booking_id helps find the seat rows for each booking.
CREATE INDEX IF NOT EXISTS idx_booking_seats_booking_id
ON booking_seats (booking_id);


-- Used by:
-- R11, R17, R24
--
-- These queries find booking_seats using seat_id.
-- The primary key is (show_id, seat_id), so it is not ideal
-- for lookups that start with seat_id.
CREATE INDEX IF NOT EXISTS idx_booking_seats_seat_show
ON booking_seats (seat_id, show_id)
INCLUDE (price);


-- =============================================================
-- 4. SEATS TABLE
-- =============================================================

-- Used by:
-- W02, R17
--
-- W02 finds the lowest seat IDs for a particular screen.
-- R17 finds the seats belonging to screen 101.
CREATE INDEX IF NOT EXISTS idx_seats_screen_seat
ON seats (screen_id, seat_id)
INCLUDE (row_label, seat_number, seat_class);


-- =============================================================
-- 5. MOVIES TABLE
-- =============================================================

-- Used by:
-- R06
--
-- R06 searches for a word anywhere inside a movie title.
-- A normal B-tree index is not suitable for ILIKE '%text%'.
-- GIN with pg_trgm supports this type of search.
CREATE INDEX IF NOT EXISTS idx_movies_title_trgm
ON movies USING GIN (title gin_trgm_ops);


-- =============================================================
-- 6. MOVIE_REVIEWS TABLE
-- =============================================================

-- Used by:
-- R14
--
-- R14 joins movie_reviews with movies using movie_id and
-- calculates average ratings and review counts.
CREATE INDEX IF NOT EXISTS idx_movie_reviews_movie
ON movie_reviews (movie_id)
INCLUDE (rating);


-- =============================================================
-- UPDATE TABLE STATISTICS
-- =============================================================

ANALYZE;

-- =============================================================
-- END OF CP3 INDEXES
-- =============================================================