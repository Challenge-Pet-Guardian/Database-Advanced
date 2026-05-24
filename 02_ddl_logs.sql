-- 02_ddl_logs.sql
-- Criação da tabela de logs para registro de erros

CREATE TABLE log_erros (
    id_log         NUMBER(12) NOT NULL,
    nome_procedure VARCHAR2(100) NOT NULL,
    usuario        VARCHAR2(100) NOT NULL,
    data_erro      TIMESTAMP DEFAULT SYSTIMESTAMP,
    codigo_erro    NUMBER,
    mensagem_erro  VARCHAR2(4000)
);

CREATE SEQUENCE log_erros_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE OR REPLACE TRIGGER trg_log_erros_bi
BEFORE INSERT ON log_erros
FOR EACH ROW
BEGIN
    IF :NEW.id_log IS NULL THEN
        SELECT log_erros_seq.NEXTVAL INTO :NEW.id_log FROM DUAL;
    END IF;
END;
/
