-- Dados demonstrativos para o MVP Gestão Restaurante.
-- Seguro para importar mais de uma vez: os registros usam códigos/marcadores DEMO.
-- Não apaga nem altera dados já existentes. Compatível com MySQL/MariaDB do cPanel.
SET NAMES utf8mb4;
START TRANSACTION;

-- Fornecedores de demonstração.
INSERT INTO fornecedores (nome, documento, telefone, contato)
SELECT d.nome, NULL, d.telefone, d.contato
FROM (
    SELECT 'DEMO | Grãos do Vale' AS nome, '(11) 4000-1001' AS telefone, 'Marina' AS contato
    UNION ALL SELECT 'DEMO | Açougue Central', '(11) 4000-1002', 'Carlos'
    UNION ALL SELECT 'DEMO | Hortifruti Fresco', '(11) 4000-1003', 'Paula'
    UNION ALL SELECT 'DEMO | Laticínios Serra', '(11) 4000-1004', 'Rogério'
) AS d
WHERE NOT EXISTS (SELECT 1 FROM fornecedores f WHERE f.nome = d.nome);

-- Preço de cada item expresso na própria unidade de consumo, pois o cálculo
-- atual da ficha técnica multiplica quantidade líquida por produtos.preco_atual.
INSERT INTO produtos
    (nome, codigo, categoria_id, marca, unidade_compra, unidade_consumo,
     fator_conversao, rendimento_percentual, estoque_minimo, preco_atual,
     fornecedor_principal_id)
SELECT d.nome, d.codigo, c.id, 'Linha demonstração', 'kg', 'kg', 1, 100,
       d.estoque_minimo, d.preco, f.id
FROM (
    SELECT 'Arroz agulhinha' AS nome, 'DEMO-ING-001' AS codigo, 'Secos' AS categoria, 'DEMO | Grãos do Vale' AS fornecedor, 7.20 AS preco, 5.000 AS estoque_minimo
    UNION ALL SELECT 'Feijão carioca', 'DEMO-ING-002', 'Secos', 'DEMO | Grãos do Vale', 8.90, 3.000
    UNION ALL SELECT 'Peito de frango', 'DEMO-ING-003', 'Carnes', 'DEMO | Açougue Central', 21.90, 4.000
    UNION ALL SELECT 'Carne bovina moída', 'DEMO-ING-004', 'Carnes', 'DEMO | Açougue Central', 36.90, 3.000
    UNION ALL SELECT 'Macarrão penne', 'DEMO-ING-005', 'Secos', 'DEMO | Grãos do Vale', 9.50, 2.000
    UNION ALL SELECT 'Molho de tomate', 'DEMO-ING-006', 'Secos', 'DEMO | Grãos do Vale', 12.00, 2.000
    UNION ALL SELECT 'Tomate', 'DEMO-ING-007', 'Hortifruti', 'DEMO | Hortifruti Fresco', 8.50, 2.000
    UNION ALL SELECT 'Cebola', 'DEMO-ING-008', 'Hortifruti', 'DEMO | Hortifruti Fresco', 6.00, 1.500
    UNION ALL SELECT 'Alface crespa', 'DEMO-ING-009', 'Hortifruti', 'DEMO | Hortifruti Fresco', 10.50, 1.000
    UNION ALL SELECT 'Cenoura', 'DEMO-ING-010', 'Hortifruti', 'DEMO | Hortifruti Fresco', 6.90, 1.000
    UNION ALL SELECT 'Óleo de soja', 'DEMO-ING-011', 'Secos', 'DEMO | Grãos do Vale', 8.90, 1.000
    UNION ALL SELECT 'Sal refinado', 'DEMO-ING-012', 'Secos', 'DEMO | Grãos do Vale', 3.50, 0.500
    UNION ALL SELECT 'Alho', 'DEMO-ING-013', 'Hortifruti', 'DEMO | Hortifruti Fresco', 28.00, 0.300
    UNION ALL SELECT 'Queijo muçarela', 'DEMO-ING-014', 'Laticínios', 'DEMO | Laticínios Serra', 34.90, 1.000
    UNION ALL SELECT 'Creme de leite', 'DEMO-ING-015', 'Laticínios', 'DEMO | Laticínios Serra', 13.50, 1.000
) AS d
INNER JOIN categorias_produto c ON c.nome = d.categoria
INNER JOIN fornecedores f ON f.nome = d.fornecedor
WHERE NOT EXISTS (SELECT 1 FROM produtos p WHERE p.codigo = d.codigo);

-- Fichas para testar lista, rendimento, custo por porção e preço de venda.
INSERT INTO fichas_tecnicas
    (nome, codigo, categoria_id, tipo, rendimento_total, unidade_rendimento,
     porcoes, tamanho_porcao, modo_preparo, status, preco_venda)
SELECT d.nome, d.codigo, c.id, d.tipo, d.rendimento, 'kg', d.porcoes,
       d.tamanho_porcao, d.preparo, 'aprovada', d.preco_venda
FROM (
    SELECT 'Arroz branco da casa' AS nome, 'DEMO-REC-001' AS codigo, 'Secos' AS categoria, 'acompanhamento' AS tipo, 3.200 AS rendimento, 16.000 AS porcoes, 0.200 AS tamanho_porcao, 'Refogue cebola e alho, acrescente o arroz e cozinhe até ficar macio.' AS preparo, 7.00 AS preco_venda
    UNION ALL SELECT 'Frango ao molho de tomate', 'DEMO-REC-002', 'Carnes', 'prato principal', 2.700, 12.000, 0.225, 'Doure o frango, junte cebola e molho de tomate e cozinhe até atingir o ponto.' , 22.00
    UNION ALL SELECT 'Penne à bolonhesa', 'DEMO-REC-003', 'Carnes', 'prato principal', 3.400, 15.000, 0.227, 'Cozinhe a massa. Prepare o molho com carne moída, tomate, cebola e temperos.' , 26.00
    UNION ALL SELECT 'Salada fresca da estação', 'DEMO-REC-004', 'Hortifruti', 'acompanhamento', 1.550, 10.000, 0.155, 'Higienize e corte os vegetais. Tempere próximo ao serviço.' , 12.00
    UNION ALL SELECT 'Feijão caseiro', 'DEMO-REC-005', 'Secos', 'acompanhamento', 2.500, 12.000, 0.208, 'Deixe o feijão de molho, cozinhe e finalize com refogado de alho e cebola.' , 9.00
) AS d
LEFT JOIN categorias_produto c ON c.nome = d.categoria
WHERE NOT EXISTS (SELECT 1 FROM fichas_tecnicas ft WHERE ft.codigo = d.codigo);

-- Ingredientes em kg, compatíveis com os preços por kg acima.
INSERT INTO ficha_tecnica_itens
    (ficha_id, produto_id, quantidade_bruta, quantidade_liquida, fator_correcao)
SELECT ft.id, p.id, d.quantidade, d.quantidade, 1
FROM (
    SELECT 'DEMO-REC-001' AS ficha, 'DEMO-ING-001' AS produto, 1.500 AS quantidade
    UNION ALL SELECT 'DEMO-REC-001', 'DEMO-ING-008', 0.100
    UNION ALL SELECT 'DEMO-REC-001', 'DEMO-ING-013', 0.020
    UNION ALL SELECT 'DEMO-REC-001', 'DEMO-ING-011', 0.060
    UNION ALL SELECT 'DEMO-REC-001', 'DEMO-ING-012', 0.025
    UNION ALL SELECT 'DEMO-REC-002', 'DEMO-ING-003', 2.000
    UNION ALL SELECT 'DEMO-REC-002', 'DEMO-ING-007', 0.500
    UNION ALL SELECT 'DEMO-REC-002', 'DEMO-ING-008', 0.200
    UNION ALL SELECT 'DEMO-REC-002', 'DEMO-ING-013', 0.030
    UNION ALL SELECT 'DEMO-REC-002', 'DEMO-ING-011', 0.050
    UNION ALL SELECT 'DEMO-REC-002', 'DEMO-ING-012', 0.020
    UNION ALL SELECT 'DEMO-REC-003', 'DEMO-ING-005', 1.500
    UNION ALL SELECT 'DEMO-REC-003', 'DEMO-ING-004', 1.200
    UNION ALL SELECT 'DEMO-REC-003', 'DEMO-ING-006', 0.800
    UNION ALL SELECT 'DEMO-REC-003', 'DEMO-ING-008', 0.150
    UNION ALL SELECT 'DEMO-REC-003', 'DEMO-ING-011', 0.040
    UNION ALL SELECT 'DEMO-REC-003', 'DEMO-ING-012', 0.020
    UNION ALL SELECT 'DEMO-REC-004', 'DEMO-ING-009', 0.800
    UNION ALL SELECT 'DEMO-REC-004', 'DEMO-ING-007', 0.500
    UNION ALL SELECT 'DEMO-REC-004', 'DEMO-ING-010', 0.300
    UNION ALL SELECT 'DEMO-REC-004', 'DEMO-ING-008', 0.080
    UNION ALL SELECT 'DEMO-REC-005', 'DEMO-ING-002', 0.800
    UNION ALL SELECT 'DEMO-REC-005', 'DEMO-ING-008', 0.120
    UNION ALL SELECT 'DEMO-REC-005', 'DEMO-ING-013', 0.030
    UNION ALL SELECT 'DEMO-REC-005', 'DEMO-ING-011', 0.040
    UNION ALL SELECT 'DEMO-REC-005', 'DEMO-ING-012', 0.020
) AS d
INNER JOIN fichas_tecnicas ft ON ft.codigo = d.ficha
INNER JOIN produtos p ON p.codigo = d.produto
WHERE NOT EXISTS (
    SELECT 1 FROM ficha_tecnica_itens fi
    WHERE fi.ficha_id = ft.id AND fi.produto_id = p.id
      AND fi.quantidade_liquida = d.quantidade
);

-- Perdas recentes para alimentar o dashboard. Usuário é escolhido entre os ativos.
INSERT INTO desperdicios
    (produto_id, quantidade, unidade, etapa, motivo, valor_estimado,
     data_registro, usuario_id, observacoes)
SELECT p.id, d.quantidade, 'kg', d.etapa, d.motivo, d.valor,
       DATE_SUB(NOW(), INTERVAL d.dias_atras DAY), u.id, d.marcador
FROM (
    SELECT 'DEMO-ING-003' AS produto, 0.400 AS quantidade, 'pré-preparo' AS etapa, 'Ajuste de porcionamento' AS motivo, 8.76 AS valor, 1 AS dias_atras, '[DEMO-SEED] Frango: aparas do pré-preparo.' AS marcador
    UNION ALL SELECT 'DEMO-ING-007', 0.300, 'armazenamento', 'Produto deteriorado', 2.55, 3, '[DEMO-SEED] Tomate: perda por amadurecimento.'
    UNION ALL SELECT 'DEMO-ING-005', 0.200, 'produção', 'Excesso de produção', 1.90, 6, '[DEMO-SEED] Penne: sobra não reaproveitável.'
    UNION ALL SELECT 'DEMO-ING-009', 0.150, 'pré-preparo', 'Folhas impróprias', 1.58, 9, '[DEMO-SEED] Alface: descarte de folhas externas.'
    UNION ALL SELECT 'DEMO-ING-002', 0.100, 'armazenamento', 'Embalagem danificada', 0.89, 14, '[DEMO-SEED] Feijão: perda de pequena quantidade.'
) AS d
INNER JOIN produtos p ON p.codigo = d.produto
CROSS JOIN (SELECT id FROM usuarios WHERE ativo = 1 ORDER BY (perfil = 'admin') DESC, id LIMIT 1) AS u
WHERE NOT EXISTS (SELECT 1 FROM desperdicios w WHERE w.observacoes = d.marcador);

COMMIT;

-- Resumo do que foi cadastrado pela carga de demonstração.
SELECT 'Produtos DEMO' AS item, COUNT(*) AS quantidade FROM produtos WHERE codigo LIKE 'DEMO-ING-%'
UNION ALL SELECT 'Fichas DEMO', COUNT(*) FROM fichas_tecnicas WHERE codigo LIKE 'DEMO-REC-%'
UNION ALL SELECT 'Itens de ficha DEMO', COUNT(*) FROM ficha_tecnica_itens fi INNER JOIN fichas_tecnicas ft ON ft.id = fi.ficha_id WHERE ft.codigo LIKE 'DEMO-REC-%'
UNION ALL SELECT 'Desperdícios DEMO', COUNT(*) FROM desperdicios WHERE observacoes LIKE '[DEMO-SEED]%';
