-- Importe uma vez pelo phpMyAdmin no banco atual para habilitar o histórico de relatórios.
CREATE TABLE IF NOT EXISTS relatorios_salvos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(180) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    dados LONGTEXT NOT NULL,
    usuario_id INT UNSIGNED NOT NULL,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_relatorios_salvos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    INDEX idx_relatorios_salvos_criado_em (criado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
