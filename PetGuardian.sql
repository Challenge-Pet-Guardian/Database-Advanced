-- ==============================================================
-- PETGUARDIAN | CLYVO VET  -  BANCO DE DADOS ORACLE
-- Challenge FIAP 2026  -  Mastering Relational & Non-Relational DB
-- Oracle 19c / Oracle XE  (Oracle Cloud VM)
-- ==============================================================
-- MUDANCAS EM RELACAO AO SCHEMA ORIGINAL (MySQL -> Oracle):
--   * AUTO_INCREMENT        -> GENERATED ALWAYS AS IDENTITY
--   * BOOLEAN               -> NUMBER(1) + CHECK (0,1)
--   * VARCHAR               -> VARCHAR2
--   * TIMESTAMP DEFAULT NOW -> DEFAULT SYSTIMESTAMP
--   * ENUM                  -> VARCHAR2 + CHECK constraints
--   * CURDATE()             -> TRUNC(SYSDATE)
--   * GROUP_CONCAT          -> LISTAGG
--   * ON UPDATE CURRENT_... -> TRIGGER trg_update_streak
--   * DELIMITER $$          -> /  (Oracle terminator)
-- CORRECOES LOGICAS:
--   * id_usuario_criador (task) era NOT NULL + ON DELETE SET NULL => agora nullable
--   * id_usuario_resp (task_completion) idem
--   * Corrigido endereco VARCHAR(100) -> VARCHAR2(200) para uso real
-- NOVOS CAMPOS / TABELAS (derivados dos prototipos do app):
--   * tb_pet.porte            (MINI/PEQUENO/MEDIO/GRANDE/GIGANTE)
--   * tb_pet.castrado         (flag, era apenas informacoes texto)
--   * tb_metricas_saude       (Painel de Saude: peso, temp, passos, sono, ativo)
--   * tb_recado               (Canto da Matilha: recados entre cuidadores)
--   * tb_log_erros            (obrigatório pelo challenge para procedures)
-- ==============================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;


-- ==============================================================
-- SECAO 1: LIMPEZA DO AMBIENTE
-- ==============================================================
BEGIN
    FOR t IN (
        SELECT table_name FROM user_tables
        WHERE  table_name IN (
            'TB_LOG_ERROS','TB_RECADO','TB_METRICAS_SAUDE',
            'TB_VACINA','TB_MEDICAMENTO','TB_CONSULTA','TB_CLINICA',
            'TB_DAY_STREAK','TB_TASK_COMPLETION','TB_TASK',
            'TB_FAMILIA','TB_PET','TB_USUARIO'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name
                          || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Ambiente limpo com sucesso.');
END;
/


-- ==============================================================
-- SECAO 2: CRIACAO DAS TABELAS (DDL)
-- ==============================================================

-- ---- TB_FAMILIA (Familia do Pet) ----
CREATE TABLE tb_familia (
    id_familia NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    data_adicao    TIMESTAMP     DEFAULT SYSTIMESTAMP,
    ativo          NUMBER(1)     DEFAULT 1 NOT NULL,
    CONSTRAINT ck_up_ativo  CHECK (ativo IN (0,1))
);
COMMENT ON TABLE  tb_familia      IS 'Familia do Pet';

-- ---- TB_USUARIO ----
CREATE TABLE tb_usuario (
    id_usuario   NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_familia   NUMBER         NOT NULL,
    papel        VARCHAR2(20)  DEFAULT 'MEMBRO' NOT NULL,
    nome         VARCHAR2(255)  NOT NULL,
    email        VARCHAR2(255)  NOT NULL,
    senha        VARCHAR2(255)  NOT NULL,
    telefone     VARCHAR2(20),
    data_criacao TIMESTAMP      DEFAULT SYSTIMESTAMP,
    ativo        NUMBER(1)      DEFAULT 1 NOT NULL,
    CONSTRAINT fk_usuario_familia FOREIGN KEY (id_familia) REFERENCES tb_familia(id_familia) ON DELETE CASCADE,
    CONSTRAINT uq_usuario_email UNIQUE (email),
    CONSTRAINT ck_usuario_ativo CHECK  (ativo IN (0,1)),
    CONSTRAINT ck_up_papel  CHECK (papel IN ('DONO','MEMBRO','VETERINARIO'))
);
COMMENT ON TABLE  tb_usuario          IS 'Usuarios da plataforma PetGuardian';
COMMENT ON COLUMN tb_usuario.ativo    IS '1 = Ativo  |  0 = Inativo (exclusao logica)';
COMMENT ON COLUMN tb_usuario.senha    IS 'Hash da senha (bcrypt ou similar)';
COMMENT ON COLUMN tb_familia.papel IS 'DONO=responsavel principal | MEMBRO=cuidador | VETERINARIO=clinica/vet';

-- ---- TB_PET ----
CREATE TABLE tb_pet (
    id_pet           NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_familia       NUMBER         NOT NULL,
    nome             VARCHAR2(255)  NOT NULL,
    especie          VARCHAR2(20)   NOT NULL,
    raca             VARCHAR2(100),
    data_nascimento  DATE,
    peso_kg          NUMBER(5,2),
    sexo             CHAR(1),
    porte            VARCHAR2(20),
    castrado         NUMBER(1)      DEFAULT 0 NOT NULL,
    informacoes      VARCHAR2(300),
    foto_url         VARCHAR2(500),
    data_criacao     TIMESTAMP      DEFAULT SYSTIMESTAMP,
    ativo            NUMBER(1)      DEFAULT 1 NOT NULL,
    CONSTRAINT fk_pet_familia FOREIGN KEY (id_familia) REFERENCES tb_familia(id_familia) ON DELETE CASCADE,
    CONSTRAINT ck_pet_especie  CHECK (especie IN ('CACHORRO','GATO','OUTRO')),
    CONSTRAINT ck_pet_sexo   CHECK (sexo  IN ('M','F')),
    CONSTRAINT ck_pet_porte    CHECK (porte   IN ('MINI','PEQUENO','MEDIO','GRANDE','GIGANTE')),
    CONSTRAINT ck_pet_castrado CHECK (castrado IN (0,1)),
    CONSTRAINT ck_pet_ativo    CHECK (ativo    IN (0,1)),
    CONSTRAINT ck_pet_peso     CHECK (peso_kg IS NULL OR peso_kg > 0)
);
COMMENT ON TABLE  tb_pet              IS 'Animais de estimacao cadastrados';
COMMENT ON COLUMN tb_pet.porte        IS 'Porte: MINI(<4kg) PEQUENO(4-10kg) MEDIO(10-25kg) GRANDE(25-45kg) GIGANTE(>45kg)';
COMMENT ON COLUMN tb_pet.castrado     IS '1 = Castrado  |  0 = Nao castrado';

-- ---- TB_TASK ----
-- id_usuario_criador: nullable (ON DELETE SET NULL => criador pode ser deletado sem perder a tarefa)
CREATE TABLE tb_task (
    id_task            NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pet             NUMBER        NOT NULL,
    id_familia         NUMBER        NOT NULL,
    id_usuario_criador NUMBER,
    titulo             VARCHAR2(255) NOT NULL,
    descricao          VARCHAR2(300),
    tipo               VARCHAR2(20)  NOT NULL,
    data_criacao       TIMESTAMP     DEFAULT SYSTIMESTAMP,
    data_vencimento    DATE,
    recorrencia        VARCHAR2(20)  DEFAULT 'UNICA' NOT NULL,
    ativo              NUMBER(1)     DEFAULT 1 NOT NULL,
    CONSTRAINT fk_task_pet     FOREIGN KEY (id_pet)             REFERENCES tb_pet(id_pet)         ON DELETE CASCADE,
    CONSTRAINT fk_task_familia FOREIGN KEY (id_familia)         REFERENCES tb_familia(id_familia) ON DELETE CASCADE,
    CONSTRAINT fk_task_usuario FOREIGN KEY (id_usuario_criador) REFERENCES tb_usuario(id_usuario) ON DELETE SET NULL,
    CONSTRAINT ck_task_tipo    CHECK (tipo        IN ('MEDICACAO','ALIMENTACAO','EXERCICIO','LIMPEZA','VETERINARIO','OUTRO')),
    CONSTRAINT ck_task_recorr  CHECK (recorrencia IN ('UNICA','DIARIA','SEMANAL','MENSAL')),
    CONSTRAINT ck_task_ativo   CHECK (ativo       IN (0,1))
);
COMMENT ON TABLE  tb_task IS 'Tarefas de cuidado para os pets (contribuem para day streak)';

-- ---- TB_TASK_COMPLETION ----
-- id_usuario_resp: nullable (ON DELETE SET NULL)
CREATE TABLE tb_task_completion (
    id_completion   NUMBER    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_task         NUMBER    NOT NULL,
    id_familia      NUMBER    NOT NULL,
    id_usuario_resp NUMBER,
    data_conclusao  TIMESTAMP DEFAULT SYSTIMESTAMP,
    observacoes     VARCHAR2(300),
    CONSTRAINT fk_tc_task    FOREIGN KEY (id_task)          REFERENCES tb_task(id_task)       ON DELETE CASCADE,
    CONSTRAINT fk_tc_familia FOREIGN KEY (id_familia)       REFERENCES tb_familia(id_familia) ON DELETE SET NULL,
    CONSTRAINT fk_tc_usuario FOREIGN KEY (id_usuario_resp)  REFERENCES tb_usuario(id_usuario) ON DELETE SET NULL
);
COMMENT ON TABLE  tb_task_completion IS 'Historico de conclusao de tarefas (base do calculo de day streak)';

-- ---- TB_DAY_STREAK ----
CREATE TABLE tb_day_streak (
    id_streak          NUMBER    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pet             NUMBER    NOT NULL,
    id_familia         NUMBER    NOT NULL,
    dias_consecutivos  NUMBER    DEFAULT 1 NOT NULL,
    data_inicio        DATE      NOT NULL,
    ultima_atualizacao TIMESTAMP DEFAULT SYSTIMESTAMP,
    quebrado           NUMBER(1) DEFAULT 0 NOT NULL,
    data_quebra        DATE,
    CONSTRAINT fk_ds_pet     FOREIGN KEY (id_pet)     REFERENCES tb_pet(id_pet)         ON DELETE CASCADE,
    CONSTRAINT fk_ds_familia FOREIGN KEY (id_familia) REFERENCES tb_familia(id_familia) ON DELETE CASCADE,
    CONSTRAINT uq_streak     UNIQUE (id_usuario, id_pet),
    CONSTRAINT ck_ds_quebrado CHECK (quebrado          IN (0,1)),
    CONSTRAINT ck_ds_dias     CHECK (dias_consecutivos >= 0)
);
COMMENT ON TABLE  tb_day_streak IS 'Sequencia de dias consecutivos de cuidado do pet por usuario';

-- ---- TB_CLINICA ----
CREATE TABLE tb_clinica (
    id_clinica   NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome         VARCHAR2(255) NOT NULL,
    email        VARCHAR2(255),
    telefone     VARCHAR2(20),
    endereco     VARCHAR2(200),
    cidade       VARCHAR2(100),
    estado       CHAR(2),
    data_criacao TIMESTAMP     DEFAULT SYSTIMESTAMP,
    ativo        NUMBER(1)     DEFAULT 1 NOT NULL,
    CONSTRAINT ck_clinica_ativo CHECK (ativo IN (0,1))
);
COMMENT ON TABLE  tb_clinica IS 'Clinicas veterinarias e hospitais parceiros';

-- ---- TB_CONSULTA ----
CREATE TABLE tb_consulta (
    id_consulta      NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pet           NUMBER        NOT NULL,
    id_clinica       NUMBER,
    id_veterinario   NUMBER,
    data_consulta    TIMESTAMP     NOT NULL,
    tipo             VARCHAR2(20)  DEFAULT 'ROTINA' NOT NULL,
    descricao        VARCHAR2(300),
    prescricao       VARCHAR2(300),
    proxima_consulta DATE,
    data_criacao     TIMESTAMP     DEFAULT SYSTIMESTAMP,
    CONSTRAINT fk_cons_pet     FOREIGN KEY (id_pet)         REFERENCES tb_pet(id_pet)         ON DELETE CASCADE,
    CONSTRAINT fk_cons_clinica FOREIGN KEY (id_clinica)     REFERENCES tb_clinica(id_clinica) ON DELETE SET NULL,
    CONSTRAINT fk_cons_vet     FOREIGN KEY (id_veterinario) REFERENCES tb_usuario(id_usuario) ON DELETE SET NULL,
    CONSTRAINT ck_cons_tipo    CHECK (tipo IN ('ROTINA','EMERGENCIA','VACINACAO','CIRURGIA'))
);
COMMENT ON TABLE  tb_consulta IS 'Consultas veterinarias do pet';

-- ---- TB_MEDICAMENTO ----
CREATE TABLE tb_medicamento (
    id_medicamento NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pet         NUMBER        NOT NULL,
    nome           VARCHAR2(255) NOT NULL,
    dosagem        VARCHAR2(100),
    frequencia     VARCHAR2(100),
    data_inicio    DATE,
    data_fim       DATE,
    id_consulta    NUMBER,
    notas          VARCHAR2(300),
    data_criacao   TIMESTAMP     DEFAULT SYSTIMESTAMP,
    CONSTRAINT fk_med_pet      FOREIGN KEY (id_pet)      REFERENCES tb_pet(id_pet)           ON DELETE CASCADE,
    CONSTRAINT fk_med_consulta FOREIGN KEY (id_consulta) REFERENCES tb_consulta(id_consulta) ON DELETE SET NULL,
    CONSTRAINT ck_med_datas    CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);
COMMENT ON TABLE  tb_medicamento IS 'Historico de medicamentos do pet (Continuidade Terapeutica)';

-- ---- TB_VACINA ----
CREATE TABLE tb_vacina (
    id_vacina      NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pet         NUMBER        NOT NULL,
    nome_vacina    VARCHAR2(255) NOT NULL,
    data_aplicacao DATE          NOT NULL,
    proxima_dose   DATE,
    veterinario    VARCHAR2(255),
    numero_lote    VARCHAR2(100),
    notas          VARCHAR2(300),
    data_criacao   TIMESTAMP     DEFAULT SYSTIMESTAMP,
    CONSTRAINT fk_vac_pet   FOREIGN KEY (id_pet) REFERENCES tb_pet(id_pet) ON DELETE CASCADE,
    CONSTRAINT ck_vac_datas CHECK (proxima_dose IS NULL OR proxima_dose > data_aplicacao)
);
COMMENT ON TABLE  tb_vacina IS 'Registro de vacinacao dos pets';

-- ---- TB_METRICAS_SAUDE (NOVA) ----
-- Painel de Saude do app: peso historico, temperatura, passos, sono, tempo ativo
CREATE TABLE tb_metricas_saude (
    id_metrica      NUMBER    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pet          NUMBER    NOT NULL,
    id_usuario      NUMBER    NOT NULL,
    data_registro   TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    peso_kg         NUMBER(5,2),
    temperatura_c   NUMBER(4,2),
    passos          NUMBER,
    sono_minutos    NUMBER,
    tempo_ativo_min NUMBER,
    notas           VARCHAR2(300),
    CONSTRAINT fk_ms_pet     FOREIGN KEY (id_pet)     REFERENCES tb_pet(id_pet)         ON DELETE CASCADE,
    CONSTRAINT fk_ms_usuario FOREIGN KEY (id_usuario) REFERENCES tb_usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT ck_ms_peso    CHECK (peso_kg       IS NULL OR peso_kg > 0),
    CONSTRAINT ck_ms_temp    CHECK (temperatura_c IS NULL OR temperatura_c BETWEEN 30 AND 45),
    CONSTRAINT ck_ms_passos  CHECK (passos        IS NULL OR passos >= 0),
    CONSTRAINT ck_ms_sono    CHECK (sono_minutos  IS NULL OR sono_minutos >= 0),
    CONSTRAINT ck_ms_tativo  CHECK (tempo_ativo_min IS NULL OR tempo_ativo_min >= 0)
);
COMMENT ON TABLE  tb_metricas_saude           IS 'Painel de Saude: metricas periodicas do pet';
COMMENT ON COLUMN tb_metricas_saude.temperatura_c IS 'Temperatura corporal em Celsius (intervalo fisiologico 30-45 C)';

-- ---- TB_AGENDA_PET (NOVA) ----
-- Agenda do pet: vacinas, consultas, exames, metricas de saúde, tarefas, etc
CREATE TABLE tb_agenda_pet (
    id_agenda       NUMBER    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pet          NUMBER    NOT NULL,
    id_familia      NUMBER    NOT NULL,
    id_consulta     NUMBER,
    id_vacina       NUMBER,
    id_metrica      NUMBER,
    id_task         NUMBER,
    id_medicamento  NUMBER,
    notas           VARCHAR2(300),
    CONSTRAINT fk_ag_pet      FOREIGN KEY (id_pet)      REFERENCES tb_pet(id_pet)           ON DELETE CASCADE,
    CONSTRAINT fk_ag_familia  FOREIGN KEY (id_familia)  REFERENCES tb_familia(id_familia)   ON DELETE CASCADE,
    CONSTRAINT fk_ag_consulta FOREIGN KEY (id_consulta) REFERENCES tb_consulta(id_consulta) ON DELETE CASCADE,
    CONSTRAINT fk_ag_vacina   FOREIGN KEY (id_vacina)   REFERENCES tb_vacina(id_vacina)     ON DELETE CASCADE,
    CONSTRAINT fk_ag_metrica  FOREIGN KEY (id_metrica)  REFERENCES tb_metricas_saude(id_metrica) ON DELETE CASCADE,
    CONSTRAINT fk_ag_task     FOREIGN KEY (id_task)     REFERENCES tb_task(id_task)         ON DELETE CASCADE,
    CONSTRAINT fk_ag_medic    FOREIGN KEY (id_medicamento) REFERENCES tb_medicamento(id_medicamento) ON DELETE CASCADE
);
COMMENT ON TABLE  tb_agenda_pet IS 'Agenda do pet: vacinas, consultas, exames, metricas de saude, tarefas, etc';

-- ---- TB_RECADO (NOVA) ----
-- Tela "Canto da Matilha": recados entre os cuidadores do pet
CREATE TABLE tb_recado (
    id_recado    NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pet       NUMBER        NOT NULL,
    id_usuario   NUMBER        NOT NULL,
    mensagem     VARCHAR2(500) NOT NULL,
    data_criacao TIMESTAMP     DEFAULT SYSTIMESTAMP,
    lido         NUMBER(1)     DEFAULT 0 NOT NULL,
    CONSTRAINT fk_rec_pet     FOREIGN KEY (id_pet)     REFERENCES tb_pet(id_pet)         ON DELETE CASCADE,
    CONSTRAINT fk_rec_usuario FOREIGN KEY (id_usuario) REFERENCES tb_usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT ck_rec_lido    CHECK (lido IN (0,1))
);
COMMENT ON TABLE  tb_recado IS 'Recados entre membros da familia do pet (Canto da Matilha)';

-- ---- TB_LOG_ERROS ----
CREATE TABLE tb_log_erros (
    id_log          NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_procedure  VARCHAR2(100),
    nome_usuario_db VARCHAR2(100) DEFAULT USER,
    data_ocorrencia TIMESTAMP     DEFAULT SYSTIMESTAMP,
    codigo_erro     NUMBER,
    mensagem_erro   VARCHAR2(500)
);
COMMENT ON TABLE  tb_log_erros IS 'Registro centralizado de erros das stored procedures';


-- ==============================================================
-- SECAO 3: INDICES
-- ==============================================================
CREATE INDEX idx_usuario_email   ON tb_usuario         (email);
CREATE INDEX idx_pet_ativo       ON tb_pet             (ativo);
CREATE INDEX idx_up_usuario      ON tb_familia     (id_usuario);
CREATE INDEX idx_up_pet          ON tb_familia     (id_pet);
CREATE INDEX idx_task_pet        ON tb_task            (id_pet);
CREATE INDEX idx_task_vencimento ON tb_task            (data_vencimento);
CREATE INDEX idx_task_tipo       ON tb_task            (tipo);
CREATE INDEX idx_tc_task         ON tb_task_completion (id_task);
CREATE INDEX idx_tc_usuario      ON tb_task_completion (id_usuario_resp);
CREATE INDEX idx_ds_pet_usuario  ON tb_day_streak      (id_pet, id_usuario);
CREATE INDEX idx_cons_pet        ON tb_consulta        (id_pet);
CREATE INDEX idx_cons_clinica    ON tb_consulta        (id_clinica);
CREATE INDEX idx_ms_pet          ON tb_metricas_saude  (id_pet);
CREATE INDEX idx_ms_data         ON tb_metricas_saude  (data_registro);
CREATE INDEX idx_vac_pet         ON tb_vacina          (id_pet);
CREATE INDEX idx_vac_proxima     ON tb_vacina          (proxima_dose);
CREATE INDEX idx_rec_pet         ON tb_recado          (id_pet);


-- ==============================================================
-- SECAO 4: TRIGGER
-- Substitui ON UPDATE CURRENT_TIMESTAMP (nao suportado no Oracle)
-- ==============================================================
CREATE OR REPLACE TRIGGER trg_streak_update_ts
    BEFORE UPDATE ON tb_day_streak
    FOR EACH ROW
BEGIN
    :NEW.ultima_atualizacao := SYSTIMESTAMP;
END;
/


-- ==============================================================
-- SECAO 5: VIEWS
-- ==============================================================

-- VIEW: Pets com seus cuidadores
CREATE OR REPLACE VIEW vw_pet_cuidadores AS
SELECT
    p.id_pet,
    p.nome                                                            AS pet_nome,
    p.especie,
    p.porte,
    p.castrado,
    COUNT(DISTINCT up.id_usuario)                                     AS nr_cuidadores,
    LISTAGG(u.nome, ', ') WITHIN GROUP (ORDER BY u.nome)             AS cuidadores
FROM tb_pet          p
LEFT JOIN tb_familia up ON p.id_pet     = up.id_pet   AND up.ativo = 1
LEFT JOIN tb_usuario      u ON up.id_usuario = u.id_usuario
WHERE p.ativo = 1
GROUP BY p.id_pet, p.nome, p.especie, p.porte, p.castrado;

-- VIEW: Tarefas pendentes por pet
CREATE OR REPLACE VIEW vw_tarefas_pendentes AS
SELECT
    t.id_task,
    p.id_pet,
    p.nome         AS pet_nome,
    t.titulo,
    t.tipo,
    t.data_vencimento,
    t.recorrencia,
    u.nome         AS criador
FROM tb_task    t
JOIN tb_pet     p ON t.id_pet             = p.id_pet
LEFT JOIN tb_usuario u ON t.id_usuario_criador = u.id_usuario
WHERE t.ativo = 1
  AND (t.data_vencimento >= TRUNC(SYSDATE) OR t.data_vencimento IS NULL);

-- VIEW: Proximas vacinas a vencer
CREATE OR REPLACE VIEW vw_proximas_vacinas AS
SELECT
    v.id_vacina,
    p.id_pet,
    p.nome                              AS pet_nome,
    v.nome_vacina,
    v.data_aplicacao,
    v.proxima_dose,
    v.proxima_dose - TRUNC(SYSDATE)     AS dias_para_vacina
FROM tb_vacina v
JOIN tb_pet    p ON v.id_pet = p.id_pet
WHERE v.proxima_dose >= TRUNC(SYSDATE)
  AND p.ativo = 1
ORDER BY v.proxima_dose;

-- VIEW: Resumo de saude (metricas mais recentes por pet)
CREATE OR REPLACE VIEW vw_saude_resumo AS
SELECT
    p.id_pet,
    p.nome          AS pet_nome,
    p.especie,
    p.porte,
    ms.peso_kg,
    ms.temperatura_c,
    ms.passos,
    ms.sono_minutos,
    ms.tempo_ativo_min,
    ms.data_registro AS ultima_medicao,
    v_ult.nome_vacina,
    v_ult.data_aplicacao,
    v_ult.proxima_dose
FROM tb_pet p
LEFT JOIN (
    SELECT id_pet, peso_kg, temperatura_c, passos, sono_minutos,
           tempo_ativo_min, data_registro,
           ROW_NUMBER() OVER (PARTITION BY id_pet ORDER BY data_registro DESC) AS rn
    FROM tb_metricas_saude
) ms ON p.id_pet = ms.id_pet AND ms.rn = 1
LEFT JOIN (
    SELECT id_pet, nome_vacina, data_aplicacao, proxima_dose,
           ROW_NUMBER() OVER (PARTITION BY id_pet ORDER BY data_aplicacao DESC) AS rn
    FROM tb_vacina
) v_ult ON p.id_pet = v_ult.id_pet AND v_ult.rn = 1
WHERE p.ativo = 1;


-- ==============================================================
-- SECAO 6: PROCEDURES DE CARGA
-- Cada procedure tem: WHEN OTHERS (obrigatorio) + 2 excecoes
-- especificas a escolha do grupo, com log em tb_log_erros.
-- ==============================================================

-- ---- PROCEDURE: Inserir Usuario ----
CREATE OR REPLACE PROCEDURE sp_inserir_usuario (
    p_nome     IN tb_usuario.nome%TYPE,
    p_email    IN tb_usuario.email%TYPE,
    p_senha    IN tb_usuario.senha%TYPE,
    p_telefone IN tb_usuario.telefone%TYPE DEFAULT NULL
) AS
BEGIN
    INSERT INTO tb_usuario (nome, email, senha, telefone)
    VALUES (p_nome, p_email, p_senha, p_telefone);
    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_usuario', -1, 'Email duplicado: ' || p_email);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20001, 'Email ja cadastrado: ' || p_email);

    WHEN VALUE_ERROR THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_usuario', -6502, 'Dado invalido ao inserir usuario: ' || p_nome);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20002, 'Dado invalido para o campo.');

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_usuario', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_inserir_usuario;
/

-- ---- PROCEDURE: Inserir Pet ----
CREATE OR REPLACE PROCEDURE sp_inserir_pet (
    p_nome            IN tb_pet.nome%TYPE,
    p_especie         IN tb_pet.especie%TYPE,
    p_raca            IN tb_pet.raca%TYPE            DEFAULT NULL,
    p_data_nascimento IN tb_pet.data_nascimento%TYPE DEFAULT NULL,
    p_peso_kg         IN tb_pet.peso_kg%TYPE         DEFAULT NULL,
    p_sexo          IN tb_pet.sexo%TYPE          DEFAULT NULL,
    p_porte           IN tb_pet.porte%TYPE           DEFAULT NULL,
    p_castrado        IN tb_pet.castrado%TYPE        DEFAULT 0,
    p_informacoes     IN tb_pet.informacoes%TYPE     DEFAULT NULL,
    p_foto_url        IN tb_pet.foto_url%TYPE        DEFAULT NULL
) AS
    e_check_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violated, -2290);
BEGIN
    INSERT INTO tb_pet (nome, especie, raca, data_nascimento, peso_kg,
                        sexo, porte, castrado, informacoes, foto_url)
    VALUES (p_nome, p_especie, p_raca, p_data_nascimento, p_peso_kg,
            p_sexo, p_porte, p_castrado, p_informacoes, p_foto_url);
    COMMIT;

EXCEPTION
    WHEN e_check_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_pet', -2290,
                'Valor invalido para especie/sexo/porte/castrado. Pet: ' || p_nome);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20003,
            'Valor fora do dominio permitido (especie, sexo, porte). Pet: ' || p_nome);

    WHEN VALUE_ERROR THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_pet', -6502, 'Tipo de dado invalido ao inserir pet: ' || p_nome);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20004, 'Tipo de dado invalido para campo do pet.');

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_pet', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_inserir_pet;
/

-- ---- PROCEDURE: Inserir Usuario_Pet (vincular cuidador ao pet) ----
CREATE OR REPLACE PROCEDURE sp_inserir_usuario_pet (
    p_id_usuario IN tb_familia.id_usuario%TYPE,
    p_id_pet     IN tb_familia.id_pet%TYPE,
    p_papel      IN tb_familia.papel%TYPE DEFAULT 'MEMBRO'
) AS
    e_fk_violated    EXCEPTION;
    e_check_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_violated,    -2291);
    PRAGMA EXCEPTION_INIT(e_check_violated, -2290);
BEGIN
    INSERT INTO tb_familia (id_usuario, id_pet, papel)
    VALUES (p_id_usuario, p_id_pet, p_papel);
    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_usuario_pet', -1,
                'Vinculo ja existe: usuario=' || p_id_usuario || ' pet=' || p_id_pet);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20005, 'Este usuario ja esta vinculado a este pet.');

    WHEN e_fk_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_usuario_pet', -2291,
                'Usuario ou Pet nao encontrado. usuario=' || p_id_usuario || ' pet=' || p_id_pet);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20006, 'Usuario ou Pet informado nao existe.');

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_usuario_pet', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_inserir_usuario_pet;
/

-- ---- PROCEDURE: Inserir Task ----
CREATE OR REPLACE PROCEDURE sp_inserir_task (
    p_id_pet             IN tb_task.id_pet%TYPE,
    p_id_usuario_criador IN tb_task.id_usuario_criador%TYPE,
    p_titulo             IN tb_task.titulo%TYPE,
    p_descricao          IN tb_task.descricao%TYPE     DEFAULT NULL,
    p_tipo               IN tb_task.tipo%TYPE,
    p_data_vencimento    IN tb_task.data_vencimento%TYPE DEFAULT NULL,
    p_recorrencia        IN tb_task.recorrencia%TYPE   DEFAULT 'UNICA'
) AS
    e_fk_violated    EXCEPTION;
    e_check_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_violated,    -2291);
    PRAGMA EXCEPTION_INIT(e_check_violated, -2290);
BEGIN
    INSERT INTO tb_task (id_pet, id_usuario_criador, titulo, descricao,
                         tipo, data_vencimento, recorrencia)
    VALUES (p_id_pet, p_id_usuario_criador, p_titulo, p_descricao,
            p_tipo, p_data_vencimento, p_recorrencia);
    COMMIT;

EXCEPTION
    WHEN e_fk_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_task', -2291,
                'Pet ou Usuario inexistente. id_pet=' || p_id_pet);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20007, 'Pet ou Usuario informado nao existe.');

    WHEN e_check_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_task', -2290,
                'Tipo ou recorrencia invalidos: ' || p_tipo || ' / ' || p_recorrencia);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20008, 'Tipo ou recorrencia da tarefa invalidos.');

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_task', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_inserir_task;
/

-- ---- PROCEDURE: Inserir Task Completion ----
CREATE OR REPLACE PROCEDURE sp_inserir_task_completion (
    p_id_task         IN tb_task_completion.id_task%TYPE,
    p_id_usuario_resp IN tb_task_completion.id_usuario_resp%TYPE,
    p_observacoes     IN tb_task_completion.observacoes%TYPE DEFAULT NULL
) AS
    e_fk_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_violated, -2291);
    v_task_ativo NUMBER;
BEGIN
    -- Valida se a tarefa existe e esta ativa
    SELECT ativo INTO v_task_ativo
    FROM   tb_task
    WHERE  id_task = p_id_task;

    IF v_task_ativo = 0 THEN
        RAISE_APPLICATION_ERROR(-20009, 'Tarefa inativa nao pode ser concluida.');
    END IF;

    INSERT INTO tb_task_completion (id_task, id_usuario_resp, observacoes)
    VALUES (p_id_task, p_id_usuario_resp, p_observacoes);
    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_task_completion', 100,
                'Tarefa nao encontrada. id_task=' || p_id_task);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20010, 'Tarefa nao encontrada: id=' || p_id_task);

    WHEN e_fk_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_task_completion', -2291,
                'Tarefa ou Usuario inexistente. id_task=' || p_id_task);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20011, 'Tarefa ou Usuario informado nao existe.');

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_task_completion', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_inserir_task_completion;
/

-- ---- PROCEDURE: Inserir / Atualizar Day Streak (MERGE/UPSERT) ----
CREATE OR REPLACE PROCEDURE sp_atualizar_day_streak (
    p_id_pet   IN tb_day_streak.id_pet%TYPE,
    p_id_usuario IN tb_day_streak.id_usuario%TYPE,
    p_dias     IN tb_day_streak.dias_consecutivos%TYPE DEFAULT 1
) AS
    e_fk_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_violated, -2291);
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM   tb_day_streak
    WHERE  id_pet = p_id_pet AND id_usuario = p_id_usuario;

    IF v_existe = 0 THEN
        INSERT INTO tb_day_streak (id_pet, id_usuario, dias_consecutivos, data_inicio)
        VALUES (p_id_pet, p_id_usuario, p_dias, TRUNC(SYSDATE));
    ELSE
        UPDATE tb_day_streak
        SET    dias_consecutivos = dias_consecutivos + p_dias,
               quebrado          = 0,
               data_quebra       = NULL
        WHERE  id_pet     = p_id_pet
          AND  id_usuario = p_id_usuario;
    END IF;
    COMMIT;

EXCEPTION
    WHEN e_fk_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_atualizar_day_streak', -2291,
                'Pet ou Usuario inexistente. id_pet=' || p_id_pet || ' id_usuario=' || p_id_usuario);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20012, 'Pet ou Usuario nao encontrado para o streak.');

    WHEN VALUE_ERROR THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_atualizar_day_streak', -6502,
                'Valor invalido para dias_consecutivos: ' || p_dias);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20013, 'Numero de dias invalido.');

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_atualizar_day_streak', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_atualizar_day_streak;
/

-- ---- PROCEDURE: Quebrar Day Streak ----
CREATE OR REPLACE PROCEDURE sp_quebrar_day_streak (
    p_id_pet     IN tb_day_streak.id_pet%TYPE,
    p_id_usuario IN tb_day_streak.id_usuario%TYPE
) AS
BEGIN
    UPDATE tb_day_streak
    SET    quebrado    = 1,
           data_quebra = TRUNC(SYSDATE)
    WHERE  id_pet     = p_id_pet
      AND  id_usuario = p_id_usuario;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20014, 'Streak nao encontrado para quebrar.');
    END IF;
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_quebrar_day_streak', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_quebrar_day_streak;
/

-- ---- PROCEDURE: Inserir Clinica ----
CREATE OR REPLACE PROCEDURE sp_inserir_clinica (
    p_nome     IN tb_clinica.nome%TYPE,
    p_email    IN tb_clinica.email%TYPE    DEFAULT NULL,
    p_telefone IN tb_clinica.telefone%TYPE DEFAULT NULL,
    p_endereco IN tb_clinica.endereco%TYPE DEFAULT NULL,
    p_cidade   IN tb_clinica.cidade%TYPE   DEFAULT NULL,
    p_estado   IN tb_clinica.estado%TYPE   DEFAULT NULL
) AS
BEGIN
    INSERT INTO tb_clinica (nome, email, telefone, endereco, cidade, estado)
    VALUES (p_nome, p_email, p_telefone, p_endereco, p_cidade, p_estado);
    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_clinica', -1, 'Clinica duplicada: ' || p_nome);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20015, 'Clinica ja cadastrada.');

    WHEN VALUE_ERROR THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_clinica', -6502, 'Dado invalido ao inserir clinica: ' || p_nome);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20016, 'Dado invalido para campo da clinica.');

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_clinica', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_inserir_clinica;
/

-- ---- PROCEDURE: Inserir Consulta ----
CREATE OR REPLACE PROCEDURE sp_inserir_consulta (
    p_id_pet           IN tb_consulta.id_pet%TYPE,
    p_id_clinica       IN tb_consulta.id_clinica%TYPE       DEFAULT NULL,
    p_id_veterinario   IN tb_consulta.id_veterinario%TYPE   DEFAULT NULL,
    p_data_consulta    IN tb_consulta.data_consulta%TYPE,
    p_tipo             IN tb_consulta.tipo%TYPE             DEFAULT 'ROTINA',
    p_descricao        IN tb_consulta.descricao%TYPE        DEFAULT NULL,
    p_prescricao       IN tb_consulta.prescricao%TYPE       DEFAULT NULL,
    p_proxima_consulta IN tb_consulta.proxima_consulta%TYPE DEFAULT NULL
) AS
    e_fk_violated    EXCEPTION;
    e_check_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_violated,    -2291);
    PRAGMA EXCEPTION_INIT(e_check_violated, -2290);
BEGIN
    INSERT INTO tb_consulta (id_pet, id_clinica, id_veterinario, data_consulta,
                             tipo, descricao, prescricao, proxima_consulta)
    VALUES (p_id_pet, p_id_clinica, p_id_veterinario, p_data_consulta,
            p_tipo, p_descricao, p_prescricao, p_proxima_consulta);
    COMMIT;

EXCEPTION
    WHEN e_fk_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_consulta', -2291,
                'Pet, Clinica ou Vet inexistente. id_pet=' || p_id_pet);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20017, 'Pet, Clinica ou Veterinario informado nao existe.');

    WHEN e_check_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_consulta', -2290, 'Tipo invalido: ' || p_tipo);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20018, 'Tipo de consulta invalido: ' || p_tipo);

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_consulta', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_inserir_consulta;
/

-- ---- PROCEDURE: Inserir Medicamento ----
CREATE OR REPLACE PROCEDURE sp_inserir_medicamento (
    p_id_pet      IN tb_medicamento.id_pet%TYPE,
    p_nome        IN tb_medicamento.nome%TYPE,
    p_dosagem     IN tb_medicamento.dosagem%TYPE    DEFAULT NULL,
    p_frequencia  IN tb_medicamento.frequencia%TYPE DEFAULT NULL,
    p_data_inicio IN tb_medicamento.data_inicio%TYPE DEFAULT NULL,
    p_data_fim    IN tb_medicamento.data_fim%TYPE   DEFAULT NULL,
    p_id_consulta IN tb_medicamento.id_consulta%TYPE DEFAULT NULL,
    p_notas       IN tb_medicamento.notas%TYPE      DEFAULT NULL
) AS
    e_check_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violated, -2290);
BEGIN
    INSERT INTO tb_medicamento (id_pet, nome, dosagem, frequencia,
                                data_inicio, data_fim, id_consulta, notas)
    VALUES (p_id_pet, p_nome, p_dosagem, p_frequencia,
            p_data_inicio, p_data_fim, p_id_consulta, p_notas);
    COMMIT;

EXCEPTION
    WHEN e_check_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_medicamento', -2290,
                'Data fim anterior a data inicio. Medicamento: ' || p_nome);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20019, 'Data de fim nao pode ser anterior a data de inicio.');

    WHEN VALUE_ERROR THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_medicamento', -6502, 'Dado invalido ao inserir medicamento: ' || p_nome);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20020, 'Dado invalido para campo do medicamento.');

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_medicamento', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_inserir_medicamento;
/

-- ---- PROCEDURE: Inserir Vacina ----
CREATE OR REPLACE PROCEDURE sp_inserir_vacina (
    p_id_pet         IN tb_vacina.id_pet%TYPE,
    p_nome_vacina    IN tb_vacina.nome_vacina%TYPE,
    p_data_aplicacao IN tb_vacina.data_aplicacao%TYPE,
    p_proxima_dose   IN tb_vacina.proxima_dose%TYPE   DEFAULT NULL,
    p_veterinario    IN tb_vacina.veterinario%TYPE    DEFAULT NULL,
    p_numero_lote    IN tb_vacina.numero_lote%TYPE    DEFAULT NULL,
    p_notas          IN tb_vacina.notas%TYPE          DEFAULT NULL
) AS
    e_fk_violated    EXCEPTION;
    e_check_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_violated,    -2291);
    PRAGMA EXCEPTION_INIT(e_check_violated, -2290);
BEGIN
    INSERT INTO tb_vacina (id_pet, nome_vacina, data_aplicacao,
                           proxima_dose, veterinario, numero_lote, notas)
    VALUES (p_id_pet, p_nome_vacina, p_data_aplicacao,
            p_proxima_dose, p_veterinario, p_numero_lote, p_notas);
    COMMIT;

EXCEPTION
    WHEN e_fk_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_vacina', -2291, 'Pet inexistente. id_pet=' || p_id_pet);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20021, 'Pet informado nao existe.');

    WHEN e_check_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_vacina', -2290,
                'Proxima dose anterior a data de aplicacao. Vacina: ' || p_nome_vacina);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20022, 'Proxima dose deve ser posterior a data de aplicacao.');

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_vacina', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_inserir_vacina;
/

-- ---- PROCEDURE: Inserir Metrica de Saude ----
CREATE OR REPLACE PROCEDURE sp_inserir_metrica_saude (
    p_id_pet          IN tb_metricas_saude.id_pet%TYPE,
    p_id_usuario      IN tb_metricas_saude.id_usuario%TYPE,
    p_peso_kg         IN tb_metricas_saude.peso_kg%TYPE         DEFAULT NULL,
    p_temperatura_c   IN tb_metricas_saude.temperatura_c%TYPE   DEFAULT NULL,
    p_passos          IN tb_metricas_saude.passos%TYPE          DEFAULT NULL,
    p_sono_minutos    IN tb_metricas_saude.sono_minutos%TYPE    DEFAULT NULL,
    p_tempo_ativo_min IN tb_metricas_saude.tempo_ativo_min%TYPE DEFAULT NULL,
    p_notas           IN tb_metricas_saude.notas%TYPE           DEFAULT NULL
) AS
    e_check_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violated, -2290);
BEGIN
    INSERT INTO tb_metricas_saude (id_pet, id_usuario, peso_kg, temperatura_c,
                                   passos, sono_minutos, tempo_ativo_min, notas)
    VALUES (p_id_pet, p_id_usuario, p_peso_kg, p_temperatura_c,
            p_passos, p_sono_minutos, p_tempo_ativo_min, p_notas);
    COMMIT;

EXCEPTION
    WHEN e_check_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_metrica_saude', -2290,
                'Valor fora do range permitido. Temperatura ou peso invalidos.');
        COMMIT;
        RAISE_APPLICATION_ERROR(-20023,
            'Metrica fora do range: temperatura deve ser 30-45 C e peso > 0.');

    WHEN VALUE_ERROR THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_metrica_saude', -6502, 'Tipo de dado invalido na metrica de saude.');
        COMMIT;
        RAISE_APPLICATION_ERROR(-20024, 'Tipo de dado invalido para metrica de saude.');

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_metrica_saude', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_inserir_metrica_saude;
/

-- ---- PROCEDURE: Inserir Recado ----
CREATE OR REPLACE PROCEDURE sp_inserir_recado (
    p_id_pet   IN tb_recado.id_pet%TYPE,
    p_id_usuario IN tb_recado.id_usuario%TYPE,
    p_mensagem IN tb_recado.mensagem%TYPE
) AS
    e_fk_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_violated, -2291);
BEGIN
    INSERT INTO tb_recado (id_pet, id_usuario, mensagem)
    VALUES (p_id_pet, p_id_usuario, p_mensagem);
    COMMIT;

EXCEPTION
    WHEN e_fk_violated THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_recado', -2291,
                'Pet ou Usuario inexistente. id_pet=' || p_id_pet);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20025, 'Pet ou Usuario informado nao existe.');

    WHEN VALUE_ERROR THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_recado', -6502, 'Dado invalido ao inserir recado.');
        COMMIT;
        RAISE_APPLICATION_ERROR(-20026, 'Dado invalido para o recado.');

    WHEN OTHERS THEN
        INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
        VALUES ('sp_inserir_recado', SQLCODE, SQLERRM);
        COMMIT;
        RAISE;
END sp_inserir_recado;
/

-- ---- PROCEDURE: Inserir Log de Erro (manual/testes) ----
CREATE OR REPLACE PROCEDURE sp_inserir_log_erros (
    p_nome_procedure IN tb_log_erros.nome_procedure%TYPE,
    p_codigo_erro    IN tb_log_erros.codigo_erro%TYPE,
    p_mensagem_erro  IN tb_log_erros.mensagem_erro%TYPE
) AS
BEGIN
    INSERT INTO tb_log_erros (nome_procedure, codigo_erro, mensagem_erro)
    VALUES (p_nome_procedure, p_codigo_erro, p_mensagem_erro);
    COMMIT;

EXCEPTION
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao registrar log: dado invalido.');
        RAISE;

    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao registrar log: chave duplicada.');
        RAISE;

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro critico ao gravar log: ' || SQLERRM);
        RAISE;
END sp_inserir_log_erros;
/


-- ==============================================================
-- SECAO 7: CARGA DE DADOS (chamada das procedures)
-- ==============================================================

-- Usuarios
BEGIN
    sp_inserir_usuario('Gustavo Keiji',   'gustavo@email.com',  'hash_gk_001', '11999990001');
    sp_inserir_usuario('Milton Jackson',  'milton@email.com',   'hash_mj_002', '11999990002');
    sp_inserir_usuario('Ana Lima',        'ana@email.com',      'hash_al_003', '11999990003');
    sp_inserir_usuario('Carlos Mendes',   'carlos@email.com',   'hash_cm_004', '11999990004');
    sp_inserir_usuario('Julia Santos',    'julia@email.com',    'hash_js_005', '11999990005');
    sp_inserir_usuario('Dr. Silva Vet',   'drsilva@clinica.com','hash_sv_006', '11988880006');
    DBMS_OUTPUT.PUT_LINE('Usuarios inseridos.');
END;
/

-- Pets
BEGIN
    sp_inserir_pet('Carlos',   'CACHORRO', 'Siberiano Husky',  DATE '2021-03-15', 28,  'M', 'GRANDE',   1);
    sp_inserir_pet('Luna',     'CACHORRO', 'Labrador',         DATE '2020-06-10', 25,  'F', 'GRANDE',   0);
    sp_inserir_pet('Mimi',     'GATO',     'Persa',            DATE '2022-01-20',  4,  'F', 'PEQUENO',  1);
    sp_inserir_pet('Rex',      'CACHORRO', 'Pastor Alemao',    DATE '2019-11-05', 35,  'M', 'GRANDE',   0);
    sp_inserir_pet('Bolinha',  'GATO',     NULL,               DATE '2023-05-12', 3.5, 'M', 'PEQUENO',  1);
    DBMS_OUTPUT.PUT_LINE('Pets inseridos.');
END;
/

-- Vincular usuarios a pets (familia)
BEGIN
    sp_inserir_usuario_pet(1, 1, 'DONO');        -- Gustavo e dono do Carlos
    sp_inserir_usuario_pet(2, 1, 'MEMBRO');      -- Milton cuida do Carlos
    sp_inserir_usuario_pet(1, 2, 'DONO');        -- Gustavo e dono da Luna
    sp_inserir_usuario_pet(3, 2, 'MEMBRO');      -- Ana cuida da Luna
    sp_inserir_usuario_pet(4, 3, 'DONO');        -- Carlos dono da Mimi
    sp_inserir_usuario_pet(5, 4, 'DONO');        -- Julia dona do Rex
    sp_inserir_usuario_pet(5, 5, 'DONO');        -- Julia dona do Bolinha
    sp_inserir_usuario_pet(6, 1, 'VETERINARIO'); -- Dr. Silva e vet do Carlos
    sp_inserir_usuario_pet(6, 2, 'VETERINARIO'); -- Dr. Silva e vet da Luna
    DBMS_OUTPUT.PUT_LINE('Vinculos usuario-pet inseridos.');
END;
/

-- Clinica
BEGIN
    sp_inserir_clinica('Clinica Vet Silva',    'contato@clinicasilva.com', '1133330001', 'Rua das Flores, 123', 'Sao Paulo', 'SP');
    sp_inserir_clinica('PetSaude Centro',      'info@petsaude.com',        '1133330002', 'Av. Paulista, 456',   'Sao Paulo', 'SP');
    sp_inserir_clinica('Veterinaria Amigos',   'amigos@vet.com',           '1133330003', 'Rua dos Pinheiros, 9','Sao Paulo', 'SP');
    DBMS_OUTPUT.PUT_LINE('Clinicas inseridas.');
END;
/

-- Tasks
BEGIN
    sp_inserir_task(1, 1, 'Vermifugo (Carlos)',          'Drontal trimesal',     'MEDICACAO',   DATE '2026-05-25', 'MENSAL');
    sp_inserir_task(1, 1, 'Passeio Longo',               '6km minimo',           'EXERCICIO',   NULL,              'DIARIA');
    sp_inserir_task(1, 1, 'Alimentacao (Jantar)',        'Racao premium 300g',   'ALIMENTACAO', NULL,              'DIARIA');
    sp_inserir_task(1, 2, 'Banho e Tosa',                'Banho quinzenal',      'LIMPEZA',     DATE '2026-05-20', 'SEMANAL');
    sp_inserir_task(2, 1, 'Vacina Anual (Luna)',         'V10 + antirabica',     'VETERINARIO', DATE '2026-05-15', 'UNICA');
    sp_inserir_task(2, 1, 'Alimentacao (Luna)',          'Racao senior',         'ALIMENTACAO', NULL,              'DIARIA');
    sp_inserir_task(3, 4, 'Medicacao Mimi',              'Antiparasitario',      'MEDICACAO',   DATE '2026-06-01', 'MENSAL');
    sp_inserir_task(4, 5, 'Check-up Rex',                'Exame sangue anual',   'VETERINARIO', DATE '2026-06-10', 'UNICA');
    sp_inserir_task(5, 5, 'Brincadeira Bolinha',         '30min com brinquedos', 'EXERCICIO',   NULL,              'DIARIA');
    DBMS_OUTPUT.PUT_LINE('Tasks inseridas.');
END;
/

-- Task Completions (historico de conclusoes)
BEGIN
    sp_inserir_task_completion(2, 1, 'Passeio feito no parque');
    sp_inserir_task_completion(3, 2, 'Carlos ja jantou! (20:30)');
    sp_inserir_task_completion(2, 1, 'Passeio de 7km');
    sp_inserir_task_completion(3, 1, 'Racao dada as 19:30');
    sp_inserir_task_completion(6, 1, 'Luna comeu bem');
    sp_inserir_task_completion(9, 5, 'Bolinha brincou 40min');
    DBMS_OUTPUT.PUT_LINE('Task completions inseridas.');
END;
/

-- Day Streaks
BEGIN
    sp_atualizar_day_streak(1, 1, 12); -- Gustavo & Carlos: 12 dias
    sp_atualizar_day_streak(1, 2, 8);  -- Milton & Carlos: 8 dias
    sp_atualizar_day_streak(2, 1, 5);  -- Gustavo & Luna: 5 dias
    sp_atualizar_day_streak(3, 4, 20); -- Carlos & Mimi: 20 dias
    sp_atualizar_day_streak(4, 5, 3);  -- Julia & Rex: 3 dias
    sp_atualizar_day_streak(5, 5, 15); -- Julia & Bolinha: 15 dias
    DBMS_OUTPUT.PUT_LINE('Day streaks inseridos.');
END;
/

-- Vacinas
BEGIN
    sp_inserir_vacina(1, 'V10 Polivalente',    DATE '2025-04-15', DATE '2026-04-15', 'Dr. Silva', 'LOTE-001A', NULL);
    sp_inserir_vacina(1, 'Antirabica',         DATE '2025-04-15', DATE '2026-04-15', 'Dr. Silva', 'LOTE-002B', NULL);
    sp_inserir_vacina(2, 'V10 Polivalente',    DATE '2025-05-01', DATE '2026-05-15', 'Dr. Silva', 'LOTE-003C', NULL);
    sp_inserir_vacina(3, 'V4 Felina',          DATE '2025-06-10', DATE '2026-06-10', 'Dr. Rocha', 'LOTE-004D', NULL);
    sp_inserir_vacina(4, 'V10 Polivalente',    DATE '2024-11-20', DATE '2025-11-20', 'Dr. Santos','LOTE-005E', NULL);
    sp_inserir_vacina(5, 'V4 Felina',          DATE '2025-02-14', DATE '2026-02-14', 'Dr. Rocha', 'LOTE-006F', NULL);
    DBMS_OUTPUT.PUT_LINE('Vacinas inseridas.');
END;
/

-- Consultas
BEGIN
    sp_inserir_consulta(1, 1, 6, TIMESTAMP '2026-05-05 10:00:00', 'ROTINA',     'Check-up anual', NULL, DATE '2027-05-05');
    sp_inserir_consulta(2, 1, 6, TIMESTAMP '2026-04-20 14:30:00', 'VACINACAO',  'V10 aplicada',   NULL, DATE '2027-04-20');
    sp_inserir_consulta(4, 2, NULL, TIMESTAMP '2026-03-15 09:00:00','ROTINA',   'Exame de sangue',NULL, DATE '2026-06-10');
    DBMS_OUTPUT.PUT_LINE('Consultas inseridas.');
END;
/

-- Medicamentos
BEGIN
    sp_inserir_medicamento(1, 'Drontal Plus',    '1 comprimido', '1x ao mes',   DATE '2026-01-01', DATE '2026-12-31', NULL, 'Vermifugo trimestral');
    sp_inserir_medicamento(3, 'Revolution',      '1 pipeta',     '1x ao mes',   DATE '2026-02-01', DATE '2026-12-31', NULL, 'Antipulgas e carrapatos');
    sp_inserir_medicamento(4, 'Meloxicam',       '0.5mg/kg',     '1x ao dia',   DATE '2026-03-15', DATE '2026-04-15', 3,    'Pos-operatorio');
    DBMS_OUTPUT.PUT_LINE('Medicamentos inseridos.');
END;
/

-- Metricas de Saude (historico para suportar os blocos LAG/LEAD)
BEGIN
    sp_inserir_metrica_saude(1, 1, 27.5, 38.5, 4200, 492, 45, 'Medicao matinal');
    sp_inserir_metrica_saude(1, 1, 27.8, 38.4, 3800, 510, 40, 'Medicao semanal');
    sp_inserir_metrica_saude(1, 1, 28.0, 38.6, 4500, 480, 50, 'Apos passeio longo');
    sp_inserir_metrica_saude(1, 1, 28.2, 38.7, 4150, 495, 48, 'Medicao mensal');
    sp_inserir_metrica_saude(1, 1, 28.0, 38.5, 4300, 500, 47, 'Medicao atual');
    sp_inserir_metrica_saude(2, 1, 24.8, 38.3, 3600, 520, 55, 'Luna - semanal');
    sp_inserir_metrica_saude(2, 1, 25.0, 38.4, 3900, 510, 50, 'Luna - atual');
    sp_inserir_metrica_saude(3, 4,  3.9, 38.2,  200, 780, 30, 'Mimi - semanal');
    sp_inserir_metrica_saude(3, 4,  4.0, 38.1,  210, 800, 28, 'Mimi - atual');
    sp_inserir_metrica_saude(4, 5, 34.5, 38.8, 5100, 460, 65, 'Rex - mensal');
    DBMS_OUTPUT.PUT_LINE('Metricas de saude inseridas.');
END;
/

-- Recados (Canto da Matilha)
BEGIN
    sp_inserir_recado(1, 2, 'Carlos ja jantou! (20:30)');
    sp_inserir_recado(1, 1, 'Passeio de manha, ele estava agitado!');
    sp_inserir_recado(2, 3, 'Luna tomou o remedio das 14h.');
    sp_inserir_recado(1, 6, 'Retorno marcado para 05/05 as 10h - Dr. Silva');
    DBMS_OUTPUT.PUT_LINE('Recados inseridos.');
END;
/


-- ==============================================================
-- SECAO 8: BLOCOS ANONIMOS COM JOINS, GROUP BY E ORDER BY
-- (3 consultas de juncao com agrupamento e ordenacao)
-- ==============================================================

-- ---- Bloco 1: Consultas com JOIN + GROUP BY + ORDER BY ----
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('RELATORIO 1: PETS COM NUMERO DE TAREFAS POR TIPO');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    FOR r IN (
        SELECT p.nome        AS pet_nome,
               p.especie,
               t.tipo,
               COUNT(t.id_task)              AS total_tarefas,
               COUNT(tc.id_completion)       AS total_concluidas
        FROM   tb_pet             p
        JOIN   tb_task            t  ON p.id_pet  = t.id_pet  AND t.ativo = 1
        LEFT   JOIN tb_task_completion tc ON t.id_task = tc.id_task
        GROUP BY p.nome, p.especie, t.tipo
        ORDER BY p.nome, total_tarefas DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(r.pet_nome, 12) || ' | ' ||
            RPAD(r.especie, 9)  || ' | ' ||
            RPAD(r.tipo, 12)    || ' | Total: ' || r.total_tarefas ||
            ' | Concluidas: ' || r.total_concluidas
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('RELATORIO 2: STREAKS ATIVOS POR USUARIO E PET');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    FOR r IN (
        SELECT u.nome              AS usuario,
               p.nome              AS pet_nome,
               ds.dias_consecutivos,
               ds.data_inicio,
               up.papel
        FROM   tb_day_streak   ds
        JOIN   tb_usuario      u  ON ds.id_usuario = u.id_usuario
        JOIN   tb_pet          p  ON ds.id_pet     = p.id_pet
        JOIN   tb_familia  up ON up.id_usuario = u.id_usuario AND up.id_pet = p.id_pet
        WHERE  ds.quebrado = 0
        ORDER BY ds.dias_consecutivos DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(r.usuario, 16)  || ' | ' ||
            RPAD(r.pet_nome, 10) || ' | Dias: ' ||
            LPAD(TO_CHAR(r.dias_consecutivos), 4) ||
            ' | Papel: ' || r.papel
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('RELATORIO 3: PROXIMAS VACINAS POR PET (com clinica)');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    FOR r IN (
        SELECT p.nome              AS pet_nome,
               p.especie,
               v.nome_vacina,
               v.proxima_dose,
               v.proxima_dose - TRUNC(SYSDATE) AS dias_faltando,
               c.nome              AS ultima_clinica
        FROM   tb_vacina      v
        JOIN   tb_pet         p  ON v.id_pet    = p.id_pet
        LEFT   JOIN tb_consulta con ON con.id_pet = p.id_pet
        LEFT   JOIN tb_clinica  c   ON con.id_clinica = c.id_clinica
        WHERE  v.proxima_dose >= TRUNC(SYSDATE)
          AND  p.ativo = 1
        GROUP BY p.nome, p.especie, v.nome_vacina, v.proxima_dose, c.nome
        ORDER BY v.proxima_dose ASC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(r.pet_nome, 10)   || ' | ' ||
            RPAD(r.nome_vacina, 18) || ' | ' ||
            TO_CHAR(r.proxima_dose, 'DD/MM/YYYY') ||
            ' (' || r.dias_faltando || ' dias) | Clinica: ' ||
            NVL(r.ultima_clinica, 'nao vinculada')
        );
    END LOOP;
END;
/


-- ==============================================================
-- SECAO 9: BLOCO COM LAG / LEAD
-- Exibe valor atual, anterior e proximo do peso do pet Carlos
-- ==============================================================
DECLARE
    CURSOR c_metricas IS
        SELECT
            id_metrica,
            TO_CHAR(data_registro, 'DD/MM/YY HH24:MI') AS dt_reg,
            peso_kg                                     AS atual,
            LAG(peso_kg)  OVER (ORDER BY data_registro) AS anterior,
            LEAD(peso_kg) OVER (ORDER BY data_registro) AS proximo
        FROM tb_metricas_saude
        WHERE id_pet = 1    -- Carlos (Siberiano Husky)
        ORDER BY data_registro;

    v_anterior VARCHAR2(20);
    v_proximo  VARCHAR2(20);
    v_linha    c_metricas%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('EVOLUCAO DE PESO - CARLOS (HUSKY)  |  LAG / LEAD');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(
        RPAD('Data', 16) || ' | ' ||
        RPAD('Anterior (kg)', 14) || ' | ' ||
        RPAD('Atual (kg)', 11) || ' | ' ||
        'Proximo (kg)'
    );
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');

    OPEN c_metricas;
    LOOP
        FETCH c_metricas INTO v_linha;
        EXIT WHEN c_metricas%NOTFOUND;

        v_anterior := CASE WHEN v_linha.anterior IS NULL THEN 'Vazio'
                           ELSE TO_CHAR(v_linha.anterior) END;
        v_proximo  := CASE WHEN v_linha.proximo  IS NULL THEN 'Vazio'
                           ELSE TO_CHAR(v_linha.proximo)  END;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_linha.dt_reg, 16)  || ' | ' ||
            RPAD(v_anterior, 14)      || ' | ' ||
            RPAD(TO_CHAR(v_linha.atual), 11) || ' | ' ||
            v_proximo
        );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('============================================================');
    CLOSE c_metricas;

EXCEPTION
    WHEN OTHERS THEN
        IF c_metricas%ISOPEN THEN CLOSE c_metricas; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro no bloco LAG/LEAD: ' || SQLERRM);
END;
/


-- ==============================================================
-- SECAO 10: BLOCO 1 DE CURSOR EXPLICITO
-- Relatorio de tarefas por pet com SUB-TOTAIS e TOTAL GERAL
-- (Requisito: um bloco com sumarizacao e agrupamento)
-- ==============================================================
DECLARE
    CURSOR c_tarefas IS
        SELECT
            p.nome       AS pet_nome,
            t.tipo,
            COUNT(*)                    AS total_tasks,
            COUNT(tc.id_completion)     AS concluidas,
            SUM(COUNT(*)) OVER (PARTITION BY p.nome) AS subtotal_pet
        FROM   tb_task            t
        JOIN   tb_pet             p  ON t.id_pet  = p.id_pet
        LEFT   JOIN tb_task_completion tc ON t.id_task = tc.id_task
        WHERE  t.ativo = 1
        GROUP BY p.nome, t.tipo
        ORDER BY p.nome, t.tipo;

    v_pet_atual     VARCHAR2(255) := NULL;
    v_subtotal      NUMBER        := 0;
    v_total_geral   NUMBER        := 0;
    v_status        VARCHAR2(30);
    v_linha         c_tarefas%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('RELATORIO DE TAREFAS POR PET (CURSOR COM SUBTOTAIS)');
    DBMS_OUTPUT.PUT_LINE('============================================================');

    OPEN c_tarefas;
    LOOP
        FETCH c_tarefas INTO v_linha;
        EXIT WHEN c_tarefas%NOTFOUND;

        -- Impressao de sub-total ao mudar de pet
        IF v_pet_atual IS NOT NULL AND v_pet_atual <> v_linha.pet_nome THEN
            DBMS_OUTPUT.PUT_LINE('  >> Sub-Total [' || v_pet_atual || ']: ' || v_subtotal || ' tarefas');
            DBMS_OUTPUT.PUT_LINE('  --------------------------------------------------');
            v_subtotal := 0;
        END IF;

        v_pet_atual   := v_linha.pet_nome;
        v_subtotal    := v_subtotal  + v_linha.total_tasks;
        v_total_geral := v_total_geral + v_linha.total_tasks;

        -- Tomada de decisao: classificar status da tarefa
        IF v_linha.total_tasks = 0 THEN
            v_status := 'SEM TAREFAS';
        ELSIF v_linha.concluidas >= v_linha.total_tasks THEN
            v_status := 'TUDO CONCLUIDO';
        ELSIF v_linha.concluidas > 0 THEN
            v_status := 'PARCIAL';
        ELSE
            v_status := 'PENDENTE';
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            '  ' ||
            RPAD(v_linha.pet_nome, 10) || ' | ' ||
            RPAD(v_linha.tipo, 12)     || ' | Tot: '   || v_linha.total_tasks  ||
            ' | Concl: '   || v_linha.concluidas    ||
            ' | ' || v_status
        );
    END LOOP;

    -- Sub-total do ultimo pet
    IF v_pet_atual IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('  >> Sub-Total [' || v_pet_atual || ']: ' || v_subtotal || ' tarefas');
    END IF;

    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('  TOTAL GERAL: ' || v_total_geral || ' tarefas');
    DBMS_OUTPUT.PUT_LINE('============================================================');

    CLOSE c_tarefas;
EXCEPTION
    WHEN OTHERS THEN
        IF c_tarefas%ISOPEN THEN CLOSE c_tarefas; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro no relatorio de tarefas: ' || SQLERRM);
END;
/


-- ==============================================================
-- SECAO 11: BLOCO 2 DE CURSOR EXPLICITO
-- Relatorio de usuarios, seus pets e papeis na familia
-- ==============================================================
DECLARE
    CURSOR c_familia IS
        SELECT
            u.nome       AS usuario,
            p.nome       AS pet_nome,
            p.especie,
            p.porte,
            up.papel,
            ds.dias_consecutivos
        FROM   tb_familia  up
        JOIN   tb_usuario      u  ON up.id_usuario = u.id_usuario
        JOIN   tb_pet          p  ON up.id_pet     = p.id_pet
        LEFT   JOIN tb_day_streak ds ON ds.id_usuario = u.id_usuario AND ds.id_pet = p.id_pet
        WHERE  up.ativo = 1 AND p.ativo = 1
        ORDER BY u.nome, p.nome;

    v_descricao_papel VARCHAR2(50);
    v_nivel_streak    VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('FAMILIA DOS PETS (USUARIO x PET x PAPEL x STREAK)');
    DBMS_OUTPUT.PUT_LINE('============================================================');

    FOR r IN c_familia LOOP
        -- Tomada de decisao: descricao do papel
        IF    r.papel = 'DONO'        THEN v_descricao_papel := 'Responsavel Principal';
        ELSIF r.papel = 'MEMBRO'      THEN v_descricao_papel := 'Cuidador da Familia';
        ELSIF r.papel = 'VETERINARIO' THEN v_descricao_papel := 'Clinica / Veterinario';
        ELSE                               v_descricao_papel := 'Papel desconhecido';
        END IF;

        -- Tomada de decisao: nivel do streak
        IF    NVL(r.dias_consecutivos, 0) >= 30 THEN v_nivel_streak := 'LENDA (30+)';
        ELSIF NVL(r.dias_consecutivos, 0) >= 10 THEN v_nivel_streak := 'DEDICADO (10+)';
        ELSIF NVL(r.dias_consecutivos, 0) >  0  THEN v_nivel_streak := 'INICIANDO';
        ELSE                                         v_nivel_streak := '-';
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(r.usuario, 16)       || ' | ' ||
            RPAD(r.pet_nome, 10)      || ' | ' ||
            RPAD(r.especie, 9)        || ' | ' ||
            RPAD(v_descricao_papel, 22) || ' | ' ||
            'Streak: ' || NVL(TO_CHAR(r.dias_consecutivos), '0') ||
            ' dias ' || v_nivel_streak
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('============================================================');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro no relatorio familia: ' || SQLERRM);
END;
/


-- ==============================================================
-- SECAO 12: BLOCO 3 DE CURSOR EXPLICITO
-- Relatorio de medicamentos ativos com status de vigencia
-- ==============================================================
DECLARE
    CURSOR c_medicamentos IS
        SELECT
            p.nome       AS pet_nome,
            m.nome       AS medicamento,
            m.dosagem,
            m.frequencia,
            m.data_inicio,
            m.data_fim,
            m.notas
        FROM   tb_medicamento m
        JOIN   tb_pet         p ON m.id_pet = p.id_pet
        WHERE  p.ativo = 1
        ORDER BY p.nome, m.data_inicio DESC;

    v_status        VARCHAR2(30);
    v_dias_restantes NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('MEDICAMENTOS DOS PETS COM STATUS DE VIGENCIA');
    DBMS_OUTPUT.PUT_LINE('============================================================');

    FOR r IN c_medicamentos LOOP
        v_dias_restantes := CASE
            WHEN r.data_fim IS NULL THEN NULL
            ELSE r.data_fim - TRUNC(SYSDATE)
        END;

        -- Tomada de decisao: status do medicamento
        IF    r.data_fim IS NULL THEN
            v_status := 'USO CONTINUO';
        ELSIF v_dias_restantes < 0 THEN
            v_status := 'ENCERRADO';
        ELSIF v_dias_restantes <= 7 THEN
            v_status := 'VENCENDO EM BREVE';
        ELSE
            v_status := 'EM TRATAMENTO';
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(r.pet_nome, 10)      || ' | ' ||
            RPAD(r.medicamento, 16)   || ' | ' ||
            NVL(r.dosagem, 'N/I')     || ' | ' ||
            NVL(r.frequencia, 'N/I')  || ' | ' ||
            v_status ||
            CASE WHEN v_dias_restantes IS NOT NULL AND v_dias_restantes >= 0
                 THEN ' (' || v_dias_restantes || ' dias)' ELSE '' END
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('============================================================');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro no relatorio de medicamentos: ' || SQLERRM);
END;
/


-- ==============================================================
-- SECAO 13: BLOCO 4 DE CURSOR EXPLICITO
-- Ranking de Day Streaks com classificacao e alerta de quebra
-- ==============================================================
DECLARE
    CURSOR c_streaks IS
        SELECT
            u.nome       AS usuario,
            p.nome       AS pet_nome,
            ds.dias_consecutivos,
            ds.data_inicio,
            ds.quebrado,
            ds.data_quebra,
            RANK() OVER (ORDER BY ds.dias_consecutivos DESC) AS posicao
        FROM   tb_day_streak ds
        JOIN   tb_usuario    u  ON ds.id_usuario = u.id_usuario
        JOIN   tb_pet        p  ON ds.id_pet     = p.id_pet
        ORDER BY ds.dias_consecutivos DESC;

    v_nivel     VARCHAR2(30);
    v_situacao  VARCHAR2(30);
    v_total     NUMBER := 0;
    v_max_dias  NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('RANKING DE DAY STREAKS');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(
        RPAD('#',  4) || RPAD('Usuario',    16) || RPAD('Pet',       10) ||
        RPAD('Dias', 6) || RPAD('Nivel',    18) || 'Situacao'
    );
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');

    FOR r IN c_streaks LOOP
        v_total := v_total + 1;
        IF r.dias_consecutivos > v_max_dias THEN
            v_max_dias := r.dias_consecutivos;
        END IF;

        -- Tomada de decisao: nivel pelo numero de dias
        IF    r.dias_consecutivos >= 30 THEN v_nivel := 'LENDA  (30+ dias)';
        ELSIF r.dias_consecutivos >= 14 THEN v_nivel := 'EXPERT (14+ dias)';
        ELSIF r.dias_consecutivos >=  7 THEN v_nivel := 'ATIVO  ( 7+ dias)';
        ELSIF r.dias_consecutivos >=  3 THEN v_nivel := 'INICIANTE';
        ELSE                                 v_nivel := 'COMECANADO';
        END IF;

        -- Tomada de decisao: situacao do streak
        IF r.quebrado = 1 THEN
            v_situacao := 'QUEBRADO em ' || TO_CHAR(r.data_quebra, 'DD/MM/YY');
        ELSIF r.dias_consecutivos >= 14 THEN
            v_situacao := 'EXCELENTE!';
        ELSE
            v_situacao := 'ATIVO';
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(TO_CHAR(r.posicao), 4) ||
            RPAD(r.usuario,     16)     ||
            RPAD(r.pet_nome,    10)     ||
            RPAD(TO_CHAR(r.dias_consecutivos), 6) ||
            RPAD(v_nivel,       18)     ||
            v_situacao
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total de streaks: ' || v_total ||
                         '  |  Maior streak: ' || v_max_dias || ' dias');
    DBMS_OUTPUT.PUT_LINE('============================================================');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro no ranking de streaks: ' || SQLERRM);
END;
/
-- ==============================================================
-- FIM DO SCRIPT
-- ==============================================================