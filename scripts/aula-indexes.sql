-- indexes

select
    schemaname, 
    tablename,
    indexname,
    indexdef
from pg_indexes
where tablename = 'address'
order by tablename, indexname;

select
    address_id,
    address,
    district,
    phone 
from address
where phone = '223665661973';

explain analyze
select
    address_id,
    address,
    district,
    phone 
from address
where phone = '223665661973';

drop index if exists idx_address_phone;

create index inx_address_phone on address(phone);
/*
 Index Scan using inx_address_phone on address  (cost=0.28..8.29 rows=1 width=45) (actual time=0.023..0.023 rows=0 loops=1)
   Index Cond: ((phone)::text = '223665661973'::text)
 Planning Time: 0.222 ms
 Execution Time: 0.035 ms
(4 rows)
*/