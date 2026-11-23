# Roadmap de implementações futuras — Gestão Restaurante

Este documento transforma as necessidades ainda não implementadas do MVP em uma sequência de trabalho. Ele complementa o [documento-base do projeto](../PROJETO_PWA_GESTAO_RESTAURANTE.md), sem substituir as regras que ainda precisam ser confirmadas com o restaurante.

## Situação atual — revisão de 21/11/2026

O ciclo inicial deste roadmap foi implementado de forma provisória: conversões básicas kg/g e l/ml, histórico de preços e regra configurável (último preço ou média ponderada), fichas versionáveis/aprováveis com sub-receitas e prevenção de ciclos, compras/recebimento, movimentos de estoque, inventário com aprovação, produção, buffet/café, quebras, relatórios operacionais, perfis de acesso e fila local de desperdícios offline. Os detalhes de publicação e migração estão no [README](./README.md).

**Não considerar os custos ou saldos como homologados para operação real ainda.** A planilha Excel e a validação das regras do restaurante ainda não foram fornecidas. A baixa automática de ingredientes na produção está deliberadamente desativada; a fila offline cobre apenas desperdícios no mesmo navegador/dispositivo; controle por lote/validade está gravado na entrada, mas ainda requer telas de consulta/alerta; comparação entre fornecedores, upload de imagens, estornos auditáveis e paginação integral das listas seguem como evolução necessária.

Para bancos existentes, primeiro é necessária a migração anterior do histórico (`atualizar_relatorios.sql`, caso ainda não tenha sido aplicada) e depois `roadmap_migracao.sql`, uma única vez. Sempre fazer backup antes.

## Princípios para as próximas etapas

- Validar regras e cálculos com planilhas e pessoas que executam a operação antes de automatizá-los.
- Não substituir nem apagar dados operacionais durante atualizações. Usar migrações incrementais e backups antes de cada publicação.
- Guardar origem, data, usuário e valores relevantes nos movimentos; custos históricos não devem mudar retroativamente quando um preço novo for cadastrado.
- Usar pesquisas e paginação no servidor para listas grandes. Não carregar o banco inteiro no navegador.
- Exibir unidades de forma explícita. Não somar quantidades de kg, litros e unidades como se fossem equivalentes.
- Manter o sistema publicável no cPanel e preservar o `config.php` do ambiente durante a atualização dos arquivos.

## Fase 0 — Descoberta e validação dos dados reais

**Prioridade: imediata, antes de confiar nos custos.**

Quando os Excel estiverem disponíveis:

1. Reunir cópias de exemplos representativos, removendo dados pessoais desnecessários.
2. Mapear abas, colunas, códigos, unidades, fórmulas, arredondamentos e campos preenchidos manualmente.
3. Escolher uma receita completa e alguns produtos com conversões reais para servir de caso de referência.
4. Confirmar com o responsável se o custo usa último preço, preço médio ou preço de uma compra específica.
5. Registrar como são calculados rendimento, fator de correção, margem, markup, sobras e perdas.
6. Comparar os resultados do sistema com os valores calculados no Excel e obter aprovação do responsável.

**Critério de conclusão:** as fórmulas e unidades do caso de referência estão documentadas e os resultados do sistema coincidem com os resultados validados pelo restaurante.

## Fase 1 — Confiabilidade de produtos, preços e fichas

1. Implementar conversão entre unidade de compra e unidade de consumo (por exemplo, caixa → unidades e kg → g).
2. Registrar histórico de preços por produto, fornecedor, data e origem, sem sobrescrever o histórico anterior.
3. Recalcular custos usando a regra de preço aprovada e sinalizar ingredientes sem preço ou com unidades incompatíveis.
4. Corrigir custo bruto/líquido e fator de correção conforme a fórmula validada.
5. Adicionar versionamento das fichas aprovadas, autor, data e comparação entre versões; arquivar em vez de apagar.
6. Permitir sub-receitas como ingrediente de outra ficha e impedir ciclos (uma ficha não pode depender dela mesma, direta ou indiretamente).
7. Completar os campos confirmados: equipamentos, tempo, validade, armazenamento, observações e imagem, se forem realmente usados.

**Critérios de conclusão:** preço alterado não modifica o custo histórico de lançamentos antigos; ficha e porção calculam corretamente; mudanças aprovadas podem ser auditadas e comparadas.

## Fase 2 — Compras e recebimento

1. Cadastrar uma compra com fornecedor, data, referência/nota e itens.
2. Guardar quantidade, unidade, preço, desconto, frete e acréscimos por item ou documento, conforme regra confirmada.
3. Registrar divergências entre pedido e recebimento, lote e validade quando aplicável.
4. Criar comparação de preço entre fornecedores para o mesmo produto e unidade normalizada.
5. Atualizar o histórico de preços a partir do recebimento, sem alterar compras passadas.

**Critério de conclusão:** cada entrada de compra pode ser rastreada até fornecedor e documento de origem, e o custo unitário efetivo pode ser reconstituído.

## Fase 3 — Estoque e inventário

1. Criar movimentações de entrada, consumo/saída, perda, devolução, transferência e ajuste.
2. Calcular saldo a partir do histórico de movimentos, evitando editar saldo sem trilha de auditoria.
3. Definir se o controle será por produto, local, lote ou validade e como tratar estoque negativo.
4. Implementar contagem de inventário, divergência entre saldo calculado e contado e aprovação de ajustes.
5. Alertar sobre estoque abaixo do mínimo e validade próxima, somente após esses dados serem confiáveis.

**Critério de conclusão:** o saldo pode ser explicado por movimentos; inventário registra contagem, responsável e ajuste aprovado.

## Fase 4 — Produção, buffet, café da manhã e perdas

1. Criar registro de produção planejada versus realizada, turno, responsável e sobra.
2. Decidir se produção baixa estoque automaticamente; se sim, exigir confirmação e permitir estorno rastreável.
3. Criar lançamento operacional rápido para buffet/café da manhã, com preparado, servido/estimado, sobra reaproveitável e descarte.
4. Distinguir desperdício de preparo, excesso de produção, vencimento, qualidade, sobra exposta e quebra patrimonial.
5. Associar o custo vigente no momento do lançamento, com origem do cálculo e sem recalcular perdas passadas.
6. Implementar quebras de utensílios/equipamentos separadas de perdas de alimento.

**Critério de conclusão:** usuário operacional consegue lançar uma perda em poucos passos; relatórios separam alimento, sobra e quebra sem misturar unidades ou categorias.

## Fase 5 — Relatórios e acompanhamento gerencial

1. Expandir relatórios com filtros por período, categoria, etapa, motivo, fornecedor e ficha, quando os dados existirem.
2. Adicionar comparativos temporais e evolução de preço/custo usando o histórico de compras.
3. Incluir estoque, validade, produção, margem, buffet e quebras somente depois de cada módulo gerar dados confiáveis.
4. Permitir exportação CSV compatível com Excel e impressão/PDF; avaliar XLSX/PDF nativo se a operação exigir.
5. Incluir paginação e filtros de servidor no histórico de relatórios conforme seu volume crescer.
6. Exibir no relatório o período, data de geração, filtros usados e responsável, mantendo o snapshot salvo.

**Critério de conclusão:** totais podem ser rastreados até registros de origem e o relatório exportado mantém os filtros e o período utilizados.

## Fase 6 — Usuários, segurança, operação e escala

1. Implementar permissões efetivas por perfil (administrador, gestor, cozinha, compras/estoque e operacional), não apenas o nome do perfil.
2. Vincular usuários a uma unidade quando houver mais de um restaurante/hotel; não antecipar multiunidade sem necessidade confirmada.
3. Revisar autenticação, proteção CSRF, limites de sessão, validação de entrada e mensagens de erro sem detalhes internos.
4. Definir backup automático do banco, retenção e procedimento de restauração testado.
5. Manter HTTPS, proteger arquivos de configuração e remover scripts de instalação após o setup.
6. Evoluir offline primeiro para lançamentos operacionais, com fila local, sincronização e tratamento explícito de conflitos.
7. Fazer teste responsivo nos dispositivos reais usados na cozinha e no estoque.

**Critério de conclusão:** cada perfil só acessa as ações autorizadas, restauração de backup foi comprovada e conflitos de sincronização não sobrescrevem movimentos silenciosamente.

## Melhorias transversais recomendadas

- Paginação também nas listas principais de produtos, fornecedores, fichas e desperdícios; o filtro geral já limita a consulta, mas a navegação das listas deve evoluir junto com o volume.
- Validação consistente no backend para campos obrigatórios, valores positivos, datas e relações com produtos/fornecedores.
- Logs técnicos protegidos e auditoria de alterações de preço, ficha, fornecedor e estoque.
- Testes automatizados das fórmulas de conversão/custo e das movimentações antes de liberar essas regras para uso financeiro.
- Identificador de unidade/estabelecimento nos dados somente quando a operação confirmar necessidade multiunidade.

## Ordem sugerida do próximo ciclo

1. Obter e mapear as planilhas reais.
2. Validar unidades, rendimento e custo de uma receita piloto.
3. Implementar conversões e histórico de preços.
4. Versionar fichas e validar custos com o responsável.
5. Só então iniciar compras e estoque.

Essa ordem reduz o risco de automatizar um cálculo errado ou criar estoque baseado em unidades ainda não padronizadas.

## Rotina de publicação no cPanel

1. Fazer backup do banco antes de qualquer migração.
2. Importar somente o arquivo de migração correspondente; não reimportar `database.sql` em um banco que já contém dados, pois ele recria as tabelas.
3. Extrair o ZIP atualizado substituindo os arquivos do sistema, sem perder o `config.php` específico do servidor.
4. Atualizar a versão do cache do service worker quando houver alterações de frontend.
5. Conferir login, listagens, consultas, cadastros e a função alterada no ambiente publicado.
6. Manter o ZIP com credenciais fora de compartilhamentos públicos.

## Registro de decisões pendentes

Antes de cada módulo, confirmar com o restaurante: política de preço, unidades e conversões, aprovação de fichas, baixa de estoque, tratamento de sobras, campos das compras, locais/turnos e perfis de acesso. As planilhas reais serão a fonte para ajustar nomes, fórmulas e fluxos, sem presumir que este modelo inicial representa exatamente a operação.
