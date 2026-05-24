-- run_all.sql
-- Script de automação para executar todos os scripts do projeto na ordem correta

SET SERVEROUTPUT ON SIZE 1000000;

PROMPT ===================================================
PROMPT [1/7] Executando DDL das tabelas (01_ddl_tabelas.sql)...
PROMPT ===================================================
@01_ddl_tabelas.sql

PROMPT ===================================================
PROMPT [2/7] Executando DDL dos logs (02_ddl_logs.sql)...
PROMPT ===================================================
@02_ddl_logs.sql

PROMPT ===================================================
PROMPT [3/7] Criando Procedures e Sequences (03_procedures_carga.sql)...
PROMPT ===================================================
@03_procedures_carga.sql

PROMPT ===================================================
PROMPT [4/7] Inserindo carga de dados inicial (04_blocos_anonimos_insercao.sql)...
PROMPT ===================================================
@04_blocos_anonimos_insercao.sql

PROMPT ===================================================
PROMPT [5/7] Executando consultas de Joins, Group By e Order By (05_consultas_joins.sql)...
PROMPT ===================================================
@05_consultas_joins.sql

PROMPT ===================================================
PROMPT [6/7] Executando Relatório LAG/LEAD (06_consulta_valor_anterior_proximo.sql)...
PROMPT ===================================================
@06_consulta_valor_anterior_proximo.sql

PROMPT ===================================================
PROMPT [7/7] Executando Relatórios com Cursores e Tomada de Decisão (07_relatorios_cursors.sql)...
PROMPT ===================================================
@07_relatorios_cursors.sql

PROMPT ===================================================
PROMPT Processo finalizado com sucesso!
PROMPT ===================================================
