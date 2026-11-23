-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Tempo de geração: 23/11/2026 às 17:14
-- Versão do servidor: 10.11.19-MariaDB-cll-lve
-- Versão do PHP: 8.4.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `oficinahotrods_RestauranteSaaS`
--

-- --------------------------------------------------------

--
-- Estrutura para tabela `auditoria`
--

CREATE TABLE `auditoria` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `usuario_id` int(10) UNSIGNED DEFAULT NULL,
  `acao` varchar(40) NOT NULL,
  `entidade` varchar(60) NOT NULL,
  `entidade_id` int(10) UNSIGNED DEFAULT NULL,
  `detalhes` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`detalhes`)),
  `criado_em` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `auditoria`
--

INSERT INTO `auditoria` (`id`, `usuario_id`, `acao`, `entidade`, `entidade_id`, `detalhes`, `criado_em`) VALUES
(1, 6, 'salvou', 'relatorio', 1, '{\"titulo\":\"Relatório de gestão\"}', '2026-11-20 17:11:14'),
(2, 6, 'salvou', 'relatorio', 2, '{\"titulo\":\"Relatório de gestão1\"}', '2026-11-20 17:11:21'),
(3, 6, 'salvou', 'relatorio', 3, '{\"titulo\":\"Relatório de gestão3\"}', '2026-11-20 17:11:28'),
(4, 6, 'confirmou', 'producao', 2, '{\"quantidade_produzida\":10000,\"baixa_automatica\":false}', '2026-11-21 14:17:52'),
(5, 6, 'selecionou', 'regra_custo', 2, '[]', '2026-11-21 15:25:45');

-- --------------------------------------------------------

--
-- Estrutura para tabela `buffet_registros`
--

CREATE TABLE `buffet_registros` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `data_operacao` datetime NOT NULL DEFAULT current_timestamp(),
  `turno` varchar(40) NOT NULL,
  `setor` varchar(80) NOT NULL,
  `ficha_id` int(10) UNSIGNED DEFAULT NULL,
  `produto_id` int(10) UNSIGNED DEFAULT NULL,
  `quantidade_preparada` decimal(14,4) NOT NULL DEFAULT 0.0000,
  `quantidade_servida` decimal(14,4) NOT NULL DEFAULT 0.0000,
  `sobra_reaproveitavel` decimal(14,4) NOT NULL DEFAULT 0.0000,
  `descarte` decimal(14,4) NOT NULL DEFAULT 0.0000,
  `unidade` varchar(12) NOT NULL,
  `motivo` varchar(120) DEFAULT NULL,
  `custo_estimado` decimal(14,2) NOT NULL DEFAULT 0.00,
  `usuario_id` int(10) UNSIGNED NOT NULL,
  `observacoes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `buffet_registros`
--

INSERT INTO `buffet_registros` (`id`, `data_operacao`, `turno`, `setor`, `ficha_id`, `produto_id`, `quantidade_preparada`, `quantidade_servida`, `sobra_reaproveitavel`, `descarte`, `unidade`, `motivo`, `custo_estimado`, `usuario_id`, `observacoes`) VALUES
(1, '2026-11-19 14:16:40', 'cafe da manha', 'Cafe', 8, NULL, 12.0000, 10.0000, 1.0000, 1.0000, 'porcao', 'Baixa procura', 5.40, 6, '[DEMO-ROADMAP] Exemplo de controle por turno.'),
(2, '2026-11-20 14:16:40', 'almoco', 'Restaurante', 9, NULL, 28.0000, 24.0000, 2.0000, 2.0000, 'porcao', 'Excesso de preparacao', 39.80, 6, '[DEMO-ROADMAP] Buffet almoco; validar destinacao da sobra.');

-- --------------------------------------------------------

--
-- Estrutura para tabela `categorias_produto`
--

CREATE TABLE `categorias_produto` (
  `id` int(10) UNSIGNED NOT NULL,
  `nome` varchar(80) NOT NULL,
  `ativo` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `categorias_produto`
--

INSERT INTO `categorias_produto` (`id`, `nome`, `ativo`) VALUES
(1, 'Carnes', 1),
(2, 'Hortifruti', 1),
(3, 'Laticínios', 1),
(4, 'Secos', 1),
(5, 'Bebidas', 1),
(6, 'Descartáveis', 1),
(7, 'Limpeza', 1),
(8, 'Outros', 1);

-- --------------------------------------------------------

--
-- Estrutura para tabela `compras`
--

CREATE TABLE `compras` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `fornecedor_id` int(10) UNSIGNED NOT NULL,
  `data_compra` datetime NOT NULL,
  `referencia` varchar(120) DEFAULT NULL,
  `status` enum('rascunho','recebida','cancelada') NOT NULL DEFAULT 'rascunho',
  `desconto_total` decimal(12,2) NOT NULL DEFAULT 0.00,
  `frete_total` decimal(12,2) NOT NULL DEFAULT 0.00,
  `observacoes` text DEFAULT NULL,
  `usuario_id` int(10) UNSIGNED NOT NULL,
  `recebida_em` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `compras`
--

INSERT INTO `compras` (`id`, `fornecedor_id`, `data_compra`, `referencia`, `status`, `desconto_total`, `frete_total`, `observacoes`, `usuario_id`, `recebida_em`) VALUES
(1, 9, '2026-11-19 14:16:40', 'DEMO-RM-NF-001', 'recebida', 5.00, 18.00, 'Compra demonstrativa recebida; valores apenas para teste.', 6, '2026-11-19 14:16:40');

-- --------------------------------------------------------

--
-- Estrutura para tabela `compra_itens`
--

CREATE TABLE `compra_itens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `compra_id` bigint(20) UNSIGNED NOT NULL,
  `produto_id` int(10) UNSIGNED NOT NULL,
  `quantidade` decimal(14,4) NOT NULL,
  `unidade` varchar(12) NOT NULL,
  `preco_unitario` decimal(14,4) NOT NULL,
  `desconto` decimal(12,2) NOT NULL DEFAULT 0.00,
  `lote` varchar(100) DEFAULT NULL,
  `validade` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `compra_itens`
--

INSERT INTO `compra_itens` (`id`, `compra_id`, `produto_id`, `quantidade`, `unidade`, `preco_unitario`, `desconto`, `lote`, `validade`) VALUES
(1, 1, 16, 6.0000, 'l', 8.9000, 0.00, 'OLE-DEMO-01', '2027-09-17'),
(2, 1, 17, 8.0000, 'kg', 9.5000, 0.00, 'PEN-DEMO-01', '2027-09-17'),
(3, 1, 18, 12.0000, 'kg', 21.9000, 0.00, 'FRA-DEMO-01', '2027-02-19'),
(4, 1, 19, 10.0000, 'kg', 8.9000, 0.00, 'FEI-DEMO-01', '2027-07-19'),
(5, 1, 20, 20.0000, 'kg', 7.2000, 0.00, 'ARZ-DEMO-01', '2027-09-17');

-- --------------------------------------------------------

--
-- Estrutura para tabela `desperdicios`
--

CREATE TABLE `desperdicios` (
  `id` int(10) UNSIGNED NOT NULL,
  `produto_id` int(10) UNSIGNED NOT NULL,
  `quantidade` decimal(12,4) NOT NULL,
  `unidade` varchar(12) NOT NULL,
  `etapa` varchar(40) NOT NULL,
  `motivo` varchar(120) NOT NULL,
  `valor_estimado` decimal(12,2) DEFAULT 0.00,
  `data_registro` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(10) UNSIGNED NOT NULL,
  `observacoes` text DEFAULT NULL,
  `client_id` char(36) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `desperdicios`
--

INSERT INTO `desperdicios` (`id`, `produto_id`, `quantidade`, `unidade`, `etapa`, `motivo`, `valor_estimado`, `data_registro`, `usuario_id`, `observacoes`, `client_id`) VALUES
(1, 4, 0.2000, 'kg', 'produção', 'Excesso de produção', 1.90, '2026-11-14 15:12:57', 6, '[DEMO-SEED] Penne: sobra não reaproveitável.', NULL),
(2, 5, 0.1000, 'kg', 'armazenamento', 'Embalagem danificada', 0.89, '2026-11-06 15:12:57', 6, '[DEMO-SEED] Feijão: perda de pequena quantidade.', NULL),
(3, 8, 0.4000, 'kg', 'pré-preparo', 'Ajuste de porcionamento', 8.76, '2026-11-19 15:12:57', 6, '[DEMO-SEED] Frango: aparas do pré-preparo.', NULL),
(4, 11, 0.1500, 'kg', 'pré-preparo', 'Folhas impróprias', 1.58, '2026-11-11 15:12:57', 6, '[DEMO-SEED] Alface: descarte de folhas externas.', NULL),
(5, 13, 0.3000, 'kg', 'armazenamento', 'Produto deteriorado', 2.55, '2026-11-17 15:12:57', 6, '[DEMO-SEED] Tomate: perda por amadurecimento.', NULL),
(8, 17, 250.0000, 'g', 'pos-servico', 'Excesso de producao', 2.38, '2026-11-16 14:16:40', 6, '[DEMO-ROADMAP] Massa pronta sem reaproveitamento.', 'seed-roadmap-waste-003'),
(9, 18, 350.0000, 'g', 'pre-preparo', 'Aparas acima do esperado', 7.67, '2026-11-20 14:16:40', 6, '[DEMO-ROADMAP] Acompanhar rendimento do frango.', 'seed-roadmap-waste-001'),
(10, 22, 500.0000, 'g', 'armazenamento', 'Amadurecimento excessivo', 4.25, '2026-11-18 14:16:40', 6, '[DEMO-ROADMAP] Tomate descartado no recebimento.', 'seed-roadmap-waste-002');

-- --------------------------------------------------------

--
-- Estrutura para tabela `fichas_tecnicas`
--

CREATE TABLE `fichas_tecnicas` (
  `id` int(10) UNSIGNED NOT NULL,
  `nome` varchar(160) NOT NULL,
  `codigo` varchar(60) DEFAULT NULL,
  `categoria_id` int(10) UNSIGNED DEFAULT NULL,
  `tipo` varchar(40) DEFAULT 'prato',
  `rendimento_total` decimal(12,3) NOT NULL,
  `unidade_rendimento` varchar(12) NOT NULL,
  `porcoes` decimal(12,3) NOT NULL DEFAULT 1.000,
  `tamanho_porcao` decimal(12,3) DEFAULT 0.000,
  `modo_preparo` text DEFAULT NULL,
  `status` enum('rascunho','aprovada','arquivada') DEFAULT 'rascunho',
  `preco_venda` decimal(12,2) DEFAULT 0.00,
  `versao` int(11) DEFAULT 1,
  `criado_em` datetime DEFAULT current_timestamp(),
  `atualizado_em` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `equipamentos` text DEFAULT NULL,
  `tempo_preparo_minutos` int(10) UNSIGNED DEFAULT NULL,
  `validade_horas` int(10) UNSIGNED DEFAULT NULL,
  `armazenamento` text DEFAULT NULL,
  `autor_id` int(10) UNSIGNED DEFAULT NULL,
  `aprovada_por` int(10) UNSIGNED DEFAULT NULL,
  `aprovada_em` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `fichas_tecnicas`
--

INSERT INTO `fichas_tecnicas` (`id`, `nome`, `codigo`, `categoria_id`, `tipo`, `rendimento_total`, `unidade_rendimento`, `porcoes`, `tamanho_porcao`, `modo_preparo`, `status`, `preco_venda`, `versao`, `criado_em`, `atualizado_em`, `equipamentos`, `tempo_preparo_minutos`, `validade_horas`, `armazenamento`, `autor_id`, `aprovada_por`, `aprovada_em`) VALUES
(1, 'Arroz branco da casa', 'DEMO-REC-001', 4, 'acompanhamento', 3.200, 'kg', 16.000, 0.200, 'Refogue cebola e alho, acrescente o arroz e cozinhe até ficar macio.', 'aprovada', 7.00, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(2, 'Frango ao molho de tomate', 'DEMO-REC-002', 1, 'prato principal', 2.700, 'kg', 12.000, 0.225, 'Doure o frango, junte cebola e molho de tomate e cozinhe até atingir o ponto.', 'aprovada', 22.00, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(3, 'Penne à bolonhesa', 'DEMO-REC-003', 1, 'prato principal', 3.400, 'kg', 15.000, 0.227, 'Cozinhe a massa. Prepare o molho com carne moída, tomate, cebola e temperos.', 'aprovada', 26.00, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(4, 'Salada fresca da estação', 'DEMO-REC-004', 2, 'acompanhamento', 1.550, 'kg', 10.000, 0.155, 'Higienize e corte os vegetais. Tempere próximo ao serviço.', 'aprovada', 12.00, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(5, 'Feijão caseiro', 'DEMO-REC-005', 4, 'acompanhamento', 2.500, 'kg', 12.000, 0.208, 'Deixe o feijão de molho, cozinhe e finalize com refogado de alho e cebola.', 'aprovada', 9.00, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(8, 'Molho rapido de tomate', 'DEMO-RM-R001', 2, 'base', 1200.000, 'g', 12.000, 100.000, 'Refogue cebola, junte tomate picado e cozinhe ate encorpar.', 'aprovada', 4.50, 1, '2026-11-21 14:16:40', '2026-11-21 14:16:40', 'Panela e fogao', 25, 48, 'Refrigerado em recipiente fechado', 6, 6, '2026-11-21 14:16:40'),
(9, 'Penne ao molho da casa', 'DEMO-RM-R002', 4, 'prato', 3000.000, 'g', 12.000, 250.000, 'Cozinhe a massa. Misture ao molho aquecido e finalize com queijo.', 'aprovada', 19.90, 1, '2026-11-21 14:16:40', '2026-11-21 14:16:40', 'Panela e fogao', 35, 24, 'Refrigerado; aquecer antes de servir', 6, 6, '2026-11-21 14:16:40'),
(10, 'Frango com arroz e feijao', 'DEMO-RM-R003', 1, 'prato', 6000.000, 'g', 20.000, 300.000, 'Cozinhe os graos e prepare o frango completamente antes de servir.', 'aprovada', 24.90, 1, '2026-11-21 14:16:40', '2026-11-21 14:16:40', 'Panelas, fogao e forno', 60, 24, 'Refrigerado em recipientes identificados', 6, 6, '2026-11-21 14:16:40');

-- --------------------------------------------------------

--
-- Estrutura para tabela `fichas_tecnicas_versoes`
--

CREATE TABLE `fichas_tecnicas_versoes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ficha_id` int(10) UNSIGNED NOT NULL,
  `versao` int(10) UNSIGNED NOT NULL,
  `snapshot` longtext NOT NULL,
  `usuario_id` int(10) UNSIGNED NOT NULL,
  `criado_em` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `ficha_tecnica_itens`
--

CREATE TABLE `ficha_tecnica_itens` (
  `id` int(10) UNSIGNED NOT NULL,
  `ficha_id` int(10) UNSIGNED NOT NULL,
  `produto_id` int(10) UNSIGNED DEFAULT NULL,
  `ficha_componente_id` int(10) UNSIGNED DEFAULT NULL,
  `quantidade_bruta` decimal(12,4) NOT NULL,
  `quantidade_liquida` decimal(12,4) NOT NULL,
  `fator_correcao` decimal(12,4) DEFAULT 1.0000
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `ficha_tecnica_itens`
--

INSERT INTO `ficha_tecnica_itens` (`id`, `ficha_id`, `produto_id`, `ficha_componente_id`, `quantidade_bruta`, `quantidade_liquida`, `fator_correcao`) VALUES
(1, 1, 1, NULL, 0.0250, 0.0250, 1.0000),
(2, 2, 1, NULL, 0.0200, 0.0200, 1.0000),
(3, 3, 1, NULL, 0.0200, 0.0200, 1.0000),
(4, 5, 1, NULL, 0.0200, 0.0200, 1.0000),
(5, 1, 2, NULL, 0.0600, 0.0600, 1.0000),
(6, 2, 2, NULL, 0.0500, 0.0500, 1.0000),
(7, 3, 2, NULL, 0.0400, 0.0400, 1.0000),
(8, 5, 2, NULL, 0.0400, 0.0400, 1.0000),
(9, 3, 3, NULL, 0.8000, 0.8000, 1.0000),
(10, 3, 4, NULL, 1.5000, 1.5000, 1.0000),
(11, 5, 5, NULL, 0.8000, 0.8000, 1.0000),
(12, 1, 6, NULL, 1.5000, 1.5000, 1.0000),
(13, 3, 7, NULL, 1.2000, 1.2000, 1.0000),
(14, 2, 8, NULL, 2.0000, 2.0000, 1.0000),
(15, 1, 9, NULL, 0.0200, 0.0200, 1.0000),
(16, 2, 9, NULL, 0.0300, 0.0300, 1.0000),
(17, 5, 9, NULL, 0.0300, 0.0300, 1.0000),
(18, 4, 10, NULL, 0.3000, 0.3000, 1.0000),
(19, 4, 11, NULL, 0.8000, 0.8000, 1.0000),
(20, 1, 12, NULL, 0.1000, 0.1000, 1.0000),
(21, 2, 12, NULL, 0.2000, 0.2000, 1.0000),
(22, 3, 12, NULL, 0.1500, 0.1500, 1.0000),
(23, 4, 12, NULL, 0.0800, 0.0800, 1.0000),
(24, 5, 12, NULL, 0.1200, 0.1200, 1.0000),
(25, 2, 13, NULL, 0.5000, 0.5000, 1.0000),
(26, 4, 13, NULL, 0.5000, 0.5000, 1.0000),
(32, 9, 17, NULL, 1800.0000, 1800.0000, 1.0000),
(33, 10, 18, NULL, 2400.0000, 1968.0000, 1.2195),
(34, 10, 19, NULL, 1200.0000, 1200.0000, 1.0000),
(35, 10, 20, NULL, 1800.0000, 1800.0000, 1.0000),
(36, 8, 21, NULL, 220.0000, 198.0000, 1.1111),
(37, 8, 22, NULL, 900.0000, 828.0000, 1.0870),
(38, 9, 23, NULL, 180.0000, 180.0000, 1.0000),
(39, 9, NULL, 8, 600.0000, 600.0000, 1.0000);

-- --------------------------------------------------------

--
-- Estrutura para tabela `fornecedores`
--

CREATE TABLE `fornecedores` (
  `id` int(10) UNSIGNED NOT NULL,
  `nome` varchar(160) NOT NULL,
  `documento` varchar(30) DEFAULT NULL,
  `telefone` varchar(30) DEFAULT NULL,
  `contato` varchar(100) DEFAULT NULL,
  `ativo` tinyint(1) DEFAULT 1,
  `criado_em` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `fornecedores`
--

INSERT INTO `fornecedores` (`id`, `nome`, `documento`, `telefone`, `contato`, `ativo`, `criado_em`) VALUES
(1, 'Fornecedor não informado', NULL, NULL, NULL, 1, '2026-11-20 13:42:24'),
(2, 'DEMO | Grãos do Vale', NULL, '(11) 4000-1001', 'Marina', 1, '2026-11-20 15:12:57'),
(3, 'DEMO | Açougue Central', NULL, '(11) 4000-1002', 'Carlos', 1, '2026-11-20 15:12:57'),
(4, 'DEMO | Hortifruti Fresco', NULL, '(11) 4000-1003', 'Paula', 1, '2026-11-20 15:12:57'),
(5, 'DEMO | Laticínios Serra', NULL, '(11) 4000-1004', 'Rogério', 1, '2026-11-20 15:12:57'),
(9, 'DEMO-RM | Distribuidora Central', '00.000.000/0001-01', '(11) 4000-2001', 'Ana Lima', 1, '2026-11-21 14:16:40'),
(10, 'DEMO-RM | Hortifruti da Serra', '00.000.000/0001-02', '(11) 4000-2002', 'Bruno Reis', 1, '2026-11-21 14:16:40'),
(11, 'DEMO-RM | Laticinios Bom Leite', '00.000.000/0001-03', '(11) 4000-2003', 'Carla Souza', 1, '2026-11-21 14:16:40');

-- --------------------------------------------------------

--
-- Estrutura para tabela `historico_precos`
--

CREATE TABLE `historico_precos` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `produto_id` int(10) UNSIGNED NOT NULL,
  `fornecedor_id` int(10) UNSIGNED DEFAULT NULL,
  `compra_item_id` bigint(20) UNSIGNED DEFAULT NULL,
  `preco` decimal(14,4) NOT NULL,
  `unidade` varchar(12) NOT NULL,
  `quantidade_base` decimal(14,4) NOT NULL,
  `quantidade_compra` decimal(14,4) NOT NULL DEFAULT 1.0000,
  `origem` enum('cadastro','compra','ajuste') NOT NULL,
  `registrado_em` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `historico_precos`
--

INSERT INTO `historico_precos` (`id`, `produto_id`, `fornecedor_id`, `compra_item_id`, `preco`, `unidade`, `quantidade_base`, `quantidade_compra`, `origem`, `registrado_em`, `usuario_id`) VALUES
(1, 1, 2, NULL, 3.5000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(2, 2, 2, NULL, 8.9000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(3, 3, 2, NULL, 12.0000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(4, 4, 2, NULL, 9.5000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(5, 5, 2, NULL, 8.9000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(6, 6, 2, NULL, 7.2000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(7, 7, 3, NULL, 36.9000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(8, 8, 3, NULL, 21.9000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(9, 9, 4, NULL, 28.0000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(10, 10, 4, NULL, 6.9000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(11, 11, 4, NULL, 10.5000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(12, 12, 4, NULL, 6.0000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(13, 13, 4, NULL, 8.5000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(14, 14, 5, NULL, 13.5000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(15, 15, 5, NULL, 34.9000, 'kg', 1.0000, 1.0000, 'cadastro', '2026-11-21 13:52:26', 6),
(16, 16, 9, 1, 8.9000, 'l', 6000.0000, 6.0000, 'compra', '2026-11-21 14:16:40', 6),
(17, 17, 9, 2, 9.5000, 'kg', 8000.0000, 8.0000, 'compra', '2026-11-21 14:16:40', 6),
(18, 18, 9, 3, 21.9000, 'kg', 12000.0000, 12.0000, 'compra', '2026-11-21 14:16:40', 6),
(19, 19, 9, 4, 8.9000, 'kg', 10000.0000, 10.0000, 'compra', '2026-11-21 14:16:40', 6),
(20, 20, 9, 5, 7.2000, 'kg', 20000.0000, 20.0000, 'compra', '2026-11-21 14:16:40', 6);

-- --------------------------------------------------------

--
-- Estrutura para tabela `inventarios`
--

CREATE TABLE `inventarios` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `local_id` int(10) UNSIGNED NOT NULL,
  `status` enum('aberto','contado','aprovado','cancelado') NOT NULL DEFAULT 'aberto',
  `iniciado_em` datetime NOT NULL DEFAULT current_timestamp(),
  `contado_em` datetime DEFAULT NULL,
  `aprovado_em` datetime DEFAULT NULL,
  `usuario_id` int(10) UNSIGNED NOT NULL,
  `aprovado_por` int(10) UNSIGNED DEFAULT NULL,
  `observacoes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `inventarios`
--

INSERT INTO `inventarios` (`id`, `local_id`, `status`, `iniciado_em`, `contado_em`, `aprovado_em`, `usuario_id`, `aprovado_por`, `observacoes`) VALUES
(1, 1, 'aberto', '2026-11-21 14:16:40', NULL, NULL, 6, NULL, '[DEMO-ROADMAP] Inventario de demonstracao; conte e aprove para testar.');

-- --------------------------------------------------------

--
-- Estrutura para tabela `inventario_itens`
--

CREATE TABLE `inventario_itens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `inventario_id` bigint(20) UNSIGNED NOT NULL,
  `produto_id` int(10) UNSIGNED NOT NULL,
  `saldo_sistema` decimal(14,4) NOT NULL,
  `quantidade_contada` decimal(14,4) DEFAULT NULL,
  `unidade_base` varchar(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `inventario_itens`
--

INSERT INTO `inventario_itens` (`id`, `inventario_id`, `produto_id`, `saldo_sistema`, `quantidade_contada`, `unidade_base`) VALUES
(1, 1, 16, 6000.0000, NULL, 'ml'),
(2, 1, 17, 8000.0000, NULL, 'g'),
(3, 1, 18, 11650.0000, NULL, 'g'),
(4, 1, 19, 10000.0000, NULL, 'g'),
(5, 1, 20, 20000.0000, NULL, 'g'),
(6, 1, 21, 0.0000, NULL, 'g'),
(7, 1, 22, 0.0000, NULL, 'g'),
(8, 1, 23, 0.0000, NULL, 'g');

-- --------------------------------------------------------

--
-- Estrutura para tabela `locais_estoque`
--

CREATE TABLE `locais_estoque` (
  `id` int(10) UNSIGNED NOT NULL,
  `nome` varchar(120) NOT NULL,
  `ativo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `locais_estoque`
--

INSERT INTO `locais_estoque` (`id`, `nome`, `ativo`) VALUES
(1, 'Estoque principal', 1);

-- --------------------------------------------------------

--
-- Estrutura para tabela `movimentacoes_estoque`
--

CREATE TABLE `movimentacoes_estoque` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `produto_id` int(10) UNSIGNED NOT NULL,
  `local_id` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `tipo` enum('entrada','consumo','perda','devolucao','transferencia_entrada','transferencia_saida','ajuste') NOT NULL,
  `quantidade_base` decimal(14,4) NOT NULL,
  `unidade_base` varchar(12) NOT NULL,
  `custo_unitario` decimal(14,4) NOT NULL DEFAULT 0.0000,
  `lote` varchar(100) DEFAULT NULL,
  `validade` date DEFAULT NULL,
  `origem_tipo` varchar(40) DEFAULT NULL,
  `origem_id` bigint(20) UNSIGNED DEFAULT NULL,
  `observacoes` text DEFAULT NULL,
  `usuario_id` int(10) UNSIGNED NOT NULL,
  `criado_em` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `movimentacoes_estoque`
--

INSERT INTO `movimentacoes_estoque` (`id`, `produto_id`, `local_id`, `tipo`, `quantidade_base`, `unidade_base`, `custo_unitario`, `lote`, `validade`, `origem_tipo`, `origem_id`, `observacoes`, `usuario_id`, `criado_em`) VALUES
(1, 16, 1, 'entrada', 6000.0000, 'ml', 0.0089, 'OLE-DEMO-01', '2027-09-17', 'compra_demo', 1, 'Entrada de compra demonstrativa.', 6, '2026-11-21 14:16:40'),
(2, 17, 1, 'entrada', 8000.0000, 'g', 0.0095, 'PEN-DEMO-01', '2027-09-17', 'compra_demo', 1, 'Entrada de compra demonstrativa.', 6, '2026-11-21 14:16:40'),
(3, 18, 1, 'entrada', 12000.0000, 'g', 0.0219, 'FRA-DEMO-01', '2027-02-19', 'compra_demo', 1, 'Entrada de compra demonstrativa.', 6, '2026-11-21 14:16:40'),
(4, 19, 1, 'entrada', 10000.0000, 'g', 0.0089, 'FEI-DEMO-01', '2027-07-19', 'compra_demo', 1, 'Entrada de compra demonstrativa.', 6, '2026-11-21 14:16:40'),
(5, 20, 1, 'entrada', 20000.0000, 'g', 0.0072, 'ARZ-DEMO-01', '2027-09-17', 'compra_demo', 1, 'Entrada de compra demonstrativa.', 6, '2026-11-21 14:16:40'),
(8, 18, 1, 'perda', 350.0000, 'g', 0.0219, NULL, NULL, 'demo_perda', NULL, '[DEMO-ROADMAP] Movimento de perda ilustrativo.', 6, '2026-11-21 14:16:40');

-- --------------------------------------------------------

--
-- Estrutura para tabela `parametros_custo`
--

CREATE TABLE `parametros_custo` (
  `id` tinyint(3) UNSIGNED NOT NULL,
  `regra_preco` enum('ultimo','media_ponderada') NOT NULL DEFAULT 'ultimo',
  `regra_id` int(10) UNSIGNED DEFAULT NULL,
  `atualizado_por` int(10) UNSIGNED DEFAULT NULL,
  `atualizado_em` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `parametros_custo`
--

INSERT INTO `parametros_custo` (`id`, `regra_preco`, `regra_id`, `atualizado_por`, `atualizado_em`) VALUES
(1, 'media_ponderada', 2, 6, '2026-11-21 15:25:45');

-- --------------------------------------------------------

--
-- Estrutura para tabela `producao_itens`
--

CREATE TABLE `producao_itens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `producao_id` bigint(20) UNSIGNED NOT NULL,
  `produto_id` int(10) UNSIGNED NOT NULL,
  `quantidade_esperada` decimal(14,4) NOT NULL,
  `quantidade_real` decimal(14,4) DEFAULT NULL,
  `unidade` varchar(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `producoes`
--

CREATE TABLE `producoes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ficha_id` int(10) UNSIGNED NOT NULL,
  `quantidade_planejada` decimal(14,4) NOT NULL,
  `quantidade_produzida` decimal(14,4) DEFAULT NULL,
  `unidade` varchar(12) NOT NULL,
  `turno` varchar(40) DEFAULT NULL,
  `status` enum('planejada','produzida','cancelada') NOT NULL DEFAULT 'planejada',
  `responsavel_id` int(10) UNSIGNED NOT NULL,
  `registrada_em` datetime NOT NULL DEFAULT current_timestamp(),
  `observacoes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `producoes`
--

INSERT INTO `producoes` (`id`, `ficha_id`, `quantidade_planejada`, `quantidade_produzida`, `unidade`, `turno`, `status`, `responsavel_id`, `registrada_em`, `observacoes`) VALUES
(1, 9, 24.0000, 22.0000, 'porcao', 'almoco', 'produzida', 6, '2026-11-21 14:16:40', '[DEMO-ROADMAP] Penne produzido; exemplo de planejado versus realizado.'),
(2, 10, 30.0000, 10000.0000, 'porcao', 'jantar', 'produzida', 6, '2026-11-21 14:16:40', '[DEMO-ROADMAP] Planejamento aguardando confirmacao da producao.');

-- --------------------------------------------------------

--
-- Estrutura para tabela `produtos`
--

CREATE TABLE `produtos` (
  `id` int(10) UNSIGNED NOT NULL,
  `nome` varchar(160) NOT NULL,
  `codigo` varchar(60) DEFAULT NULL,
  `categoria_id` int(10) UNSIGNED DEFAULT NULL,
  `marca` varchar(100) DEFAULT NULL,
  `unidade_compra` varchar(12) NOT NULL,
  `unidade_consumo` varchar(12) NOT NULL,
  `fator_conversao` decimal(12,4) NOT NULL DEFAULT 1.0000,
  `rendimento_percentual` decimal(7,2) NOT NULL DEFAULT 100.00,
  `estoque_minimo` decimal(12,3) DEFAULT 0.000,
  `estoque_maximo` decimal(12,3) DEFAULT NULL,
  `validade_padrao_dias` int(10) UNSIGNED DEFAULT NULL,
  `preco_atual` decimal(12,4) NOT NULL DEFAULT 0.0000,
  `fornecedor_principal_id` int(10) UNSIGNED DEFAULT NULL,
  `ativo` tinyint(1) DEFAULT 1,
  `criado_em` datetime DEFAULT current_timestamp(),
  `atualizado_em` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `produtos`
--

INSERT INTO `produtos` (`id`, `nome`, `codigo`, `categoria_id`, `marca`, `unidade_compra`, `unidade_consumo`, `fator_conversao`, `rendimento_percentual`, `estoque_minimo`, `estoque_maximo`, `validade_padrao_dias`, `preco_atual`, `fornecedor_principal_id`, `ativo`, `criado_em`, `atualizado_em`) VALUES
(1, 'Sal refinado', 'DEMO-ING-012', 4, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 0.500, NULL, NULL, 3.5000, 2, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(2, 'Óleo de soja', 'DEMO-ING-011', 4, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 1.000, NULL, NULL, 8.9000, 2, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(3, 'Molho de tomate', 'DEMO-ING-006', 4, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 2.000, NULL, NULL, 12.0000, 2, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(4, 'Macarrão penne', 'DEMO-ING-005', 4, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 2.000, NULL, NULL, 9.5000, 2, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(5, 'Feijão carioca', 'DEMO-ING-002', 4, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 3.000, NULL, NULL, 8.9000, 2, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(6, 'Arroz agulhinha', 'DEMO-ING-001', 4, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 5.000, NULL, NULL, 7.2000, 2, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(7, 'Carne bovina moída', 'DEMO-ING-004', 1, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 3.000, NULL, NULL, 36.9000, 3, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(8, 'Peito de frango', 'DEMO-ING-003', 1, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 4.000, NULL, NULL, 21.9000, 3, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(9, 'Alho', 'DEMO-ING-013', 2, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 0.300, NULL, NULL, 28.0000, 4, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(10, 'Cenoura', 'DEMO-ING-010', 2, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 1.000, NULL, NULL, 6.9000, 4, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(11, 'Alface crespa', 'DEMO-ING-009', 2, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 1.000, NULL, NULL, 10.5000, 4, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(12, 'Cebola', 'DEMO-ING-008', 2, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 1.500, NULL, NULL, 6.0000, 4, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(13, 'Tomate', 'DEMO-ING-007', 2, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 2.000, NULL, NULL, 8.5000, 4, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(14, 'Creme de leite', 'DEMO-ING-015', 3, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 1.000, NULL, NULL, 13.5000, 5, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(15, 'Queijo muçarela', 'DEMO-ING-014', 3, 'Linha demonstração', 'kg', 'kg', 1.0000, 100.00, 1.000, NULL, NULL, 34.9000, 5, 1, '2026-11-20 15:12:57', '2026-11-20 15:12:57'),
(16, 'Oleo de soja', 'DEMO-RM-P008', 4, 'Cozinha Pratica', 'l', 'ml', 1000.0000, 100.00, 1000.000, 5000.000, 365, 8.9000, 9, 1, '2026-11-21 14:16:40', '2026-11-21 14:16:40'),
(17, 'Macarrao penne', 'DEMO-RM-P006', 4, 'Casa Italiana', 'kg', 'g', 1000.0000, 100.00, 2000.000, 10000.000, 365, 9.5000, 9, 1, '2026-11-21 14:16:40', '2026-11-21 14:16:40'),
(18, 'Peito de frango', 'DEMO-RM-P003', 1, 'Granja Boa Mesa', 'kg', 'g', 1000.0000, 82.00, 4000.000, 20000.000, 180, 21.9000, 9, 1, '2026-11-21 14:16:40', '2026-11-21 14:16:40'),
(19, 'Feijao carioca', 'DEMO-RM-P002', 4, 'Sabor do Campo', 'kg', 'g', 1000.0000, 100.00, 3000.000, 15000.000, 365, 8.9000, 9, 1, '2026-11-21 14:16:40', '2026-11-21 14:16:40'),
(20, 'Arroz agulhinha tipo 1', 'DEMO-RM-P001', 4, 'Sabor do Campo', 'kg', 'g', 1000.0000, 100.00, 5000.000, 25000.000, 365, 7.2000, 9, 1, '2026-11-21 14:16:40', '2026-11-21 14:16:40'),
(21, 'Cebola', 'DEMO-RM-P005', 2, 'Horta Viva', 'kg', 'g', 1000.0000, 90.00, 1500.000, 8000.000, 20, 6.0000, 10, 1, '2026-11-21 14:16:40', '2026-11-21 14:16:40'),
(22, 'Tomate italiano', 'DEMO-RM-P004', 2, 'Horta Viva', 'kg', 'g', 1000.0000, 92.00, 2000.000, 10000.000, 7, 8.5000, 10, 1, '2026-11-21 14:16:40', '2026-11-21 14:16:40'),
(23, 'Queijo mussarela', 'DEMO-RM-P007', 8, 'Bom Leite', 'kg', 'g', 1000.0000, 100.00, 1000.000, 5000.000, 30, 34.9000, 11, 1, '2026-11-21 14:16:40', '2026-11-21 14:16:40');

-- --------------------------------------------------------

--
-- Estrutura para tabela `produto_fornecedores`
--

CREATE TABLE `produto_fornecedores` (
  `produto_id` int(10) UNSIGNED NOT NULL,
  `fornecedor_id` int(10) UNSIGNED NOT NULL,
  `codigo_fornecedor` varchar(80) DEFAULT NULL,
  `preferencial` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `produto_fornecedores`
--

INSERT INTO `produto_fornecedores` (`produto_id`, `fornecedor_id`, `codigo_fornecedor`, `preferencial`) VALUES
(1, 2, NULL, 1),
(2, 2, NULL, 1),
(3, 2, NULL, 1),
(4, 2, NULL, 1),
(5, 2, NULL, 1),
(6, 2, NULL, 1),
(7, 3, NULL, 1),
(8, 3, NULL, 1),
(9, 4, NULL, 1),
(10, 4, NULL, 1),
(11, 4, NULL, 1),
(12, 4, NULL, 1),
(13, 4, NULL, 1),
(14, 5, NULL, 1),
(15, 5, NULL, 1),
(16, 9, NULL, 1),
(17, 9, NULL, 1),
(18, 9, NULL, 1),
(19, 9, NULL, 1),
(20, 9, NULL, 1),
(21, 10, NULL, 1),
(22, 10, NULL, 1),
(23, 11, NULL, 1);

-- --------------------------------------------------------

--
-- Estrutura para tabela `quebras`
--

CREATE TABLE `quebras` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item` varchar(160) NOT NULL,
  `categoria` varchar(80) NOT NULL,
  `quantidade` decimal(12,3) NOT NULL,
  `unidade` varchar(12) NOT NULL DEFAULT 'un',
  `local_descricao` varchar(100) DEFAULT NULL,
  `motivo` varchar(160) NOT NULL,
  `valor_estimado` decimal(12,2) NOT NULL DEFAULT 0.00,
  `data_registro` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(10) UNSIGNED NOT NULL,
  `reposicao_necessaria` tinyint(1) NOT NULL DEFAULT 0,
  `observacoes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `quebras`
--

INSERT INTO `quebras` (`id`, `item`, `categoria`, `quantidade`, `unidade`, `local_descricao`, `motivo`, `valor_estimado`, `data_registro`, `usuario_id`, `reposicao_necessaria`, `observacoes`) VALUES
(1, 'Prato raso branco', 'Utensilio', 2.000, 'un', 'Cozinha', 'Queda durante a lavagem', 36.00, '2026-11-21 14:16:40', 6, 1, '[DEMO-ROADMAP] Quebra patrimonial demonstrativa.'),
(2, 'Jarra de vidro', 'Utensilio', 1.000, 'un', 'Salao', 'Trinca identificada no fechamento', 28.00, '2026-11-21 14:16:40', 6, 1, '[DEMO-ROADMAP] Reposicao pendente para teste.');

-- --------------------------------------------------------

--
-- Estrutura para tabela `regras_custo`
--

CREATE TABLE `regras_custo` (
  `id` int(10) UNSIGNED NOT NULL,
  `nome` varchar(80) NOT NULL,
  `metodo` enum('ultimo','media_ponderada') NOT NULL,
  `sistema` tinyint(1) NOT NULL DEFAULT 0,
  `criado_por` int(10) UNSIGNED DEFAULT NULL,
  `criado_em` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `regras_custo`
--

INSERT INTO `regras_custo` (`id`, `nome`, `metodo`, `sistema`, `criado_por`, `criado_em`) VALUES
(1, 'Ultimo preco efetivo', 'ultimo', 1, NULL, '2026-11-21 14:56:02'),
(2, 'Media ponderada', 'media_ponderada', 1, NULL, '2026-11-21 14:56:02');

-- --------------------------------------------------------

--
-- Estrutura para tabela `relatorios_salvos`
--

CREATE TABLE `relatorios_salvos` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `titulo` varchar(180) NOT NULL,
  `data_inicio` date NOT NULL,
  `data_fim` date NOT NULL,
  `dados` longtext NOT NULL,
  `usuario_id` int(10) UNSIGNED NOT NULL,
  `criado_em` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `relatorios_salvos`
--

INSERT INTO `relatorios_salvos` (`id`, `titulo`, `data_inicio`, `data_fim`, `dados`, `usuario_id`, `criado_em`) VALUES
(1, 'Relatório de gestão', '2026-10-22', '2026-11-20', '{\"from\":\"2026-10-22\",\"to\":\"2026-11-20\",\"summary\":{\"quantidade_registros\":5,\"total_valor\":\"15.68\"},\"byProduct\":[{\"produto_id\":8,\"produto\":\"Peito de frango\",\"ocorrencias\":1,\"valor\":\"8.76\"},{\"produto_id\":13,\"produto\":\"Tomate\",\"ocorrencias\":1,\"valor\":\"2.55\"},{\"produto_id\":4,\"produto\":\"Macarrão penne\",\"ocorrencias\":1,\"valor\":\"1.90\"},{\"produto_id\":11,\"produto\":\"Alface crespa\",\"ocorrencias\":1,\"valor\":\"1.58\"},{\"produto_id\":5,\"produto\":\"Feijão carioca\",\"ocorrencias\":1,\"valor\":\"0.89\"}],\"byReason\":[{\"motivo\":\"Ajuste de porcionamento\",\"ocorrencias\":1,\"valor\":\"8.76\"},{\"motivo\":\"Produto deteriorado\",\"ocorrencias\":1,\"valor\":\"2.55\"},{\"motivo\":\"Excesso de produção\",\"ocorrencias\":1,\"valor\":\"1.90\"},{\"motivo\":\"Folhas impróprias\",\"ocorrencias\":1,\"valor\":\"1.58\"},{\"motivo\":\"Embalagem danificada\",\"ocorrencias\":1,\"valor\":\"0.89\"}],\"byDay\":[{\"dia\":\"2026-11-06\",\"valor\":\"0.89\"},{\"dia\":\"2026-11-11\",\"valor\":\"1.58\"},{\"dia\":\"2026-11-14\",\"valor\":\"1.90\"},{\"dia\":\"2026-11-17\",\"valor\":\"2.55\"},{\"dia\":\"2026-11-19\",\"valor\":\"8.76\"}],\"productsByCategory\":[{\"categoria\":\"Secos\",\"quantidade\":6},{\"categoria\":\"Hortifruti\",\"quantidade\":5},{\"categoria\":\"Carnes\",\"quantidade\":2},{\"categoria\":\"Laticínios\",\"quantidade\":2}],\"suppliersByProducts\":[{\"fornecedor\":\"DEMO | Grãos do Vale\",\"produtos_vinculados\":6},{\"fornecedor\":\"DEMO | Hortifruti Fresco\",\"produtos_vinculados\":5},{\"fornecedor\":\"DEMO | Açougue Central\",\"produtos_vinculados\":2},{\"fornecedor\":\"DEMO | Laticínios Serra\",\"produtos_vinculados\":2},{\"fornecedor\":\"Fornecedor não informado\",\"produtos_vinculados\":0}],\"counts\":{\"produtos\":15,\"fornecedores\":5,\"fichas\":5},\"recipes\":{\"quantidade\":5,\"custo_medio\":31.39199999999999590727384202182292938232421875,\"mais_custosas\":[{\"id\":3,\"nome\":\"Penne à bolonhesa\",\"codigo\":\"DEMO-REC-003\",\"categoria_id\":1,\"tipo\":\"prato principal\",\"rendimento_total\":\"3.400\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"15.000\",\"tamanho_porcao\":\"0.227\",\"modo_preparo\":\"Cozinhe a massa. Prepare o molho com carne moída, tomate, cebola e temperos.\",\"status\":\"aprovada\",\"preco_venda\":\"26.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Carnes\",\"custo_total\":69.4599999999999937472239253111183643341064453125,\"custo_porcao\":4.630666666666666486662506940774619579315185546875},{\"id\":2,\"nome\":\"Frango ao molho de tomate\",\"codigo\":\"DEMO-REC-002\",\"categoria_id\":1,\"tipo\":\"prato principal\",\"rendimento_total\":\"2.700\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"12.000\",\"tamanho_porcao\":\"0.225\",\"modo_preparo\":\"Doure o frango, junte cebola e molho de tomate e cozinhe até atingir o ponto.\",\"status\":\"aprovada\",\"preco_venda\":\"22.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Carnes\",\"custo_total\":50.6099999999999994315658113919198513031005859375,\"custo_porcao\":4.21750000000000024868995751603506505489349365234375},{\"id\":4,\"nome\":\"Salada fresca da estação\",\"codigo\":\"DEMO-REC-004\",\"categoria_id\":2,\"tipo\":\"acompanhamento\",\"rendimento_total\":\"1.550\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"10.000\",\"tamanho_porcao\":\"0.155\",\"modo_preparo\":\"Higienize e corte os vegetais. Tempere próximo ao serviço.\",\"status\":\"aprovada\",\"preco_venda\":\"12.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Hortifruti\",\"custo_total\":15.199999999999999289457264239899814128875732421875,\"custo_porcao\":1.520000000000000017763568394002504646778106689453125},{\"id\":1,\"nome\":\"Arroz branco da casa\",\"codigo\":\"DEMO-REC-001\",\"categoria_id\":4,\"tipo\":\"acompanhamento\",\"rendimento_total\":\"3.200\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"16.000\",\"tamanho_porcao\":\"0.200\",\"modo_preparo\":\"Refogue cebola e alho, acrescente o arroz e cozinhe até ficar macio.\",\"status\":\"aprovada\",\"preco_venda\":\"7.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Secos\",\"custo_total\":12.5800000000000000710542735760100185871124267578125,\"custo_porcao\":0.78625000000000000444089209850062616169452667236328125},{\"id\":5,\"nome\":\"Feijão caseiro\",\"codigo\":\"DEMO-REC-005\",\"categoria_id\":4,\"tipo\":\"acompanhamento\",\"rendimento_total\":\"2.500\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"12.000\",\"tamanho_porcao\":\"0.208\",\"modo_preparo\":\"Deixe o feijão de molho, cozinhe e finalize com refogado de alho e cebola.\",\"status\":\"aprovada\",\"preco_venda\":\"9.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Secos\",\"custo_total\":9.1099999999999994315658113919198513031005859375,\"custo_porcao\":0.75916666666666665630458510349853895604610443115234375}]}}', 6, '2026-11-20 17:11:14'),
(2, 'Relatório de gestão1', '2026-11-11', '2026-11-20', '{\"from\":\"2026-11-11\",\"to\":\"2026-11-20\",\"summary\":{\"quantidade_registros\":4,\"total_valor\":\"14.79\"},\"byProduct\":[{\"produto_id\":8,\"produto\":\"Peito de frango\",\"ocorrencias\":1,\"valor\":\"8.76\"},{\"produto_id\":13,\"produto\":\"Tomate\",\"ocorrencias\":1,\"valor\":\"2.55\"},{\"produto_id\":4,\"produto\":\"Macarrão penne\",\"ocorrencias\":1,\"valor\":\"1.90\"},{\"produto_id\":11,\"produto\":\"Alface crespa\",\"ocorrencias\":1,\"valor\":\"1.58\"}],\"byReason\":[{\"motivo\":\"Ajuste de porcionamento\",\"ocorrencias\":1,\"valor\":\"8.76\"},{\"motivo\":\"Produto deteriorado\",\"ocorrencias\":1,\"valor\":\"2.55\"},{\"motivo\":\"Excesso de produção\",\"ocorrencias\":1,\"valor\":\"1.90\"},{\"motivo\":\"Folhas impróprias\",\"ocorrencias\":1,\"valor\":\"1.58\"}],\"byDay\":[{\"dia\":\"2026-11-11\",\"valor\":\"1.58\"},{\"dia\":\"2026-11-14\",\"valor\":\"1.90\"},{\"dia\":\"2026-11-17\",\"valor\":\"2.55\"},{\"dia\":\"2026-11-19\",\"valor\":\"8.76\"}],\"productsByCategory\":[{\"categoria\":\"Secos\",\"quantidade\":6},{\"categoria\":\"Hortifruti\",\"quantidade\":5},{\"categoria\":\"Carnes\",\"quantidade\":2},{\"categoria\":\"Laticínios\",\"quantidade\":2}],\"suppliersByProducts\":[{\"fornecedor\":\"DEMO | Grãos do Vale\",\"produtos_vinculados\":6},{\"fornecedor\":\"DEMO | Hortifruti Fresco\",\"produtos_vinculados\":5},{\"fornecedor\":\"DEMO | Açougue Central\",\"produtos_vinculados\":2},{\"fornecedor\":\"DEMO | Laticínios Serra\",\"produtos_vinculados\":2},{\"fornecedor\":\"Fornecedor não informado\",\"produtos_vinculados\":0}],\"counts\":{\"produtos\":15,\"fornecedores\":5,\"fichas\":5},\"recipes\":{\"quantidade\":5,\"custo_medio\":31.39199999999999590727384202182292938232421875,\"mais_custosas\":[{\"id\":3,\"nome\":\"Penne à bolonhesa\",\"codigo\":\"DEMO-REC-003\",\"categoria_id\":1,\"tipo\":\"prato principal\",\"rendimento_total\":\"3.400\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"15.000\",\"tamanho_porcao\":\"0.227\",\"modo_preparo\":\"Cozinhe a massa. Prepare o molho com carne moída, tomate, cebola e temperos.\",\"status\":\"aprovada\",\"preco_venda\":\"26.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Carnes\",\"custo_total\":69.4599999999999937472239253111183643341064453125,\"custo_porcao\":4.630666666666666486662506940774619579315185546875},{\"id\":2,\"nome\":\"Frango ao molho de tomate\",\"codigo\":\"DEMO-REC-002\",\"categoria_id\":1,\"tipo\":\"prato principal\",\"rendimento_total\":\"2.700\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"12.000\",\"tamanho_porcao\":\"0.225\",\"modo_preparo\":\"Doure o frango, junte cebola e molho de tomate e cozinhe até atingir o ponto.\",\"status\":\"aprovada\",\"preco_venda\":\"22.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Carnes\",\"custo_total\":50.6099999999999994315658113919198513031005859375,\"custo_porcao\":4.21750000000000024868995751603506505489349365234375},{\"id\":4,\"nome\":\"Salada fresca da estação\",\"codigo\":\"DEMO-REC-004\",\"categoria_id\":2,\"tipo\":\"acompanhamento\",\"rendimento_total\":\"1.550\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"10.000\",\"tamanho_porcao\":\"0.155\",\"modo_preparo\":\"Higienize e corte os vegetais. Tempere próximo ao serviço.\",\"status\":\"aprovada\",\"preco_venda\":\"12.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Hortifruti\",\"custo_total\":15.199999999999999289457264239899814128875732421875,\"custo_porcao\":1.520000000000000017763568394002504646778106689453125},{\"id\":1,\"nome\":\"Arroz branco da casa\",\"codigo\":\"DEMO-REC-001\",\"categoria_id\":4,\"tipo\":\"acompanhamento\",\"rendimento_total\":\"3.200\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"16.000\",\"tamanho_porcao\":\"0.200\",\"modo_preparo\":\"Refogue cebola e alho, acrescente o arroz e cozinhe até ficar macio.\",\"status\":\"aprovada\",\"preco_venda\":\"7.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Secos\",\"custo_total\":12.5800000000000000710542735760100185871124267578125,\"custo_porcao\":0.78625000000000000444089209850062616169452667236328125},{\"id\":5,\"nome\":\"Feijão caseiro\",\"codigo\":\"DEMO-REC-005\",\"categoria_id\":4,\"tipo\":\"acompanhamento\",\"rendimento_total\":\"2.500\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"12.000\",\"tamanho_porcao\":\"0.208\",\"modo_preparo\":\"Deixe o feijão de molho, cozinhe e finalize com refogado de alho e cebola.\",\"status\":\"aprovada\",\"preco_venda\":\"9.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Secos\",\"custo_total\":9.1099999999999994315658113919198513031005859375,\"custo_porcao\":0.75916666666666665630458510349853895604610443115234375}]}}', 6, '2026-11-20 17:11:21'),
(3, 'Relatório de gestão3', '2026-11-15', '2026-11-20', '{\"from\":\"2026-11-15\",\"to\":\"2026-11-20\",\"summary\":{\"quantidade_registros\":2,\"total_valor\":\"11.31\"},\"byProduct\":[{\"produto_id\":8,\"produto\":\"Peito de frango\",\"ocorrencias\":1,\"valor\":\"8.76\"},{\"produto_id\":13,\"produto\":\"Tomate\",\"ocorrencias\":1,\"valor\":\"2.55\"}],\"byReason\":[{\"motivo\":\"Ajuste de porcionamento\",\"ocorrencias\":1,\"valor\":\"8.76\"},{\"motivo\":\"Produto deteriorado\",\"ocorrencias\":1,\"valor\":\"2.55\"}],\"byDay\":[{\"dia\":\"2026-11-17\",\"valor\":\"2.55\"},{\"dia\":\"2026-11-19\",\"valor\":\"8.76\"}],\"productsByCategory\":[{\"categoria\":\"Secos\",\"quantidade\":6},{\"categoria\":\"Hortifruti\",\"quantidade\":5},{\"categoria\":\"Carnes\",\"quantidade\":2},{\"categoria\":\"Laticínios\",\"quantidade\":2}],\"suppliersByProducts\":[{\"fornecedor\":\"DEMO | Grãos do Vale\",\"produtos_vinculados\":6},{\"fornecedor\":\"DEMO | Hortifruti Fresco\",\"produtos_vinculados\":5},{\"fornecedor\":\"DEMO | Açougue Central\",\"produtos_vinculados\":2},{\"fornecedor\":\"DEMO | Laticínios Serra\",\"produtos_vinculados\":2},{\"fornecedor\":\"Fornecedor não informado\",\"produtos_vinculados\":0}],\"counts\":{\"produtos\":15,\"fornecedores\":5,\"fichas\":5},\"recipes\":{\"quantidade\":5,\"custo_medio\":31.39199999999999590727384202182292938232421875,\"mais_custosas\":[{\"id\":3,\"nome\":\"Penne à bolonhesa\",\"codigo\":\"DEMO-REC-003\",\"categoria_id\":1,\"tipo\":\"prato principal\",\"rendimento_total\":\"3.400\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"15.000\",\"tamanho_porcao\":\"0.227\",\"modo_preparo\":\"Cozinhe a massa. Prepare o molho com carne moída, tomate, cebola e temperos.\",\"status\":\"aprovada\",\"preco_venda\":\"26.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Carnes\",\"custo_total\":69.4599999999999937472239253111183643341064453125,\"custo_porcao\":4.630666666666666486662506940774619579315185546875},{\"id\":2,\"nome\":\"Frango ao molho de tomate\",\"codigo\":\"DEMO-REC-002\",\"categoria_id\":1,\"tipo\":\"prato principal\",\"rendimento_total\":\"2.700\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"12.000\",\"tamanho_porcao\":\"0.225\",\"modo_preparo\":\"Doure o frango, junte cebola e molho de tomate e cozinhe até atingir o ponto.\",\"status\":\"aprovada\",\"preco_venda\":\"22.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Carnes\",\"custo_total\":50.6099999999999994315658113919198513031005859375,\"custo_porcao\":4.21750000000000024868995751603506505489349365234375},{\"id\":4,\"nome\":\"Salada fresca da estação\",\"codigo\":\"DEMO-REC-004\",\"categoria_id\":2,\"tipo\":\"acompanhamento\",\"rendimento_total\":\"1.550\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"10.000\",\"tamanho_porcao\":\"0.155\",\"modo_preparo\":\"Higienize e corte os vegetais. Tempere próximo ao serviço.\",\"status\":\"aprovada\",\"preco_venda\":\"12.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Hortifruti\",\"custo_total\":15.199999999999999289457264239899814128875732421875,\"custo_porcao\":1.520000000000000017763568394002504646778106689453125},{\"id\":1,\"nome\":\"Arroz branco da casa\",\"codigo\":\"DEMO-REC-001\",\"categoria_id\":4,\"tipo\":\"acompanhamento\",\"rendimento_total\":\"3.200\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"16.000\",\"tamanho_porcao\":\"0.200\",\"modo_preparo\":\"Refogue cebola e alho, acrescente o arroz e cozinhe até ficar macio.\",\"status\":\"aprovada\",\"preco_venda\":\"7.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Secos\",\"custo_total\":12.5800000000000000710542735760100185871124267578125,\"custo_porcao\":0.78625000000000000444089209850062616169452667236328125},{\"id\":5,\"nome\":\"Feijão caseiro\",\"codigo\":\"DEMO-REC-005\",\"categoria_id\":4,\"tipo\":\"acompanhamento\",\"rendimento_total\":\"2.500\",\"unidade_rendimento\":\"kg\",\"porcoes\":\"12.000\",\"tamanho_porcao\":\"0.208\",\"modo_preparo\":\"Deixe o feijão de molho, cozinhe e finalize com refogado de alho e cebola.\",\"status\":\"aprovada\",\"preco_venda\":\"9.00\",\"versao\":1,\"criado_em\":\"2026-11-20 15:12:57\",\"atualizado_em\":\"2026-11-20 15:12:57\",\"categoria\":\"Secos\",\"custo_total\":9.1099999999999994315658113919198513031005859375,\"custo_porcao\":0.75916666666666665630458510349853895604610443115234375}]}}', 6, '2026-11-20 17:11:28');

-- --------------------------------------------------------

--
-- Estrutura para tabela `unidades_medida`
--

CREATE TABLE `unidades_medida` (
  `codigo` varchar(12) NOT NULL,
  `nome` varchar(40) NOT NULL,
  `ordem` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `unidades_medida`
--

INSERT INTO `unidades_medida` (`codigo`, `nome`, `ordem`) VALUES
('cx', 'Caixa', 6),
('g', 'Grama', 2),
('kg', 'Quilograma', 1),
('l', 'Litro', 3),
('ml', 'Mililitro', 4),
('pct', 'Pacote', 7),
('porcao', 'Porção', 8),
('un', 'Unidade', 5);

-- --------------------------------------------------------

--
-- Estrutura para tabela `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(10) UNSIGNED NOT NULL,
  `nome` varchar(120) NOT NULL,
  `email` varchar(160) NOT NULL,
  `senha_hash` varchar(255) NOT NULL,
  `perfil` enum('admin','gestor','cozinha','compras','operacional') NOT NULL DEFAULT 'operacional',
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  `criado_em` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `usuarios`
--

INSERT INTO `usuarios` (`id`, `nome`, `email`, `senha_hash`, `perfil`, `ativo`, `criado_em`) VALUES
(6, 'Administrador', 'madaraeobixo@gmail.com', '$2y$10$2Bf820PJ2KzKaMF85B4Y9e23vYIMyuQir/.nud.eMVZxjoaWKcCba', 'admin', 1, '2026-11-20 14:24:45');

--
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `auditoria`
--
ALTER TABLE `auditoria`
  ADD PRIMARY KEY (`id`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Índices de tabela `buffet_registros`
--
ALTER TABLE `buffet_registros`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ficha_id` (`ficha_id`),
  ADD KEY `produto_id` (`produto_id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `data_operacao` (`data_operacao`);

--
-- Índices de tabela `categorias_produto`
--
ALTER TABLE `categorias_produto`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nome` (`nome`);

--
-- Índices de tabela `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fornecedor_id` (`fornecedor_id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `data_compra` (`data_compra`),
  ADD KEY `status` (`status`);

--
-- Índices de tabela `compra_itens`
--
ALTER TABLE `compra_itens`
  ADD PRIMARY KEY (`id`),
  ADD KEY `compra_id` (`compra_id`),
  ADD KEY `produto_id` (`produto_id`);

--
-- Índices de tabela `desperdicios`
--
ALTER TABLE `desperdicios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `client_id` (`client_id`),
  ADD KEY `produto_id` (`produto_id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `data_registro` (`data_registro`);

--
-- Índices de tabela `fichas_tecnicas`
--
ALTER TABLE `fichas_tecnicas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `categoria_id` (`categoria_id`),
  ADD KEY `fk_fichas_autor` (`autor_id`),
  ADD KEY `fk_fichas_aprovador` (`aprovada_por`);

--
-- Índices de tabela `fichas_tecnicas_versoes`
--
ALTER TABLE `fichas_tecnicas_versoes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ficha_id` (`ficha_id`,`versao`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Índices de tabela `ficha_tecnica_itens`
--
ALTER TABLE `ficha_tecnica_itens`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ficha_id` (`ficha_id`),
  ADD KEY `produto_id` (`produto_id`),
  ADD KEY `fk_ficha_item_componente` (`ficha_componente_id`);

--
-- Índices de tabela `fornecedores`
--
ALTER TABLE `fornecedores`
  ADD PRIMARY KEY (`id`);

--
-- Índices de tabela `historico_precos`
--
ALTER TABLE `historico_precos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fornecedor_id` (`fornecedor_id`),
  ADD KEY `compra_item_id` (`compra_item_id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `produto_id` (`produto_id`,`registrado_em`);

--
-- Índices de tabela `inventarios`
--
ALTER TABLE `inventarios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `local_id` (`local_id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `aprovado_por` (`aprovado_por`);

--
-- Índices de tabela `inventario_itens`
--
ALTER TABLE `inventario_itens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `inventario_id` (`inventario_id`,`produto_id`),
  ADD KEY `produto_id` (`produto_id`);

--
-- Índices de tabela `locais_estoque`
--
ALTER TABLE `locais_estoque`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nome` (`nome`);

--
-- Índices de tabela `movimentacoes_estoque`
--
ALTER TABLE `movimentacoes_estoque`
  ADD PRIMARY KEY (`id`),
  ADD KEY `local_id` (`local_id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `produto_id` (`produto_id`,`local_id`,`criado_em`),
  ADD KEY `validade` (`validade`);

--
-- Índices de tabela `parametros_custo`
--
ALTER TABLE `parametros_custo`
  ADD PRIMARY KEY (`id`),
  ADD KEY `atualizado_por` (`atualizado_por`),
  ADD KEY `fk_parametros_custo_regra` (`regra_id`);

--
-- Índices de tabela `producao_itens`
--
ALTER TABLE `producao_itens`
  ADD PRIMARY KEY (`id`),
  ADD KEY `producao_id` (`producao_id`),
  ADD KEY `produto_id` (`produto_id`);

--
-- Índices de tabela `producoes`
--
ALTER TABLE `producoes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ficha_id` (`ficha_id`),
  ADD KEY `responsavel_id` (`responsavel_id`),
  ADD KEY `registrada_em` (`registrada_em`);

--
-- Índices de tabela `produtos`
--
ALTER TABLE `produtos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `categoria_id` (`categoria_id`),
  ADD KEY `fornecedor_principal_id` (`fornecedor_principal_id`),
  ADD KEY `nome` (`nome`);

--
-- Índices de tabela `produto_fornecedores`
--
ALTER TABLE `produto_fornecedores`
  ADD PRIMARY KEY (`produto_id`,`fornecedor_id`),
  ADD KEY `fornecedor_id` (`fornecedor_id`);

--
-- Índices de tabela `quebras`
--
ALTER TABLE `quebras`
  ADD PRIMARY KEY (`id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `data_registro` (`data_registro`);

--
-- Índices de tabela `regras_custo`
--
ALTER TABLE `regras_custo`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nome` (`nome`),
  ADD KEY `criado_por` (`criado_por`);

--
-- Índices de tabela `relatorios_salvos`
--
ALTER TABLE `relatorios_salvos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_relatorios_salvos_usuario` (`usuario_id`),
  ADD KEY `idx_relatorios_salvos_criado_em` (`criado_em`);

--
-- Índices de tabela `unidades_medida`
--
ALTER TABLE `unidades_medida`
  ADD PRIMARY KEY (`codigo`);

--
-- Índices de tabela `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT para tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `auditoria`
--
ALTER TABLE `auditoria`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de tabela `buffet_registros`
--
ALTER TABLE `buffet_registros`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de tabela `categorias_produto`
--
ALTER TABLE `categorias_produto`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de tabela `compras`
--
ALTER TABLE `compras`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `compra_itens`
--
ALTER TABLE `compra_itens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de tabela `desperdicios`
--
ALTER TABLE `desperdicios`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de tabela `fichas_tecnicas`
--
ALTER TABLE `fichas_tecnicas`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de tabela `fichas_tecnicas_versoes`
--
ALTER TABLE `fichas_tecnicas_versoes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `ficha_tecnica_itens`
--
ALTER TABLE `ficha_tecnica_itens`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT de tabela `fornecedores`
--
ALTER TABLE `fornecedores`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de tabela `historico_precos`
--
ALTER TABLE `historico_precos`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT de tabela `inventarios`
--
ALTER TABLE `inventarios`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `inventario_itens`
--
ALTER TABLE `inventario_itens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de tabela `locais_estoque`
--
ALTER TABLE `locais_estoque`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `movimentacoes_estoque`
--
ALTER TABLE `movimentacoes_estoque`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de tabela `producao_itens`
--
ALTER TABLE `producao_itens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `producoes`
--
ALTER TABLE `producoes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de tabela `produtos`
--
ALTER TABLE `produtos`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT de tabela `quebras`
--
ALTER TABLE `quebras`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de tabela `regras_custo`
--
ALTER TABLE `regras_custo`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de tabela `relatorios_salvos`
--
ALTER TABLE `relatorios_salvos`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de tabela `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Restrições para tabelas despejadas
--

--
-- Restrições para tabelas `auditoria`
--
ALTER TABLE `auditoria`
  ADD CONSTRAINT `auditoria_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `buffet_registros`
--
ALTER TABLE `buffet_registros`
  ADD CONSTRAINT `buffet_registros_ibfk_1` FOREIGN KEY (`ficha_id`) REFERENCES `fichas_tecnicas` (`id`),
  ADD CONSTRAINT `buffet_registros_ibfk_2` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`),
  ADD CONSTRAINT `buffet_registros_ibfk_3` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `compras`
--
ALTER TABLE `compras`
  ADD CONSTRAINT `compras_ibfk_1` FOREIGN KEY (`fornecedor_id`) REFERENCES `fornecedores` (`id`),
  ADD CONSTRAINT `compras_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `compra_itens`
--
ALTER TABLE `compra_itens`
  ADD CONSTRAINT `compra_itens_ibfk_1` FOREIGN KEY (`compra_id`) REFERENCES `compras` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `compra_itens_ibfk_2` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`);

--
-- Restrições para tabelas `desperdicios`
--
ALTER TABLE `desperdicios`
  ADD CONSTRAINT `desperdicios_ibfk_1` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`),
  ADD CONSTRAINT `desperdicios_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `fichas_tecnicas`
--
ALTER TABLE `fichas_tecnicas`
  ADD CONSTRAINT `fichas_tecnicas_ibfk_1` FOREIGN KEY (`categoria_id`) REFERENCES `categorias_produto` (`id`),
  ADD CONSTRAINT `fk_fichas_aprovador` FOREIGN KEY (`aprovada_por`) REFERENCES `usuarios` (`id`),
  ADD CONSTRAINT `fk_fichas_autor` FOREIGN KEY (`autor_id`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `fichas_tecnicas_versoes`
--
ALTER TABLE `fichas_tecnicas_versoes`
  ADD CONSTRAINT `fichas_tecnicas_versoes_ibfk_1` FOREIGN KEY (`ficha_id`) REFERENCES `fichas_tecnicas` (`id`),
  ADD CONSTRAINT `fichas_tecnicas_versoes_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `ficha_tecnica_itens`
--
ALTER TABLE `ficha_tecnica_itens`
  ADD CONSTRAINT `ficha_tecnica_itens_ibfk_1` FOREIGN KEY (`ficha_id`) REFERENCES `fichas_tecnicas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `ficha_tecnica_itens_ibfk_2` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`),
  ADD CONSTRAINT `fk_ficha_item_componente` FOREIGN KEY (`ficha_componente_id`) REFERENCES `fichas_tecnicas` (`id`);

--
-- Restrições para tabelas `historico_precos`
--
ALTER TABLE `historico_precos`
  ADD CONSTRAINT `historico_precos_ibfk_1` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`),
  ADD CONSTRAINT `historico_precos_ibfk_2` FOREIGN KEY (`fornecedor_id`) REFERENCES `fornecedores` (`id`),
  ADD CONSTRAINT `historico_precos_ibfk_3` FOREIGN KEY (`compra_item_id`) REFERENCES `compra_itens` (`id`),
  ADD CONSTRAINT `historico_precos_ibfk_4` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `inventarios`
--
ALTER TABLE `inventarios`
  ADD CONSTRAINT `inventarios_ibfk_1` FOREIGN KEY (`local_id`) REFERENCES `locais_estoque` (`id`),
  ADD CONSTRAINT `inventarios_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`),
  ADD CONSTRAINT `inventarios_ibfk_3` FOREIGN KEY (`aprovado_por`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `inventario_itens`
--
ALTER TABLE `inventario_itens`
  ADD CONSTRAINT `inventario_itens_ibfk_1` FOREIGN KEY (`inventario_id`) REFERENCES `inventarios` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `inventario_itens_ibfk_2` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`);

--
-- Restrições para tabelas `movimentacoes_estoque`
--
ALTER TABLE `movimentacoes_estoque`
  ADD CONSTRAINT `movimentacoes_estoque_ibfk_1` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`),
  ADD CONSTRAINT `movimentacoes_estoque_ibfk_2` FOREIGN KEY (`local_id`) REFERENCES `locais_estoque` (`id`),
  ADD CONSTRAINT `movimentacoes_estoque_ibfk_3` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `parametros_custo`
--
ALTER TABLE `parametros_custo`
  ADD CONSTRAINT `fk_parametros_custo_regra` FOREIGN KEY (`regra_id`) REFERENCES `regras_custo` (`id`),
  ADD CONSTRAINT `parametros_custo_ibfk_1` FOREIGN KEY (`atualizado_por`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `producao_itens`
--
ALTER TABLE `producao_itens`
  ADD CONSTRAINT `producao_itens_ibfk_1` FOREIGN KEY (`producao_id`) REFERENCES `producoes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `producao_itens_ibfk_2` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`);

--
-- Restrições para tabelas `producoes`
--
ALTER TABLE `producoes`
  ADD CONSTRAINT `producoes_ibfk_1` FOREIGN KEY (`ficha_id`) REFERENCES `fichas_tecnicas` (`id`),
  ADD CONSTRAINT `producoes_ibfk_2` FOREIGN KEY (`responsavel_id`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `produtos`
--
ALTER TABLE `produtos`
  ADD CONSTRAINT `produtos_ibfk_1` FOREIGN KEY (`categoria_id`) REFERENCES `categorias_produto` (`id`),
  ADD CONSTRAINT `produtos_ibfk_2` FOREIGN KEY (`fornecedor_principal_id`) REFERENCES `fornecedores` (`id`);

--
-- Restrições para tabelas `produto_fornecedores`
--
ALTER TABLE `produto_fornecedores`
  ADD CONSTRAINT `produto_fornecedores_ibfk_1` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`),
  ADD CONSTRAINT `produto_fornecedores_ibfk_2` FOREIGN KEY (`fornecedor_id`) REFERENCES `fornecedores` (`id`);

--
-- Restrições para tabelas `quebras`
--
ALTER TABLE `quebras`
  ADD CONSTRAINT `quebras_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `regras_custo`
--
ALTER TABLE `regras_custo`
  ADD CONSTRAINT `regras_custo_ibfk_1` FOREIGN KEY (`criado_por`) REFERENCES `usuarios` (`id`);

--
-- Restrições para tabelas `relatorios_salvos`
--
ALTER TABLE `relatorios_salvos`
  ADD CONSTRAINT `fk_relatorios_salvos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
