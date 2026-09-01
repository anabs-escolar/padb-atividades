
-- Resumo de pedidos por usuários

drop view if exists v_users_orders; 
create view v_users_orders as 
select 
    u.id id,
    u.name usuario,
    count(o.id) qtd_pedidos,
    coalesce(sum(o.total),0) total_gasto
from users u
left join orders o on o.user_id = u.id
group by u.id, u.name;

select * from v_users_orders order by id;

-- Relatorio de vendas de produtos
drop view if exists v_products_sales;
create view v_products_sales as
select
    p.id id,
    p.name produto,
    sum(op.quantity) qtd_vendida,
    sum(op.quantity * op.unit_price) total_vendido
from products p
join orders_products op on op.product_id = p.id
join orders o on o.id = op.order_id
where o.status <> 'canceled'
group by p.id, p.name;

select * from v_products_sales order by id;

drop view if exists v_orders_details;
create view v_orders_details as
select
    o.id id,
    u.name usuario,
    u.email email,
    o.order_date data_pedido,
    o.status,
    p.name produto,
    op.quantity qtd,
    op.unit_price preco_unitario,
    op.unit_price * op.quantity valor_total
from orders o 
join users u on u.id = o.user_id
join orders_products op on op.order_id = o.id
join products p on p.id = op.product_id;

select * from v_orders_details order by id;

-- Relatorio de itens em estoque

drop view if exists v_products_in_stock;
create view v_products_in_stock as
select
    id,
    name produto, 
    price valor, 
    stock estoque
from products
where stock > 0
with check option;

select * from v_products_in_stock order by id;