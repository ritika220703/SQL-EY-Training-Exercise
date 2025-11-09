--3.1
mysql> SELECT first_name, last_name, email, membership_type FROM members WHERE status='active' ORDER BY last_name ASC, first_name ASC;

--3.2
SELECT
    b.title,
    a.author_name,
    b.publication_year AS pub_year,
    b.genre
FROM
    books b
LEFT JOIN
    authors a ON b.author_id = a.author_id
WHERE
    b.publication_year >= 2001
ORDER BY
    b.publication_year DESC;


--3.3
mysql> SELECT b.title, a.author_name, b.total_copies,b.genre FROM books AS b INNER JOIN authors as a ON a.author_id=b.author_id WHERE b.genre='fiction' ORDER BY b.title ASC;

--3.4
 SELECT concat(m.first_name ,' ', m.last_name) as member_name, b.title as book_title,l.loan_date, l.due_date, DATEDIFF(curdate(),l.due_date) as days_overdue from loans l join members m on l.member_id=m.member_id join book_copies bc on l.copy_id=bc.copy_id join books b on b.book_id=bc.book_id where l.status='active' and l.due_date<CURDATE();

--3.5
mysql> SELECT first_name,last_name,join_date,membership_type FROM members WHERE join_date>=DATE_SUB(CURDATE(),INTERVAL 180 DAY) ORDER BY join_date DESC;

--3.6
SELECT b.title, bc.copy_number, bc.condition, bc.acquisition_date FROM books AS b INNER JOIN book_copies AS bc ON b.book_id=bc.book_id WHERE bc.condition='poor' OR bc.condition='fair' ORDER BY bc.condition ASC, bc.acquisition_date ASC;

--3.7
SELECT CONCAT(m.first_name,' ',m.last_name) as member_name, f.fine_amount, 'Overdue or damage book' AS fine_reason,l.loan_date from fines f join loans l on f.loan_id=l.loan_id join members m on l.member_id=m.member_id where f.paid =false order by f.fine_amount DESC LIMIT 10;

--3.8
SELECT event_name,event_date, event_type,max_attendees FROM events WHERE event_date>CURDATE() AND event_date<=DATE_ADD(CURDATE(),INTERVAL 30 DAY) ORDER BY event_date ASC;
