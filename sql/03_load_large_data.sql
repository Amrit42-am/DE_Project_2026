\set ON_ERROR_STOP on

SET search_path TO bms;

\copy bms.cities FROM 'large_data/cities.csv' WITH (FORMAT csv, HEADER true)
\copy bms.movies FROM 'large_data/movies.csv' WITH (FORMAT csv, HEADER true)
\copy bms.offers FROM 'large_data/offers.csv' WITH (FORMAT csv, HEADER true)
\copy bms.venues FROM 'large_data/venues.csv' WITH (FORMAT csv, HEADER true)
\copy bms.customers FROM 'large_data/customers.csv' WITH (FORMAT csv, HEADER true)
\copy bms.screens FROM 'large_data/screens.csv' WITH (FORMAT csv, HEADER true)
\copy bms.seats FROM 'large_data/seats.csv' WITH (FORMAT csv, HEADER true)
\copy bms.shows FROM 'large_data/shows.csv' WITH (FORMAT csv, HEADER true)
\copy bms.bookings FROM 'large_data/bookings.csv' WITH (FORMAT csv, HEADER true)
\copy bms.booking_seats FROM 'large_data/booking_seats.csv' WITH (FORMAT csv, HEADER true)
\copy bms.movie_reviews FROM 'large_data/movie_reviews.csv' WITH (FORMAT csv, HEADER true)

ANALYZE;
