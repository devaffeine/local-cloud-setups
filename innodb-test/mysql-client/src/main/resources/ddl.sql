CREATE TABLE IF NOT EXISTS tb_users (
      id INT NOT NULL AUTO_INCREMENT,
      email VARCHAR(255) NOT NULL,
      name VARCHAR(255) NOT NULL,
      password VARCHAR(256) NOT NULL,
      PRIMARY KEY(id),
      INDEX idx_email (email),
      INDEX idx_password (password)
);