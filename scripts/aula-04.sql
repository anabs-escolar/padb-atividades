-- aulinha de DQL

select * from funcionario;

select pnome, unome, numero_departamento from funcionario;

select pnome || ' ' || unome, numero_departamento from funcionario;

-- alias. apelido para nome da coluna
select pnome || ' ' || unome as "Nome Completo", numero_departamento as "N° Dep." from funcionario;
select pnome || ' ' || unome nome, numero_departamento dep from funcionario;

select numero_departamento from funcionario;

select all numero_departamento from funcionario;

-- exibir valores distintos
select distinct numero_departamento from funcionario;

-- round. especifica casas decimais, só aceita NUMERIC
select pnome || ' ' || unome nome, salario, round(salario*0.11, 2) inss from funcionario;

-- filtragem com where
select pnome || ' ' || unome nome, cpf from funcionario where numero_departamento=1 and salario>2500;

select pnome || ' ' || unome nome, cpf from funcionario where salario between 2500 and 3000;

-- %. substitui qualquer cadeia textual
-- _. susbsitui qualquer caracter especifico

select cpf, pnome, unome from funcionario
where endereco like '%Ali';

-- ilike. desconsidera case-sensitive
select cpf, pnome, unome from funcionario
where unome ilike '%sil%';


select cpf, pnome, unome from funcionario
where unome like '%e_'; -- Nome termina com E + caracter
