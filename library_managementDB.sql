-- Library Management System Database
-- This SQL script creates a complete database for managing library operations

-- Create the database
CREATE DATABASE library_management;
USE library_management;

-- Members table (1-M with Loans, 1-M with Reservations)
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    membership_date DATE NOT NULL,
    membership_expiry DATE NOT NULL,
    status ENUM('active', 'suspended', 'expired') DEFAULT 'active',
    CONSTRAINT chk_expiry CHECK (membership_expiry > membership_date)
);

-- Authors table (M-M with Books via book_authors)
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_year YEAR,
    death_year YEAR,
    biography TEXT,
    CONSTRAINT chk_lifespan CHECK (death_year IS NULL OR death_year > birth_year)
);

-- Publishers table (1-M with Books)
CREATE TABLE publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(255)
);

-- Categories table (M-M with Books via book_categories)
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

-- Books table (1-M with BookItems, M-M with Authors, M-M with Categories)
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    edition VARCHAR(20),
    publication_year YEAR,
    publisher_id INT,
    pages INT,
    summary TEXT,
    language VARCHAR(30),
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) 
        REFERENCES publishers(publisher_id) ON DELETE SET NULL
);

-- Book-Authors junction table (M-M relationship)
CREATE TABLE book_authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_ba_book FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_ba_author FOREIGN KEY (author_id) 
        REFERENCES authors(author_id) ON DELETE CASCADE
);

-- Book-Categories junction table (M-M relationship)
CREATE TABLE book_categories (
    book_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (book_id, category_id),
    CONSTRAINT fk_bc_book FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_bc_category FOREIGN KEY (category_id) 
        REFERENCES categories(category_id) ON DELETE CASCADE
);

-- BookItems table (physical copies, 1-M with Loans)
CREATE TABLE book_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    barcode VARCHAR(50) UNIQUE NOT NULL,
    acquisition_date DATE NOT NULL,
    price DECIMAL(10,2),
    status ENUM('available', 'checked_out', 'lost', 'damaged', 'in_repair') DEFAULT 'available',
    shelf_location VARCHAR(50),
    CONSTRAINT fk_item_book FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE
);

-- Loans table (M-1 with Members, M-1 with BookItems)
CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    member_id INT NOT NULL,
    checkout_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date DATE NOT NULL,
    return_date DATETIME,
    late_fee DECIMAL(10,2) DEFAULT 0.00,
    status ENUM('active', 'returned', 'overdue', 'lost') DEFAULT 'active',
    CONSTRAINT fk_loan_item FOREIGN KEY (item_id) 
        REFERENCES book_items(item_id),
    CONSTRAINT fk_loan_member FOREIGN KEY (member_id) 
        REFERENCES members(member_id),
    CONSTRAINT chk_due_date CHECK (due_date > DATE(checkout_date)),
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= checkout_date)
);

-- Reservations table (M-1 with Members, M-1 with Books)
CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATETIME NOT NULL,
    status ENUM('pending', 'fulfilled', 'cancelled', 'expired') DEFAULT 'pending',
    CONSTRAINT fk_reservation_book FOREIGN KEY (book_id) 
        REFERENCES books(book_id),
    CONSTRAINT fk_reservation_member FOREIGN KEY (member_id) 
        REFERENCES members(member_id),
    CONSTRAINT chk_reservation_expiry CHECK (expiry_date > reservation_date)
);

-- Fines table (1-1 with Loans)
CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT UNIQUE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    issue_date DATE NOT NULL,
    payment_date DATE,
    status ENUM('unpaid', 'paid', 'waived') DEFAULT 'unpaid',
    CONSTRAINT fk_fine_loan FOREIGN KEY (loan_id) 
        REFERENCES loans(loan_id)
);

-- Staff table
CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    position VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2),
    supervisor_id INT,
    CONSTRAINT fk_staff_supervisor FOREIGN KEY (supervisor_id) 
        REFERENCES staff(staff_id) ON DELETE SET NULL
);

-- Audit log table
CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_type ENUM('insert', 'update', 'delete') NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id INT,
    old_values JSON,
    new_values JSON
);

-- Create indexes for performance
CREATE INDEX idx_book_title ON books(title);
CREATE INDEX idx_member_name ON members(last_name, first_name);
CREATE INDEX idx_author_name ON authors(last_name, first_name);
CREATE INDEX idx_loan_dates ON loans(checkout_date, due_date, return_date);
CREATE INDEX idx_item_status ON book_items(status);
CREATE INDEX idx_reservation_status ON reservations(status);