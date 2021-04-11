
CREATE TABLE vatool_users (
  user_id INT,
  username VARCHAR(16),
  password VARCHAR(16),
  first_name VARCHAR(32),
  last_name VARCHAR(32),
  country VARCHAR(16),
  role VARCHAR(16)
);

CREATE TABLE vatool_sessions (
    user_id INT,
    start_time   TIMESTAMP,
    end_time   TIMESTAMP
);

CREATE TABLE vatool_cods (
  user_id INT,
  death_id VARCHAR(16),
  cod_code_1 VARCHAR(64),
  cod_1 VARCHAR(32),
  cod_code_2 VARCHAR(64),
  cod_2 VARCHAR(32),
  cod_code_3 VARCHAR(64),
  cod_3 VARCHAR(32),
  time_stamp TIMESTAMP
);