
select pg_backend_pid();

-- Questão 1
begin;

insert into customer (store_id, first_name, last_name, email, address_id, active)
values (1, 
        'AAAAAAAAAaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 
        'B', 'ana@email.com', 5, 2);

select * from customer order by customer_id desc limit 3;

rollback;

select * from customer order by customer_id desc limit 3;


/* 

Active é inserido como 2, mas deveria ser um campo 0 ou 1, no Rollback o usuário não aparece.

BEGIN
INSERT 0 1
 customer_id | store_id | first_name | last_name |               email               | address_id | activebool | create_date |        last_update         | active 
-------------+----------+------------+-----------+-----------------------------------+------------+------------+-------------+----------------------------+--------
         600 |        1 | AAAAAAAAA  | B         | ana@email.com                     |          5 | t          | 2026-10-27  | 2026-10-27 14:06:50.524594 |      2
         599 |        2 | Austin     | Cintron   | austin.cintron@sakilacustomer.org |        605 | t          | 2006-02-14  | 2013-05-26 14:49:45.738    |      1
         598 |        1 | Wade       | Delvalle  | wade.delvalle@sakilacustomer.org  |        604 | t          | 2006-02-14  | 2013-05-26 14:49:45.738    |      1
(3 rows)

ROLLBACK
 customer_id | store_id | first_name | last_name |               email               | address_id | activebool | create_date |       last_update       | active 
-------------+----------+------------+-----------+-----------------------------------+------------+------------+-------------+-------------------------+--------
         599 |        2 | Austin     | Cintron   | austin.cintron@sakilacustomer.org |        605 | t          | 2006-02-14  | 2013-05-26 14:49:45.738 |      1
         598 |        1 | Wade       | Delvalle  | wade.delvalle@sakilacustomer.org  |        604 | t          | 2006-02-14  | 2013-05-26 14:49:45.738 |      1
         597 |        1 | Freddie    | Duggan    | freddie.duggan@sakilacustomer.org |        603 | t          | 2006-02-14  | 2013-05-26 14:49:45.738 |      1
(3 rows)

Tentando inserir um nome longo demais, um erro é reportado e a transação é abortada.

BEGIN
ERROR:  value too long for type character varying(45)
ERROR:  current transaction is aborted, commands ignored until end of transaction block
ROLLBACK
 customer_id | store_id | first_name | last_name |               email               | address_id | activebool | create_date |       last_update       | active 
-------------+----------+------------+-----------+-----------------------------------+------------+------------+-------------+-------------------------+--------
         599 |        2 | Austin     | Cintron   | austin.cintron@sakilacustomer.org |        605 | t          | 2006-02-14  | 2013-05-26 14:49:45.738 |      1
         598 |        1 | Wade       | Delvalle  | wade.delvalle@sakilacustomer.org  |        604 | t          | 2006-02-14  | 2013-05-26 14:49:45.738 |      1
         597 |        1 | Freddie    | Duggan    | freddie.duggan@sakilacustomer.org |        603 | t          | 2006-02-14  | 2013-05-26 14:49:45.738 |      1
(3 rows)

O banco de dados deve esquecer para garantir a integridade e a consistência dos dados, a Atomicidade.
*/


-- Questão 2


begin;

insert into inventory (film_id, store_id, last_update)
values (1, 1, now());

select * from inventory order by inventory_id desc limit 3; 

savepoint estoque_atualizado;

insert into inventory (film_id, store_id, last_update)
values (2000, 1, now());
-- film_id vão até 1000

select * from inventory order by inventory_id desc limit 3; 

rollback to estoque_atualizado;

insert into inventory (film_id, store_id, last_update)
values (10, 1, now());

select * from inventory order by inventory_id desc limit 3; 

commit;

/* 
O comando mantém apenas as inserções válidas. 

BEGIN
INSERT 0 1
 inventory_id | film_id | store_id |        last_update         
--------------+---------+----------+----------------------------
         4590 |       1 |        1 | 2026-10-27 14:20:36.305799
         4589 |      10 |        1 | 2026-10-27 14:20:33.844821
         4587 |       1 |        1 | 2026-10-27 14:20:33.83495
(3 rows)

SAVEPOINT
ERROR:  insert or update on table "inventory" violates foreign key constraint "inventory_film_id_fkey"
DETAIL:  Key (film_id)=(2000) is not present in table "film".
ERROR:  current transaction is aborted, commands ignored until end of transaction block
ROLLBACK
INSERT 0 1
 inventory_id | film_id | store_id |        last_update         
--------------+---------+----------+----------------------------
         4592 |      10 |        1 | 2026-10-27 14:20:36.305799
         4590 |       1 |        1 | 2026-10-27 14:20:36.305799
         4589 |      10 |        1 | 2026-10-27 14:20:33.844821
(3 rows)

COMMIT

A vantagem de usar o Savepoint é ter o controle sobre os erros, um roolback parcial.

*/
