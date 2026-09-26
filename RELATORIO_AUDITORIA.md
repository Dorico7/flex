# Relatório de Auditoria e Correções — GM Flex

## Escopo

Foi revisado o projeto `flex-main` com foco em integridade financeira, histórico de lançamentos, transportadoras, módulo de motoboys, backup/restauração, sincronização offline e compatibilidade do PWA.

## Correções implementadas

### 1. Tarifas históricas de transportadoras

- Adicionados `ml_rate_snapshot` e `sh_rate_snapshot` em `entries`.
- Registros existentes são preenchidos com a tarifa conhecida no momento da migração.
- Novos lançamentos congelam automaticamente as tarifas usadas no lançamento.
- Fechamento, dashboard, rankings, receita por período, CSV e PDFs passaram a calcular usando o snapshot, com fallback seguro para dados legados.
- A alteração de tarifa atual não modifica valores históricos.

### 2. Edição segura de transportadoras

- Adicionada interface para editar nome, tarifa ML e tarifa SH.
- Validação de nome vazio, duplicidade, valores inválidos e taxas negativas.
- Renomeação feita por função SQL transacional, preservando `entries` e referências do módulo de motoboys.
- Conflitos de lançamentos são detectados antes da atualização.
- Suporte à fila offline e auditoria local.
- A remoção/reativação existente foi preservada.

### 3. Diárias históricas de motoristas

- Adicionado `valor_diaria_snapshot` aos lançamentos de `motoboy_entries`.
- Lançamentos novos e reatribuições de motorista capturam o valor vigente.
- Totais, detalhamento e telas de fechamento usam o snapshot, com fallback compatível.
- O cadastro do motorista pode ser alterado sem reescrever fechamentos antigos.

### 4. Backup e restauração

- Backup agora inclui todas as tarifas, inclusive estado ativo/inativo, além dos snapshots presentes nos lançamentos.
- Restauração aceita o formato novo e permanece compatível com backups legados baseados em `customRates`.
- A restauração local é seguida de tentativa de sincronização remota com tratamento de erro.
- Foi evitada sincronização duplicada das configurações durante o restore.

### 5. Operação offline/PWA

- O cache inicial do service worker passou a incluir o repositório e o módulo de motoboys.
- O repositório mantém fallback de escrita para bancos antigos que ainda não possuem as colunas de snapshot, evitando quebra imediata enquanto a migration não é aplicada.

## Arquivos principais alterados

- `js/app.js`
- `js/repositories/dataRepository.js`
- `js/repositories/motoboysRepository.js`
- `js/modules/motoboysModule.js`
- `js/database/migrations.sql`
- `js/database/motoboys_module.sql`
- `css/styles.css`
- `css/responsive.css`
- `service-worker.js`
- `SUPABASE_SETUP.md`

## Validações executadas

- `node --check` em todos os JavaScripts próprios: **OK**.
- Varredura de cálculos restantes com tarifas atuais: somente referências legítimas de exibição/sincronização permaneceram; os cálculos financeiros foram migrados para snapshots.
- Conferência de presença e integração de snapshots, RPC de renomeação, backup e fila offline: **OK**.
- Conferência de existência e tamanho dos arquivos alterados: **OK**.
- Comparação com o ZIP original: alterações limitadas ao escopo funcional e de documentação descrito acima.

## Implantação do banco

1. Faça backup do banco Supabase.
2. Execute o `js/database/migrations.sql` atualizado.
3. Se o módulo de motoboys estiver habilitado, execute o `js/database/motoboys_module.sql` atualizado.
4. Execute as migrations complementares do módulo já previstas no projeto, na ordem documentada em `SUPABASE_SETUP.md`.
5. Publique os arquivos frontend e faça uma atualização forçada do PWA para renovar o service worker.
6. Teste um lançamento novo, alteração de tarifa, edição/renomeação de transportadora, fechamento, exportação e restauração de backup.

> As migrations são aditivas/idempotentes nas colunas e funções adicionadas. A execução em produção deve seguir o procedimento de backup e validação do ambiente do cliente.
