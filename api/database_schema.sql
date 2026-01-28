-- ============================================
-- SLTB Board of Survey - MySQL Database Schema
-- ============================================
-- Run this SQL to create the assets table in your MySQL database

CREATE DATABASE IF NOT EXISTS sltb_bos;
USE sltb_bos;

-- Drop existing table if needed (uncomment if you want to recreate)
-- DROP TABLE IF EXISTS assets;

CREATE TABLE IF NOT EXISTS assets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    serial_no INT NULL,
    description VARCHAR(500) NOT NULL,
    old_code VARCHAR(100) NULL,
    new_code VARCHAR(100) NOT NULL UNIQUE,
    book_balance INT DEFAULT 0,
    physical_balance INT DEFAULT 0,
    excess INT DEFAULT 0,
    shortage INT DEFAULT 0,
    remarks TEXT NULL,
    survey_status VARCHAR(50) NULL COMMENT 'verified, damaged, missing, pending',
    image_path_1 VARCHAR(255) NULL COMMENT 'Filename of first image',
    image_path_2 VARCHAR(255) NULL COMMENT 'Filename of second image',
    image_path_3 VARCHAR(255) NULL COMMENT 'Filename of third image',
    entered_by VARCHAR(100) NULL COMMENT 'Username of regional officer who entered data',
    entered_date DATETIME NULL COMMENT 'Date/time of initial data entry',
    verified_by VARCHAR(100) NULL COMMENT 'Username of field officer who verified',
    verified_date DATETIME NULL COMMENT 'Date/time of verification',
    verification_status VARCHAR(50) DEFAULT 'pending' COMMENT 'pending, verified, needs_correction',
    last_updated_by VARCHAR(100) NULL,
    last_updated_date DATETIME NULL,
    is_new_item TINYINT(1) DEFAULT 0 COMMENT '0=existing item, 1=new item added during survey',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_new_code (new_code),
    INDEX idx_survey_status (survey_status),
    INDEX idx_verification_status (verification_status),
    INDEX idx_entered_by (entered_by),
    INDEX idx_last_updated_by (last_updated_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sample data for testing (optional)
-- INSERT INTO assets (serial_no, description, old_code, new_code, book_balance) VALUES
-- (1, 'Office Chair - Executive', 'OLD001', 'NEW001', 5),
-- (2, 'Computer Desktop', 'OLD002', 'NEW002', 10),
-- (3, 'Air Conditioner 2HP', 'OLD003', 'NEW003', 2);
