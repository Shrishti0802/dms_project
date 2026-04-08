-- ============================================================
-- FAKE PRODUCT REVIEW & SELLER REPUTATION SYSTEM
-- Final Combined Script
-- ============================================================

-- ============================================================
-- MEMBER 1: Core Schema - Users, Products, Orders
-- ============================================================

CREATE DATABASE IF NOT EXISTS review_system;
USE review_system;

CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL
);

CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_status VARCHAR(50) DEFAULT 'pending',
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE
);

-- Sample data
INSERT INTO Users (name, email) VALUES
('Aman', 'aman@gmail.com'),
('Riya', 'riya@gmail.com'),
('Karan', 'karan@gmail.com');

INSERT INTO Products (product_name) VALUES
('Phone'),
('Laptop'),
('Headphones');

INSERT INTO Orders (user_id, product_id, order_date, order_status) VALUES
(1, 1, '2026-03-29', 'delivered'),
(2, 2, '2026-03-28', 'delivered'),
(1, 3, '2026-03-27', 'pending');

-- Query: all orders with user and product details
SELECT u.name, p.product_name, o.order_date, o.order_status
FROM Orders o
JOIN Users u ON o.user_id = u.user_id
JOIN Products p ON o.product_id = p.product_id;


-- ============================================================
-- MEMBER 2: Reviews, Fraud Detection, Triggers, Views
-- ============================================================

CREATE TABLE Reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    product_id INT,
    order_id INT,
    rating INT,
    comment TEXT,
    verified BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

CREATE TABLE Review_Flag (
    flag_id INT PRIMARY KEY AUTO_INCREMENT,
    review_id INT,
    flag_type VARCHAR(50),
    description TEXT,
    flagged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (review_id) REFERENCES Reviews(review_id)
);

-- Trigger: block invalid ratings
DELIMITER $$
CREATE TRIGGER validate_rating
BEFORE INSERT ON Reviews
FOR EACH ROW
BEGIN
    IF NEW.rating < 1 OR NEW.rating > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rating must be between 1 and 5';
    END IF;
END $$
DELIMITER ;

-- Trigger: auto-flag duplicate reviews
DELIMITER $$
CREATE TRIGGER detect_duplicate_review
AFTER INSERT ON Reviews
FOR EACH ROW
BEGIN
    IF (
        SELECT COUNT(*)
        FROM Reviews
        WHERE user_id = NEW.user_id
        AND product_id = NEW.product_id
    ) > 1 THEN
        INSERT INTO Review_Flag (review_id, flag_type, description)
        VALUES (NEW.review_id, 'Duplicate', 'User reviewed same product multiple times');
    END IF;
END $$
DELIMITER ;

-- Sample data
INSERT INTO Reviews (user_id, product_id, order_id, rating, comment, verified)
VALUES (1, 1, 1, 5, 'Good product', TRUE);

INSERT INTO Reviews (user_id, product_id, order_id, rating, comment, verified)
VALUES (2, 2, 2, 4, 'Works great', TRUE);

-- View: detect rating spikes (more than 5 reviews in one day)
CREATE OR REPLACE VIEW View_Rating_Spikes AS
SELECT
    product_id,
    DATE(created_at) AS review_date,
    COUNT(*) AS review_count,
    AVG(rating) AS average_rating
FROM Reviews
GROUP BY product_id, review_date
HAVING review_count > 5;

-- View: users with 2 or more flagged reviews
CREATE OR REPLACE VIEW View_Suspicious_Users AS
SELECT
    r.user_id,
    COUNT(f.flag_id) AS total_flags
FROM Reviews r
JOIN Review_Flag f ON r.review_id = f.review_id
GROUP BY r.user_id
HAVING total_flags >= 2;

SELECT * FROM Review_Flag;


-- ============================================================
-- MEMBER 3: Sellers, Reputation Scoring, Indexes
-- ============================================================

CREATE TABLE Sellers (
    seller_id INT AUTO_INCREMENT PRIMARY KEY,
    seller_name VARCHAR(100) NOT NULL
);

ALTER TABLE Products
ADD seller_id INT;

ALTER TABLE Products
ADD FOREIGN KEY (seller_id) REFERENCES Sellers(seller_id);

-- Sample data
INSERT INTO Sellers (seller_name) VALUES
('TechStore'),
('GadgetHub'),
('ElectroWorld');

UPDATE Products SET seller_id = 1 WHERE product_id = 1;
UPDATE Products SET seller_id = 2 WHERE product_id = 2;
UPDATE Products SET seller_id = 3 WHERE product_id = 3;

-- Query: basic average rating per seller
SELECT
    p.seller_id,
    AVG(r.rating) AS avg_rating
FROM Reviews r
JOIN Products p ON r.product_id = p.product_id
GROUP BY p.seller_id;

-- Query: weighted reputation score (verified reviews count 1.5x)
SELECT
    p.seller_id,
    AVG(
        CASE
            WHEN r.verified = TRUE THEN r.rating * 1.5
            ELSE r.rating
        END
    ) AS reputation_score
FROM Reviews r
JOIN Products p ON r.product_id = p.product_id
GROUP BY p.seller_id;

-- View: seller reputation summary
CREATE VIEW Seller_Reputation AS
SELECT
    s.seller_id,
    s.seller_name,
    AVG(r.rating) AS avg_rating,
    COUNT(r.review_id) AS total_reviews
FROM Sellers s
LEFT JOIN Products p ON s.seller_id = p.seller_id
LEFT JOIN Reviews r ON p.product_id = r.product_id
GROUP BY s.seller_id, s.seller_name;

-- Query: top sellers
SELECT * FROM Seller_Reputation ORDER BY avg_rating DESC LIMIT 5;

-- Query: worst sellers
SELECT * FROM Seller_Reputation ORDER BY avg_rating ASC;

-- Query: verified vs unverified reviews per seller
SELECT
    p.seller_id,
    SUM(CASE WHEN r.verified = TRUE THEN 1 ELSE 0 END) AS verified_reviews,
    SUM(CASE WHEN r.verified = FALSE THEN 1 ELSE 0 END) AS unverified_reviews
FROM Reviews r
JOIN Products p ON r.product_id = p.product_id
GROUP BY p.seller_id;

-- Performance indexes
CREATE INDEX idx_reviews_product ON Reviews(product_id);
CREATE INDEX idx_products_seller ON Products(seller_id);


-- ============================================================
-- MEMBER 4: Admin, Audit Log, Delivery Validation Triggers
-- ============================================================

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

-- Rating check constraint
ALTER TABLE Reviews
ADD CONSTRAINT chk_rating
CHECK (rating BETWEEN 1 AND 5);

-- Trigger: only one review per order
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
DELIMITER ;

-- Trigger: review only allowed for delivered orders
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

-- Trigger: log every review deletion
DELIMITER $$
CREATE TRIGGER log_review_delete
AFTER DELETE ON Reviews
FOR EACH ROW
BEGIN
   INSERT INTO Audit_Log(admin_id, action, table_name, record_id)
   VALUES (1, 'DELETE', 'Reviews', OLD.review_id);
END$$
DELIMITER ;

-- Sample admin data
INSERT INTO Admin (name, role)
VALUES ('Admin1', 'moderator');

-- Test audit log
DELETE FROM Review_Flag WHERE review_id = 1;
DELETE FROM Reviews WHERE review_id = 1;

SELECT * FROM Audit_Log;
DESC Audit_Log;

-- ============================================================
-- END OF SCRIPT
-- ============================================================
