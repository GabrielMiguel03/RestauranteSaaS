-- Execute uma unica vez depois de fazer backup do banco.
-- Permite cadastrar regras nomeadas que usam um dos metodos de calculo suportados.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS regras_custo (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(80) NOT NULL UNIQUE,
    metodo ENUM('ultimo','media_ponderada') NOT NULL,
    sistema TINYINT(1) NOT NULL DEFAULT 0,
    criado_por INT UNSIGNED NULL,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (criado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE parametros_custo ADD COLUMN regra_id INT UNSIGNED NULL AFTER regra_preco;

INSERT IGNORE INTO regras_custo(nome,metodo,sistema)
VALUES ('Ultimo preco efetivo','ultimo',1),('Media ponderada','media_ponderada',1);

UPDATE parametros_custo p
SET p.regra_id=(SELECT r.id FROM regras_custo r WHERE r.metodo=p.regra_preco ORDER BY r.sistema DESC,r.id LIMIT 1)
WHERE p.id=1 AND p.regra_id IS NULL;

ALTER TABLE parametros_custo
    ADD CONSTRAINT fk_parametros_custo_regra FOREIGN KEY (regra_id) REFERENCES regras_custo(id);
