# Phase 3 – Baseline Execution Timings (Checkpoint 2)

**Project:** BookMyShow Movie & Event Ticketing Database  
**Team:** T0112 | **Lead:** Vansh Kumar | **Date:** November 2026  
**Database:** PostgreSQL 15+

---

## 1. Overview & Setup

Baseline performance benchmarks were conducted across all 30 standard queries (`R01` through `R25` and `W01` through `W05`) using the provided benchmarking harness:
```bash
./benchmarks/run_benchmark.sh capstone baseline
```
Each query was executed 3 times using `EXPLAIN (ANALYZE, BUFFERS)`. Write queries (`W01`–`W05`) were wrapped in `BEGIN ... ROLLBACK` transactions to prevent state mutation.

---

## 2. Baseline Timing Table

| SQL Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01: Home page: movies showing in Bengaluru on 2 July 2026 and how many shows each has | READ | 8.550 | 4.878 | 5.003 | 6.144 |
| R02: Showtimes page: shows of movie 2 in Bengaluru on 2 July 2026, grouped by cinema | READ | 4.733 | 4.212 | 4.212 | 4.386 |
| R03: Seat layout: every seat of show 144446 and whether it is already sold | READ | 0.326 | 0.333 | 0.283 | 0.314 |
| R04: Support: open a booking by its code | READ | 0.053 | 0.032 | 0.030 | 0.038 |
| R05: "My bookings": customer 1331's upcoming confirmed shows | READ | 9.671 | 8.575 | 8.028 | 8.758 |
| R06: Search: movies whose title contains "kalki" | READ | 0.147 | 0.140 | 0.144 | 0.144 |
| R07: Cinema dashboard: occupancy of every show at venue 11 on 28 June 2026 | READ | 1.024 | 0.921 | 0.959 | 0.968 |
| R08: Box office: top 10 movies by collections over the weekend of 26–28 June 2026 | READ | 14.536 | 14.327 | 14.043 | 14.302 |
| R09: Seat-lock service: bookings still PENDING more than 10 minutes after they were made (checked at 23:59, 30 Jun 2026) | READ | 6.679 | 6.421 | 6.241 | 6.447 |
| R10: Cinema operations: consecutive shows on the same screen with less than 30 minutes for cleaning (June 2026) | READ | 270.207 | 266.752 | 271.489 | 269.483 |
| R11: Revenue mix: share of ticket revenue from recliner seats, per screen type | READ | 56.961 | 54.169 | 51.808 | 54.313 |
| R12: Fans: customers who booked the same movie more than once | READ | 102.894 | 80.309 | 79.906 | 87.703 |
| R13: Partnerships: offers that have never been redeemed | READ | 14.401 | 13.970 | 13.901 | 14.091 |
| R14: Movie pages: average user rating of 2026 releases with at least 20 reviews | READ | 5.682 | 5.314 | 5.432 | 5.476 |
| R15: Capacity planning: bookings by weekday and hour of booking | READ | 41.008 | 39.229 | 38.783 | 39.673 |
| R16: Cinema partners: cancellation rate per venue for June 2026 shows | READ | 22.448 | 22.428 | 22.563 | 22.480 |
| R17: Cinema operations: seats of screen 101 that were never sold for any June 2026 show | READ | 35.613 | 37.067 | 36.111 | 36.264 |
| R18: Regional insights: collections per language per city in 2026 | READ | 72.742 | 69.839 | 69.898 | 70.826 |
| R19: Distributor report: tickets sold for every June 2026 show of movie 2 | READ | 255.421 | 248.586 | 267.361 | 257.123 |
| R20: Finance: daily collections and running total for June 2026 | READ | 17.732 | 18.386 | 17.875 | 17.998 |
| R21: Loyalty: 20 customers with the most confirmed bookings in 2026 | READ | 53.079 | 53.149 | 52.812 | 53.013 |
| R22: Support console: all bookings, newest first, page 4,001 (25 per page) | READ | 47.144 | 44.252 | 45.657 | 45.684 |
| R23: Sign-in with mobile number | READ | 0.039 | 0.027 | 0.030 | 0.032 |
| R24: Pricing: average price paid per seat class in each city (2026) | READ | 63.764 | 66.177 | 63.734 | 64.558 |
| R25: Programming: average occupancy of late-night shows (starting 22:30 or later) in June 2026 | READ | 25.827 | 26.585 | 28.390 | 26.934 |
| W01: Checkout: create a PENDING booking for 2 tickets of show 144446 | WRITE | 0.836 | 0.769 | 0.813 | 0.806 |
| W02: Seat lock: the oldest PENDING booking adds 2 more seats (the unsold seats with the lowest ids in its show) | WRITE | 11.119 | 10.718 | 10.426 | 10.754 |
| W03: Payment callback: confirm the oldest PENDING booking | WRITE | 0.871 | 0.741 | 0.774 | 0.795 |
| W04: Seat-lock expiry: release seats held by PENDING bookings older than 10 minutes | WRITE | 26.592 | 26.190 | 25.720 | 26.167 |
| W05: Pricing: 10% higher prices for all July weekend shows of movie 2 | WRITE | 6.175 | 5.942 | 5.787 | 5.968 |
| **Total (sum of all 30)** | | **1176.274** | **1130.438** | **1148.213** | **1151.642** |

---

## 3. Query Plan Analysis & Scan Types

Below is the scan breakdown and performance explanation for all 30 queries on the unindexed schema:

### R01: Home page: movies showing in Bengaluru on 2 July 2026 and how many shows each has
- **Scan Nodes:** `Index Scan using movies_pkey on movies | Seq Scan on screens | Seq Scan on venues | Index Scan using no_overlapping_shows on shows`
- **Why it is fast/slow:** Uses Index Scan on movies primary key, but requires Sequential Scans on screens and venues before joining with shows.

### R02: Showtimes page: shows of movie 2 in Bengaluru on 2 July 2026, grouped by cinema
- **Scan Nodes:** `Seq Scan on screens | Seq Scan on venues | Index Scan using no_overlapping_shows on shows`
- **Why it is fast/slow:** Filter by city and cinema name requires Sequential Scans across venues and screens due to lack of composite city/venue indexes.

### R03: Seat layout: every seat of show 144446 and whether it is already sold
- **Scan Nodes:** `Index Scan using shows_pkey on shows | Index Scan using uq_screen_seat_position on seats | Index Only Scan using pk_booking_seats on booking_seats`
- **Why it is fast/slow:** Fast retrieval using Primary Key on shows and unique index on screen seats, reading sold seats via Index Only Scan on pk_booking_seats.

### R04: Support: open a booking by its code
- **Scan Nodes:** `Index Scan using bookings_booking_code_key on bookings`
- **Why it is fast/slow:** Near instantaneous (<0.05 ms) because booking_code has a UNIQUE B-Tree index constraint.

### R05: "My bookings": customer 1331's upcoming confirmed shows
- **Scan Nodes:** `Seq Scan on bookings | Index Scan using shows_pkey on shows | Seq Scan on movies | Seq Scan on screens | Seq Scan on venues`
- **Why it is fast/slow:** Sequential Scan on bookings table filtering by customer_id=1331 causes slow performance; missing index on bookings(customer_id).

### R06: Search: movies whose title contains "kalki"
- **Scan Nodes:** `Seq Scan on movies`
- **Why it is fast/slow:** Requires full Sequential Scan on movies table to match ILIKE pattern '%kalki%'; lacks trigram (pg_trgm) GIN index.

### R07: Cinema dashboard: occupancy of every show at venue 11 on 28 June 2026
- **Scan Nodes:** `Index Scan using uq_venue_screen on screens | Bitmap Heap Scan on shows | Bitmap Index Scan on no_overlapping_shows | Index Only Scan using pk_booking_seats on booking_seats`
- **Why it is fast/slow:** Uses index on venue_screen and bitmap index scan on no_overlapping_shows; reasonable speed for single venue.

### R08: Box office: top 10 movies by collections over the weekend of 26–28 June 2026
- **Scan Nodes:** `Seq Scan on bookings | Seq Scan on shows | Seq Scan on movies`
- **Why it is fast/slow:** Aggregating weekend box office collections requires heavy Sequential Scans on bookings, shows, and movies tables.

### R09: Seat-lock service: bookings still PENDING more than 10 minutes after they were made (checked at 23:59, 30 Jun 2026)
- **Scan Nodes:** `Seq Scan on bookings`
- **Why it is fast/slow:** Sequential Scan across all bookings checking status = 'PENDING' and timestamp; needs partial index on status = 'PENDING'.

### R10: Cinema operations: consecutive shows on the same screen with less than 30 minutes for cleaning (June 2026)
- **Scan Nodes:** `Seq Scan on shows`
- **Why it is fast/slow:** Takes ~270 ms (the longest baseline query) due to self-joining shows with a sequential scan on 144k+ rows to detect cleaning time overlaps.

### R11: Revenue mix: share of ticket revenue from recliner seats, per screen type
- **Scan Nodes:** `Seq Scan on booking_seats | Seq Scan on seats | Seq Scan on screens`
- **Why it is fast/slow:** Sequential scans across booking_seats and seats tables for recliner revenue calculations; needs composite foreign key index.

### R12: Fans: customers who booked the same movie more than once
- **Scan Nodes:** `Seq Scan on shows | Seq Scan on bookings`
- **Why it is fast/slow:** Customer repeat booking analysis performs full Sequential Scan on shows and bookings with multiple group-by passes.

### R13: Partnerships: offers that have never been redeemed
- **Scan Nodes:** `Seq Scan on offers | Seq Scan on bookings`
- **Why it is fast/slow:** Sequential Scan on offers and bookings to compute anti-join for unredeemed promo codes.

### R14: Movie pages: average user rating of 2026 releases with at least 20 reviews
- **Scan Nodes:** `Seq Scan on movie_reviews | Seq Scan on movies`
- **Why it is fast/slow:** Sequential Scan across movie_reviews and movies calculating average ratings with minimum review threshold.

### R15: Capacity planning: bookings by weekday and hour of booking
- **Scan Nodes:** `Seq Scan on bookings`
- **Why it is fast/slow:** Sequential Scan on bookings extracting weekday and hour components from booked_at timestamps.

### R16: Cinema partners: cancellation rate per venue for June 2026 shows
- **Scan Nodes:** `Seq Scan on bookings | Seq Scan on shows | Seq Scan on screens | Seq Scan on venues`
- **Why it is fast/slow:** Sequential Scan on bookings and shows computing cancellation rates by venue for June 2026.

### R17: Cinema operations: seats of screen 101 that were never sold for any June 2026 show
- **Scan Nodes:** `Seq Scan on booking_seats | Seq Scan on shows | Index Scan using uq_screen_seat_position on seats`
- **Why it is fast/slow:** NOT EXISTS anti-join filtering unsold seats for screen 101 over June shows requires scanning shows and booking_seats.

### R18: Regional insights: collections per language per city in 2026
- **Scan Nodes:** `Seq Scan on bookings | Seq Scan on shows | Seq Scan on movies | Seq Scan on screens | Seq Scan on venues`
- **Why it is fast/slow:** Multi-table join across cities, venues, screens, shows, and bookings performs multiple sequential scans and hash joins.

### R19: Distributor report: tickets sold for every June 2026 show of movie 2
- **Scan Nodes:** `Seq Scan on shows | Index Scan using uq_booking_show on bookings`
- **Why it is fast/slow:** Full scan on shows and nested loop on booking_seats for movie 2 distributor reporting.

### R20: Finance: daily collections and running total for June 2026
- **Scan Nodes:** `Seq Scan on bookings`
- **Why it is fast/slow:** Daily running totals over June 2026 require full scan of bookings and window function computation over date buckets.

### R21: Loyalty: 20 customers with the most confirmed bookings in 2026
- **Scan Nodes:** `Seq Scan on bookings`
- **Why it is fast/slow:** Top 20 loyal customer query requires aggregating the entire bookings table by customer_id.

### R22: Support console: all bookings, newest first, page 4,001 (25 per page)
- **Scan Nodes:** `Seq Scan on bookings`
- **Why it is fast/slow:** Deep pagination (OFFSET 100000 LIMIT 25) requires scanning and sorting 100k+ rows before returning 25 rows.

### R23: Sign-in with mobile number
- **Scan Nodes:** `Index Scan using customers_phone_key on customers`
- **Why it is fast/slow:** Customer login by phone number performs Sequential Scan on customers; lacks B-Tree index on customers(phone).

### R24: Pricing: average price paid per seat class in each city (2026)
- **Scan Nodes:** `Seq Scan on booking_seats | Seq Scan on seats | Seq Scan on screens | Seq Scan on venues`
- **Why it is fast/slow:** Multi-table aggregation for average seat class price per city scans booking_seats, seats, screens, and venues.

### R25: Programming: average occupancy of late-night shows (starting 22:30 or later) in June 2026
- **Scan Nodes:** `Seq Scan on booking_seats | Seq Scan on shows | Seq Scan on screens`
- **Why it is fast/slow:** Late-night occupancy filtering starts_at::time >= '22:30' requires sequential scanning and filtering of shows.

### W01: Checkout: create a PENDING booking for 2 tickets of show 144446
- **Scan Nodes:** `(no scan)`
- **Why it is fast/slow:** Single row INSERT into bookings; fast B-Tree key insertion.

### W02: Seat lock: the oldest PENDING booking adds 2 more seats (the unsold seats with the lowest ids in its show)
- **Scan Nodes:** `Index Scan using bookings_pkey on bookings | Index Scan using seats_pkey on seats | Index Only Scan using uq_booking_show on bookings | Index Scan using shows_pkey on shows | Index Only Scan using pk_booking_seats on booking_seats`
- **Why it is fast/slow:** Seat lock insert requires finding oldest pending booking and scanning available seats with NOT EXISTS subquery.

### W03: Payment callback: confirm the oldest PENDING booking
- **Scan Nodes:** `Index Scan using bookings_pkey on bookings | Index Scan using uq_booking_show on bookings`
- **Why it is fast/slow:** UPDATE status to 'CONFIRMED' for oldest pending booking uses subquery on bookings with sequential scan.

### W04: Seat-lock expiry: release seats held by PENDING bookings older than 10 minutes
- **Scan Nodes:** `Seq Scan on booking_seats | Seq Scan on bookings`
- **Why it is fast/slow:** DELETE from booking_seats with join on bookings for expired pending locks does a full table scan on bookings.

### W05: Pricing: 10% higher prices for all July weekend shows of movie 2
- **Scan Nodes:** `Seq Scan on shows`
- **Why it is fast/slow:** Dynamic pricing UPDATE on shows for weekend July shows filters with EXTRACT on unindexed timestamp.

