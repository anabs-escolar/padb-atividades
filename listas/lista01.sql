-- 1.   Liste os produtos com preço superior a R$ 1000.
select * from products
where price >= 1000;

-- 2.	Liste os produtos ordenados pelo preço, do maior para o menor.
select * from products
order by price desc;

-- 3.	Aumente o preço de todos os produtos da `Dell` em 10%.
update products
set price = price + price * 0.1
where name ilike '%dell%';

-- 4.	Exclua todos os produtos que sejam do tipo `Macbook`.
delete from products
where name ilike '%macbook%';

-- 5.	Exclua um produto que não possua pedidos associados.
delete from products p
where not exists (
    select 1 from orders_products op where op.product_id = p.id
);

-- 6.	Liste todos os pedidos realizados nos últimos 30 dias.
select * from orders
where order_date >= now() - interval '30 days';

-- 7.	Liste os pedidos e os respectivos nomes de usuário.
select u.name nome_usuario, o pedido from orders o
join users u
    on o.user_id = u.id;

-- 8.	Liste todos os usuários e seus pedidos, inclusive usuários sem pedidos.
select u.name nome_usuario, o pedido from users u
left join orders o
    on o.user_id = u.id;

-- 9.	Liste todos os usuários (id, nome e email) que realizaram pelo menos um pedido.
select distinct u.id, u.name, u.email from users u
join orders o on o.user_id = u.id
order by u.id;

-- 10.	Liste produtos que nunca foram vendidos.
select p.name, p.price from products p
left join orders_products op
    on op.product_id = p.id
where op.product_id is null;

-- 11.	Liste usuários que nunca realizaram pedidos.
select u.id, u.name, u.email from users u
left join orders o 
    on u.id = o.user_id
where o.user_id is null;

-- 12.	Liste os produtos com preço acima da média em ordem decrescente.
select name, price from products
where price > (
    select avg(price) from products
);


-- 13.	Liste a quantidade de pedidos realizados por cada usuário.
select count(distinct o.user_id) from orders o
left join users u
    on u.id = o.user_id;

-- 14.	Listar os três produtos mais vendidos.
select p.name, p.price, sum(op.quantity) as total_quantity from products p
join orders_products op
    on p.id = o.pproduct_id
group by p.name, p.price
order by total_quantity desc
limit 3;

-- 15.	Gerar um relatório com: usuários, quantidade de pedidos e valor total comprado.
select u.id, u.name, count(o.user_id), sum(o.total) as total from users u 
left join orders o
    on u.id = o.user_id
group by u.id
order by u.id, total;
