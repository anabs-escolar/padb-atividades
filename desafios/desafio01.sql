-- 1.
drop materialized view if exists mv_driver_season_summary;
create materialized view mv_driver_season_summary as
select 
    r.year,
    d.name,
    count(rd.driver_id) as total_race_entries, 
    count(case when rd.position_number = 1 then 1 end) as total_race_wins,
    count(case when rd.position_number <= 3 then 1 end) as total_podiums,
    count(case when rd.race_reason_retired is not null then 1 end) as race_reason_retired,
    sum(rd.race_points) as total_points
from race_data rd
left join driver d 
    on rd.driver_id = d.id
left join race r 
    on rd.race_id = r.id 
where rd.type = 'RACE_RESULT'
group by r.year, d.name
order by r.year;
     
create unique index idx_driver_season_summary
on mv_driver_season_summary (year, name);

refresh materialized view concurrently mv_driver_season_summary;

select * from mv_driver_season_summary
where name = 'Ayrton Senna'
limit 10;
    
/* 
DROP MATERIALIZED VIEW
SELECT 3266
CREATE INDEX
REFRESH MATERIALIZED VIEW
 year |     name     | total_race_entries | total_race_wins | total_podiums | race_reason_retired | total_points 
------+--------------+--------------------+-----------------+---------------+---------------------+--------------
 1984 | Ayrton Senna |                 15 |               0 |             3 |                   8 |        13.00
 1985 | Ayrton Senna |                 16 |               2 |             6 |                   9 |        38.00
 1986 | Ayrton Senna |                 16 |               2 |             8 |                   7 |        55.00
 1987 | Ayrton Senna |                 16 |               2 |             8 |                   4 |        57.00
 1988 | Ayrton Senna |                 16 |               8 |            11 |                   3 |        94.00
 1989 | Ayrton Senna |                 16 |               6 |             7 |                   8 |        60.00
 1990 | Ayrton Senna |                 16 |               6 |            11 |                   5 |        78.00
 1991 | Ayrton Senna |                 16 |               7 |            12 |                   3 |        96.00
 1992 | Ayrton Senna |                 16 |               3 |             7 |                   8 |        50.00
 1993 | Ayrton Senna |                 16 |               5 |             7 |                   6 |        73.00
(10 rows)
*/

-- 2.

DROP TABLE IF EXISTS points_adjustment_audit;
CREATE TABLE points_adjustment_audit (
    id         SERIAL PRIMARY KEY,
    year       INT NOT NULL,
    driver_id  VARCHAR(100) NOT NULL,
    old_points DECIMAL(8,2),
    new_points DECIMAL(8,2),
    changed_at TIMESTAMPTZ DEFAULT NOW()
);


create or replace function points_adjustment()
returns trigger
language plpgsql
as $$
begin 
    if not exists (
        select 1 
        from points_adjustment_audit 
        where driver_id = old.driver_id
    ) then
        insert into points_adjustment_audit (
            year,
            driver_id,
            new_points
        )values(
            NEW.year,
            NEW.driver_id,
            NEW.points
        );
    else
        if NEW.points != OLD.points then
            update points_adjustment_audit
            set old_points = OLD.points,
                new_points = NEW.points,
                changed_at = now()
            where OLD.driver_id = NEW.driver_id;
        end if;
    end if;
    return NEW;
end;
$$;

drop trigger if exists trg_points_adjustment on season_driver_standing;
create trigger trg_points_adjustment
after update on season_driver_standing
for each row
execute function points_adjustment();

update season_driver_standing set points = 100 
where driver_id = 'ayrton-senna';

select * from points_adjustment_audit where driver_id = 'ayrton-senna';


-- 3. 
create or replace function validete_driver()
returns trigger
as $$
begin
    if exists(
        select 1 from race_data
        where driver_id = OLD.id
    ) then raise exception
        'Não pode excluir %. Outros registros utilizam.',
        OLD.name;
    end if;
    return OLD;
end;
$$ language plpgsql;

drop trigger if exists trg_validete_driver on driver;
create trigger trg_validete_driver
before delete on driver
for each row
execute function validete_driver();

delete from driver where id = 'ayrton-senna';

/*
ERROR:  Não pode excluir Ayrton Senna. Outros registros utilizam.
CONTEXT:  PL/pgSQL function validete_driver() line 6 at RAISE
*/