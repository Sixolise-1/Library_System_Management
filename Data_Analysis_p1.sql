SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM return_status;
SELECT * FROM members;


-- Project Task
-- PART 1
-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

-- Task 2: Update an Existing Member's Address

UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';
SELECT * FROM members;

-- Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

SELECT * FROM issued_status
WHERE issued_id = 'IS121';

DELETE FROM issued_status
WHERE issued_id = 'IS121'

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT 
    ist.issued_emp_id,
     e.emp_name
    -- COUNT(*)
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
GROUP BY ist.issued_emp_id, e.emp_name
HAVING COUNT(ist.issued_id) > 1

-- CTAS
-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

SELECT 
    b.isbn,
    b.book_title,
    COUNT(ist.issued_id) AS no_issued
INTO book_cnts
FROM books AS b
JOIN issued_status AS ist
    ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;

SELECT * FROM book_cnts;

-- Task 7. Retrieve All Books in a Specific Category:

SELECT * FROM books
WHERE category = 'Classic'

-- Task 8: Find Total Rental Income by Category:

SELECT
    b.category,
    SUM(b.rental_price) AS total_Rental_Inc,
    COUNT(*) AS number_of_book
FROM books as b
JOIN
issued_status as ist
ON ist.issued_book_isbn = b.isbn
GROUP BY b.category;

-- List Members Who Registered in the Last 180 Days:

SELECT * FROM members
WHERE reg_date >= DATEADD(DAY, -180, GETDATE());  

-- task 10 List Employees with Their Branch Manager's Name and their branch details:

SELECT 
    e1.*,
    b.manager_id,
    e2.emp_name as manager
FROM employees as e1
JOIN  
branch as b
ON b.branch_id = e1.branch_id
JOIN
employees as e2
ON b.manager_id = e2.emp_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold 7USD:

SELECT *
INTO books_price_greater_than_seven 
FROM books
WHERE rental_price > 7;

SELECT * FROM books_price_greater_than_seven;

-- Task 12: Retrieve the List of Books Not Yet Returned

SELECT 
    DISTINCT ist.issued_book_name
FROM issued_status as ist
LEFT JOIN
return_status as rs
ON ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL;
 
SELECT * FROM return_status;

/*
- PART 2: Advanced Analysis
- Insert or add new data 
*/


-- INSERT INTO book_issued in last 30 days

INSERT INTO issued_status(issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
VALUES
('IS151', 'C118', 'The Catcher in the Rye', DATEADD(DAY, -24, GETDATE()),  '978-0-553-29698-2', 'E108'),
('IS152', 'C119', 'The Catcher in the Rye', DATEADD(DAY, -13, GETDATE()),  '978-0-553-29698-2', 'E109'),
('IS153', 'C106', 'Pride and Prejudice', DATEADD(DAY, -7, GETDATE()),  '978-0-14-143951-8', 'E107'),
('IS154', 'C105', 'The Road', DATEADD(DAY, -32, GETDATE()),  '978-0-375-50167-0', 'E101');

-- Adding new column in return_status

ALTER TABLE return_status
ADD book_quality VARCHAR(15) DEFAULT'Good';

UPDATE return_status
SET book_quality = 'Damaged'
WHERE issued_id 
    IN ('IS112', 'IS117', 'IS118');
SELECT * FROM return_status;


/*
Task 13: 
Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.
*/

-- issued_status == members == books == return_status
-- filter books which is return
-- overdue > 30 

SELECT GETDATE();

SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    rs.return_date,
    DATEDIFF(DAY, ist.issued_date, GETDATE()) AS over_dues_days
FROM issued_status as ist
JOIN 
members as m ON m.member_id = ist.issued_member_id
JOIN 
books as bk ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    DATEDIFF(DAY, ist.issued_date, GETDATE()) > 30
ORDER BY 1;

/*    
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-330-25864-8';
-- IS104

SELECT * FROM books
WHERE isbn = '978-0-451-52994-2';

UPDATE books
SET status = 'no'
WHERE isbn = '978-0-451-52994-2';

SELECT * FROM return_status
WHERE issued_id = 'IS130';

-- 
INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
VALUES
('RS125', 'IS130', GETDATE(), 'Good');
SELECT * FROM return_status
WHERE issued_id = 'IS130';

-- Store Procedures

CREATE PROCEDURE add_return_records
    @p_return_id VARCHAR(10),
    @p_issued_id VARCHAR(10),
    @p_book_quality VARCHAR(10)
AS
BEGIN
    DECLARE @v_isbn VARCHAR(50);
    DECLARE @v_book_name VARCHAR(80);

    -- Insert a return record
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES (@p_return_id, @p_issued_id, GETDATE(), @p_book_quality);

    -- Get the book ISBN and name from issued_status
    SELECT 
        @v_isbn = issued_book_isbn,
        @v_book_name = issued_book_name
    FROM issued_status
    WHERE issued_id = @p_issued_id;

    -- Update books table to mark the book as available
    UPDATE books
    SET status = 'yes'
    WHERE isbn = @v_isbn;

    -- Print message
    PRINT 'Thank you for returning the book: ' + @v_book_name;
END;

-- Testing FUNCTION add_return_records

-- Check book information
SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

-- Check issued status
SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

-- Check return status before calling procedure
SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- Call stored procedure to add return record
EXEC add_return_records 'RS138', 'IS135', 'Good';

-- Call again for a different issued_id
EXEC add_return_records 'RS148', 'IS140', 'Good';

-- Check return status again to see the result
SELECT * FROM return_status
WHERE issued_id IN ('IS135', 'IS140');

/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
*/

SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) AS number_book_issued,
    COUNT(rs.return_id) AS number_of_book_return,
    SUM(bk.rental_price) AS total_revenue
INTO branch_reports
FROM issued_status AS ist
JOIN employees AS e
    ON e.emp_id = ist.issued_emp_id
JOIN branch AS b
    ON e.branch_id = b.branch_id
LEFT JOIN return_status AS rs
    ON rs.issued_id = ist.issued_id
JOIN books AS bk
    ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.manager_id;

-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.

SELECT *
INTO active_members
FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id   
    FROM issued_status
    WHERE issued_date >= DATEADD(MONTH, -2, GETDATE())
);
SELECT * FROM active_members;

-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

SELECT 
    e.emp_name,
    b.branch_id,
    b.manager_id,
    b.branch_address,
    b.contact_no,
    COUNT(ist.issued_id) AS no_book_issued
FROM issued_status AS ist
JOIN employees AS e
    ON e.emp_id = ist.issued_emp_id
JOIN branch AS b
    ON e.branch_id = b.branch_id
GROUP BY 
    e.emp_name,
    b.branch_id,
    b.manager_id,
    b.branch_address,
    b.contact_no;  

/*
Task 19: Stored Procedure Objective: 

Create a stored procedure to manage the status of books in a library system. 

Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 

The procedure should function as follows: 

The stored procedure should take the book_id as an input parameter. 

The procedure should first check if the book is available (status = 'yes'). 

If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 

If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/

-- Check existing data
SELECT * FROM books;
SELECT * FROM issued_status;

-- Drop procedure if it already exists
IF OBJECT_ID('issue_book', 'P') IS NOT NULL
    DROP PROCEDURE issue_book;
GO

-- Create procedure
CREATE PROCEDURE issue_book
    @p_issued_id VARCHAR(10),
    @p_issued_member_id VARCHAR(30),
    @p_issued_book_isbn VARCHAR(30),
    @p_issued_emp_id VARCHAR(10)
AS
BEGIN
    DECLARE @v_status VARCHAR(10);

    -- Check if book is available
    SELECT @v_status = status
    FROM books
    WHERE isbn = @p_issued_book_isbn;

    IF @v_status = 'yes'
    BEGIN
        -- Insert record into issued_status
        INSERT INTO issued_status (issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES (@p_issued_id, @p_issued_member_id, GETDATE(), @p_issued_book_isbn, @p_issued_emp_id);

        -- Update book status to 'no'
        UPDATE books
        SET status = 'no'
        WHERE isbn = @p_issued_book_isbn;

        PRINT 'Book records added successfully for book ISBN: ' + @p_issued_book_isbn;
    END
    ELSE
    BEGIN
        PRINT 'Sorry, the book you requested is unavailable. Book ISBN: ' + @p_issued_book_isbn;
    END
END;
GO

-- Check data again
SELECT * FROM books;
SELECT * FROM issued_status;

-- Test procedure calls
EXEC issue_book 'IS155', 'C108', '978-0-553-29698-2', 'E104';
EXEC issue_book 'IS156', 'C108', '978-0-375-41398-8', 'E104';

-- Verify if book is updated
SELECT * FROM books WHERE isbn = '978-0-375-41398-8';


-- 

