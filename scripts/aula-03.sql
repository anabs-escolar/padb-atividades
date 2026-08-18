-- Inserir

insert into funcionario values
('11122233344', 'Josefina', 'Silva', 'silva@email.com', 'Rua Acula', 2333, '2000-04-24', 'F', null, null),
('11122233355', 'Pedro', 'Silva', 'pedro@email.com', 'Rua Ali', 4333, '2000-05-23', 'F', null, null),
('11122233366', 'Felipe', 'Silva', 'lipe@email.com', 'Rua Acula', 6333, '2000-06-22', 'M', null, null);

insert into funcionario (cpf, pnome, unome, email, salario, data_nasc, sexo) values
('22233344455', 'Icaro', 'Soares', 'icaro@email.com', 2550, '2005-04-14', 'M');

-- Atualizar

update funcionario
set sexo='M' where email='pedro@email.com'
returning cpf, pnome, unome, sexo;

-- returning. faz um pequena consulta.


-- Remover
delete from funcionario
where cpf='22233344455'
returning cpf, pnome, unome, sexo;