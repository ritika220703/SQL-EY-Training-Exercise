--6.1
SELECT
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    SUM(f.fine_amount) AS total_unpaid_fines,
    COUNT(f.fine_id) AS number_of_fines
FROM
    members AS m
JOIN
    loans AS l ON m.member_id = l.member_id
JOIN
    fines AS f ON l.loan_id = f.loan_id
WHERE
    f.paid = FALSE
GROUP BY
    m.member_id, m.first_name, m.last_name
HAVING
    total_unpaid_fines >
    (
        SELECT AVG(member_total)
        FROM (
            SELECT SUM(f2.fine_amount) AS member_total
            FROM fines AS f2
            JOIN loans AS l2 ON f2.loan_id = l2.loan_id
            WHERE f2.paid = FALSE
            GROUP BY l2.member_id
        ) AS fine_stats
    )
ORDER BY
    total_unpaid_fines DESC;

--6.2
SELECT
    b.title,
    a.author_name AS author,
    COUNT(l.loan_id) AS total_loans,
    (
        SELECT ROUND(AVG(book_loan_count), 2)
        FROM (
            SELECT COUNT(l2.loan_id) AS book_loan_count
            FROM books AS b2
            JOIN book_copies AS bc2 ON b2.book_id = bc2.book_id
            LEFT JOIN loans AS l2 ON bc2.copy_id = l2.copy_id
            GROUP BY b2.book_id
        ) AS loan_stats
    ) AS average_loans
FROM
    books AS b
JOIN
    authors AS a ON b.author_id = a.author_id
JOIN
    book_copies AS bc ON b.book_id = bc.book_id
LEFT JOIN
    loans AS l ON bc.copy_id = l.copy_id
GROUP BY
    b.book_id, b.title, a.author_name
HAVING
    total_loans >
    (
        SELECT AVG(book_loan_count)
        FROM (
            SELECT COUNT(l2.loan_id) AS book_loan_count
            FROM books AS b2
            JOIN book_copies AS bc2 ON b2.book_id = bc2.book_id
            LEFT JOIN loans AS l2 ON bc2.copy_id = l2.copy_id
            GROUP BY b2.book_id
        ) AS loan_stats
    )
ORDER BY
    total_loans DESC;

--6.3
WITH loan_counts AS (
    SELECT member_id, COUNT(loan_id) AS total_loans
    FROM loans
    GROUP BY member_id
),
fine_totals AS (
    SELECT L.member_id, COALESCE(SUM(F.fine_amount), 0.00) AS total_fines
    FROM fines F
    JOIN loans L ON F.loan_id = L.loan_id
    WHERE F.paid = FALSE
    GROUP BY L.member_id
),
active_counts AS (
    SELECT member_id, COUNT(loan_id) AS active_loans
    FROM loans
    WHERE status = 'active'
    GROUP BY member_id
)
SELECT
    M.first_name,
    M.last_name,
    COALESCE(LC.total_loans, 0) AS total_loans,
    COALESCE(AC.active_loans, 0) AS active_loans,
    COALESCE(FT.total_fines, 0.00) AS total_unpaid_fines,
    M.status AS member_status
FROM
    members M
LEFT JOIN loan_counts LC ON M.member_id = LC.member_id
LEFT JOIN fine_totals FT ON M.member_id = FT.member_id
LEFT JOIN active_counts AC ON M.member_id = AC.member_id
ORDER BY
    total_loans DESC;

--6.4
 select b.title,a.author_name AS author, b.genre,count(b.total_copies) AS total_copies from books b join authors a on b.author_id=a.author_id where not exists(select 1 from loans l join book_copies bc on l.copy_id=bc.copy_id where bc.book_id=b.book_id) group by b.book_id,b.title,a.author_name,b.genre order by b.publication_year asc;

--6.5
SELECT
    M.first_name,
    M.last_name,
    COUNT(ER.registration_id) AS events_attended
FROM
    members M
JOIN
    event_registrations ER ON M.member_id = ER.member_id
JOIN
    events E ON ER.event_id = E.event_id
WHERE
    E.event_type = 'book_club'
GROUP BY
    M.member_id, M.first_name, M.last_name
HAVING
    COUNT(ER.registration_id) = (
        -- Subquery: Finds the total count of 'book_club' events
        SELECT COUNT(event_id) FROM events WHERE event_type = 'book_club'
    )
ORDER BY
    M.last_name, M.first_name;

--6.6
WITH fine_revenue AS (
    SELECT
        DATE_FORMAT(payment_date, '%Y-%m') AS year_month,
        SUM(fine_amount) AS fine_revenue
    FROM fines
    WHERE paid = TRUE AND payment_date IS NOT NULL
    GROUP BY year_month
),
membership_revenue AS (
    -- Placeholder: Estimates new membership revenue for simplicity
    SELECT
        DATE_FORMAT(join_date, '%Y-%m') AS year_month,
        COUNT(member_id) * 10.00 AS membership_revenue
    FROM members
    GROUP BY year_month
)
SELECT
    COALESCE(FR.year_month, MR.year_month) AS year_month,
    COALESCE(FR.fine_revenue, 0.00) AS fine_revenue,
    COALESCE(MR.membership_revenue, 0.00) AS membership_revenue,
    COALESCE(FR.fine_revenue, 0.00) + COALESCE(MR.membership_revenue, 0.00) AS total_revenue
FROM
    fine_revenue FR
LEFT JOIN membership_revenue MR ON FR.year_month = MR.year_month
UNION
SELECT
    COALESCE(FR.year_month, MR.year_month) AS year_month,
    COALESCE(FR.fine_revenue, 0.00) AS fine_revenue,
    COALESCE(MR.membership_revenue, 0.00) AS membership_revenue,
    COALESCE(FR.fine_revenue, 0.00) + COALESCE(MR.membership_revenue, 0.00) AS total_revenue
FROM
    membership_revenue MR
LEFT JOIN fine_revenue FR ON MR.year_month = FR.year_month
ORDER BY
    year_month DESC
LIMIT 12;

--6.7
SELECT
    B.title,
    A.author_name,
    B.genre,
    (
        -- Correlated Subquery: Finds the MAX loan_date for the current book (B.book_id)
        SELECT MAX(L.loan_date)
        FROM loans L
        JOIN book_copies BC ON L.copy_id = BC.copy_id
        WHERE BC.book_id = B.book_id
    ) AS most_recent_loan_date
FROM
    books B
JOIN
    authors A ON B.author_id = A.author_id
WHERE
    B.book_id IN (
        -- Ensures only books that have been loaned at least once are included
        SELECT DISTINCT BC_Sub.book_id
        FROM loans L_Sub
        JOIN book_copies BC_Sub ON L_Sub.copy_id = BC_Sub.copy_id
    )
ORDER BY
    most_recent_loan_date DESC;

--6.8
WITH member_favorite_genre AS (
    -- CTE 1: Determine each member's most borrowed genre
    SELECT
        L.member_id,
        B.genre,
        ROW_NUMBER() OVER(PARTITION BY L.member_id ORDER BY COUNT(B.genre) DESC) AS rn
    FROM loans L
    JOIN book_copies BC ON L.copy_id = BC.copy_id
    JOIN books B ON BC.book_id = B.book_id
    GROUP BY L.member_id, B.genre
),
recommended_books AS (
    -- CTE 2: Find the most popular book in each genre
    SELECT
        B.title AS recommended_title,
        B.genre,
        B.book_id
    FROM books B
    JOIN book_copies BC ON B.book_id = BC.book_id
    LEFT JOIN loans L ON BC.copy_id = L.copy_id
    GROUP BY B.book_id, B.title, B.genre
    ORDER BY COUNT(L.loan_id) DESC
    LIMIT 100
)
SELECT
    M.first_name,
    M.last_name,
    MFG.genre AS favorite_genre,
    RB.recommended_title
FROM
    members M
JOIN
    member_favorite_genre MFG ON M.member_id = MFG.member_id AND MFG.rn = 1
JOIN
    recommended_books RB ON MFG.genre = RB.genre
WHERE
    RB.book_id NOT IN (
        -- Exclude books the member has already borrowed
        SELECT BC_Sub.book_id
        FROM loans L_Sub
        JOIN book_copies BC_Sub ON L_Sub.copy_id = BC_Sub.copy_id
        WHERE L_Sub.member_id = M.member_id
    )
LIMIT 10;