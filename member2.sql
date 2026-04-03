CREATE TABLE Reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    product_id INT,
    order_id INT,
    rating INT,
    comment TEXT,
    verified BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Review_Flag (
    flag_id INT PRIMARY KEY AUTO_INCREMENT,
    review_id INT,
    flag_type VARCHAR(50),
    description TEXT,
    flagged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (review_id) REFERENCES Reviews(review_id)
);

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

INSERT INTO Reviews (user_id, product_id, order_id, rating, comment, verified)
VALUES (1, 1, 101, 5, 'Good product', TRUE);

INSERT INTO Reviews (user_id, product_id, order_id, rating)
VALUES (1, 1, 102, 10);

INSERT INTO Reviews (user_id, product_id, order_id, rating, comment, verified)
VALUES (1, 1, 103, 5, 'Second review same product', TRUE);

SELECT * FROM Review_Flag;

-- This creates a 'View' that managers can check to see suspicious spikes
CREATE OR REPLACE VIEW View_Rating_Spikes AS
SELECT 
    product_id, 
    DATE(created_at) AS review_date, 
    COUNT(*) AS review_count,
    AVG(rating) AS average_rating
FROM Reviews
GROUP BY product_id, review_date
HAVING review_count > 5; -- We flag it if there are more than 5 reviews in one day

-- This query finds users who have 2 or more flagged reviews
CREATE OR REPLACE VIEW View_Suspicious_Users AS
SELECT 
    r.user_id, 
    COUNT(f.flag_id) AS total_flags
FROM Reviews r
JOIN Review_Flag f ON r.review_id = f.review_id
GROUP BY r.user_id
HAVING total_flags >= 2; - so this is final - is it 100% complete now?