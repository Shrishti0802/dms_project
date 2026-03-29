CREATE DATABASE review_system;
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
    
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
        ON DELETE CASCADE,
        
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
        ON DELETE CASCADE
);

-- Users
INSERT INTO Users (name, email) VALUES
('Aman', 'aman@gmail.com'),
('Riya', 'riya@gmail.com'),
('Karan', 'karan@gmail.com');

-- Products
INSERT INTO Products (product_name) VALUES
('Phone'),
('Laptop'),
('Headphones');

-- Orders
INSERT INTO Orders (user_id, product_id, order_date) VALUES
(1, 1, '2026-03-29'),
(2, 2, '2026-03-28'),
(1, 3, '2026-03-27');

SELECT *
FROM Orders
WHERE user_id = 3 AND product_id = 1;

SELECT *
FROM Orders
WHERE user_id = 3 AND product_id = 1;

-- Find all orders of a user
SELECT u.name, p.product_name, o.order_date
FROM Orders o
JOIN Users u ON o.user_id = u.user_id
JOIN Products p ON o.product_id = p.product_id;
