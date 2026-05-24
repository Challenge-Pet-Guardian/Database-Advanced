-- 03_procedures_carga.sql
-- Procedures para carga de dados em cada tabela, com tratamento de exceções e registro em log
-- Inclui sequences auxiliares para facilitar geração de PK quando necessário

-- Sequences para PK
BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_pet START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_raca START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_telefone START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_endereco START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_bairro START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_cidade START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_estado START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_clinica START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_veterinario START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_usuario START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_tipo_atend START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_status START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_tarefa START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_atendimento START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN
        RAISE;
    END IF;
END;
/

-- Procedure helper para gravar logs
CREATE OR REPLACE PROCEDURE prc_grava_log(
    p_nome_procedure IN VARCHAR2,
    p_usuario        IN VARCHAR2,
    p_codigo_erro    IN NUMBER,
    p_mensagem_erro  IN VARCHAR2
) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO log_erros (id_log, nome_procedure, usuario, data_erro, codigo_erro, mensagem_erro)
    VALUES (log_erros_seq.NEXTVAL, p_nome_procedure, NVL(p_usuario, USER), SYSTIMESTAMP, p_codigo_erro, p_mensagem_erro);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END prc_grava_log;
/

-- Procedure: inserir pet
CREATE OR REPLACE PROCEDURE prc_insere_pet(
    p_id_pet       IN NUMBER DEFAULT NULL,
    p_nome         IN VARCHAR2,
    p_idade        IN NUMBER,
    p_sexo         IN VARCHAR2,
    p_porte        IN VARCHAR2,
    p_castrado     IN CHAR,
    p_raca_id_raca IN NUMBER
) AS
    v_id NUMBER;
BEGIN
    IF p_id_pet IS NULL THEN
        SELECT seq_pet.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_pet;
    END IF;

    INSERT INTO pet (id_pet, nome, idade, sexo, porte, castrado, raca_id_raca)
    VALUES (v_id, p_nome, p_idade, p_sexo, p_porte, p_castrado, p_raca_id_raca);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_pet', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_pet', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_pet', USER, SQLCODE, SQLERRM);
END prc_insere_pet;
/

-- Procedure: inserir raca
CREATE OR REPLACE PROCEDURE prc_insere_raca(
    p_id_raca IN NUMBER DEFAULT NULL,
    p_nome_raca IN VARCHAR2
) AS
    v_id NUMBER;
BEGIN
    IF p_id_raca IS NULL THEN
        SELECT seq_raca.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_raca;
    END IF;
    INSERT INTO raca (id_raca, nome_raca) VALUES (v_id, p_nome_raca);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_raca', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_raca', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_raca', USER, SQLCODE, SQLERRM);
END prc_insere_raca;
/

-- Procedure: inserir telefone
CREATE OR REPLACE PROCEDURE prc_insere_telefone(
    p_id_telefone IN NUMBER DEFAULT NULL,
    p_num_ddd IN VARCHAR2,
    p_num_tel IN VARCHAR2
) AS
    v_id NUMBER;
BEGIN
    IF p_id_telefone IS NULL THEN
        SELECT seq_telefone.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_telefone;
    END IF;
    INSERT INTO telefone (id_telefone, num_ddd, num_tel) VALUES (v_id, p_num_ddd, p_num_tel);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_telefone', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_telefone', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_telefone', USER, SQLCODE, SQLERRM);
END prc_insere_telefone;
/

-- Procedure: inserir usuario
CREATE OR REPLACE PROCEDURE prc_insere_usuario(
    p_id_usuario IN NUMBER DEFAULT NULL,
    p_nome IN VARCHAR2,
    p_email IN VARCHAR2,
    p_senha IN VARCHAR2,
    p_telefone_id_telefone IN NUMBER
) AS
    v_id NUMBER;
BEGIN
    IF p_id_usuario IS NULL THEN
        SELECT seq_usuario.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_usuario;
    END IF;
    INSERT INTO usuario (id_usuario, nome, email, senha, telefone_id_telefone)
    VALUES (v_id, p_nome, p_email, p_senha, p_telefone_id_telefone);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_usuario', USER, SQLCODE, SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_usuario', USER, SQLCODE, SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_usuario', USER, SQLCODE, SQLERRM);
END prc_insere_usuario;
/

-- Procedure: inserir endereco
CREATE OR REPLACE PROCEDURE prc_insere_endereco(
    p_id_endereco IN NUMBER DEFAULT NULL,
    p_cep IN VARCHAR2,
    p_rua IN VARCHAR2,
    p_numero IN VARCHAR2,
    p_bairro_id_bairro IN NUMBER
) AS
    v_id NUMBER;
BEGIN
    IF p_id_endereco IS NULL THEN
        SELECT seq_endereco.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_endereco;
    END IF;
    INSERT INTO endereco (id_endereco, cep, rua, numero, bairro_id_bairro)
    VALUES (v_id, p_cep, p_rua, p_numero, p_bairro_id_bairro);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_endereco', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_endereco', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_endereco', USER, SQLCODE, SQLERRM);
END prc_insere_endereco;
/

-- Procedure: inserir bairro
CREATE OR REPLACE PROCEDURE prc_insere_bairro(
    p_id_bairro IN NUMBER DEFAULT NULL,
    p_nome_bairro IN VARCHAR2,
    p_cidade_id_cidade IN NUMBER
) AS
    v_id NUMBER;
BEGIN
    IF p_id_bairro IS NULL THEN
        SELECT seq_bairro.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_bairro;
    END IF;
    INSERT INTO bairro (id_bairro, nome_bairro, cidade_id_cidade)
    VALUES (v_id, p_nome_bairro, p_cidade_id_cidade);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_bairro', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_bairro', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_bairro', USER, SQLCODE, SQLERRM);
END prc_insere_bairro;
/

-- Procedure: inserir cidade
CREATE OR REPLACE PROCEDURE prc_insere_cidade(
    p_id_cidade IN NUMBER DEFAULT NULL,
    p_nome_cidade IN VARCHAR2,
    p_estado_id_estado IN NUMBER
) AS
    v_id NUMBER;
BEGIN
    IF p_id_cidade IS NULL THEN
        SELECT seq_cidade.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_cidade;
    END IF;
    INSERT INTO cidade (id_cidade, nome_cidade, estado_id_estado)
    VALUES (v_id, p_nome_cidade, p_estado_id_estado);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_cidade', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_cidade', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_cidade', USER, SQLCODE, SQLERRM);
END prc_insere_cidade;
/

-- Procedure: inserir estado
CREATE OR REPLACE PROCEDURE prc_insere_estado(
    p_id_estado IN NUMBER DEFAULT NULL,
    p_nome_estado IN VARCHAR2
) AS
    v_id NUMBER;
BEGIN
    IF p_id_estado IS NULL THEN
        SELECT seq_estado.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_estado;
    END IF;
    INSERT INTO estado (id_estado, nome_estado) VALUES (v_id, p_nome_estado);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_estado', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_estado', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_estado', USER, SQLCODE, SQLERRM);
END prc_insere_estado;
/

-- Procedure: inserir clinica
CREATE OR REPLACE PROCEDURE prc_insere_clinica(
    p_id_clinica IN NUMBER DEFAULT NULL,
    p_nome IN VARCHAR2,
    p_telefone_id_telefone IN NUMBER,
    p_endereco_id_endereco IN NUMBER
) AS
    v_id NUMBER;
BEGIN
    IF p_id_clinica IS NULL THEN
        SELECT seq_clinica.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_clinica;
    END IF;
    INSERT INTO clinica (id_clinica, nome, telefone_id_telefone, endereco_id_endereco)
    VALUES (v_id, p_nome, p_telefone_id_telefone, p_endereco_id_endereco);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_clinica', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_clinica', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_clinica', USER, SQLCODE, SQLERRM);
END prc_insere_clinica;
/

-- Procedure: inserir veterinario
CREATE OR REPLACE PROCEDURE prc_insere_veterinario(
    p_id_veterinario IN NUMBER DEFAULT NULL,
    p_nome IN VARCHAR2,
    p_email IN VARCHAR2,
    p_senha IN VARCHAR2,
    p_telefone_id_telefone IN NUMBER,
    p_clinica_id_clinica IN NUMBER
) AS
    v_id NUMBER;
BEGIN
    IF p_id_veterinario IS NULL THEN
        SELECT seq_veterinario.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_veterinario;
    END IF;
    INSERT INTO veterinario (id_veterinario, nome, email, senha, telefone_id_telefone, clinica_id_clinica)
    VALUES (v_id, p_nome, p_email, p_senha, p_telefone_id_telefone, p_clinica_id_clinica);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_veterinario', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_veterinario', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_veterinario', USER, SQLCODE, SQLERRM);
END prc_insere_veterinario;
/

-- Procedure: inserir tipo_atend
CREATE OR REPLACE PROCEDURE prc_insere_tipo_atend(
    p_id_tipo_atend IN NUMBER DEFAULT NULL,
    p_tipo IN VARCHAR2
) AS
    v_id NUMBER;
BEGIN
    IF p_id_tipo_atend IS NULL THEN
        SELECT seq_tipo_atend.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_tipo_atend;
    END IF;
    INSERT INTO tipo_atend (id_tipo_atend, tipo) VALUES (v_id, p_tipo);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_tipo_atend', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_tipo_atend', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_tipo_atend', USER, SQLCODE, SQLERRM);
END prc_insere_tipo_atend;
/

-- Procedure: inserir status
CREATE OR REPLACE PROCEDURE prc_insere_status(
    p_id_status IN NUMBER DEFAULT NULL,
    p_nome_status IN VARCHAR2
) AS
    v_id NUMBER;
BEGIN
    IF p_id_status IS NULL THEN
        SELECT seq_status.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_status;
    END IF;
    INSERT INTO status (id_status, nome_status) VALUES (v_id, p_nome_status);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_status', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_status', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_status', USER, SQLCODE, SQLERRM);
END prc_insere_status;
/

-- Procedure: inserir tarefa
CREATE OR REPLACE PROCEDURE prc_insere_tarefa(
    p_id_tarefa IN NUMBER DEFAULT NULL,
    p_titulo IN VARCHAR2,
    p_pontos_tarefa IN NUMBER,
    p_descricao IN VARCHAR2,
    p_criacao IN TIMESTAMP DEFAULT SYSTIMESTAMP,
    p_prazo IN TIMESTAMP,
    p_usuario_id_usuario IN NUMBER DEFAULT NULL,
    p_pet_id_pet IN NUMBER,
    p_status_id_status IN NUMBER,
    p_veterinario_id_veterinario IN NUMBER
) AS
    v_id NUMBER;
BEGIN
    IF p_id_tarefa IS NULL THEN
        SELECT seq_tarefa.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_tarefa;
    END IF;
    INSERT INTO tarefa (id_tarefa, titulo, pontos_tarefa, descricao, criacao, prazo, usuario_id_usuario, pet_id_pet, status_id_status, veterinario_id_veterinario)
    VALUES (v_id, p_titulo, p_pontos_tarefa, p_descricao, p_criacao, p_prazo, p_usuario_id_usuario, p_pet_id_pet, p_status_id_status, p_veterinario_id_veterinario);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_tarefa', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_tarefa', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_tarefa', USER, SQLCODE, SQLERRM);
END prc_insere_tarefa;
/

-- Procedure: concluir tarefa (marca usuário e data de conclusão, atualiza status para CONCLUIDO)
CREATE OR REPLACE PROCEDURE prc_concluir_tarefa(
    p_id_tarefa IN NUMBER,
    p_id_usuario IN NUMBER,
    p_data_conclusao IN TIMESTAMP DEFAULT SYSTIMESTAMP
) AS
    v_status_concluido NUMBER;
    v_usuario_atual NUMBER;
BEGIN
    -- Verificar se a tarefa existe e se já possui um concluinte cadastrado
    SELECT usuario_id_usuario INTO v_usuario_atual 
    FROM tarefa 
    WHERE id_tarefa = p_id_tarefa;

    -- Regra de negócio: somente uma pessoa pode concluir a tarefa
    IF v_usuario_atual IS NOT NULL THEN
        prc_grava_log('prc_concluir_tarefa', USER, -20001, 'Tarefa ' || p_id_tarefa || ' ja concluida pelo usuario ' || v_usuario_atual);
        RETURN;
    END IF;

    SELECT id_status INTO v_status_concluido FROM status WHERE nome_status = 'CONCLUIDO' AND ROWNUM = 1;
    UPDATE tarefa
    SET usuario_id_usuario = p_id_usuario,
        conclusao = p_data_conclusao,
        status_id_status = v_status_concluido
    WHERE id_tarefa = p_id_tarefa;
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        prc_grava_log('prc_concluir_tarefa', USER, SQLCODE, 'Tarefa ' || p_id_tarefa || ' ou status CONCLUIDO nao encontrado');
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_concluir_tarefa', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_concluir_tarefa', USER, SQLCODE, SQLERRM);
END prc_concluir_tarefa;
/

-- Procedure: inserir atendimento
CREATE OR REPLACE PROCEDURE prc_insere_atendimento(
    p_id_atendimento IN NUMBER DEFAULT NULL,
    p_data IN TIMESTAMP,
    p_anotacoes IN VARCHAR2,
    p_valor IN NUMBER,
    p_pet_id_pet IN NUMBER,
    p_status_id_status IN NUMBER,
    p_tipo_atend_id_tipo_atend IN NUMBER,
    p_veterinario_id_veterinario IN NUMBER
) AS
    v_id NUMBER;
BEGIN
    IF p_id_atendimento IS NULL THEN
        SELECT seq_atendimento.NEXTVAL INTO v_id FROM DUAL;
    ELSE
        v_id := p_id_atendimento;
    END IF;
    INSERT INTO atendimento (id_atendimento, data, anotacoes, valor, pet_id_pet, status_id_status, tipo_atend_id_tipo_atend, veterinario_id_veterinario)
    VALUES (v_id, p_data, p_anotacoes, p_valor, p_pet_id_pet, p_status_id_status, p_tipo_atend_id_tipo_atend, p_veterinario_id_veterinario);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_atendimento', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_atendimento', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_atendimento', USER, SQLCODE, SQLERRM);
END prc_insere_atendimento;
/

-- Procedure: inserir relacionamento usuario_pet
CREATE OR REPLACE PROCEDURE prc_insere_usuario_pet(
    p_usuario_id_usuario IN NUMBER,
    p_pet_id_pet IN NUMBER,
    p_respon_princ IN CHAR
) AS
BEGIN
    INSERT INTO usuario_pet (usuario_id_usuario, pet_id_pet, respon_princ)
    VALUES (p_usuario_id_usuario, p_pet_id_pet, p_respon_princ);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_usuario_pet', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_usuario_pet', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_usuario_pet', USER, SQLCODE, SQLERRM);
END prc_insere_usuario_pet;
/

-- Procedure: inserir relacionamento usuario_endereco
CREATE OR REPLACE PROCEDURE prc_insere_usuario_endereco(
    p_usuario_id_usuario IN NUMBER,
    p_endereco_id_endereco IN NUMBER
) AS
BEGIN
    INSERT INTO usuario_endereco (usuario_id_usuario, endereco_id_endereco)
    VALUES (p_usuario_id_usuario, p_endereco_id_endereco);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('prc_insere_usuario_endereco', USER, SQLCODE, 'Registro duplicado: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('prc_insere_usuario_endereco', USER, SQLCODE, 'Erro de valor: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('prc_insere_usuario_endereco', USER, SQLCODE, SQLERRM);
END prc_insere_usuario_endereco;
/

-- Fim das procedures de carga
