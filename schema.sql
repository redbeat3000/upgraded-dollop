-- E-Commerce Order & Delivery System

-- Drop and create database
DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

-- Customers table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT
);

-- Products table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    category VARCHAR(50)
);

-- Orders table
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10,2),
    status ENUM('pending', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Order Items table
CREATE TABLE order_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Deliveries table
CREATE TABLE deliveries (
    delivery_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    delivery_date DATE,
    delivery_status ENUM('scheduled', 'in transit', 'delivered', 'failed') DEFAULT 'scheduled',
    courier VARCHAR(100),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Inventory Log (for auditing stock changes)
CREATE TABLE inventory_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    change_amount INT,
    change_type ENUM('add', 'remove', 'return', 'manual') NOT NULL,
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Trigger: Log inventory changes after stock update
DELIMITER $$
CREATE TRIGGER trg_inventory_update
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    DECLARE change_val INT;
    SET change_val = NEW.stock - OLD.stock;

    IF change_val != 0 THEN
        INSERT INTO inventory_log(product_id, change_amount, change_type)
        VALUES (
            NEW.product_id,
            change_val,
            'manual'
        );
    END IF;
END$$
DELIMITER ;

-- View: Order summary
CREATE VIEW order_summary AS
SELECT 
    o.order_id,
    c.full_name AS customer,
    o.order_date,
    o.total,
    o.status,
    d.delivery_status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN deliveries d ON o.order_id = d.order_id;

