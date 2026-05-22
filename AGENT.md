# AGENT.md

Projeto: Challenge Clyvo — Database-Advanced

## Objetivo
Documento de orientação para o agente (assistente) responsável por manter, executar e explicar os scripts SQL/PLSQL deste projeto.

## Escopo do agente
- Manter os scripts DDL e PL/SQL para Oracle 11g.
- Fornecer instruções de execução, exemplos de uso e procedimentos de verificação (logs, testes básicos).
- Registrar mudanças de forma minimalista e ajudar a ajustar sequências/erros após execução.

## Mapa rápido de arquivos
- `01_ddl_tabelas.sql`: DDL principal (tabelas, PKs, FKs, constraints) gerado pelo Oracle Data Modeler.
- `02_ddl_logs.sql`: infraestrutura de logs (`log_erros`, `log_erros_seq`, trigger BI).
- `03_procedures_carga.sql`: sequências, `prc_grava_log` (autonomous), e `prc_insere_*` + `prc_concluir_tarefa` (procedures parametrizadas por tabela).
- `04_blocos_anonimos_insercao.sql`: blocos anônimos de exemplo que usam as procedures de carga.
- `05_consultas_joins.sql`: blocos anônimos com joins, GROUP BY e ORDER BY (≥3 consultas demonstrativas).
- `06_consulta_valor_anterior_proximo.sql`: bloco demonstrando `LAG`/`LEAD` (relatório current/previous/next).
- `07_relatorios_cursors.sql`: quatro blocos com cursores explícitos, lógica decisória e sumarização.
- `08_instrucoes_execucao.md`: ordem recomendada de execução e notas (SQL*Plus/SQLcl).

## Requisitos e como o projeto atende ao enunciado
- DDL do Data Modeler: presente em `01_ddl_tabelas.sql`.
- Procedimento de carga por tabela: há uma `prc_insere_<entidade>` por entidade em `03_procedures_carga.sql`.
- Logs centralizados: `prc_grava_log` grava `nome_procedure`, `usuario`, `data_erro`, `codigo_erro`, `mensagem_erro` na tabela `log_erros` (PRAGMA AUTONOMOUS_TRANSACTION).
- Tratamento de exceções: cada bloco/procedure possui `WHEN OTHERS` e pelo menos dois outros handlers (por exemplo `NO_DATA_FOUND`, `VALUE_ERROR`/`DUP_VAL_ON_INDEX`) que chamam `prc_grava_log`.
- Blocos anônimos e relatórios: templates e exemplos incluídos nos arquivos 04–07; LAG/LEAD em `06_...`; 4 relatórios com cursores em `07_...`.

## Como executar (exemplo com SQL*Plus / SQLcl)
1. Conectar no banco Oracle (exemplo):

```sql
sqlplus usuario/senha@host:1521/SID
-- ou com SQLcl
sql sqlcl usuario/senha@host:1521/SID
```

2. Ativar o `DBMS_OUTPUT` (ver saída dos blocos):

```sql
SET SERVEROUTPUT ON SIZE 1000000
```

3. Executar scripts na ordem recomendada (use `@file.sql`):

```sql
@01_ddl_tabelas.sql
@02_ddl_logs.sql
@03_procedures_carga.sql
SET SERVEROUTPUT ON
@04_blocos_anonimos_insercao.sql
@05_consultas_joins.sql
@06_consulta_valor_anterior_proximo.sql
@07_relatorios_cursors.sql
```

Observações:
- Crie o esquema/usuário com privilégios adequados antes de executar (CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER, EXECUTE PROCEDURE).
- Se houver dados existentes, ajuste `START WITH` das sequences para `MAX(id)+1` (ver seção Sequências abaixo).

## Exemplos de chamadas PL/SQL (rápidas)
```sql
-- Inserir um usuário (exemplo)
BEGIN
  prc_insere_usuario(NULL, 'João Silva', 'joao@ex.com', '1990-01-01');
END;
/

-- Inserir pet (exemplo)
BEGIN
  prc_insere_pet(NULL, 'Rex', 4, 'M', 'GRANDE', 'S', 1);
END;
/

-- Concluir tarefa
BEGIN
  prc_concluir_tarefa(1, 2, SYSTIMESTAMP);
END;
/
-- Ver logs
SELECT * FROM log_erros ORDER BY data_erro DESC;
```

Adapte os parâmetros conforme a assinatura das procedures em `03_procedures_carga.sql`.

## Logs e tratamento de erros
- A procedure `prc_grava_log` registra erros com `PRAGMA AUTONOMOUS_TRANSACTION` para garantir persistência mesmo em rollback das transações principais.
- Campos gravados: `id_log`, `nome_procedure`, `usuario`, `data_erro`, `codigo_erro`, `mensagem_erro`.
- Para depurar: consultar `log_erros` e inspecionar `SQLCODE` + `SQLERRM`.

## Sequências
- As sequences são criadas em `03_procedures_carga.sql` (nomes do tipo `seq_<entidade>` e `log_erros_seq`).
- Se estiver importando dados num esquema que já tem registros, ajuste o `START WITH` das sequences ou recrie-as com `START WITH (SELECT NVL(MAX(<PK>),0)+1 FROM <tabela>)` antes de inserir dados.

## Testes e validação
- Passos básicos:
  - Executar `01_ddl_tabelas.sql` e `02_ddl_logs.sql`.
  - Executar `03_procedures_carga.sql` (cria procedures e sequences).
  - Executar o `04_blocos_anonimos_insercao.sql` para popular dados de exemplo; observar `log_erros` caso exceções ocorram.
  - Executar os blocos de relatórios (05–07) para validar saída esperada.
- Verifique se `06_consulta_valor_anterior_proximo.sql` tem pelo menos 5 registros na tabela alvo (o bloco checa e informa quando não há registros suficientes).

## Checklist de conformidade (mapping rápido)
- DDL do Data Modeler: `01_ddl_tabelas.sql` — OK.
- Logs com nome procedure, usuário, data, código e mensagem: `02_ddl_logs.sql` + `03_procedures_carga.sql` (prc_grava_log) — OK.
- Procedures parametrizadas por tabela: `03_procedures_carga.sql` — OK.
- Blocos anônimos + exemplos com joins/GROUP BY/ORDER BY: `04_` e `05_` — OK.
- LAG/LEAD report (≥5 linhas): `06_` (ver pré-condição de linhas) — OK.
- 4 relatórios com cursores e sumarização: `07_` — OK.

## Boas práticas e notas do agente
- Sempre rodar em um schema de desenvolvimento antes de rodar em produção.
- Ajustar `START WITH` das sequences quando necessário.
- Habilitar `SERVEROUTPUT` para ver `DBMS_OUTPUT` dos blocos.
- Ao reportar um erro, copie `SQLCODE`, `SQLERRM` e a linha/stack do bloco para permitir investigação.

## Se quiser que eu faça mais
- Gerar `run_all.sql` que execute os arquivos na ordem correta.
- Ajustar automaticamente as `START WITH` das sequences com base nos max(id) atuais (posso gerar script para isso).
- Gerar a capa em PDF (nomes / RMs) para submissão.

---
Arquivo gerado automaticamente pelo assistente. Para alterações, edite este `AGENT.md` conforme convier.
