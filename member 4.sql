USE review_system;

-- Admin table
CREATE TABLE Admin (
    admin_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    role VARCHAR(50)
);

-- Audit Log table
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

-- Trigger: only one review allowed per order
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

-- Trigger: review allowed only for delivered orders
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

-- Trigger: log every review deletion into Audit_Log
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

-- Test: delete a review and check audit log
DELETE FROM Review_Flag WHERE review_id = 1;
DELETE FROM Reviews WHERE review_id = 1;

-- Verify audit log recorded the deletion
SELECT * FROM Audit_Log;
DESC Audit_Log;
