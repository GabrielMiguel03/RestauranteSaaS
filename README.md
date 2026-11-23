# Gestão Restaurante — pacote para cPanel

Este pacote já contém o frontend, backend, banco e configuração do MVP. Foi preparado para ser enviado como um único arquivo ZIP e extraído dentro da pasta do domínio no cPanel.

## Instalação

1. No cPanel, crie o banco MySQL e o usuário com todos os privilégios.
2. Confirme que o arquivo `config.php` deste pacote contém os dados corretos do banco.
3. Envie o arquivo ZIP pelo Gerenciador de Arquivos para `public_html` ou para a pasta do domínio.
4. Use **Extract/Extrair** no ZIP. Os arquivos `index.html`, `api.php` e `.htaccess` devem ficar diretamente na pasta pública do domínio, sem uma pasta extra por fora.
5. No phpMyAdmin, selecione o banco e importe `database.sql`.
6. Acesse `https://seu-dominio/setup.php`, crie o usuário administrador e apague `setup.php` depois da criação.
7. Abra o domínio e faça login.

### Instalar como aplicativo (PWA)

O site pode ser instalado como aplicativo em dispositivos móveis e computadores, sem alterar o backend PHP/MySQL hospedado no cPanel. A instalação requer HTTPS (exceto em localhost).

- **Android:** abra o site em um navegador compatível, toque em **Baixar aplicativo** e confirme **Instalar**. Se o navegador não abrir o prompt, use o menu do Chrome e escolha **Instalar aplicativo** ou **Adicionar à tela inicial**.
- **iPhone/iPad:** abra o endereço no Safari, toque em **Compartilhar**, escolha **Adicionar à Tela de Início** e confirme. O iOS não permite que o site abra o prompt de instalação diretamente.

O aplicativo instalado continua precisando de internet para acessar os dados e a API no cPanel. O modo offline existente só mantém a fila de novos lançamentos de desperdício.

### Atualização do histórico de relatórios

Se o sistema já estiver instalado, importe `atualizar_relatorios.sql` pelo phpMyAdmin antes de usar o salvamento/histórico. Em uma instalação nova, `database.sql` já cria essa tabela.

### Atualização dos módulos do roadmap (banco já existente)

1. Faça um backup do banco pelo phpMyAdmin e guarde o arquivo fora da pasta pública.
2. Importe `roadmap_migracao.sql` **uma única vez** no banco que já contém o MVP e a migração do histórico de relatórios. Ela acrescenta compras, estoque, inventário, produção, buffet, quebras, histórico de preços, versões de fichas e perfis.
3. Não reimporte `database.sql` em um banco com dados: esse arquivo recria tabelas.
4. Extraia o ZIP novo substituindo os arquivos do aplicativo, mas preserve o `config.php` que já está no servidor. Se o gerenciador de arquivos sobrescrever esse arquivo, recoloque nele as credenciais do cPanel antes de acessar o sistema.
5. Faça login novamente. Se o navegador mantiver arquivos antigos, feche/abra a página ou limpe os dados do site para atualizar o PWA.

Em instalação totalmente nova, importe `database.sql` e, em seguida, `roadmap_migracao.sql` antes de criar o primeiro administrador. A migração altera estruturas existentes e não foi projetada para ser executada duas vezes; em caso de importação interrompida, não tente repetir sem verificar quais comandos já foram aplicados.

### Cadastro de regras de custo

Para ativar o cadastro de regras nomeadas, faça backup e importe `atualizar_regras_custo.sql` uma única vez depois de `roadmap_migracao.sql`. Faça isso antes de publicar os arquivos atualizados, pois a tela e a API passam a consultar a tabela `regras_custo`.

Na aplicação, compras e produções têm uma ação **Informações** para consultar os detalhes dos registros. Em **Quebras**, o histórico também permite abrir as informações da ocorrência; o campo de observações pode registrar a pessoa envolvida. A tela **Custos** permite cadastrar regras nomeadas usando um dos métodos disponíveis e selecionar a regra ativa.

No computador, o menu lateral rola independentemente do conteúdo principal. O botão **Sair** fica no cabeçalho, no canto superior direito.

### Popular o sistema com dados de teste

Depois de importar a estrutura e criar pelo menos um usuário ativo, importe `seed_demo_roadmap.sql` no phpMyAdmin. Ele adiciona fornecedores, produtos, fichas (incluindo sub-receita), compra recebida, preços, movimentos, desperdícios, produção, buffet, quebras e um inventário aberto. Os registros são identificados como `DEMO-RM`; importar o arquivo novamente não deve duplicá-los e não apaga os dados existentes. São valores fictícios para teste, não use como custo real.

## Requisitos do cPanel

- PHP 8.0 ou superior;
- extensão PDO MySQL habilitada;
- MySQL ou MariaDB;
- HTTPS necessário para instalação como PWA e recomendado para uso real.

## Conteúdo

- `index.html`, `assets/`, `manifest.json` e `sw.js`: interface e PWA;
- `api.php` e `api/`: backend e conexão com banco;
- `database.sql`: tabelas, índices e dados iniciais;
- `atualizar_relatorios.sql`: migração antiga e isolada do histórico de relatórios;
- `roadmap_migracao.sql`: migração incremental dos novos módulos e perfis, executar uma vez;
- `atualizar_regras_custo.sql`: migração adicional, executar uma vez depois da migração do roadmap;
- `seed_demo_roadmap.sql`: carga demonstrativa dos novos módulos, após a migração e a criação de um usuário ativo;
- `config.php`: configuração real do banco deste ambiente;
- `config.example.php`: modelo sem credenciais;
- `setup.php`: criação do primeiro administrador;
- `.htaccess`: proteção de arquivos sensíveis.

## Segurança

Depois de criar o administrador, apague `setup.php`. Mantenha HTTPS ativo, faça backups do banco e não compartilhe o ZIP publicamente porque ele contém a configuração do banco.

## Regras provisórias e limites

O sistema registra compras, recebimentos, histórico de preços, movimentos e contagens de estoque, produção, buffet/café da manhã, desperdícios e quebras. A regra inicial de custo é o último preço recebido, configurável para média ponderada; confirme a regra e as conversões com o restaurante e com as planilhas antes de usar os valores para decisões financeiras. A confirmação da produção ainda não baixa ingredientes automaticamente, e o inventário usa o local principal. Esses comportamentos são intencionais até validar o fluxo real.

O modo offline enfileira somente novos lançamentos de desperdício no navegador atual; sincronize no mesmo dispositivo e navegador. Não é backup e não substitui conexão ou cópia no servidor. O arquivo ZIP pode conter `config.php`; mantenha-o privado. A migração SQL deve ser feita após backup e não pode ser repetida sem diagnóstico.
