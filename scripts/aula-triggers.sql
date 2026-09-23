-- triggers

-- como criar uma função
create function trigger_function()
    returns trigger_name
    language plpgsql
as $$
begin
    -- logica do trigger
end;
$$

-- after insert - depois de inserir
-- sincronizando total gasto por cliente a cada novo pagamento
drop table if exists customer_spending;
create table customer_spending(
    customer_id int primary key references customer(customer_id),
    total numeric not null default 0
);

insert into customer_spending(customer_id, total)
select customer_id, sum(amount)
from payment
group by customer_id;

create or replace function update_customer_spending()
    returns trigger
    language plpgsql
as $$
begin
    update customer_spending
    set total = total + NEW.amount
    where customer_id = NEW.customer_id;
    return NEW;
end
$$;

drop trigger if exists trg_update_customer_spending on payment;
create trigger trg_update_customer_spending 
after insert on payment
for each row 
execute function update_customer_spending();

-- observando o trigger
select * from customer_spending where customer_id = 1;

insert into payment(customer_id, staff_id, rental_id, amount, payment_date)
values (1, 1, 1, 55.3, now());

select * from customer_spending where customer_id = 1;

/*
customer_id | total  
-------------+--------
           1 | 114.70
INSERT 0 1
 customer_id | total  
-------------+--------
           1 | 170.00
*/

-- before insert - depois de inserir
-- validação de regra de negócio (rental_date não pode ser no futuro)

create or replace function check_rental_date()
    returns trigger
    language plpgsql
as $$
begin
    if NEW.rental_date > now() then
        raise exception 'rental_date é uma data posterior à data atual (value: %)', NEW.rental_date;
    end if;
    return NEW;
end;
$$;

drop trigger if exists trg_check_rental_date on rental;
create trigger trg_check_rental_date 
before insert on rental
for each row
execute function check_rental_date();

-- Criando um aluguel com um dia depois da data atual
insert into rental(rental_date, inventory_id, customer_id, staff_id)
values(now() + interval '1 day', 1, 1, 1);