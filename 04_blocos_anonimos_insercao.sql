-- 04_blocos_anonimos_insercao.sql
-- Blocos anônimos que utilizam as procedures de carga criadas em 03_procedures_carga.sql
-- Cada bloco apresenta tratamento de exceção (WHEN OTHERS + 2 tratamentos extra)

-- 1) Inserção de dados de referência (raca, status, tipo_atend)
BEGIN
    prc_insere_raca(NULL, 'Vira-Lata');
    prc_insere_raca(NULL, 'Labrador');
    prc_insere_raca(NULL, 'Siamês');
    prc_insere_status(NULL, 'PENDENTE');
    prc_insere_status(NULL, 'CONCLUIDO');
    prc_insere_status(NULL, 'EXPIRADO');
    prc_insere_tipo_atend(NULL, 'CONSULTA');
    prc_insere_tipo_atend(NULL, 'VACINACAO');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('bloco_ref_01', USER, SQLCODE, 'Registro duplicado em bloco de referencia: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('bloco_ref_01', USER, SQLCODE, 'Erro de valor em bloco de referencia: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('bloco_ref_01', USER, SQLCODE, SQLERRM);
END;
/

-- 2) Inserção de telephones, endereco, bairro, cidade, estado, clinica
BEGIN
    prc_insere_telefone(NULL, '11', '999988877');
    prc_insere_estado(NULL, 'SP');
    prc_insere_cidade(NULL, 'Sao Paulo', 1);
    prc_insere_bairro(NULL, 'Pinheiros', 1);
    prc_insere_endereco(NULL, '05400000', 'Rua Exemplo', '123', 1);
    prc_insere_clinica(NULL, 'Clinica Exemplo', 1, 1);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('bloco_ref_02', USER, SQLCODE, 'Registro duplicado em bloco endereco/clinica: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('bloco_ref_02', USER, SQLCODE, 'Erro de valor em bloco endereco/clinica: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('bloco_ref_02', USER, SQLCODE, SQLERRM);
END;
/

-- 3) Inserção de usuários e pets através das procedures
BEGIN
    prc_insere_telefone(NULL, '21', '988776655');
    prc_insere_usuario(NULL, 'Joao Silva', 'joao@example.com', 'senha123', 2);
    prc_insere_usuario(NULL, 'Maria Souza', 'maria@example.com', 'senha123', 1);
    prc_insere_pet(NULL, 'Rex', 5, 'M', 'GRANDE', 'S', 1);
    prc_insere_pet(NULL, 'Mimi', 3, 'F', 'PEQUENO', 'N', 3);
    prc_insere_usuario_pet(1, 1, 'S'); -- Joao dono do Rex
    prc_insere_usuario_pet(2, 2, 'S'); -- Maria dono do Mimi
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('bloco_ref_03', USER, SQLCODE, 'Registro duplicado em bloco usuarios/pets: ' || SQLERRM);
    WHEN VALUE_ERROR THEN
        prc_grava_log('bloco_ref_03', USER, SQLCODE, 'Erro de valor em bloco usuarios/pets: ' || SQLERRM);
    WHEN OTHERS THEN
        prc_grava_log('bloco_ref_03', USER, SQLCODE, SQLERRM);
END;
/

-- 4) Inserção de tarefas de exemplo
BEGIN
    -- buscar um status id para usar (ex: PENDENTE)
    DECLARE
        v_status NUMBER;
    BEGIN
        SELECT id_status INTO v_status FROM status WHERE nome_status = 'PENDENTE' AND ROWNUM = 1;
        prc_insere_tarefa(NULL, 'Tomar remedio', 10, 'Dar remédio pela manhã', SYSTIMESTAMP, SYSTIMESTAMP + 1, NULL, 1, v_status, 1);
        prc_insere_tarefa(NULL, 'Passear', 5, 'Levar para passear', SYSTIMESTAMP, SYSTIMESTAMP + 2, NULL, 1, v_status, 1);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            prc_grava_log('bloco_ref_04', USER, SQLCODE, 'Status PENDENTE não encontrado para inserir tarefas');
        WHEN VALUE_ERROR THEN
            prc_grava_log('bloco_ref_04', USER, SQLCODE, 'Erro de valor ao inserir tarefas: ' || SQLERRM);
        WHEN OTHERS THEN
            prc_grava_log('bloco_ref_04', USER, SQLCODE, SQLERRM);
    END;
END;
/

-- Os blocos acima são exemplos de carga em blocos anônimos; para cargas maiores,
-- reutilize as procedures definidas em 03_procedures_carga.sql passando parâmetros.
