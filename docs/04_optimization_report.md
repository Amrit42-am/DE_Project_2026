# CP3 – Query Optimization Report

## 1. Overview

The objective of CP3 was to improve the performance of the BookMyShow database queries without changing their results.

The original workload contains 30 queries: 25 read queries (R01–R25) and 5 write queries (W01–W05).

The CP2 baseline timings were used to identify slow queries. Indexes and query rewrites were then introduced, and the optimized workload was benchmarked again.

The original workload file `queries/workload_30.sql` was not modified. All optimized queries are stored separately in `sql/06_optimized_queries.sql`.

## 2. Benchmark Environment

| Item | Details |
|---|---|
| Database | bookmyshow |
| Schema | bms |
| PostgreSQL server | 18.6 |
| PostgreSQL client | 15.20 |
| Tables | 11 |
| Total rows | 778,048 |
| Baseline runs per query | 3 |
| Optimized runs per query | 5 |

The same database and laptop were used for the baseline and optimized benchmarks.

Baseline command:

```bash
./benchmarks/run_benchmark.sh bookmyshow baseline
```

Optimized benchmark command:

```bash
./benchmarks/run_benchmark.sh bookmyshow optimized 5 sql/06_optimized_queries.sql
```

The benchmark script records execution time, query plans and scan nodes. Write queries are run inside transactions and rolled back.

## 3. Indexes Created

The following 15 indexes were created in `sql/05_indexes.sql`.

| Index name | Table | Main purpose |
|---|---|---|
| idx_shows_starts_at | shows | Date and time range searches |
| idx_shows_movie_starts_at | shows | Movie and date filtering |
| idx_shows_screen_starts_at | shows | Screen and time searches |
| idx_bookings_show_status | bookings | Booking lookup by show and status |
| idx_bookings_customer_show_confirmed | bookings | Customer's confirmed bookings |
| idx_bookings_confirmed_booked_at | bookings | Confirmed bookings by booking date |
| idx_bookings_pending_booking_id | bookings | Finding the oldest pending booking |
| idx_bookings_pending_booked_at | bookings | Finding expired pending bookings |
| idx_bookings_booked_at_desc | bookings | Newest-first booking pagination |
| idx_bookings_offer_code | bookings | Checking whether an offer was redeemed |
| idx_booking_seats_booking_id | booking_seats | Finding seats belonging to a booking |
| idx_booking_seats_seat_show | booking_seats | Looking up seats by seat ID |
| idx_seats_screen_seat | seats | Finding seats belonging to a screen |
| idx_movies_title_trgm | movies | Searching text inside movie titles |
| idx_movie_reviews_movie | movie_reviews | Joining reviews with movies |

A GIN trigram index was created for the movie title search using the `pg_trgm` extension.

Primary key, unique and exclusion-constraint indexes already existed before CP3. They were not counted among these 15 new indexes.

## 4. Before and After Timing Results

The following table compares the average execution time from CP2 and CP3.

All timings are in milliseconds.

Improvement is calculated using:

```text
Improvement (%) = ((Before - After) / Before) * 100
```

A positive percentage means the query became faster. A negative percentage means its measured average became slower.

| Query | Before (ms) | Problem / optimization | After (ms) | Improvement | Result |
|---|---:|---|---:|---:|---|
| R01 | 6.144 | Date range filter and shows index | 0.672 | 89.06% | Same |
| R02 | 4.386 | Composite movie/date index | 0.275 | 93.73% | Same |
| R03 | 0.314 | Screen and seat index | 0.504 | -60.51% | Same |
| R04 | 0.038 | Existing booking code unique index | 0.384 | -910.53% | Same |
| R05 | 8.758 | Partial index for confirmed customer bookings | 0.351 | 95.99% | Same |
| R06 | 0.144 | Trigram index created; planner kept sequential scan | 0.143 | 0.69% | Same |
| R07 | 0.968 | Date range and screen/time index | 0.375 | 61.26% | Same |
| R08 | 14.302 | Date index used; bookings aggregation remains expensive | 19.872 | -38.95% | Same |
| R09 | 6.447 | Partial index for expired pending bookings | 0.016 | 99.75% | Same |
| R10 | 269.483 | Time-gap condition rewrite and screen/time index | 61.576 | 77.15% | Same |
| R11 | 54.313 | Seat lookup index created; full aggregation remains | 64.481 | -18.72% | Same |
| R12 | 87.703 | Existing scans remain on bookings and shows | 92.416 | -5.37% | Same |
| R13 | 14.091 | NOT IN changed to NOT EXISTS; offer-code index | 0.669 | 95.25%* | Corrected |
| R14 | 5.476 | Movie review index created; sequential scans remain | 5.596 | -2.19% | Same |
| R15 | 39.673 | Full-table grouping; sequential scan remains | 39.699 | -0.07% | Same |
| R16 | 22.480 | Shows date index used | 20.529 | 8.68% | Same |
| R17 | 36.264 | Screen-seat and booking-seat indexes | 4.348 | 88.01% | Same |
| R18 | 70.826 | Date filter rewritten as range | 53.454 | 24.53% | Same |
| R19 | 257.123 | Correlated subquery replaced with JOIN and GROUP BY | 1.769 | 99.31% | Same |
| R20 | 17.998 | Date filter rewritten as range and partial index | 8.074 | 55.14% | Same |
| R21 | 53.013 | Confirmed-booking index created; grouping remains | 46.440 | 12.40% | Same |
| R22 | 45.684 | Descending booking-date index | 13.291 | 70.91% | Same |
| R23 | 0.032 | Existing customer phone unique index | 0.125 | -290.62% | Same |
| R24 | 64.558 | Seat lookup index created; full aggregation remains | 83.729 | -29.70% | Same |
| R25 | 26.934 | Shows date index used; occupancy aggregation remains | 27.021 | -0.32% | Same |
| W01 | 0.806 | Additional indexes maintained during insert | 1.307 | -62.16% | Same |
| W02 | 10.754 | Pending booking and seat indexes | 11.416 | -6.16% | Same |
| W03 | 0.795 | Partial pending-booking index | 0.657 | 17.36% | Same |
| W04 | 26.167 | Pending booking and booking-seat indexes | 0.412 | 98.43% | Same |
| W05 | 5.968 | Movie/date index used | 3.745 | 37.25% | Same |

\* R13's percentage is only a timing reference. The original query returned an incorrect result, while the corrected query returns the seven offers that were never redeemed. These results are not semantically equivalent.

The sum of all 30 reported average timings was:

| Measurement | Total |
|---|---:|
| Baseline | 1,151.642 ms |
| Optimized | 563.346 ms |
| Reduction | 51.08% |

This total is descriptive rather than a strict like-for-like workload measurement because the baseline used three runs and the optimized benchmark used five. R13 also corrects an original wrong answer.

## 5. Analysis of the Five Biggest Improvements

The following five queries had the most significant measured improvements. Their raw execution plans are saved in the baseline and optimized result folders.

### 5.1 R09 – Pending Payment Queue

**Before:** 6.447 ms  
**After:** 0.016 ms  
**Improvement:** 99.75%

Original plan:

```text
Parallel Seq Scan on bookings

Filter:
status = 'PENDING'
AND booked_at < cutoff

Rows Removed by Filter: 75044
Buffers: shared hit=2184
```

Optimized plan:

```text
Index Only Scan using idx_bookings_pending_booked_at

Index Cond:
booked_at < cutoff
```

The original query scanned the bookings table and filtered out most of its records.

The new partial index contains only pending bookings, so PostgreSQL can search the relevant booking dates without scanning all bookings.

### 5.2 R19 – Distributor Report

**Before:** 257.123 ms  
**After:** 1.769 ms  
**Improvement:** 99.31%

Original plan:

```text
Parallel Seq Scan on shows

SubPlan 1
    Aggregate
    Index Scan using uq_booking_show on bookings
    loops=207
```

The original query executed the correlated aggregate once for every matching show. There were 207 matching shows, which caused repeated booking lookups and approximately 85,514 shared buffer hits inside the subplan.

The optimized query uses a LEFT JOIN and GROUP BY:

```sql
SELECT s.show_id,
       s.starts_at,
       s.screen_id,
       COALESCE(sum(b.num_tickets), 0) AS tickets_sold
FROM shows s
LEFT JOIN bookings b
    ON b.show_id = s.show_id
   AND b.status = 'CONFIRMED'
WHERE s.movie_id = 2
  AND s.starts_at >= '2026-06-01'
  AND s.starts_at < '2026-07-01'
GROUP BY s.show_id, s.starts_at, s.screen_id
ORDER BY tickets_sold DESC, s.starts_at;
```

The optimized plan uses the movie/date index and the booking/show/status index. It calculates ticket totals through a grouped join instead of repeatedly executing a subquery.

### 5.3 R05 – My Bookings

**Before:** 8.758 ms  
**After:** 0.351 ms  
**Improvement:** 95.99%

Original plan:

```text
Seq Scan on bookings

Filter:
customer_id = 1331
AND status = 'CONFIRMED'

Rows Removed by Filter: 150087
```

The database scanned the bookings table to find only a few records belonging to the requested customer.

Optimized plan:

```text
Index Only Scan using
idx_bookings_customer_show_confirmed
```

The partial index contains only confirmed bookings and starts with `customer_id`, which is the main lookup condition.

The remaining joins use the primary key indexes of shows, movies, screens and venues.

### 5.4 R02 – Showtimes Page

**Before:** 4.386 ms  
**After:** 0.275 ms  
**Improvement:** 93.73%

Original plan:

```text
Seq Scan on screens
Seq Scan on venues
Index Scan on shows using no_overlapping_shows
```

The original plan examined many show records before filtering by movie and date. It also accessed a large number of shared buffers.

Optimized plan:

```text
Bitmap Heap Scan on shows

Bitmap Index Scan using
idx_shows_movie_starts_at
```

The new composite index directly filters using `movie_id` and `starts_at`.

This reduces the number of show records that must be examined. The plan still uses a sequential scan on the relatively small screens table, which is reasonable.

### 5.5 W04 – Seat-Lock Expiry

**Before:** 26.167 ms  
**After:** 0.412 ms  
**Improvement:** 98.43%

Original plan:

```text
Seq Scan on booking_seats
actual rows = 300389

Seq Scan on bookings
actual rows = 150094
```

The original query scanned the booking-seat and bookings tables to find seats belonging to expired pending bookings.

Optimized plan:

```text
Nested Loop

Index Scan using idx_bookings_pending_booking_id

Index Scan using idx_booking_seats_booking_id
```

The database first locates the pending bookings and then finds their seat rows using `booking_id`.

Instead of scanning all booking-seat records, the optimized plan looks up the seat rows belonging to the matching bookings.

## 6. NULL-Related Bug in R13

The original R13 query was:

```sql
SELECT o.offer_code, o.description, o.discount_pct
FROM offers o
WHERE o.offer_code NOT IN (
    SELECT b.offer_code
    FROM bookings b
);
```

The problem is that `bookings.offer_code` allows NULL values because a booking does not always use an offer.

The database check found:

| Check | Result |
|---|---:|
| Bookings with NULL offer codes | 127,659 |
| Original query result rows | 0 |
| Corrected query result rows | 7 |

When a `NOT IN` subquery contains NULL, comparisons can evaluate to UNKNOWN. Rows with unmatched offer codes therefore do not pass the WHERE condition.

The query was corrected using NOT EXISTS:

```sql
SELECT o.offer_code, o.description, o.discount_pct
FROM offers o
WHERE NOT EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.offer_code = o.offer_code
);
```

The corrected query returned 7 offers that had never been redeemed.

This is a correctness fix, not only a performance optimization. The original result of zero rows was wrong.

## 7. Result Equivalence Checks

The original and optimized outputs were compared using `EXCEPT ALL` in both directions.

This checks both the values and the number of duplicate rows.

The following rewritten queries were tested:

| Query | Original-only rows | Optimized-only rows | Result |
|---|---:|---:|---|
| R01 | 0 | 0 | PASS |
| R07 | 0 | 0 | PASS |
| R10 | 0 | 0 | PASS |
| R18 | 0 | 0 | PASS |
| R19 | 0 | 0 | PASS |
| R20 | 0 | 0 | PASS |

All six rewritten queries returned identical results.

R13 was checked separately because it intentionally fixes the NULL-related bug. Its result changed from zero rows to seven rows.

The remaining query text was unchanged. The new indexes do not change the logical results of those queries.

## 8. Write Query Overhead

Indexes can make read queries faster, but they also need to be maintained when rows are inserted, updated or deleted.

The write-query measurements were:

| Query | Before (ms) | After (ms) | Change |
|---|---:|---:|---:|
| W01 | 0.806 | 1.307 | 0.501 ms slower |
| W02 | 10.754 | 11.416 | 0.662 ms slower |
| W03 | 0.795 | 0.657 | 0.138 ms faster |
| W04 | 26.167 | 0.412 | 25.755 ms faster |
| W05 | 5.968 | 3.745 | 2.223 ms faster |

W01 became slower because inserting a booking requires PostgreSQL to maintain the applicable booking indexes.

W02 also became slightly slower. It inserts booking-seat rows and must maintain the new booking-seat indexes.

The increase in these two queries is relatively small in absolute terms. W03, W04 and W05 improved after optimization.

The write overhead is acceptable for this workload because the improvements to several important read and seat-lock operations are much larger.

The measurements can still vary between runs, so the changes should be considered alongside the individual execution plans.

## 9. Index Storage Analysis

The index sizes were collected using `pg_relation_size()`.

| Index | Table | Index size | Table size |
|---|---|---:|---:|
| idx_bookings_booked_at_desc | bookings | 9,912 KB | 17 MB |
| idx_booking_seats_seat_show | booking_seats | 9,264 KB | 15 MB |
| idx_shows_screen_starts_at | shows | 9,216 KB | 11 MB |
| idx_shows_movie_starts_at | shows | 7,792 KB | 11 MB |
| idx_bookings_show_status | bookings | 7,376 KB | 17 MB |
| idx_shows_starts_at | shows | 6,392 KB | 11 MB |
| idx_bookings_confirmed_booked_at | bookings | 5,320 KB | 17 MB |
| idx_bookings_customer_show_confirmed | bookings | 5,304 KB | 17 MB |
| idx_booking_seats_booking_id | booking_seats | 4,800 KB | 15 MB |
| idx_seats_screen_seat | seats | 3,744 KB | 4,992 KB |
| idx_movie_reviews_movie | movie_reviews | 728 KB | 2,048 KB |
| idx_bookings_offer_code | bookings | 176 KB | 17 MB |
| idx_movies_title_trgm | movies | 48 KB | 24 KB |
| idx_bookings_pending_booked_at | bookings | 16 KB | 17 MB |
| idx_bookings_pending_booking_id | bookings | 16 KB | 17 MB |

The total size of the 15 new indexes is approximately **68.46 MiB**, based on the sizes reported by PostgreSQL.

The largest indexes belong to the bookings, booking_seats and shows tables because these tables contain a large number of records.

The indexes use additional disk space, but they reduce the amount of table data that needs to be scanned for selective queries.

## 10. Queries That Did Not Improve

Some queries became slower or showed very little improvement.

### R08 – Box Office

The query still needs to aggregate collections across a large number of confirmed bookings. The execution plan continues to use a sequential scan on bookings.

### R11 – Revenue Mix

This query calculates ticket revenue across seat classes and screen types. It reads a large portion of booking_seats, seats and screens. PostgreSQL continues to use sequential scans.

### R12 – Repeat Movie Bookings

The query groups bookings by customer and movie and checks which combinations occurred more than once. It processes many bookings and still uses sequential scans on bookings and shows.

### R14 – Movie Ratings

The query aggregates reviews and calculates average ratings. The new movie-review index was created, but PostgreSQL chose sequential scans for the tables in the benchmark plan.

### R15 – Booking Patterns

The query groups the entire bookings table by weekday and hour. Since it needs most booking rows, a sequential scan is reasonable.

Its average time changed only slightly, from 39.673 ms to 39.699 ms.

### R18 – Regional Collections

The optimized query uses a date range instead of extracting the year from every timestamp. However, the execution plan still uses sequential scans on several tables. The date range covers most of the available 2026 show data.

### R21 – Customer Loyalty

This query groups confirmed bookings by customer and calculates the total booking count and spend. It still needs to process many confirmed bookings.

### R24 – Average Seat Price

This query aggregates almost the entire booking_seats table and joins it with seats, screens and venues. The planner continues to prefer sequential scans.

### R25 – Late-Night Occupancy

The query still performs occupancy aggregation over many booking-seat records. Its execution time remained almost unchanged.

### Small lookup queries

R04 and R23 already used unique indexes before optimization. Their average timings are very small, and individual slow runs affected the optimized averages. Their median times remained close to the baseline medians, so these differences should not be treated as reliable evidence of a real regression.

A sequential scan is not always a problem. When a query needs a large part of a table, scanning the table can be cheaper than looking up many individual records through an index.

## 11. Conclusion

The CP3 optimization improved several important queries in the BookMyShow database.

The biggest improvements were seen in R09, R19, R05, R02, R17 and W04. These queries benefited from indexes that match their filtering and joining conditions or from replacing repeated subqueries with grouped joins.

The R13 correction also fixed an important NULL-related correctness problem that caused the original query to return an empty result.

The optimized workload had a lower sum of reported average execution times than the baseline, although some analytical queries still need improvement and a few small queries showed timing variation.

The database now has 15 additional indexes, using approximately 68.46 MiB of storage. These indexes improve several read operations but introduce some overhead for write operations.

The optimized benchmark results and raw execution plans are saved in:

```text
benchmarks/results/optimized/
```

The original baseline results remain in:

```text
benchmarks/results/baseline/
```

These two sets of results will be used as the starting point for the next scalability phase.