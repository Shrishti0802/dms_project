CREATE DATABASE fake_review_system;
USE fake_review_system;


CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE
);

CREATE TABLE Seller (
    seller_id INT PRIMARY KEY AUTO_INCREMENT,
    seller_name VARCHAR(100)
);

CREATE TABLE Product (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100),
    price DECIMAL(10,2),
    seller_id INT,
    FOREIGN KEY (seller_id) REFERENCES Seller(seller_id)
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    product_id INT,
    order_status VARCHAR(50),
    order_date DATE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

CREATE TABLE Reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    rating INT,
    review_text TEXT,
    is_flagged BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

CREATE TABLE Review_Flag (
    flag_id INT PRIMARY KEY AUTO_INCREMENT,
    review_id INT,
    reason VARCHAR(255),
    FOREIGN KEY (review_id) REFERENCES Reviews(review_id)
);

SHOW TABLES;

INSERT INTO Users (name, email) VALUES
('Alice', 'alice@gmail.com'),
('Bob', 'bob@gmail.com');

INSERT INTO Seller (seller_name) VALUES
('TechStore'),
('GadgetHub');

INSERT INTO Product (product_name, price, seller_id) VALUES
('Phone', 15000, 1),
('Laptop', 50000, 2);

INSERT INTO Orders (user_id, product_id, order_status, order_date) VALUES
(1, 1, 'delivered', '2024-01-01'),
(2, 2, 'pending', '2024-01-02');

INSERT INTO Reviews (order_id, rating, review_text) VALUES
(1, 5, 'Great product!');

INSERT INTO Review_Flag (review_id, reason) VALUES
(1, 'Spam detected');

SELECT * FROM Users;
SELECT * FROM Orders;
SELECT * FROM Reviews;

DELIMITER $$

CREATE TRIGGER one_review_per_order
BEFORE INSERT ON Reviews
FOR EACH ROW
BEGIN
   IF EXISTS (
      SELECT 1 FROM Reviews
      WHERE order_id = NEW.order_id
   ) THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Only one review allowed per order';
   END IF;
END$$

DELIMITER $$

CREATE TRIGGER check_order_delivered
BEFORE INSERT ON Reviews
FOR EACH ROW
BEGIN
   IF NOT EXISTS (
      SELECT 1 FROM Orders
      WHERE order_id = NEW.order_id
      AND order_status = 'delivered'
   ) THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Review allowed only for delivered orders';
   END IF;
END$$

DELIMITER ;

ALTER TABLE Reviews
ADD CONSTRAINT chk_rating
CHECK (rating BETWEEN 1 AND 5);

INSERT INTO Reviews (order_id, rating, review_text)
VALUES (1, 4, 'Duplicate review');

CREATE TABLE Admin (
    admin_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    role VARCHAR(50)
);

CREATE TABLE Audit_Log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    admin_id INT,
    action VARCHAR(100),
    table_name VARCHAR(50),
    record_id INT,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES Admin(admin_id)
);

INSERT INTO Admin (name, role)
VALUES ('Admin1', 'moderator');

DELIMITER $$

CREATE TRIGGER log_review_delete
AFTER DELETE ON Reviews
FOR EACH ROW
BEGIN
   INSERT INTO Audit_Log(admin_id, action, table_name, record_id)
   VALUES (1, 'DELETE', 'Reviews', OLD.review_id);
END$$

DELIMITER ;

DELETE FROM Reviews WHERE review_id = 1;

SELECT * FROM Audit_Log;

DELETE FROM Review_Flag WHERE review_id = 1;

DELETE FROM Reviews WHERE review_id = 1;

SELECT * FROM Audit_Log;

DESC Audit_Log;

SELECT * FROM Audit_Log;