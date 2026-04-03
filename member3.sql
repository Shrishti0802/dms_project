CREATE TABLE Sellers (
    seller_id INT AUTO_INCREMENT PRIMARY KEY,
    seller_name VARCHAR(100) NOT NULL
);

ALTER TABLE Products
ADD seller_id INT;

ALTER TABLE Products
ADD FOREIGN KEY (seller_id) REFERENCES Sellers(seller_id);

INSERT INTO Sellers (seller_name) VALUES
('TechStore'),
('GadgetHub'),
('ElectroWorld');

UPDATE Products SET seller_id = 1 WHERE product_id = 1;
UPDATE Products SET seller_id = 2 WHERE product_id = 2;
UPDATE Products SET seller_id = 3 WHERE product_id = 3;

-- Basic Seller Analytics (Average Rating)
SELECT 
    p.seller_id,
    AVG(r.rating) AS avg_rating
FROM Reviews r
JOIN Products p ON r.product_id = p.product_id
GROUP BY p.seller_id;

-- Seller Reputation Score (Weighted)
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

-- Seller Reputation View
CREATE VIEW Seller_Reputation AS
SELECT 
    s.seller_id,
    s.seller_name,
    AVG(r.rating) AS avg_rating,
    COUNT(r.review_id) AS total_reviews
FROM Sellers s
JOIN Products p ON s.seller_id = p.seller_id
JOIN Reviews r ON p.product_id = r.product_id
GROUP BY s.seller_id;

-- Top Sellers
SELECT * 
FROM Seller_Reputation
ORDER BY avg_rating DESC
LIMIT 5;

-- Worst Sellers
SELECT * 
FROM Seller_Reputation
ORDER BY avg_rating ASC;

-- Verified vs Unverified Reviews
SELECT 
    p.seller_id,
    SUM(CASE WHEN r.verified = TRUE THEN 1 ELSE 0 END) AS verified_reviews,
    SUM(CASE WHEN r.verified = FALSE THEN 1 ELSE 0 END) AS unverified_reviews
FROM Reviews r
JOIN Products p ON r.product_id = p.product_id
GROUP BY p.seller_id;

-- Indexing (Performance Optimization)
CREATE INDEX idx_reviews_product ON Reviews(product_id);
CREATE INDEX idx_products_seller ON Products(seller_id);