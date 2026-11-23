# CP2 – Baseline Timings

## 1. Overview

This document records the baseline performance of the BookMyShow database before applying query optimizations or adding performance indexes.

The benchmark was performed on the `bookmyshow` database using the provided 30-query workload.

- 25 read queries (R01–R25)
- 5 write queries (W01–W05)
- Each query was executed 3 times.
- Query execution plans were collected using `EXPLAIN (ANALYZE, BUFFERS)`.

The purpose of this benchmark is to understand the current query performance and identify queries that may need optimization in CP3.

## 2. Database and Benchmark Environment

| Item | Details |
|---|---|
| Database | bookmyshow |
| Schema | bms |
| PostgreSQL server | 18.6 |
| psql client | 15.20 (Homebrew) |
| Total tables | 11 |
| Total rows | 778,048 |
| Read queries | 25 |
| Write queries | 5 |
| Runs per query | 3 |
| Benchmark phase | baseline |
| Benchmark date | 17 November 2026 |

**Version note:** The PostgreSQL client version (15.20) differs from the server version (18.6). The client displayed a version warning, but the benchmark completed successfully.

## 3. Benchmark Method

The benchmark was executed using the provided benchmark script:

```bash
./benchmarks/run_benchmark.sh bookmyshow baseline
```

The script executed the provided workload file:

```text
queries/workload_30.sql
```

Each query was executed three times. The execution time of each run was collected from the `Execution Time` line in the execution plan.

The average execution time was calculated using:

```text
Average = (Run 1 + Run 2 + Run 3) / 3
```

The benchmark also recorded the median, minimum and maximum execution times, along with the scan nodes found in the execution plans.

The write queries were executed inside transactions and rolled back, so the benchmark did not permanently change the database records.

## 4. Baseline Timing Results

All execution times are in milliseconds (ms). The individual run timings below are taken from the raw execution plan files in `benchmarks/results/baseline/`.

| SQL Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01: Home page – movies showing in Bengaluru on 2 July 2026 and show counts | READ | 8.550 | 4.878 | 5.003 | 6.144 |
| R02: Showtimes page – shows of movie 2 in Bengaluru on 2 July 2026 | READ | 4.733 | 4.212 | 4.212 | 4.386 |
| R03: Seat layout – every seat of show 144446 and whether it is sold | READ | 0.326 | 0.333 | 0.283 | 0.314 |
| R04: Support – open a booking by its code | READ | 0.053 | 0.032 | 0.030 | 0.038 |
| R05: My bookings – customer 1331's upcoming confirmed shows | READ | 9.671 | 8.575 | 8.028 | 8.758 |
| R06: Search – movies whose title contains "kalki" | READ | 0.147 | 0.140 | 0.144 | 0.144 |
| R07: Cinema dashboard – occupancy of every show at venue 11 on 28 June 2026 | READ | 1.024 | 0.921 | 0.959 | 0.968 |
| R08: Box office – top 10 movies by collections over the weekend of 26–28 June 2026 | READ | 14.536 | 14.327 | 14.043 | 14.302 |
| R09: Seat-lock service – pending bookings older than 10 minutes | READ | 6.679 | 6.421 | 6.241 | 6.447 |
| R10: Cinema operations – consecutive shows on the same screen with less than 30 minutes for cleaning | READ | 270.207 | 266.752 | 271.489 | 269.483 |
| R11: Revenue mix – share of ticket revenue from recliner seats per screen type | READ | 56.961 | 54.169 | 51.808 | 54.313 |
| R12: Fans – customers who booked the same movie more than once | READ | 102.894 | 80.309 | 79.906 | 87.703 |
| R13: Partnerships – offers that have never been redeemed | READ | 14.401 | 13.970 | 13.901 | 14.091 |
| R14: Movie pages – average rating of 2026 releases with at least 20 reviews | READ | 5.682 | 5.314 | 5.432 | 5.476 |
| R15: Capacity planning – bookings by weekday and hour | READ | 41.008 | 39.229 | 38.783 | 39.673 |
| R16: Cinema partners – cancellation rate per venue for June 2026 shows | READ | 22.448 | 22.428 | 22.563 | 22.480 |
| R17: Cinema operations – seats of screen 101 never sold during June 2026 | READ | 35.613 | 37.067 | 36.111 | 36.264 |
| R18: Regional insights – collections per language per city in 2026 | READ | 72.742 | 69.839 | 69.898 | 70.826 |
| R19: Distributor report – tickets sold for every June 2026 show of movie 2 | READ | 255.421 | 248.586 | 267.361 | 257.123 |
| R20: Finance – daily collections and running total for June 2026 | READ | 17.732 | 18.386 | 17.875 | 17.998 |
| R21: Loyalty – 20 customers with the most confirmed bookings in 2026 | READ | 53.079 | 53.149 | 52.812 | 53.013 |
| R22: Support console – all bookings, newest first, page 4,001 | READ | 47.144 | 44.252 | 45.657 | 45.684 |
| R23: Sign-in – search customer using mobile number | READ | 0.039 | 0.027 | 0.030 | 0.032 |
| R24: Pricing – average price paid per seat class in each city | READ | 63.764 | 66.177 | 63.734 | 64.558 |
| R25: Programming – average occupancy of late-night shows in June 2026 | READ | 25.827 | 26.585 | 28.390 | 26.934 |
| W01: Checkout – create a PENDING booking for 2 tickets of show 144446 | WRITE | 0.836 | 0.769 | 0.813 | 0.806 |
| W02: Seat lock – oldest PENDING booking adds 2 more seats | WRITE | 11.119 | 10.718 | 10.426 | 10.754 |
| W03: Payment callback – confirm the oldest PENDING booking | WRITE | 0.871 | 0.741 | 0.774 | 0.795 |
| W04: Seat-lock expiry – release seats held by expired PENDING bookings | WRITE | 26.592 | 26.190 | 25.720 | 26.167 |
| W05: Pricing – 10% higher prices for July weekend shows of movie 2 | WRITE | 6.175 | 5.942 | 5.787 | 5.968 |
| **Total (sum of all 30)** | | **1176.274** | **1130.438** | **1148.213** | **1151.642** |

The average for each query was calculated from its three execution times. The totals are the sum of the corresponding run timings and averages across all 30 queries.

## 5. Execution Plan Observations

The following table records the scan nodes reported in the baseline execution plans and explains their effect on query performance.

| Query | Observed scan nodes | Observation |
|---|---|---|
| R01 | Index Scan on movies; Seq Scan on screens and venues; Index Scan on shows | The query uses an index for show lookup, but joins and date filtering still require processing several records. |
| R02 | Seq Scan on screens and venues; Index Scan on shows | The query checks the screen and venue tables and uses an index for show lookup. |
| R03 | Index Scan on shows and seats; Index Only Scan on booking_seats | Index lookups help retrieve the selected show, its seats and sold-seat information quickly. |
| R04 | Index Scan on bookings | The booking code unique index allows a quick lookup. |
| R05 | Seq Scan on bookings; Index Scan on shows; Seq Scan on movies, screens and venues | The booking table is scanned to find bookings for the requested customer. |
| R06 | Seq Scan on movies | The movies table is small, so scanning it is inexpensive. |
| R07 | Index Scan on screens; Bitmap Heap Scan and Bitmap Index Scan on shows; Index Only Scan on booking_seats | Indexes help find the required shows and booking-seat information for occupancy calculation. |
| R08 | Seq Scan on bookings, shows and movies | The query processes many booking records and aggregates their collections. |
| R09 | Seq Scan on bookings | The database scans bookings to find pending bookings older than the specified time. |
| R10 | Seq Scan on shows | The self-join on shows makes this query expensive because it compares shows on the same screens. |
| R11 | Seq Scan on booking_seats, seats and screens | The query aggregates ticket revenue across a large number of booking-seat records. |
| R12 | Seq Scan on shows and bookings | A large number of bookings are processed and grouped by customer and movie. |
| R13 | Seq Scan on offers and bookings | The original `NOT IN` query scans bookings and has a NULL-related correctness problem. |
| R14 | Seq Scan on movie_reviews and movies | The query processes reviews and groups them to calculate average ratings. |
| R15 | Seq Scan on bookings | The query groups the booking table by weekday and hour, requiring data from most rows. |
| R16 | Seq Scan on bookings, shows, screens and venues | Multiple tables are processed to calculate cancellation rates per venue. |
| R17 | Seq Scan on booking_seats and shows; Index Scan on seats | The query searches for seats that have never been sold, requiring checks against many booking records. |
| R18 | Seq Scan on bookings, shows, movies, screens and venues | The query joins several tables and aggregates collections by city and language. |
| R19 | Seq Scan on shows; Index Scan on bookings | The correlated subquery performs repeated booking lookups for individual shows. |
| R20 | Seq Scan on bookings | The query scans bookings and groups them by booking date to calculate daily collections. |
| R21 | Seq Scan on bookings | The query groups confirmed bookings by customer and calculates total spending. |
| R22 | Seq Scan on bookings | A large number of bookings must be considered and sorted for pagination using OFFSET. |
| R23 | Index Scan on customers | The unique phone index allows a quick customer lookup. |
| R24 | Seq Scan on booking_seats, seats, screens and venues | The query aggregates seat prices across many booking-seat records and related tables. |
| R25 | Seq Scan on booking_seats, shows and screens | The query processes late-night shows and their booked seats to calculate occupancy. |
| W01 | No scan node reported | The INSERT does not require a table scan, although PostgreSQL still checks constraints and indexes. |
| W02 | Index Scan on bookings, seats and shows; Index Only Scan on bookings and booking_seats | Indexes help locate the oldest pending booking and available seats. |
| W03 | Index Scan on bookings; Index Only Scan on bookings | The update locates the pending booking using indexed lookup conditions. |
| W04 | Seq Scan on booking_seats and bookings | The query scans both tables to find and release expired pending seat locks. |
| W05 | Seq Scan on shows | The update checks show records to find July weekend shows of movie 2. |

## 6. Main Observations

### 6.1 Slow read queries

The slowest read queries based on average execution time were:

| Query | Average execution time |
|---|---:|
| R10 | 269.483 ms |
| R19 | 257.123 ms |
| R12 | 87.703 ms |
| R18 | 70.826 ms |
| R24 | 64.558 ms |
| R11 | 54.313 ms |

R10 and R19 have the highest average execution times.

R10 performs a self-join on the shows table to find consecutive shows on the same screen. This requires comparing show records and checking the time difference between them.

R19 uses a correlated subquery to calculate the number of tickets sold for every show. The subquery performs repeated lookups on bookings, which increases the execution time.

R12 also takes a relatively long time because it processes bookings and shows to identify customers who booked the same movie more than once.

These queries were important candidates for optimization during CP3.

### 6.2 Fast read queries

The fastest read queries were:

| Query | Average execution time |
|---|---:|
| R23 | 0.032 ms |
| R04 | 0.038 ms |
| R06 | 0.144 ms |
| R03 | 0.314 ms |
| R07 | 0.968 ms |

R04 and R23 use unique indexes for booking-code and phone-number lookups.

R03 uses index scans and an index-only scan to retrieve the seat information for one show.

R06 performs a sequential scan on the movies table, but the table is small, so the query still executes quickly.

### 6.3 Write query observations

Among the write queries, W04 has the highest average execution time at 26.167 ms.

Its execution plan contains sequential scans on `booking_seats` and `bookings`. It needs to find pending bookings older than the specified time and delete their associated seat records.

W02 takes 10.754 ms and uses several index scans and index-only scans to locate the oldest pending booking and available seats.

W01 and W03 are the fastest write queries, with average execution times below 1 ms.

### 6.4 Sequential scans and index scans

Many queries use sequential scans, especially queries involving `bookings`, `shows` and `booking_seats`.

Some queries use indexes created by primary keys, unique constraints and the show-overlap exclusion constraint.

A sequential scan is not always inefficient. PostgreSQL may choose it when a large portion of a table needs to be read or when scanning the whole table is cheaper than using an index.

For example, reporting queries such as R11, R15 and R24 need to process a large portion of the available records. In such cases, a sequential scan may be a reasonable choice.

Therefore, the scan type should be considered along with execution time and the complete execution plan.

## 7. Baseline Conclusion

The baseline benchmark provides a starting point for measuring the performance of the BookMyShow database.

The results show that some queries execute very quickly, while queries such as R10 and R19 take considerably longer.

The execution plans also show that many queries use sequential scans on larger tables, including `shows`, `bookings` and `booking_seats`.

The results indicate that queries using selective index lookups generally perform well, while queries involving large table scans, repeated subqueries and multiple joins take more time.

These results will be used in CP3 to investigate slow queries, test query rewrites and evaluate suitable indexes. The optimized queries will be compared against these baseline timings to measure changes in performance.

## 8. Benchmark Output Files

The benchmark script saved its output in:

```text
benchmarks/results/baseline/
```

The folder contains:

- `summary.csv` – average, median, minimum and maximum execution times, with scan-node information for all 30 queries.
- `R01.txt` to `R25.txt` – raw execution plans containing all three runs for each read query.
- `W01.txt` to `W05.txt` – raw execution plans containing all three runs for each write query.

The individual Run 1, Run 2 and Run 3 timings in this document were taken from the raw execution plan files. The calculated averages were checked against `summary.csv`.

These files are retained as the baseline benchmark results for comparison during CP3.