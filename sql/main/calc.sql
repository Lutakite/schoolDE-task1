--������� ������� results c ���������� id (INT), response (TEXT), ���
--�  id � ����� ������� �� ������ ����
--�  response � ��������� �������
-- ���� ������ �������� ��������� ���������, �� �� �������� ������ ������������ � ����, ����� ������������ � ������������ �|�
--���� ��������� ���������� ��������� �������, �� ��� ������ ������������ � �������������� �������,
--� id ������ ������� � ��������������� �� ����������� �� ���� ��������� ���������.

CREATE TABLE results (id int, response text);

--+1.  ������� ������������ ���������� ������� � ����� ������������;

INSERT INTO results
SELECT 1 AS id,
       max(pass_num)
FROM
  (SELECT bookings.book_ref,
          count(*) AS pass_num
   FROM bookings,
        tickets
   WHERE tickets.book_ref = bookings.book_ref
   GROUP BY bookings.book_ref) AS s;

--+2.  ������� ���������� ������������ � ����������� ����� ������ �������� �������� ����� �� ���� ������������;

INSERT INTO results
SELECT 2 AS id,
       count(*) AS response
FROM
  (SELECT bookings.book_ref,
          count(*) AS pass_num
   FROM bookings,
        tickets
   WHERE tickets.book_ref = bookings.book_ref
   GROUP BY bookings.book_ref) AS s
WHERE pass_num >
    (SELECT
       (SELECT count(*)
        FROM tickets)::float/
       (SELECT count(*)
        FROM bookings));

--+3.  ������� ���������� ������������, � ������� ������ ���������� ���������� ��� � ����� ����, ����� ������������ � ������������ ���������� ����� (�.1);

INSERT INTO results
SELECT 3 AS id,
       coalesce(sum(c), 0)
FROM
  (SELECT passengers,
          count(passengers) AS c
   FROM
     (SELECT bookings.book_ref,
             string_agg(tickets.passenger_id, ','
                        ORDER BY tickets.passenger_id) AS passengers
      FROM bookings,
           tickets
      WHERE tickets.book_ref = bookings.book_ref
        AND bookings.book_ref in
          (SELECT bookings.book_ref AS book_ref
           FROM bookings,
                tickets
           WHERE tickets.book_ref = bookings.book_ref
           GROUP BY bookings.book_ref
           HAVING count(*) in
             (SELECT max(pass_num)
              FROM
                (SELECT bookings.book_ref,
                        count(*) AS pass_num
                 FROM bookings,
                      tickets
                 WHERE tickets.book_ref = bookings.book_ref
                 GROUP BY bookings.book_ref) AS s))
      GROUP BY bookings.book_ref) AS s
   GROUP BY passengers
   HAVING count(passengers) > 1) AS ss;

--+4.  ������� ������ ����� � ���������� ���������� �� ���������� � ����� (passenger_id, passenger_name, contact_data) � ����������� ����� � ����� = 3

INSERT INTO results
SELECT 4 AS id,
       tickets.book_ref::text || '|' || tickets.passenger_id::text || '|' || tickets.passenger_name::text || '|' || tickets.contact_data::text AS response
FROM tickets
WHERE tickets.book_ref in
    (SELECT tickets.book_ref
     FROM tickets
     GROUP BY tickets.book_ref
     HAVING count(*)=3);


INSERT INTO results (id, response)
SELECT 4,
       NULL
WHERE NOT EXISTS
    (SELECT *
     FROM results
     WHERE id = 4 );

--+5.  ������� ������������ ���������� �������� �� �����

INSERT INTO results
SELECT 5 AS id,
       max(c) AS response
FROM
  (SELECT count(*) AS c
   FROM tickets,
        ticket_flights
   WHERE tickets.ticket_no = ticket_flights.ticket_no
   GROUP BY tickets.book_ref) AS s;

--+6.  ������� ������������ ���������� �������� �� ��������� � ����� �����

INSERT INTO results
SELECT 6 AS id,
       count(*) AS response
FROM tickets,
     ticket_flights
WHERE tickets.ticket_no = ticket_flights.ticket_no
GROUP BY tickets.book_ref,
         tickets.passenger_id
ORDER BY count(*) DESC
LIMIT 1;

--+7.  ������� ������������ ���������� �������� �� ���������

INSERT INTO results
SELECT 7 AS id,
       count(*) AS response
FROM tickets,
     ticket_flights
WHERE tickets.ticket_no = ticket_flights.ticket_no
GROUP BY tickets.passenger_id
ORDER BY count(*) DESC
LIMIT 1;

--+8.  ������� ���������� ���������� �� ��������� (passenger_id, passenger_name, contact_data)
--� ����� ����� �� ������, ��� ��������� ������������ ����������� ���������� ����� �� ��������

INSERT INTO results
SELECT 8 AS id,
       tickets.passenger_id::text || '|' || tickets.passenger_name::text || '|' || tickets.contact_data::text || '|' || sum(ticket_flights.amount)::text AS response
FROM tickets,
     ticket_flights,
     flights
WHERE tickets.ticket_no = ticket_flights.ticket_no
  AND flights.flight_id=ticket_flights.flight_id
  AND flights.status <> 'Cancelled'
GROUP BY tickets.passenger_id,
         tickets.passenger_name,
         tickets.contact_data
HAVING sum(ticket_flights.amount) in
  (SELECT sum(ticket_flights.amount) AS s
   FROM tickets,
        ticket_flights,
        flights
   WHERE tickets.ticket_no = ticket_flights.ticket_no
     AND flights.flight_id=ticket_flights.flight_id
     AND flights.status <> 'Cancelled'
   GROUP BY tickets.passenger_id
   ORDER BY s
   LIMIT 1);

--+9.  ������� ���������� ���������� �� ��������� (passenger_id, passenger_name, contact_data)
--� ����� ����� � ������, ��� ���������, ������� ����� ������������ ����� � ������

INSERT INTO results
SELECT 9 AS id,
       tickets.passenger_id::text || '|' || tickets.passenger_name::text || '|' || tickets.contact_data::text || '|' || sum(flights.actual_arrival-flights.actual_departure)::text AS response
FROM tickets,
     ticket_flights,
     flights
WHERE tickets.ticket_no = ticket_flights.ticket_no
  AND flights.flight_id=ticket_flights.flight_id
  AND flights.status = 'Arrived'
GROUP BY tickets.passenger_id,
         tickets.passenger_name,
         tickets.contact_data
HAVING sum(flights.actual_arrival-flights.actual_departure) in
  (SELECT sum(flights.actual_arrival-flights.actual_departure) AS s
   FROM tickets,
        ticket_flights,
        flights
   WHERE tickets.ticket_no = ticket_flights.ticket_no
     AND flights.flight_id=ticket_flights.flight_id
     AND flights.status = 'Arrived'
   GROUP BY tickets.passenger_id
   ORDER BY s DESC
   LIMIT 1);

--10+.  ������� ������ � ����������� ���������� ������ ������

INSERT INTO results
SELECT 10 AS id,
       airports.city AS response
FROM airports
GROUP BY airports.city
HAVING count(*)>1
ORDER BY count(*) DESC, airports.city ASC;


INSERT INTO results (id, response)
SELECT 10,
       NULL
WHERE NOT EXISTS
    (SELECT *
     FROM results
     WHERE id = 10 );

--11+.  ������� �����, � �������� ����� ������� ���������� ������� ������� ���������

INSERT INTO results
SELECT 11 AS id,
       a1 AS response
FROM
  (SELECT DISTINCT a.city AS a1,
                   aa.city AS a2
   FROM flights,
        airports AS a,
        airports AS aa
   WHERE flights.departure_airport = a.airport_code
     AND flights.arrival_airport = aa.airport_code
   UNION SELECT DISTINCT aa.city AS a1,
                         a.city AS a2
   FROM flights,
        airports AS a,
        airports AS aa
   WHERE flights.departure_airport = a.airport_code
     AND flights.arrival_airport = aa.airport_code ) AS s
GROUP BY a1
HAVING count(DISTINCT a2) in
  (SELECT count(DISTINCT a2) AS c
   FROM
     (SELECT DISTINCT a.city AS a1,
                      aa.city AS a2
      FROM flights,
           airports AS a,
           airports AS aa
      WHERE flights.departure_airport = a.airport_code
        AND flights.arrival_airport = aa.airport_code
      UNION SELECT DISTINCT aa.city AS a1,
                            a.city AS a2
      FROM flights,
           airports AS a,
           airports AS aa
      WHERE flights.departure_airport = a.airport_code
        AND flights.arrival_airport = aa.airport_code ) AS ss
   GROUP BY a1
   ORDER BY c
   LIMIT 1)
ORDER BY a1;

--+12.  ������� ���� �������, � ������� ��� ������ ��������� �������� ��������� ���������

INSERT INTO results
SELECT 12 AS id,
       a1 || '|' || a2 AS response
FROM
  (SELECT a.city AS a1,
          aa.city AS a2
   FROM airports AS a,
        airports AS aa
   WHERE a.city < aa.city
   EXCEPT
     (SELECT DISTINCT a.city AS a1,
                      aa.city AS a2
      FROM flights,
           airports AS a,
           airports AS aa
      WHERE flights.departure_airport = a.airport_code
        AND flights.arrival_airport = aa.airport_code
      UNION SELECT DISTINCT aa.city AS a1,
                            a.city AS a2
      FROM flights,
           airports AS a,
           airports AS aa
      WHERE flights.departure_airport = a.airport_code
        AND flights.arrival_airport = aa.airport_code )) AS f
ORDER BY a1,
         a2;


INSERT INTO results (id, response)
SELECT 12,
       NULL
WHERE NOT EXISTS
    (SELECT *
     FROM results
     WHERE id = 12 );

--+13.  ������� ������, �� ������� ������ ��������� ��� ��������� �� ������?

INSERT INTO results
SELECT 13 AS id,
       a2 AS response
FROM
  (SELECT a.city AS a1,
          aa.city AS a2
   FROM airports AS a,
        airports AS aa
   EXCEPT
     (SELECT DISTINCT a.city AS a1,
                      aa.city AS a2
      FROM flights,
           airports AS a,
           airports AS aa
      WHERE flights.departure_airport = a.airport_code
        AND flights.arrival_airport = aa.airport_code
      UNION SELECT DISTINCT aa.city AS a1,
                            a.city AS a2
      FROM flights,
           airports AS a,
           airports AS aa
      WHERE flights.departure_airport = a.airport_code
        AND flights.arrival_airport = aa.airport_code )) AS f
WHERE a1 = '������'
ORDER BY a2;


INSERT INTO results (id, response)
SELECT 13,
       NULL
WHERE NOT EXISTS
    (SELECT *
     FROM results
     WHERE id = 13 );

--+14.  ������� ������ ��������, ������� �������� ������ ����� ������

INSERT INTO results
SELECT 14 AS id,
       aircrafts.model AS response
FROM aircrafts,
     flights
WHERE aircrafts.aircraft_code = flights.aircraft_code
  AND flights.status = 'Arrived'
GROUP BY aircrafts.aircraft_code,
         aircrafts.model
ORDER BY count(*) DESC, aircrafts.model
LIMIT 1;

--+15.  ������� ������ ��������, ������� ������� ������ ����� ����������

INSERT INTO results
SELECT 15 AS id,
       aircrafts.model AS response
FROM aircrafts,
     flights,
     ticket_flights
WHERE aircrafts.aircraft_code = flights.aircraft_code
  AND ticket_flights.flight_id = flights.flight_id
  AND flights.status = 'Arrived'
GROUP BY aircrafts.aircraft_code,
         aircrafts.model
ORDER BY count(*) DESC, aircrafts.model
LIMIT 1;

--+16.  ������� ���������� � ������� ����� ���������������� ������� �������� �� ������������ �� ���� ��������

INSERT INTO results
SELECT 16 AS id,
       sum(greatest(-((flights.scheduled_arrival - flights.scheduled_departure) - (flights.actual_arrival - flights.actual_departure))::interval, ((flights.scheduled_arrival - flights.scheduled_departure) - (flights.actual_arrival - flights.actual_departure))::interval)) AS response
FROM flights
WHERE flights.status = 'Arrived';

--+17. ������� ������, � ������� ������������� ������ �� �����-���������� 2016-09-13

INSERT INTO results
SELECT 17 AS id,
       *
FROM
  (SELECT DISTINCT aa.city
   FROM flights,
        airports AS a,
        airports AS aa
   WHERE flights.status = 'Arrived'
     AND flights.departure_airport = a.airport_code
     AND a.city = '�����-���������'
     AND flights.actual_departure >= '2016-09-13'
     AND flights.actual_departure < '2016-09-14'
     AND flights.arrival_airport = aa.airport_code
   ORDER BY aa.city) AS response;


INSERT INTO results (id, response)
SELECT 17,
       NULL
WHERE NOT EXISTS
    (SELECT *
     FROM results
     WHERE id = 17 );

--+18. ������� ������ � ������������ ��������� ���� �������
-- �� Cancelled

INSERT INTO results
SELECT 18 AS id,
       flights.flight_id AS response
FROM flights,
     ticket_flights
WHERE flights.status <> 'Cancelled'
  AND ticket_flights.flight_id = flights.flight_id
GROUP BY flights.flight_id
ORDER BY sum(ticket_flights.amount) DESC
LIMIT 1;

--+19. ������� ��� � ������� ���� ������������ ����������� ���������� ��������

INSERT INTO results
SELECT 19 AS id,
       date(flights.actual_departure) AS response
FROM flights
GROUP BY date(flights.actual_departure)
HAVING count(*) in
  (SELECT count(*)
   FROM flights
   WHERE flights.status <> 'Cancelled'
     AND flights.actual_departure NOTNULL
   GROUP BY date(flights.actual_departure)
   ORDER BY count(*)
   LIMIT 1);

--+20.  ������� ������� ���������� ������� � ���� �� ������ �� 09 ����� 2016 ����

INSERT INTO results
SELECT 20 AS id,
       coalesce(sum(c)/30, 0) AS response
FROM
  (SELECT count(*) AS c
   FROM flights
   WHERE flights.actual_departure NOTNULL
     AND flights.actual_departure >= '2016-09-01'
     AND flights.actual_departure < '2016-10-01'
   GROUP BY date(flights.actual_departure)) AS s;

--+21.  ������� ��� 5 ������� � ������� ������� ����� �������� �� ������ ���������� ������ 3 �����

INSERT INTO results
SELECT 21 AS id,
       airports.city AS response
FROM flights,
     airports
WHERE airports.airport_code = flights.departure_airport
  AND flights.status = 'Arrived'
GROUP BY airports.city
HAVING sum(flights.actual_arrival - flights.actual_departure)/count(*) > '3:00:00'
ORDER BY sum(flights.actual_arrival - flights.actual_departure)/count(*)
LIMIT 5;


INSERT INTO results (id, response)
SELECT 21,
       NULL
WHERE NOT EXISTS
    (SELECT *
     FROM results
     WHERE id = 21 );
     