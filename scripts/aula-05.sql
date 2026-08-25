-- order by
-- asc. ordernação crescente
-- desc. ordenação decrescente

select pnome, unome from funcionario
order by pnome desc, unome desc;

-- limit. definie limite de linhas

select pnome, unome, salario from funcionario
order by salario desc
limit 1;

-- funções de agregação. count, sum, avg, min, max

-- count. contagem de linhas da listagem
select count(*) as "Total de Funcionarios" from funcionario;

select count(distinct numero_departamento) from funcionario;

-- sum.
select sum(salario) as "Folha Salarial" from funcionario;
where numero_departamento=1;

-- avg.
select round(avg(salario), 2) media_salarial from funcionario;

-- min, max
select min(salario) menor_salario, max(salario) maior_salario from funcionario;

-- subconsulta. na maioria das vezes usa funções de agregação
select
    pnome || ' ' || unome nome_completo
from funcionario
where salario = (
    select min(salario) from funcionario
);

-- Quais funcionarios recebem salario acima da média

select
    pnome || ' ' || unome nome_completo, salario
from funcionario
where salario > (
    select avg(salario) from funcionario
);

-- Relatorio completo. Total de funcionarios, folha salarial, INSS, média salarial, menor e maior salario

select
    count(*) total_funcionario,
    sum(salario) folha_salarial,
    sum(salario)*0.11 inss,
    round(avg(salario), 2) media_salarial, 
    min(salario) min_salario,
    max(salario) max_salario
from funcionario;

-- junções. inner join, left join, right join, full join

-- listar nome dos funcionarios e seus departamentos
select f.pnome || ' ' || f.unome funcionario, d.nome departamento 
from funcionario f
join departamento d
    on f.numero_departamento = d.numero
order by departamento, funcionario;

-- listar todos os funcionarios e seus supervisores

select 
    f.pnome || ' ' || f.unome funcionario,
    s.pnome || ' ' || s.unome supervisor
from funcionario f
join funcionario s
    on f.cpf_supervisor=s.cpf
order by funcionario, supervisor;


-- incluindo valor null
-- coalesce, função para evitar linhas vazias
select f.pnome funcionario,
        coalesce(s.pnome, 'Sem supervisor') supervisor
from funcionario f
left join funcionario s 
    on f.cpf_supervisor=s.cpf
order by funcionario, supervisor;