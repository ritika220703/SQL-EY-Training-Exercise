--5.1
 SELECT
    ->     CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    ->     m.email,
    ->     b.title AS book_title,
    ->     a.author_name AS author,
    ->     l.loan_date,
    ->     l.due_date,
    ->     l.return_date,
    ->     l.status
    -> FROM
    ->     loans AS l
    -> JOIN
    ->     members AS m ON l.member_id = m.member_id
    -> JOIN
    ->     book_copies AS bc ON l.copy_id = bc.copy_id
    -> JOIN
    ->     books AS b ON bc.book_id = b.book_id
    -> JOIN
    ->     authors AS a ON b.author_id = a.author_id
    -> ORDER BY
    ->     l.loan_date DESC
    -> LIMIT 20;

--5.2
SELECT
    b.title AS book_title,
    a.author_name AS author,
    bc.copy_number,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    l.loan_date,
    l.due_date,
    DATEDIFF(l.due_date, CURDATE()) AS days_until_due
FROM
    loans AS l
JOIN
    members AS m ON l.member_id = m.member_id
JOIN
    book_copies AS bc ON l.copy_id = bc.copy_id
JOIN
    books AS b ON bc.book_id = b.book_id
JOIN
    authors AS a ON b.author_id = a.author_id
WHERE
    l.status = 'active'
ORDER BY
    l.due_date ASC;

--5.3
SELECT
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.email,
    m.phone,
    SUM(CASE WHEN l.status = 'active' AND l.due_date < CURDATE() THEN 1 ELSE 0 END) AS overdue_books,
    SUM(f.fine_amount) AS total_unpaid_fines
FROM
    members AS m
JOIN
    loans AS l ON m.member_id = l.member_id
JOIN
    fines AS f ON l.loan_id = f.loan_id
WHERE
    f.paid = FALSE
GROUP BY
    m.member_id, m.first_name, m.last_name, m.email, m.phone
HAVING
    total_unpaid_fines > 0
ORDER BY
    total_unpaid_fines DESC;

--5.4
SELECT 
  b.title,
  a.author_name AS author,
  COUNT(DISTINCT bc.copy_id) AS total_copies,
  COUNT(DISTINCT CASE WHEN l.status='borrowed' THEN l.loan_id END) AS copies_loan,
  (COUNT(DISTINCT bc.copy_id) - COUNT(DISTINCT CASE WHEN l.status='borrowed' THEN l.loan_id END)) AS available
FROM books b
JOIN authors a ON b.author_id=a.author_id
LEFT JOIN book_copies bc ON b.book_id=bc.book_id
LEFT JOIN loans l ON bc.copy_id=l.copy_id
GROUP BY b.book_id, b.title, a.author_name
ORDER BY available ASC;

--5.5
SELECT
    e.event_name,
    e.event_date,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.email,
    er.registration_date
FROM
    events AS e
JOIN
    event_registrations AS er ON e.event_id = er.event_id
JOIN
    members AS m ON er.member_id = m.member_id
WHERE
    e.event_date >= CURDATE()
ORDER BY
    e.event_date ASC,
    m.last_name ASC,
    m.first_name ASC;

--5.6
SELECT
    a.author_name AS author,
    COUNT(DISTINCT b.book_id) AS book_count,
    COUNT(l.loan_id) AS total_loans,
    ROUND(COUNT(l.loan_id) / COUNT(DISTINCT b.book_id), 2) AS avg_loans_per_book
FROM
    authors AS a
JOIN
    books AS b ON a.author_id = b.author_id
JOIN
    book_copies AS bc ON b.book_id = bc.book_id
JOIN
    loans AS l ON bc.copy_id = l.copy_id
GROUP BY
    a.author_id, a.author_name
HAVING
    total_loans > 0
ORDER BY
    total_loans DESC
LIMIT 10;

--5.7
SELECT
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.email,
    m.join_date,
    m.membership_type
FROM
    members AS m
LEFT JOIN
    loans AS l ON m.member_id = l.member_id
WHERE
    l.loan_id IS NULL
ORDER BY
    m.join_date ASC;

--5.8
SELECT
    CONCAT(m1.first_name, ' ', m1.last_name) AS member1_name,
    CONCAT(m2.first_name, ' ', m2.last_name) AS member2_name,
    m1.address AS shared_address
FROM
    members AS m1
JOIN
    members AS m2 ON m1.address = m2.address
    AND m1.member_id < m2.member_id
ORDER BY
    m1.address ASC;