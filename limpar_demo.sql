-- Remove somente os registros criados por seed_demo.sql.
-- Se algum produto DEMO tiver sido usado em registros reais, a chave estrangeira
-- impedirá sua exclusão; remova/ajuste essas referências antes de repetir.
SET NAMES utf8mb4;
START TRANSACTION;

DELETE FROM desperdicios WHERE observacoes LIKE '[DEMO-SEED]%';

DELETE fi FROM ficha_tecnica_itens fi
INNER JOIN fichas_tecnicas ft ON ft.id = fi.ficha_id
WHERE ft.codigo LIKE 'DEMO-REC-%';

DELETE FROM fichas_tecnicas WHERE codigo LIKE 'DEMO-REC-%';
DELETE FROM produtos WHERE codigo LIKE 'DEMO-ING-%';

DELETE FROM fornecedores
WHERE nome LIKE 'DEMO | %'
  AND NOT EXISTS (SELECT 1 FROM produtos p WHERE p.fornecedor_principal_id = fornecedores.id);

COMMIT;
