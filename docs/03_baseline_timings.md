# CP2 – Baseline Timings

## 1. Overview

This document records the baseline performance of the BookMyShow database before applying query optimizations or adding performance indexes.

The benchmark was performed on the `bookmyshow` database using the provided 30-query workload:

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

Each query was executed three times. The benchmark script recorded the average, median, minimum and maximum execution times, along with the scan nodes found in the execution plans.

The write queries were executed inside transactions and rolled back, so the benchmark did not permanently change the database records.

## 4. Baseline Timing Results

All execution times are in milliseconds (ms).

| Query | Type | Average (ms) | Median (ms) | Minimum (ms) | Maximum (ms) |
|---|---|---:|---:|---:|---:|
| R01 | READ | 6.144 | 5.003 | 4.878 | 8.550 |
| R02 | READ | 4.386 | 4.212 | 4.212 | 4.733 |
| R03 | READ | 0.314 | 0.326 | 0.283 | 0.333 |
| R04 | READ | 0.038 | 0.032 | 0.030 | 0.053 |
| R05 | READ | 8.758 | 8.575 | 8.028 | 9.671 |
| R06 | READ | 0.144 | 0.144 | 0.140 | 0.147 |
| R07 | READ | 0.968 | 0.959 | 0.921 | 1.024 |
| R08 | READ | 14.302 | 14.327 | 14.043 | 14.536 |
| R09 | READ | 6.447 | 6.421 | 6.241 | 6.679 |
| R10 | READ | 269.483 | 270.207 | 266.752 | 271.489 |
| R11 | READ | 54.313 | 54.169 | 51.808 | 56.961 |
| R12 | READ | 87.703 | 80.309 | 79.906 | 102.894 |
| R13 | READ | 14.091 | 13.970 | 13.901 | 14.401 |
| R14 | READ | 5.476 | 5.432 | 5.314 | 5.682 |
| R15 | READ | 39.673 | 39.229 | 38.783 | 41.008 |
| R16 | READ | 22.480 | 22.448 | 22.428 | 22.563 |
| R17 | READ | 36.264 | 36.111 | 35.613 | 37.067 |
| R18 | READ | 70.826 | 69.898 | 69.839 | 72.742 |
| R19 | READ | 257.123 | 255.421 | 248.586 | 267.361 |
| R20 | READ | 17.998 | 17.875 | 17.732 | 18.386 |
| R21 | READ | 53.013 | 53.079 | 52.812 | 53.149 |
| R22 | READ | 45.684 | 45.657 | 44.252 | 47.144 |
| R23 | READ | 0.032 | 0.030 | 0.027 | 0.039 |
| R24 | READ | 64.558 | 63.764 | 63.734 | 66.177 |
| R25 | READ | 26.934 | 26.585 | 25.827 | 28.390 |
| W01 | WRITE | 0.806 | 0.813 | 0.769 | 0.836 |
| W02 | WRITE | 10.754 | 10.718 | 10.426 | 11.119 |
| W03 | WRITE | 0.795 | 0.774 | 0.741 | 0.871 |
| W04 | WRITE | 26.167 | 26.190 | 25.720 | 26.592 |
| W05 | WRITE | 5.968 | 5.942 | 5.787 | 6.175 |

## 5. Execution Plan Observations

The following table records the scan nodes reported by the benchmark for each query.

| Query | Observed scan nodes |
|---|---|
| R01 | Index Scan on movies; Seq Scan on screens and venues; Index Scan on shows |
| R02 | Seq Scan on screens and venues; Index Scan on shows |
| R03 | Index Scan on shows and seats; Index Only Scan on booking_seats |
| R04 | Index Scan on bookings |
| R05 | Seq Scan on bookings, movies, screens and venues; Index Scan on shows |
| R06 | Seq Scan on movies |
| R07 | Index Scan on screens; Bitmap Heap Scan and Bitmap Index Scan on shows; Index Only Scan on booking_seats |
| R08 | Seq Scan on bookings, shows and movies |
| R09 | Seq Scan on bookings |
| R10 | Seq Scan on shows |
| R11 | Seq Scan on booking_seats, seats and screens |
| R12 | Seq Scan on shows and bookings |
| R13 | Seq Scan on offers and bookings |
| R14 | Seq Scan on movie_reviews and movies |
| R15 | Seq Scan on bookings |
| R16 | Seq Scan on bookings, shows, screens and venues |
| R17 | Seq Scan on booking_seats and shows; Index Scan on seats |
| R18 | Seq Scan on bookings, shows, movies, screens and venues |
| R19 | Seq Scan on shows; Index Scan on bookings |
| R20 | Seq Scan on bookings |
| R21 | Seq Scan on bookings |
| R22 | Seq Scan on bookings |
| R23 | Index Scan on customers |
| R24 | Seq Scan on booking_seats, seats, screens and venues |
| R25 | Seq Scan on booking_seats, shows and screens |
| W01 | No scan node reported |
| W02 | Index Scan on bookings, seats and shows; Index Only Scan on bookings and booking_seats |
| W03 | Index Scan on bookings |
| W04 | Seq Scan on booking_seats and bookings |
| W05 | Seq Scan on shows |

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

R10 and R19 have the highest average execution times. Both use sequential scans on the `shows` table.

R12 also takes a relatively long time and performs sequential scans on both `shows` and `bookings`.

These queries are good candidates for further investigation during CP3.

### 6.2 Fast read queries

The fastest read queries were:

| Query | Average execution time |
|---|---:|
| R23 | 0.032 ms |
| R04 | 0.038 ms |
| R06 | 0.144 ms |
| R03 | 0.314 ms |
| R07 | 0.968 ms |

R04 and R23 use index scans for their lookups. R03 uses index scans and an index-only scan.

R06 performs a sequential scan on the `movies` table, but its execution time is still very low.

### 6.3 Write query observations

Among the write queries, W04 has the highest average execution time at 26.167 ms. Its execution plan contains sequential scans on `booking_seats` and `bookings`.

W02 takes 10.754 ms and uses several index scans and index-only scans.

W01 and W03 are the fastest write queries, with average execution times below 1 ms.

### 6.4 Sequential scans and index scans

Many queries use sequential scans, especially queries involving `bookings`, `shows` and `booking_seats`.

Some queries use indexes created by primary keys, unique constraints and the show-overlap exclusion constraint.

A sequential scan is not always inefficient. PostgreSQL may choose it when a large portion of a table needs to be read or when scanning the whole table is cheaper than using an index.

Therefore, the scan type should be considered along with execution time and the complete execution plan.

## 7. Baseline Conclusion

The baseline benchmark provides a starting point for measuring the performance of the BookMyShow database.

The results show that some queries execute very quickly, while queries such as R10 and R19 take considerably longer.

The execution plans also show that many queries use sequential scans on larger tables, including `shows`, `bookings` and `booking_seats`.

These results will be used in CP3 to investigate slow queries, test query rewrites and evaluate suitable indexes. The optimized queries will be compared against these baseline timings to measure the changes in performance.

## 8. Benchmark Output Files

The benchmark script saved its output in:

```text
benchmarks/results/baseline/
```

The folder contains:

- `summary.csv` – average, median, minimum and maximum execution times, with scan-node information for all 30 queries.
- `R01.txt` to `R25.txt` – raw execution plans for read queries.
- `W01.txt` to `W05.txt` – raw execution plans for write queries.

These files are retained as the baseline benchmark results for comparison during CP3.