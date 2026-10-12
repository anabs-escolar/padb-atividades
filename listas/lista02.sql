-- 1.
create view v_staff_performance as
select 
    s.staff_id,
    s.first_name || ' ' || s.last_name as nome_completo,
    c.city || ', ' || co.country as endereco,
    count(distinct r.rental_id) as total_locacoes,
    coalesce(sum(p.amount), 0) as total_arrecadado
from staff s
left join store st
    on st.store_id = s.store_id
left join address a 
    on a.address_id = st.address_id
left join city c
    on c.city_id = a.city_id
left join country co
    on co.country_id = c.country_id
left join  rental r
    on r.staff_id = s.staff_id
left join payment p
    on p.rental_id = r.rental_id
group by 
    s.staff_id,
    s.first_name,
    s.last_name,
    c.city,
    co.country;

select * from v_staff_performance;
select * from v_staff_performance where total_locacoes = 0;
select * from v_staff_performance 
where total_locacoes is null 
    or total_arrecadado is null;

-- 2.
create materialized view mv_category_total as
select 
    c.category_id,
    c.name as nome_categoria,
    coalesce(sum(p.amount), 0) as total_vendas
from category c 
left join film_category fc
    on fc.category_id = c.category_id
left join film f 
    on fc.film_id = f.film_id
left join inventory i
    on i.film_id = f.film_id
left join rental r
    on r.inventory_id = i.inventory_id
left join payment p
    on p.rental_id = r.rental_id
group by
    c.category_id,
    c.name;

create unique index idx_mv_category_total
on mv_category_total (category_id);

refresh materialized view concurrently mv_category_total;


-- 3.
create index idx_rental_open
on rental (rental_id)
where return_date is null;

explain analyze
select * from rental
where return_date is null;

/* 
                                                          QUERY PLAN                                                          
------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_rental_open on rental  (cost=0.14..16.23 rows=183 width=36) (actual time=0.015..0.050 rows=183 loops=1)
 Planning Time: 0.217 ms
 Execution Time: 0.067 ms
*/

-- 4.
create index idx_film_descriptions
on film using gin (to_tsvector('english', description));

select film_id, title, description
from film 
where to_tsvector('english', description) @@ to_tsquery('english', 'documentary & drama');

explain analyze
select film_id, title, description
from film 
where to_tsvector('english', description) @@ to_tsquery('english', 'documentary & drama');

/*
                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on film  (cost=12.96..17.22 rows=1 width=113) (actual time=0.019..0.020 rows=0 loops=1)
   Recheck Cond: (to_tsvector('english'::regconfig, description) @@ '''documentari'' & ''drama'''::tsquery)
   ->  Bitmap Index Scan on idx_film_descriptions  (cost=0.00..12.96 rows=1 width=0) (actual time=0.019..0.019 rows=0 loops=1)
         Index Cond: (to_tsvector('english'::regconfig, description) @@ '''documentari'' & ''drama'''::tsquery)
 Planning Time: 0.066 ms
 Execution Time: 0.030 ms
*/

-- 5.
drop index if exists idx_payment_costumer_date;
create index idx_payment_costumer_date
on payment (customer_id, payment_date DESC);

select * from payment
where customer_id = 1
order by payment_date DESC;

explain analyze
select * from payment
where customer_id = 1
order by payment_date DESC;

/*
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=73.13..73.20 rows=30 width=26) (actual time=0.041..0.043 rows=31 loops=1)
   Sort Key: payment_date DESC
   Sort Method: quicksort  Memory: 26kB
   ->  Bitmap Heap Scan on payment  (cost=4.52..72.39 rows=30 width=26) (actual time=0.023..0.031 rows=31 loops=1)
         Recheck Cond: (customer_id = 1)
         Heap Blocks: exact=4
         ->  Bitmap Index Scan on idx_payment_costumer_date  (cost=0.00..4.51 rows=30 width=0) (actual time=0.015..0.016 rows=31 loops=1)
               Index Cond: (customer_id = 1)
 Planning Time: 0.111 ms
 Execution Time: 0.066 ms
*/

create index idx_customer_email
on customer(lower(email));

select * from customer
where lower(email) = lower('MARY.SMITH@example.com');

explain analyze
select * from customer
where lower(email) = lower('MARY.SMITH@example.com');

/*
                                                        QUERY PLAN                                                         
---------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on customer  (cost=4.30..11.15 rows=3 width=70) (actual time=0.005..0.005 rows=0 loops=1)
   Recheck Cond: (lower((email)::text) = 'mary.smith@example.com'::text)
   ->  Bitmap Index Scan on idx_customer_email  (cost=0.00..4.30 rows=3 width=0) (actual time=0.004..0.004 rows=0 loops=1)
         Index Cond: (lower((email)::text) = 'mary.smith@example.com'::text)
 Planning Time: 0.100 ms
 Execution Time: 0.018 ms
*/

-- 7.

create function validate_date_rental()
returns trigger
as $$
begin
    if new.return_date is not null
        and new.return_date < new.rental_date then
        raise exception
            'Data de devolução (%) não pode ser anterior à data de locação (%)',
            new.return_date,
            new.rental_date;
    end if;
    return new;
end;
$$ language plpgsql;


create trigger trg_validate_date_rental
before insert or update
on rental for each row
execute function validate_date_rental();

update rental
set return_date = rental_date + interval '1 day'
where rental_id = 1;

update rental
set return_date = rental_date - interval '1 day'
where rental_id = 1;

-- 8.
create table film_replace_audit (
    film_id integer,
    old_cost numeric(5,2),
    new_cost numeric(5,2),
    changed_at timestamp
);

create function audit_film_cost()
returns trigger
as $$
begin
    insert into film_replace_audit(
        film_id, old_cost, new_cost, changed_at
    ) values (
        new.film_id, old.replacement_cost, new.replacement_cost, current_timestamp
    );
    return new;
end
$$ language plpgsql;

create trigger trg_audit_film_cost
after update of replacement_cost on film
for each row
when (old.replacement_cost is distinct from new.replacement_cost)
execute function audit_film_cost();

update film set replacement_cost = replacement_cost + 1.0
where film_id = 1;

select * from film_replace_audit
where film_id = 1;

-- 9.
create or replace function validete_language_delete()
returns trigger
as $$
begin
    if exists(
        select 1 from film
        where language_id = OLD.language_id
    ) then raise exception
        'Não pode excluir idioma %. Outros utilizam esse idioma.',
        OLD.language_id;
    end if;
    return OLD;
end;
$$ language plpgsql;

drop trigger if exists trg_validate_date_rental on language;
create trigger trg_validate_language_delete
before delete
on language
for each row
execute function validete_language_delete();

-- 10.
create table customer_rental_stats (
    customer_id int primary key,
    total_rentals int default 0
);

alter table customer_rental_stats
add constraint fk_customer_rental_stats
foreign key (customer_id)
references customer(customer_id);

insert into customer_rental_stats (customer_id, total_rentals)
select c.customer_id, count(r.rental_id) as total_rentals
from customer c
left join rental r
    on r.customer_id = c.customer_id
group by c.customer_id;

create or replace function update_customer_rental_stats()
returns trigger
as $$
begin
    if exists (
        select 1 from customer_rental_stats
        where customer_id = NEW.customer_id
    ) then
        update customer_rental_stats
        set total_rentals = total_rentals +1
        where customer_id = NEW.customer_id;
    else
        insert into customer_rental_stats(
            customer_id,
            total_rentals
        ) values (NEW.customer_id, 1);
    end if;
    return NEW;
end;
$$ language plpgsql;

drop trigger if exists trg_update_customer_rental_stats on rental;
create trigger trg_update_customer_rental_stats
after insert
on rental
for each row
execute function update_customer_rental_stats();

select * from customer_rental_stats
order by customer_id;

select rental_id, customer_id
from rental
where rental_id = 1;

select total_rentals from customer_rental_stats
where customer_id = (
    select customer_id
    from rental
    where rental_id = 1
);

insert into rental (
    rental_date,
    inventory_id,
    customer_id,
    staff_id
) values (current_timestamp, 1, 1, 1);

select * from customer_rental_stats
where customer_id = 1;