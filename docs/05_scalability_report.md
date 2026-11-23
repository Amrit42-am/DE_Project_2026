# CP4: Scalability Report

## 1. Objective

The objective of this phase was to test the optimized BookMyShow database using the faculty-provided large dataset.

The large dataset was loaded into a separate PostgreSQL database named `bookmyshow_large`.

All 30 optimized benchmark queries were executed three times using:

```bash
./benchmarks/run_benchmark.sh bookmyshow_large large 3 sql/06_optimized_queries.sql
```

The benchmark generated raw execution plans and a summary file under `benchmarks/results/large/`.

## 2. Large Dataset

All 11 CSV files were loaded successfully.

| Table | Rows |
|---|---:|
| cities | 10 |
| movies | 6,000 |
| offers | 25 |
| venues | 2,800 |
| customers | 800,000 |
| screens | 9,800 |
| seats | 1,879,182 |
| shows | 3,201,268 |
| bookings | 3,004,077 |
| booking_seats | 6,016,946 |
| movie_reviews | 651,398 |
| **Total** | **15,571,506** |

The large dataset contains approximately 20 times the seed data volume for the major transaction tables.

## 3. Query Performance

The following table compares the optimized seed benchmark averages with the large-data benchmark averages.

| Query | Type | Seed Avg (ms) | Large Avg (ms) | Growth (×) | Target | Result |
|---|---|---:|---:|---:|---:|---|
| R01 | READ | 0.672 | 6.615 | 9.84 | <250 ms | PASS |
| R02 | READ | 0.275 | 0.627 | 2.28 | <5 ms | PASS |
| R03 | READ | 0.504 | 0.460 | 0.91 | <5 ms | PASS |
| R04 | READ | 0.384 | 0.135 | 0.35 | <5 ms | PASS |
| R05 | READ | 0.351 | 0.426 | 1.21 | <5 ms | PASS |
| R06 | READ | 0.143 | 0.290 | 2.03 | <5 ms | PASS |
| R07 | READ | 0.375 | 0.416 | 1.11 | <250 ms | PASS |
| R08 | READ | 19.872 | 73.181 | 3.68 | <5,000 ms | PASS |
| R09 | READ | 0.016 | 0.025 | 1.56 | <5 ms | PASS |
| R10 | READ | 61.576 | 569.852 | 9.25 | <5,000 ms | PASS |
| R11 | READ | 64.481 | 889.847 | 13.80 | <5,000 ms | PASS |
| R12 | READ | 92.416 | 1,966.842 | 21.28 | <5,000 ms | PASS |
| R13 | READ | 0.669 | 1.043 | 1.56 | <250 ms | PASS |
| R14 | READ | 5.596 | 49.714 | 8.88 | <5,000 ms | PASS |
| R15 | READ | 39.699 | 263.978 | 6.65 | <5,000 ms | PASS |
| R16 | READ | 20.529 | 432.684 | 21.08 | <5,000 ms | PASS |
| R17 | READ | 4.348 | 3.352 | 0.77 | <250 ms | PASS |
| R18 | READ | 53.454 | 896.749 | 16.78 | <5,000 ms | PASS |
| R19 | READ | 1.769 | 8.660 | 4.90 | <5,000 ms | PASS |
| R20 | READ | 8.074 | 61.913 | 7.67 | <5,000 ms | PASS |
| R21 | READ | 46.440 | 4,196.211 | 90.36 | <5,000 ms | PASS |
| R22 | READ | 13.291 | 8.170 | 0.61 | <250 ms | PASS |
| R23 | READ | 0.125 | 0.201 | 1.61 | <5 ms | PASS |
| R24 | READ | 83.729 | 1,125.370 | 13.44 | <5,000 ms | PASS |
| R25 | READ | 27.021 | 232.203 | 8.59 | <5,000 ms | PASS |
| W01 | WRITE | 1.307 | 2.385 | 1.82 | <5 ms | PASS |
| W02 | WRITE | 11.416 | 1.140 | 0.10 | <5 ms | PASS |
| W03 | WRITE | 0.657 | 0.938 | 1.43 | <5 ms | PASS |
| W04 | WRITE | 0.412 | 5.233 | 12.70 | <250 ms | PASS |
| W05 | WRITE | 3.745 | 10.975 | 2.93 | <250 ms | PASS |

### Performance Summary

All 30 queries passed their respective performance targets.

- Real-time queries: below 5 ms.
- Interactive queries: below 250 ms.
- Analytics queries: below 5,000 ms.

## 4. Performance Analysis

### Queries with good scalability

Queries R03, R04, R05, R07, R09, R13, R17, R22, R23, W02 and W03 remained close to their seed timings.

These queries generally use primary-key, unique or secondary indexes to access a small number of rows.

### Queries with moderate performance growth

Queries R01, R02, R06, R08, R10, R11, R14, R15, R18, R19, R20, R24, R25, W01, W04 and W05 became slower with the larger dataset.

Many of these queries process larger date ranges, join multiple tables or aggregate many rows.

Sequential scans on `booking_seats` in R11 and R24 are reasonable because these queries process a large portion of the table.

### Queries requiring attention

R12 and R16 grew by approximately 21 times compared with their seed timings.

R21 showed the largest growth, from 46.440 ms to 4,196.211 ms.

Its execution plan reads approximately 2.67 million confirmed booking rows and groups a large number of customers before returning the top 20 results.

Although R21 still meets the 5-second target, it should be monitored as the database grows further.

A periodically refreshed customer-booking summary or materialized view could reduce the repeated aggregation work.

## 5. Execution Plan Observations

The large-data execution plans show the following:

- **R11 and R24:** Sequential scans on `booking_seats` are used for queries that aggregate a large portion of the table.
- **R12:** The query performs a large hash aggregation over bookings and shows. The execution plan reports multiple hash batches and temporary disk usage.
- **R18:** The query joins and aggregates data across multiple tables. It uses parallel scans and temporary storage.
- **R21:** The index scan still reads millions of confirmed bookings. Most of the work comes from filtering and grouping a large number of rows.

No additional query rewrite was required to meet the CP4 benchmark targets.

## 6. Storage Analysis

The total large database size reported by PostgreSQL was **3,412 MB**.

| Table | Table Size | Index Size | Total Size |
|---|---:|---:|---:|
| bookings | 338 MB | 788 MB | 1,126 MB |
| shows | 212 MB | 779 MB | 991 MB |
| booking_seats | 300 MB | 469 MB | 769 MB |
| seats | 94 MB | 153 MB | 247 MB |
| customers | 77 MB | 105 MB | 182 MB |
| movie_reviews | 40 MB | 47 MB | 86 MB |
| screens | 560 kB | 552 kB | 1,144 kB |
| movies | 576 kB | 504 kB | 1,112 kB |
| venues | 264 kB | 80 kB | 384 kB |
| offers | 8 kB | 16 kB | 32 kB |
| cities | 8 kB | 16 kB | 24 kB |

The largest tables are `bookings`, `shows` and `booking_seats`.

Based on the rounded table sizes:

- Table data occupies approximately 1,062 MB.
- Indexes occupy approximately 2,342 MB.
- Indexes account for approximately 69% of the combined table and index size.

Indexes improve query performance but also increase storage requirements.

### Seed and Large Database Comparison

| Database | Size |
|---|---:|
| Seed database (`bookmyshow`) | 180 MB |
| Large database (`bookmyshow_large`) | 3,412 MB |

The large database is approximately 19 times larger than the seed database.

The increase in storage is expected because the large dataset contains millions of records compared with the smaller seed dataset.

The large database size was measured before creating the separate partitioned copy of `booking_seats` used for the partitioning demonstration.

## 7. Partitioning Strategy

### 7.1 HASH Partitioning

The `booking_seats` table contains approximately 6 million rows in the large dataset.

To improve data management and support queries that filter by show, HASH partitioning on `show_id` is proposed.

The design uses 16 partitions.

A separate table named `booking_seats_partitioned` is created for this demonstration. The original `booking_seats` table is not changed, so the benchmark results remain unaffected.

The partitioning SQL performs these operations:

1. Creates a partitioned table.
2. Creates 16 hash partitions.
3. Copies the existing booking-seat data.
4. Checks the original and partitioned row counts.
5. Runs an `EXPLAIN ANALYZE` query to demonstrate partition pruning.

### 7.2 Primary Key Consideration

PostgreSQL requires the partition key to be part of every primary key or unique constraint on a partitioned table.

The original primary key is:

```sql
PRIMARY KEY (show_id, seat_id)
```

Since the partition key is `show_id`, the existing primary key structure can be retained.

### 7.3 Partition Pruning

Partition pruning was tested using a specific `show_id`.

The following query was executed:

```sql
SELECT booking_id, seat_id, price
FROM bms.booking_seats_partitioned
WHERE show_id = 2750343;

**Partition pruning execution plan:**

Paste the actual `EXPLAIN (ANALYZE, BUFFERS)` output here after running `sql/08_partitioning.sql`.

Partitioning helps queries that filter on `show_id`. However, queries that scan the entire table, such as R11 and R24, still need to access all partitions.

## 8. Future Scalability Architecture

For future growth, the following architecture is proposed.

### 8.1 Sharding

The booking system can be sharded using `show_id` as the routing key.

Bookings and their corresponding booking-seat records for the same show can remain on the same shard.

This helps keep important operations together:

- Seat availability checks.
- Seat locking.
- Booking creation.
- Payment status updates.
- Seat-lock expiration.

Reports that require data from multiple shows or regions may need to combine results from multiple shards.

### 8.2 Read Replicas

Read replicas can handle reporting queries and reduce the workload on the primary database.

Queries such as R08, R11, R12, R14, R15, R16, R18, R19, R20, R21, R24 and R25 are possible candidates.

All write operations should continue to use the primary database.

Queries that require immediately updated booking or seat availability information should also use a strongly consistent path.

### 8.3 Caching

Frequently requested data can be cached to reduce repeated database queries.

Examples include:

- Movie search results (R06).
- Movie and show listings (R01 and R02).
- Cinema dashboard information (R07).

Cache entries should be refreshed or invalidated when relevant movie, show, price or booking information changes.

Seat availability should not rely on stale cached data during the booking process.

### 8.4 Maintenance and Archiving

As the database grows, regular maintenance becomes important.

- Run `ANALYZE` to keep query planner statistics updated.
- Monitor PostgreSQL autovacuum activity.
- Monitor index and table sizes.
- Archive old booking and booking-seat records according to the data retention policy.
- Consider summary tables or materialized views for frequently executed reports.

## 9. Conclusion

The optimized BookMyShow database successfully handled the faculty-provided large dataset containing 15,571,506 rows.

All 30 benchmark queries met their required performance targets.

Most indexed lookups remained fast, while queries involving large joins and aggregations became slower as expected.

R21 was the slowest query, with an average execution time of 4,196.211 ms. It should be monitored as the database grows.

The large database occupied 3,412 MB. HASH partitioning on `show_id`, read replicas, caching and sharding are proposed as future scalability improvements.

A simple linear estimate based on the approximately 20× dataset suggests around 17 GB of database storage at 100× seed-data volume, before allowing for additional operational storage, backups and logs.