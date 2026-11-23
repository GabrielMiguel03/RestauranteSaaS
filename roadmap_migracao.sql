-- MIGRACAO INCREMENTAL - execute uma vez no banco existente, depois de fazer backup.
-- Nao importe database.sql em um banco com dados: ele apaga/recria as tabelas.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS relatorios_salvos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(180) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    dados LONGTEXT NOT NULL,
    usuario_id INT UNSIGNED NOT NULL,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(usuario_id) REFERENCES usuarios(id),
    INDEX(criado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE usuarios MODIFY perfil ENUM('admin','gestor','cozinha','compras','operacional') NOT NULL DEFAULT 'operacional';
ALTER TABLE produtos
    ADD COLUMN estoque_maximo DECIMAL(12,3) NULL AFTER estoque_minimo,
    ADD COLUMN validade_padrao_dias INT UNSIGNED NULL AFTER estoque_maximo;
ALTER TABLE fichas_tecnicas
    ADD COLUMN equipamentos TEXT NULL,
    ADD COLUMN tempo_preparo_minutos INT UNSIGNED NULL,
    ADD COLUMN validade_horas INT UNSIGNED NULL,
    ADD COLUMN armazenamento TEXT NULL,
    ADD COLUMN autor_id INT UNSIGNED NULL,
    ADD COLUMN aprovada_por INT UNSIGNED NULL,
    ADD COLUMN aprovada_em DATETIME NULL,
    ADD CONSTRAINT fk_fichas_autor FOREIGN KEY (autor_id) REFERENCES usuarios(id),
    ADD CONSTRAINT fk_fichas_aprovador FOREIGN KEY (aprovada_por) REFERENCES usuarios(id);
ALTER TABLE ficha_tecnica_itens
    MODIFY produto_id INT UNSIGNED NULL,
    ADD COLUMN ficha_componente_id INT UNSIGNED NULL AFTER produto_id,
    ADD CONSTRAINT fk_ficha_item_componente FOREIGN KEY (ficha_componente_id) REFERENCES fichas_tecnicas(id);

CREATE TABLE IF NOT EXISTS parametros_custo (
    id TINYINT UNSIGNED PRIMARY KEY,
    regra_preco ENUM('ultimo','media_ponderada') NOT NULL DEFAULT 'ultimo',
    atualizado_por INT UNSIGNED NULL,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (atualizado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO parametros_custo(id,regra_preco) VALUES (1,'ultimo');

CREATE TABLE IF NOT EXISTS locais_estoque (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(120) NOT NULL UNIQUE,
    ativo TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO locais_estoque(id,nome) VALUES (1,'Estoque principal');

CREATE TABLE IF NOT EXISTS produto_fornecedores (
    produto_id INT UNSIGNED NOT NULL,
    fornecedor_id INT UNSIGNED NOT NULL,
    codigo_fornecedor VARCHAR(80) NULL,
    preferencial TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY(produto_id,fornecedor_id),
    FOREIGN KEY(produto_id) REFERENCES produtos(id),
    FOREIGN KEY(fornecedor_id) REFERENCES fornecedores(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO produto_fornecedores(produto_id,fornecedor_id,preferencial)
SELECT id,fornecedor_principal_id,1 FROM produtos WHERE fornecedor_principal_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS compras (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fornecedor_id INT UNSIGNED NOT NULL,
    data_compra DATETIME NOT NULL,
    referencia VARCHAR(120) NULL,
    status ENUM('rascunho','recebida','cancelada') NOT NULL DEFAULT 'rascunho',
    desconto_total DECIMAL(12,2) NOT NULL DEFAULT 0,
    frete_total DECIMAL(12,2) NOT NULL DEFAULT 0,
    observacoes TEXT NULL,
    usuario_id INT UNSIGNED NOT NULL,
    recebida_em DATETIME NULL,
    FOREIGN KEY(fornecedor_id) REFERENCES fornecedores(id),
    FOREIGN KEY(usuario_id) REFERENCES usuarios(id),
    INDEX(data_compra), INDEX(status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS compra_itens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    compra_id BIGINT UNSIGNED NOT NULL,
    produto_id INT UNSIGNED NOT NULL,
    quantidade DECIMAL(14,4) NOT NULL,
    unidade VARCHAR(12) NOT NULL,
    preco_unitario DECIMAL(14,4) NOT NULL,
    desconto DECIMAL(12,2) NOT NULL DEFAULT 0,
    lote VARCHAR(100) NULL,
    validade DATE NULL,
    FOREIGN KEY(compra_id) REFERENCES compras(id) ON DELETE CASCADE,
    FOREIGN KEY(produto_id) REFERENCES produtos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS historico_precos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    produto_id INT UNSIGNED NOT NULL,
    fornecedor_id INT UNSIGNED NULL,
    compra_item_id BIGINT UNSIGNED NULL,
    preco DECIMAL(14,4) NOT NULL,
    unidade VARCHAR(12) NOT NULL,
    quantidade_base DECIMAL(14,4) NOT NULL,
    quantidade_compra DECIMAL(14,4) NOT NULL DEFAULT 1,
    origem ENUM('cadastro','compra','ajuste') NOT NULL,
    registrado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_id INT UNSIGNED NOT NULL,
    FOREIGN KEY(produto_id) REFERENCES produtos(id),
    FOREIGN KEY(fornecedor_id) REFERENCES fornecedores(id),
    FOREIGN KEY(compra_item_id) REFERENCES compra_itens(id),
    FOREIGN KEY(usuario_id) REFERENCES usuarios(id),
    INDEX(produto_id,registrado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO historico_precos(produto_id,fornecedor_id,preco,unidade,quantidade_base,quantidade_compra,origem,usuario_id)
SELECT p.id,p.fornecedor_principal_id,p.preco_atual,p.unidade_compra,
       CASE WHEN p.unidade_compra='kg' AND p.unidade_consumo='g' THEN 1000
            WHEN p.unidade_compra='g' AND p.unidade_consumo='kg' THEN 0.001
            WHEN p.unidade_compra='l' AND p.unidade_consumo='ml' THEN 1000
            WHEN p.unidade_compra='ml' AND p.unidade_consumo='l' THEN 0.001
            ELSE GREATEST(p.fator_conversao,0.000001) END,
       1,'cadastro',(SELECT MIN(id) FROM usuarios)
FROM produtos p
WHERE p.preco_atual>0 AND EXISTS(SELECT 1 FROM usuarios)
  AND NOT EXISTS(SELECT 1 FROM historico_precos h WHERE h.produto_id=p.id);

CREATE TABLE IF NOT EXISTS movimentacoes_estoque (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    produto_id INT UNSIGNED NOT NULL,
    local_id INT UNSIGNED NOT NULL DEFAULT 1,
    tipo ENUM('entrada','consumo','perda','devolucao','transferencia_entrada','transferencia_saida','ajuste') NOT NULL,
    quantidade_base DECIMAL(14,4) NOT NULL,
    unidade_base VARCHAR(12) NOT NULL,
    custo_unitario DECIMAL(14,4) NOT NULL DEFAULT 0,
    lote VARCHAR(100) NULL,
    validade DATE NULL,
    origem_tipo VARCHAR(40) NULL,
    origem_id BIGINT UNSIGNED NULL,
    observacoes TEXT NULL,
    usuario_id INT UNSIGNED NOT NULL,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(produto_id) REFERENCES produtos(id),
    FOREIGN KEY(local_id) REFERENCES locais_estoque(id),
    FOREIGN KEY(usuario_id) REFERENCES usuarios(id),
    INDEX(produto_id,local_id,criado_em), INDEX(validade)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
ALTER TABLE desperdicios ADD COLUMN client_id CHAR(36) NULL UNIQUE AFTER observacoes;

CREATE TABLE IF NOT EXISTS inventarios (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    local_id INT UNSIGNED NOT NULL,
    status ENUM('aberto','contado','aprovado','cancelado') NOT NULL DEFAULT 'aberto',
    iniciado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    contado_em DATETIME NULL,
    aprovado_em DATETIME NULL,
    usuario_id INT UNSIGNED NOT NULL,
    aprovado_por INT UNSIGNED NULL,
    observacoes TEXT NULL,
    FOREIGN KEY(local_id) REFERENCES locais_estoque(id),
    FOREIGN KEY(usuario_id) REFERENCES usuarios(id),
    FOREIGN KEY(aprovado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS inventario_itens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    inventario_id BIGINT UNSIGNED NOT NULL,
    produto_id INT UNSIGNED NOT NULL,
    saldo_sistema DECIMAL(14,4) NOT NULL,
    quantidade_contada DECIMAL(14,4) NULL,
    unidade_base VARCHAR(12) NOT NULL,
    FOREIGN KEY(inventario_id) REFERENCES inventarios(id) ON DELETE CASCADE,
    FOREIGN KEY(produto_id) REFERENCES produtos(id),
    UNIQUE KEY(inventario_id,produto_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS producoes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ficha_id INT UNSIGNED NOT NULL,
    quantidade_planejada DECIMAL(14,4) NOT NULL,
    quantidade_produzida DECIMAL(14,4) NULL,
    unidade VARCHAR(12) NOT NULL,
    turno VARCHAR(40) NULL,
    status ENUM('planejada','produzida','cancelada') NOT NULL DEFAULT 'planejada',
    responsavel_id INT UNSIGNED NOT NULL,
    registrada_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT NULL,
    FOREIGN KEY(ficha_id) REFERENCES fichas_tecnicas(id),
    FOREIGN KEY(responsavel_id) REFERENCES usuarios(id),
    INDEX(registrada_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS producao_itens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    producao_id BIGINT UNSIGNED NOT NULL,
    produto_id INT UNSIGNED NOT NULL,
    quantidade_esperada DECIMAL(14,4) NOT NULL,
    quantidade_real DECIMAL(14,4) NULL,
    unidade VARCHAR(12) NOT NULL,
    FOREIGN KEY(producao_id) REFERENCES producoes(id) ON DELETE CASCADE,
    FOREIGN KEY(produto_id) REFERENCES produtos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS buffet_registros (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    data_operacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    turno VARCHAR(40) NOT NULL,
    setor VARCHAR(80) NOT NULL,
    ficha_id INT UNSIGNED NULL,
    produto_id INT UNSIGNED NULL,
    quantidade_preparada DECIMAL(14,4) NOT NULL DEFAULT 0,
    quantidade_servida DECIMAL(14,4) NOT NULL DEFAULT 0,
    sobra_reaproveitavel DECIMAL(14,4) NOT NULL DEFAULT 0,
    descarte DECIMAL(14,4) NOT NULL DEFAULT 0,
    unidade VARCHAR(12) NOT NULL,
    motivo VARCHAR(120) NULL,
    custo_estimado DECIMAL(14,2) NOT NULL DEFAULT 0,
    usuario_id INT UNSIGNED NOT NULL,
    observacoes TEXT NULL,
    FOREIGN KEY(ficha_id) REFERENCES fichas_tecnicas(id),
    FOREIGN KEY(produto_id) REFERENCES produtos(id),
    FOREIGN KEY(usuario_id) REFERENCES usuarios(id),
    INDEX(data_operacao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS quebras (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    item VARCHAR(160) NOT NULL,
    categoria VARCHAR(80) NOT NULL,
    quantidade DECIMAL(12,3) NOT NULL,
    unidade VARCHAR(12) NOT NULL DEFAULT 'un',
    local_descricao VARCHAR(100) NULL,
    motivo VARCHAR(160) NOT NULL,
    valor_estimado DECIMAL(12,2) NOT NULL DEFAULT 0,
    data_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_id INT UNSIGNED NOT NULL,
    reposicao_necessaria TINYINT(1) NOT NULL DEFAULT 0,
    observacoes TEXT NULL,
    FOREIGN KEY(usuario_id) REFERENCES usuarios(id),
    INDEX(data_registro)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS fichas_tecnicas_versoes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ficha_id INT UNSIGNED NOT NULL,
    versao INT UNSIGNED NOT NULL,
    snapshot LONGTEXT NOT NULL,
    usuario_id INT UNSIGNED NOT NULL,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(ficha_id) REFERENCES fichas_tecnicas(id),
    FOREIGN KEY(usuario_id) REFERENCES usuarios(id),
    UNIQUE KEY(ficha_id,versao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
