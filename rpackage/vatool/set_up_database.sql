-- CREATE DATABASE va;
-- NOTE switch to the va database before proceeding with the following queries execution.
-- psql command `\c va`
-- on ubuntu: export PGPASSWORD='va'; psql -h 'localhost' -U 'va' -d 'va'

CREATE TABLE users (
  user_id INT,
  username VARCHAR(16),
  password VARCHAR(16),
  first_name VARCHAR(32),
  last_name VARCHAR(32),
  country VARCHAR(16),
  role VARCHAR(16)
);

CREATE TABLE sessions (
    user_id INT,
    start_time   TIMESTAMP,
    end_time   TIMESTAMP
);

CREATE TABLE cods (
  user_id INT,
  death_id VARCHAR(16),
  cod_code VARCHAR(64),
  cod VARCHAR(32),
  time_stamp TIMESTAMP
);