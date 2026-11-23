-- Dados demonstrativos para os modulos do roadmap.
-- Requer database.sql + roadmap_migracao.sql ja importados e ao menos um usuario ativo.
-- Seguro para importar novamente: usa codigos DEMO-RM e marcadores unicos; nao apaga dados.
SET NAMES utf8mb4;
START TRANSACTION;

-- Fornecedores de exemplo.
INSERT INTO fornecedores (nome, documento, telefone, contato)
SELECT d.nome,d.documento,d.telefone,d.contato
FROM (
    SELECT 'DEMO-RM | Distribuidora Central' nome,'00.000.000/0001-01' documento,'(11) 4000-2001' telefone,'Ana Lima' contato
    UNION ALL SELECT 'DEMO-RM | Hortifruti da Serra','00.000.000/0001-02','(11) 4000-2002','Bruno Reis'
    UNION ALL SELECT 'DEMO-RM | Laticinios Bom Leite','00.000.000/0001-03','(11) 4000-2003','Carla Souza'
) d
WHERE NOT EXISTS (SELECT 1 FROM fornecedores f WHERE f.nome=d.nome);

-- Produtos com unidades de compra e consumo diferentes para exercitar conversoes.
INSERT INTO produtos
    (nome,codigo,categoria_id,marca,unidade_compra,unidade_consumo,fator_conversao,
     rendimento_percentual,estoque_minimo,estoque_maximo,validade_padrao_dias,preco_atual,fornecedor_principal_id)
SELECT d.nome,d.codigo,c.id,d.marca,d.unidade_compra,d.unidade_consumo,d.fator,
       d.rendimento,d.minimo,d.maximo,d.validade,d.preco,f.id
FROM (
    SELECT 'Arroz agulhinha tipo 1' nome,'DEMO-RM-P001' codigo,'Secos' categoria,'Sabor do Campo' marca,'kg' unidade_compra,'g' unidade_consumo,1000 fator,100 rendimento,5000 minimo,25000 maximo,365 validade,7.20 preco,'DEMO-RM | Distribuidora Central' fornecedor
    UNION ALL SELECT 'Feijao carioca','DEMO-RM-P002','Secos','Sabor do Campo','kg','g',1000,100,3000,15000,365,8.90,'DEMO-RM | Distribuidora Central'
    UNION ALL SELECT 'Peito de frango','DEMO-RM-P003','Carnes','Granja Boa Mesa','kg','g',1000,82,4000,20000,180,21.90,'DEMO-RM | Distribuidora Central'
    UNION ALL SELECT 'Tomate italiano','DEMO-RM-P004','Hortifruti','Horta Viva','kg','g',1000,92,2000,10000,7,8.50,'DEMO-RM | Hortifruti da Serra'
    UNION ALL SELECT 'Cebola','DEMO-RM-P005','Hortifruti','Horta Viva','kg','g',1000,90,1500,8000,20,6.00,'DEMO-RM | Hortifruti da Serra'
    UNION ALL SELECT 'Macarrao penne','DEMO-RM-P006','Secos','Casa Italiana','kg','g',1000,100,2000,10000,365,9.50,'DEMO-RM | Distribuidora Central'
    UNION ALL SELECT 'Queijo mussarela','DEMO-RM-P007','Outros','Bom Leite','kg','g',1000,100,1000,5000,30,34.90,'DEMO-RM | Laticinios Bom Leite'
    UNION ALL SELECT 'Oleo de soja','DEMO-RM-P008','Secos','Cozinha Pratica','l','ml',1000,100,1000,5000,365,8.90,'DEMO-RM | Distribuidora Central'
) d
JOIN categorias_produto c ON c.nome=d.categoria
JOIN fornecedores f ON f.nome=d.fornecedor
WHERE NOT EXISTS (SELECT 1 FROM produtos p WHERE p.codigo=d.codigo);

INSERT IGNORE INTO produto_fornecedores(produto_id,fornecedor_id,preferencial)
SELECT p.id,p.fornecedor_principal_id,1 FROM produtos p WHERE p.codigo LIKE 'DEMO-RM-P%';

-- Fichas de exemplo. A ficha de penne usa o molho como sub-receita.
INSERT INTO fichas_tecnicas
    (nome,codigo,categoria_id,tipo,rendimento_total,unidade_rendimento,porcoes,
     tamanho_porcao,modo_preparo,status,preco_venda,equipamentos,tempo_preparo_minutos,
     validade_horas,armazenamento,autor_id,aprovada_por,aprovada_em)
SELECT d.nome,d.codigo,c.id,d.tipo,d.rendimento,d.unidade,d.porcoes,d.tamanho,d.preparo,
       'aprovada',d.preco,d.equipamentos,d.tempo,d.validade,d.armazenamento,u.id,u.id,NOW()
FROM (
    SELECT 'Molho rapido de tomate' nome,'DEMO-RM-R001' codigo,'Hortifruti' categoria,'base' tipo,1200.000 rendimento,'g' unidade,12.000 porcoes,100.000 tamanho,'Refogue cebola, junte tomate picado e cozinhe ate encorpar.' preparo,4.50 preco,'Panela e fogao' equipamentos,25 tempo,48 validade,'Refrigerado em recipiente fechado' armazenamento
    UNION ALL SELECT 'Penne ao molho da casa','DEMO-RM-R002','Secos','prato',3000.000,'g',12.000,250.000,'Cozinhe a massa. Misture ao molho aquecido e finalize com queijo.',19.90,'Panela e fogao',35,24,'Refrigerado; aquecer antes de servir'
    UNION ALL SELECT 'Frango com arroz e feijao','DEMO-RM-R003','Carnes','prato',6000.000,'g',20.000,300.000,'Cozinhe os graos e prepare o frango completamente antes de servir.',24.90,'Panelas, fogao e forno',60,24,'Refrigerado em recipientes identificados'
) d
LEFT JOIN categorias_produto c ON c.nome=d.categoria
CROSS JOIN (SELECT id FROM usuarios WHERE ativo=1 ORDER BY id LIMIT 1) u
WHERE NOT EXISTS (SELECT 1 FROM fichas_tecnicas f WHERE f.codigo=d.codigo);

INSERT INTO ficha_tecnica_itens(ficha_id,produto_id,ficha_componente_id,quantidade_bruta,quantidade_liquida,fator_correcao)
SELECT f.id,p.id,NULL,d.quantidade,d.liquida,d.fator
FROM (
    SELECT 'DEMO-RM-R001' ficha,'DEMO-RM-P004' produto,900.000 quantidade,828.000 liquida,1.0870 fator
    UNION ALL SELECT 'DEMO-RM-R001','DEMO-RM-P005',220.000,198.000,1.1111
    UNION ALL SELECT 'DEMO-RM-R002','DEMO-RM-P006',1800.000,1800.000,1.0000
    UNION ALL SELECT 'DEMO-RM-R002','DEMO-RM-P007',180.000,180.000,1.0000
    UNION ALL SELECT 'DEMO-RM-R003','DEMO-RM-P003',2400.000,1968.000,1.2195
    UNION ALL SELECT 'DEMO-RM-R003','DEMO-RM-P001',1800.000,1800.000,1.0000
    UNION ALL SELECT 'DEMO-RM-R003','DEMO-RM-P002',1200.000,1200.000,1.0000
) d
JOIN fichas_tecnicas f ON f.codigo=d.ficha
JOIN produtos p ON p.codigo=d.produto
WHERE NOT EXISTS (SELECT 1 FROM ficha_tecnica_itens i WHERE i.ficha_id=f.id AND i.produto_id=p.id);

INSERT INTO ficha_tecnica_itens(ficha_id,produto_id,ficha_componente_id,quantidade_bruta,quantidade_liquida,fator_correcao)
SELECT f.id,NULL,component.id,600.000,600.000,1.0000
FROM fichas_tecnicas f
JOIN fichas_tecnicas component ON component.codigo='DEMO-RM-R001'
WHERE f.codigo='DEMO-RM-R002'
  AND NOT EXISTS (SELECT 1 FROM ficha_tecnica_itens i WHERE i.ficha_id=f.id AND i.ficha_componente_id=component.id);

-- Uma compra ja recebida, com nota, lote e validade para popular historico e saldo.
INSERT INTO compras(fornecedor_id,data_compra,referencia,status,desconto_total,frete_total,observacoes,usuario_id,recebida_em)
SELECT f.id,DATE_SUB(NOW(),INTERVAL 2 DAY),'DEMO-RM-NF-001','recebida',5.00,18.00,'Compra demonstrativa recebida; valores apenas para teste.',u.id,DATE_SUB(NOW(),INTERVAL 2 DAY)
FROM fornecedores f CROSS JOIN (SELECT id FROM usuarios WHERE ativo=1 ORDER BY id LIMIT 1) u
WHERE f.nome='DEMO-RM | Distribuidora Central'
  AND NOT EXISTS (SELECT 1 FROM compras c WHERE c.referencia='DEMO-RM-NF-001');

INSERT INTO compra_itens(compra_id,produto_id,quantidade,unidade,preco_unitario,desconto,lote,validade)
SELECT c.id,p.id,d.quantidade,d.unidade,d.preco,0,d.lote,DATE_ADD(CURDATE(),INTERVAL d.dias DAY)
FROM (
    SELECT 'DEMO-RM-P001' codigo,20.000 quantidade,'kg' unidade,7.20 preco,'ARZ-DEMO-01' lote,300 dias
    UNION ALL SELECT 'DEMO-RM-P002',10.000,'kg',8.90,'FEI-DEMO-01',240
    UNION ALL SELECT 'DEMO-RM-P003',12.000,'kg',21.90,'FRA-DEMO-01',90
    UNION ALL SELECT 'DEMO-RM-P006',8.000,'kg',9.50,'PEN-DEMO-01',300
    UNION ALL SELECT 'DEMO-RM-P008',6.000,'l',8.90,'OLE-DEMO-01',300
) d
JOIN produtos p ON p.codigo=d.codigo
JOIN compras c ON c.referencia='DEMO-RM-NF-001'
WHERE NOT EXISTS (SELECT 1 FROM compra_itens i WHERE i.compra_id=c.id AND i.produto_id=p.id);

INSERT INTO historico_precos(produto_id,fornecedor_id,compra_item_id,preco,unidade,quantidade_base,quantidade_compra,origem,usuario_id)
SELECT p.id,c.fornecedor_id,i.id,i.preco_unitario,i.unidade,
       i.quantidade * CASE WHEN i.unidade IN ('kg','l') AND p.unidade_consumo IN ('g','ml') THEN 1000 ELSE p.fator_conversao END,
       i.quantidade,'compra',c.usuario_id
FROM compra_itens i JOIN compras c ON c.id=i.compra_id JOIN produtos p ON p.id=i.produto_id
WHERE c.referencia='DEMO-RM-NF-001'
  AND NOT EXISTS (SELECT 1 FROM historico_precos h WHERE h.compra_item_id=i.id);

INSERT INTO movimentacoes_estoque(produto_id,local_id,tipo,quantidade_base,unidade_base,custo_unitario,lote,validade,origem_tipo,origem_id,observacoes,usuario_id)
SELECT p.id,1,'entrada',
       i.quantidade * CASE WHEN i.unidade IN ('kg','l') AND p.unidade_consumo IN ('g','ml') THEN 1000 ELSE p.fator_conversao END,
       p.unidade_consumo,i.preco_unitario / CASE WHEN i.unidade IN ('kg','l') AND p.unidade_consumo IN ('g','ml') THEN 1000 ELSE p.fator_conversao END,
       i.lote,i.validade,'compra_demo',c.id,'Entrada de compra demonstrativa.',c.usuario_id
FROM compra_itens i JOIN compras c ON c.id=i.compra_id JOIN produtos p ON p.id=i.produto_id
WHERE c.referencia='DEMO-RM-NF-001'
  AND NOT EXISTS (SELECT 1 FROM movimentacoes_estoque m WHERE m.origem_tipo='compra_demo' AND m.origem_id=c.id AND m.produto_id=p.id);

UPDATE produtos p
JOIN (
    SELECT i.produto_id,i.preco_unitario
    FROM compra_itens i JOIN compras c ON c.id=i.compra_id
    WHERE c.referencia='DEMO-RM-NF-001'
) x ON x.produto_id=p.id
SET p.preco_atual=x.preco_unitario
WHERE p.codigo LIKE 'DEMO-RM-P%';

-- Desperdicios com client_id estavel para permitir reimportacao sem duplicar.
INSERT INTO desperdicios(produto_id,quantidade,unidade,etapa,motivo,valor_estimado,data_registro,usuario_id,observacoes,client_id)
SELECT p.id,d.quantidade,d.unidade,d.etapa,d.motivo,d.valor,DATE_SUB(NOW(),INTERVAL d.dias DAY),u.id,d.observacoes,d.client_id
FROM (
    SELECT 'DEMO-RM-P003' codigo,350.000 quantidade,'g' unidade,'pre-preparo' etapa,'Aparas acima do esperado' motivo,7.67 valor,1 dias,'[DEMO-ROADMAP] Acompanhar rendimento do frango.' observacoes,'seed-roadmap-waste-001' client_id
    UNION ALL SELECT 'DEMO-RM-P004',500.000,'g','armazenamento','Amadurecimento excessivo',4.25,3,'[DEMO-ROADMAP] Tomate descartado no recebimento.','seed-roadmap-waste-002'
    UNION ALL SELECT 'DEMO-RM-P006',250.000,'g','pos-servico','Excesso de producao',2.38,5,'[DEMO-ROADMAP] Massa pronta sem reaproveitamento.','seed-roadmap-waste-003'
) d JOIN produtos p ON p.codigo=d.codigo
CROSS JOIN (SELECT id FROM usuarios WHERE ativo=1 ORDER BY id LIMIT 1) u
WHERE NOT EXISTS (SELECT 1 FROM desperdicios w WHERE w.client_id=d.client_id);

-- Movimento de perda compativel com o desperdicio de frango, para demonstrar saldo.
INSERT INTO movimentacoes_estoque(produto_id,local_id,tipo,quantidade_base,unidade_base,custo_unitario,origem_tipo,observacoes,usuario_id)
SELECT p.id,1,'perda',350.000,'g',0.0219,'demo_perda','[DEMO-ROADMAP] Movimento de perda ilustrativo.',u.id
FROM produtos p CROSS JOIN (SELECT id FROM usuarios WHERE ativo=1 ORDER BY id LIMIT 1) u
WHERE p.codigo='DEMO-RM-P003'
  AND NOT EXISTS (SELECT 1 FROM movimentacoes_estoque m WHERE m.origem_tipo='demo_perda' AND m.produto_id=p.id AND m.observacoes='[DEMO-ROADMAP] Movimento de perda ilustrativo.');

INSERT INTO producoes(ficha_id,quantidade_planejada,quantidade_produzida,unidade,turno,status,responsavel_id,observacoes)
SELECT f.id,d.planejada,d.realizada,'porcao',d.turno,d.status,u.id,d.marcador
FROM (
    SELECT 'DEMO-RM-R002' ficha,24.000 planejada,22.000 realizada,'almoco' turno,'produzida' status,'[DEMO-ROADMAP] Penne produzido; exemplo de planejado versus realizado.' marcador
    UNION ALL SELECT 'DEMO-RM-R003',30.000,NULL,'jantar','planejada','[DEMO-ROADMAP] Planejamento aguardando confirmacao da producao.'
) d JOIN fichas_tecnicas f ON f.codigo=d.ficha
CROSS JOIN (SELECT id FROM usuarios WHERE ativo=1 ORDER BY id LIMIT 1) u
WHERE NOT EXISTS (SELECT 1 FROM producoes p WHERE p.observacoes=d.marcador);

INSERT INTO buffet_registros(data_operacao,turno,setor,ficha_id,produto_id,quantidade_preparada,quantidade_servida,sobra_reaproveitavel,descarte,unidade,motivo,custo_estimado,usuario_id,observacoes)
SELECT DATE_SUB(NOW(),INTERVAL d.dias DAY),d.turno,d.setor,f.id,NULL,d.preparada,d.servida,d.sobra,d.descarte,'porcao',d.motivo,d.custo,u.id,d.marcador
FROM (
    SELECT 'almoco' turno,'Restaurante' setor,'DEMO-RM-R002' ficha,28.000 preparada,24.000 servida,2.000 sobra,2.000 descarte,'Excesso de preparacao' motivo,39.80 custo,1 dias,'[DEMO-ROADMAP] Buffet almoco; validar destinacao da sobra.' marcador
    UNION ALL SELECT 'cafe da manha','Cafe','DEMO-RM-R001',12.000,10.000,1.000,1.000,'Baixa procura',5.40,2,'[DEMO-ROADMAP] Exemplo de controle por turno.'
) d JOIN fichas_tecnicas f ON f.codigo=d.ficha
CROSS JOIN (SELECT id FROM usuarios WHERE ativo=1 ORDER BY id LIMIT 1) u
WHERE NOT EXISTS (SELECT 1 FROM buffet_registros b WHERE b.observacoes=d.marcador);

INSERT INTO quebras(item,categoria,quantidade,unidade,local_descricao,motivo,valor_estimado,usuario_id,reposicao_necessaria,observacoes)
SELECT d.item,d.categoria,d.quantidade,d.unidade,d.local_nome,d.motivo,d.valor,u.id,d.repor,d.marcador
FROM (
    SELECT 'Prato raso branco' item,'Utensilio' categoria,2.000 quantidade,'un' unidade,'Cozinha' local_nome,'Queda durante a lavagem' motivo,36.00 valor,1 repor,'[DEMO-ROADMAP] Quebra patrimonial demonstrativa.' marcador
    UNION ALL SELECT 'Jarra de vidro','Utensilio',1.000,'un','Salao','Trinca identificada no fechamento',28.00,1,'[DEMO-ROADMAP] Reposicao pendente para teste.'
) d CROSS JOIN (SELECT id FROM usuarios WHERE ativo=1 ORDER BY id LIMIT 1) u
WHERE NOT EXISTS (SELECT 1 FROM quebras q WHERE q.observacoes=d.marcador);

-- Inventario aberto contendo apenas os produtos desta carga para testar contagem e aprovacao.
INSERT INTO inventarios(local_id,status,usuario_id,observacoes)
SELECT 1,'aberto',u.id,'[DEMO-ROADMAP] Inventario de demonstracao; conte e aprove para testar.'
FROM (SELECT id FROM usuarios WHERE ativo=1 ORDER BY id LIMIT 1) u
WHERE NOT EXISTS (SELECT 1 FROM inventarios i WHERE i.observacoes='[DEMO-ROADMAP] Inventario de demonstracao; conte e aprove para testar.');

INSERT INTO inventario_itens(inventario_id,produto_id,saldo_sistema,quantidade_contada,unidade_base)
SELECT inv.id,p.id,
       COALESCE((SELECT SUM(CASE WHEN m.tipo IN ('entrada','devolucao','transferencia_entrada') THEN m.quantidade_base WHEN m.tipo IN ('consumo','perda','transferencia_saida') THEN -m.quantidade_base ELSE m.quantidade_base END) FROM movimentacoes_estoque m WHERE m.produto_id=p.id AND m.local_id=inv.local_id),0),
       NULL,p.unidade_consumo
FROM inventarios inv JOIN produtos p ON p.codigo LIKE 'DEMO-RM-P%'
WHERE inv.observacoes='[DEMO-ROADMAP] Inventario de demonstracao; conte e aprove para testar.'
  AND NOT EXISTS (SELECT 1 FROM inventario_itens ii WHERE ii.inventario_id=inv.id AND ii.produto_id=p.id);

COMMIT;

SELECT 'Fornecedores DEMO-RM' item,COUNT(*) quantidade FROM fornecedores WHERE nome LIKE 'DEMO-RM | %'
UNION ALL SELECT 'Produtos DEMO-RM',COUNT(*) FROM produtos WHERE codigo LIKE 'DEMO-RM-P%'
UNION ALL SELECT 'Fichas DEMO-RM',COUNT(*) FROM fichas_tecnicas WHERE codigo LIKE 'DEMO-RM-R%'
UNION ALL SELECT 'Compras recebidas DEMO-RM',COUNT(*) FROM compras WHERE referencia='DEMO-RM-NF-001'
UNION ALL SELECT 'Desperdicios DEMO-RM',COUNT(*) FROM desperdicios WHERE client_id LIKE 'seed-roadmap-waste-%'
UNION ALL SELECT 'Inventarios DEMO-RM',COUNT(*) FROM inventarios WHERE observacoes='[DEMO-ROADMAP] Inventario de demonstracao; conte e aprove para testar.';
