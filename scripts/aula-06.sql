
-- funções de agrupamento: group by, having

-- Qual o salário médio dos funcionários em cada departamento?
select
    numero_departamento,
    round(salario, 2) media_salarial
from funcionario
group by numero_departamento
order by numero_departamento;

-- Qual o salário médio dos funcionários em cada departamento (sem valores nulos)?

-- usando where
select
    numero_departamento,
    round(salario, 2) media_salarial
from funcionario
where numero_departamento is not null
group by numero_departamento
order by numero_departamento;

-- usando having
select
    numero_departamento,
    round(salario, 2) media_salarial
from funcionario
group by numero_departamento
having numero_departamento is not null
order by numero_departamento;

-- Qual o número de funcionários que trabalham em cada departamento?

select 
    numero_departamento,
    count(*) numero_funcionarios
from funcionario
group by numero_departamento
order by numero_departamento;

-- Listar número e nome do departamento, quantidade de funcionários, média salarial e folha salarial
select 
    d.nome departamento, 
    d.numero num_departamento, 
    count(f.cpf) num_funcionarios, 
    round(avg(f.salario), 2) media_salarial,
    sum(f.salario) folha_salarial
from departamento d
left join funcionario f
    on f.numero_departamento = d.numero
group by d.numero
order by d.numero, d.nome;