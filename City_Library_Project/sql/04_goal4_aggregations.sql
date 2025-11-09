--4.1
SELECT membership_type, COUNT(*) AS member_count,concat( ROUND( COUNT(*) *100.0/(SELECT COUNT(*) FROM members),2),'%') AS percentage from members GROUP by membership_type ORDER by member_count DESC; 

--4.2
SELECT
    CASE
        WHEN paid = 1 THEN 'Paid'
        WHEN paid=0 then 'outstanding'
        else
        'unknown'
        end as payment_status,
        count(*) as fine_count ,
        sum(fine_amount) as total_amount
        from fines GROUP by paid;

--4.3
SELECT genre, count(DISTINCT book_id) as number_title, sum(total_copies) as total_copy from books group by genre order by total_copy desc limit 5;

--4.4
SELECT
    m.membership_type,
    ROUND(AVG(DATEDIFF(l.return_date, l.loan_date)), 2) AS avg_days_borrowed,
    COUNT(*) AS loan_count
FROM
    loans AS l
JOIN
    members AS m ON l.member_id = m.member_id
WHERE
    l.status = 'returned'
GROUP BY
    m.membership_type
ORDER BY
    avg_days_borrowed DESC;

--4.5
SELECT b.title as book_title, a.author_name as author,b.genre,bc.acquisition_date from book_copies bc join books b on bc.book_id=b.book_id join authors a on b.author_id=a.author_id left join loans l on bc.copy_id=l.copy_id where l.loan_id is NULL ORDER by bc.acquisition_date asc;

--4.6
select concat(m.first_name,' ',m.last_name) as memebrs_name , count(l.loan_id) as total_loans, count(DISTINCT case when l.status='active' then l.loan_id end) as active_loans,COALESCE(sum(case when f.paid=0 then f.fine_amount else 0 end),0) as unpaid_fines from members m join loans l on m.member_id=l.member_id left join fines f on l.loan_id=f.loan_id group by m.member_id,m.first_name,m.last_name order by total_loans desc limit 10;

--4.7
select year(l.loan_date) as loan_year,
month(l.loan_date) as loan_month,
count(*) as total_loans,
count(DISTINCT l.member_id) as unique_borrow,
count(DISTINCT bc.book_id )as unique_books from loans l join book_copies bc on l.copy_id=bc.copy_id where l.loan_date>date_sub(curdate(),interval 6 month) GROUP by year(l.loan_date),month(l.loan_date) order by loan_year desc,loan_month desc limit 6;

--4.8
 SELECT e.event_name,e.event_date,count(r.registration_id) AS registrations, e.max_attendees,ROUND((COUNT(r.registration_id)*100.0/e.max_attendees),2) AS capacity_percentage from events e left join event_registrations r on e.event_id=r.event_id where e.event_date>curdate() group by e.event_id,e.event_name,e.event_date,e.max_attendees order by capacity_percentage desc;