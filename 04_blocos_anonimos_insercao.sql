-- 04_blocos_anonimos_insercao.sql
-- Blocos anônimos que utilizam as procedures de carga criadas em 03_procedures_carga.sql
-- Cada bloco apresenta tratamento de exceção (WHEN OTHERS + 2 tratamentos extra)

-- 1) Inserção de dados de referência (raca, status, tipo_atend)
BEGIN
    prc_insere_raca(NULL, 'Vira-Lata');
    prc_insere_raca(NULL, 'Labrador');
    prc_insere_raca(NULL, 'Siamês');
    prc_insere_raca(NULL, 'Poodle');
    prc_insere_raca(NULL, 'Persa');
    
    prc_insere_status(NULL, 'PENDENTE');
    prc_insere_status(NULL, 'CONCLUIDO');
    prc_insere_status(NULL, 'EXPIRADO');
    
    prc_insere_tipo_atend(NULL, 'CONSULTA');
    prc_insere_tipo_atend(NULL, 'VACINACAO');
    prc_insere_tipo_atend(NULL, 'EXAME');
    prc_insere_tipo_atend(NULL, 'CIRURGIA');
    prc_insere_tipo_atend(NULL, 'CASTRACAO');

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('bloco_ref_01', USER, SQLCODE, 'Registro duplicado em bloco de referencia: ' || SQLERRM);
        ROLLBACK;
        RAISE;

    WHEN VALUE_ERROR THEN
        prc_grava_log('bloco_ref_01', USER, SQLCODE, 'Erro de valor em bloco de referencia: ' || SQLERRM);
        ROLLBACK;
        RAISE;

    WHEN OTHERS THEN
        prc_grava_log('bloco_ref_01', USER, SQLCODE, SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

-- 2) Inserção de telefones, endereco, bairro, cidade, estado, clinica
BEGIN
    prc_insere_telefone(NULL, '11', '999988877'); -- Tel Clinica / Vet / Maria (id 1)
    prc_insere_telefone(NULL, '21', '988776655'); -- Tel Joao (id 2)
    prc_insere_telefone(NULL, '11', '977776666'); -- Tel Pedro (id 3)
    prc_insere_telefone(NULL, '11', '966665555'); -- Tel Ana (id 4)
    prc_insere_telefone(NULL, '11', '955554444'); -- Tel Lucas (id 5)
    prc_insere_telefone(NULL, '11', '944443333'); -- Tel Dr. Carlos (id 6)
    prc_insere_telefone(NULL, '11', '933332222'); -- Tel Dra. Juliana (id 7)
    prc_insere_telefone(NULL, '11', '922221111'); -- Tel Dr. Marcos (id 8)
    
    prc_insere_estado(NULL, 'SP'); -- ID 1
    prc_insere_estado(NULL, 'RJ'); -- ID 2
    
    prc_insere_cidade(NULL, 'Sao Paulo', 1); -- ID 1 (SP)
    prc_insere_cidade(NULL, 'Rio de Janeiro', 2); -- ID 2 (RJ)
    
    prc_insere_bairro(NULL, 'Pinheiros', 1); -- ID 1 (SP)
    prc_insere_bairro(NULL, 'Copacabana', 2); -- ID 2 (RJ)
    prc_insere_bairro(NULL, 'Bela Vista', 1); -- ID 3 (SP)
    
    prc_insere_endereco(NULL, '05400000', 'Rua Exemplo SP', '123', 1); -- ID 1
    prc_insere_endereco(NULL, '02000000', 'Avenida Copacabana', '456', 2); -- ID 2
    prc_insere_endereco(NULL, '01311000', 'Avenida Paulista', '1000', 3); -- ID 3
    prc_insere_endereco(NULL, '05401000', 'Rua dos Pinheiros', '789', 1); -- ID 4
    
    prc_insere_clinica(NULL, 'Clinica Exemplo', 1, 1);

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('bloco_ref_02', USER, SQLCODE, 'Registro duplicado em bloco endereco/clinica: ' || SQLERRM);
        ROLLBACK;
        RAISE;

    WHEN VALUE_ERROR THEN
        prc_grava_log('bloco_ref_02', USER, SQLCODE, 'Erro de valor em bloco endereco/clinica: ' || SQLERRM);
        ROLLBACK;
        RAISE;

    WHEN OTHERS THEN
        prc_grava_log('bloco_ref_02', USER, SQLCODE, SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

-- 3) Inserção de usuários, veterinarios e pets através das procedures
BEGIN
    -- Usuarios
    prc_insere_usuario(NULL, 'Joao Silva', 'joao@example.com', '123mudar', 2);
    prc_insere_usuario(NULL, 'Maria Souza', 'maria@example.com', '123mudar', 1);
    prc_insere_usuario(NULL, 'Pedro Santos', 'pedro@example.com', '123mudar', 3);
    prc_insere_usuario(NULL, 'Ana Oliveira', 'ana@example.com', '123mudar', 4);
    prc_insere_usuario(NULL, 'Lucas Lima', 'lucas@example.com', '123mudar', 5);
    
    -- Veterinarios (Carlos e Marcos com clinica, Juliana sem clinica [NULL])
    prc_insere_veterinario(NULL, 'Dr. Carlos', 'carlos@vet.com', '123mudar', 6, 1);
    prc_insere_veterinario(NULL, 'Dr. Marcos', 'marcos@vet.com', '123mudar', 8, 1);
    prc_insere_veterinario(NULL, 'Dra. Juliana', 'juliana@vet.com', '123mudar', 7, NULL);
    
    -- Pets (pelo menos 5 para o relatorio LAG/LEAD)
    prc_insere_pet(NULL, 'Rex', 5, 'M', 'GRANDE', 'S', 1);
    prc_insere_pet(NULL, 'Mimi', 3, 'F', 'PEQUENO', 'N', 3);
    prc_insere_pet(NULL, 'Thor', 2, 'M', 'MEDIO', 'S', 2);
    prc_insere_pet(NULL, 'Luna', 1, 'F', 'PEQUENO', 'N', 4);
    prc_insere_pet(NULL, 'Mel', 4, 'F', 'PEQUENO', 'S', 5);
    
    -- Relacionamentos usuario_pet (responsabilidade)
    -- Caso 1: 2 usuários cuidam de 1 pet (Rex - ID 1)
    prc_insere_usuario_pet(1, 1, 'S'); -- João responsável principal por Rex
    prc_insere_usuario_pet(2, 1, 'N'); -- Maria responsável secundária por Rex

    -- Caso 2: 2 usuários (Pedro e Ana) cuidam de 2 pets (Mimi [ID 2] e Thor [ID 3])
    prc_insere_usuario_pet(3, 2, 'S'); -- Pedro principal de Mimi
    prc_insere_usuario_pet(4, 2, 'N'); -- Ana secundária de Mimi
    prc_insere_usuario_pet(3, 3, 'N'); -- Pedro secundário de Thor
    prc_insere_usuario_pet(4, 3, 'S'); -- Ana principal de Thor

    -- Caso 3: 1 usuário cuida de 1 pet (Mel - ID 5)
    prc_insere_usuario_pet(5, 5, 'S'); -- Lucas principal de Mel

    -- Caso Extra: Luna (ID 4) cuidada por Maria
    prc_insere_usuario_pet(2, 4, 'S'); -- Maria principal de Luna
    
    -- Relacionamentos usuario_endereco (distribuindo os 5 endereços únicos)
    prc_insere_usuario_endereco(1, 1); -- João no Endereço 1
    prc_insere_usuario_endereco(2, 1); -- Maria no Endereço 1
    prc_insere_usuario_endereco(3, 2); -- Pedro no Endereço 2
    prc_insere_usuario_endereco(4, 3); -- Ana no Endereço 3
    prc_insere_usuario_endereco(5, 4); -- Lucas no Endereço 4

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        prc_grava_log('bloco_ref_03', USER, SQLCODE, 'Registro duplicado em bloco usuarios/veterinarios/pets: ' || SQLERRM);
        ROLLBACK;
        RAISE;

    WHEN VALUE_ERROR THEN
        prc_grava_log('bloco_ref_03', USER, SQLCODE, 'Erro de valor em bloco usuarios/veterinarios/pets: ' || SQLERRM);
        ROLLBACK;
        RAISE;

    WHEN OTHERS THEN
        prc_grava_log('bloco_ref_03', USER, SQLCODE, SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

-- 4) Inserção de tarefas e atendimentos de exemplo
BEGIN
    DECLARE
        v_status_pendente NUMBER;
        v_status_concluido NUMBER;
        v_status_expirado NUMBER;
        v_tipo_consulta NUMBER;
        v_tipo_vacina NUMBER;
    BEGIN
        SELECT id_status INTO v_status_pendente FROM status WHERE nome_status = 'PENDENTE' AND ROWNUM = 1;
        SELECT id_status INTO v_status_concluido FROM status WHERE nome_status = 'CONCLUIDO' AND ROWNUM = 1;
        SELECT id_status INTO v_status_expirado FROM status WHERE nome_status = 'EXPIRADO' AND ROWNUM = 1;
        SELECT id_tipo_atend INTO v_tipo_consulta FROM tipo_atend WHERE tipo = 'CONSULTA' AND ROWNUM = 1;
        SELECT id_tipo_atend INTO v_tipo_vacina FROM tipo_atend WHERE tipo = 'VACINACAO' AND ROWNUM = 1;

        -- Inserção de Tarefas (Home-Care a serem realizadas pelos cuidadores do pet)
        -- a) Tarefas que permanecem PENDENTES
        prc_insere_tarefa(1, 'Dar Remedio do Coracao', 15, 'Dar 1 comprimido de Benazepril pela manha antes do alimento', SYSTIMESTAMP, SYSTIMESTAMP + 1, NULL, 1, v_status_pendente, 1); -- Criado por Dr. Carlos (ID 1)
        prc_insere_tarefa(2, 'Restringir Exercicios', 20, 'Manter o pet em ambiente sem degraus e evitar pulos do sofa', SYSTIMESTAMP, SYSTIMESTAMP + 2, NULL, 1, v_status_pendente, 2);  -- Criado por Dra. Juliana (ID 2)
        prc_insere_tarefa(3, 'Limpar Cicatriz do Pet', 10, 'Higienizar a regiao dos pontos cirurgicos com soro fisiologico', SYSTIMESTAMP, SYSTIMESTAMP + 3, NULL, 3, v_status_pendente, 3); -- Criado por Dr. Marcos (ID 3)

        -- b) Tarefas que iniciam pendentes e serão concluídas pelos usuários (histórico de cuidados realizados)
        prc_insere_tarefa(4, 'Caminhada Fisioterapia', 25, 'Realizar passeio leve de no maximo 10 minutos na grama plana', SYSTIMESTAMP - 5, SYSTIMESTAMP - 4, NULL, 4, v_status_pendente, 1); -- Criado por Dr. Carlos (ID 1)
        prc_insere_tarefa(5, 'Oferecer Racao Renal', 8, 'Fornecer 80g de racao renal umida no pote higienizado', SYSTIMESTAMP - 2, SYSTIMESTAMP - 1, NULL, 5, v_status_pendente, 2);      -- Criado por Dra. Juliana (ID 2)
        prc_insere_tarefa(6, 'Aplicar Pomada Otologica', 12, 'Passar 3 gotas de pomada no ouvido esquerdo apos limpeza', SYSTIMESTAMP - 3, SYSTIMESTAMP - 2, NULL, 1, v_status_pendente, 1);  -- Criado por Dr. Carlos (ID 1)

        -- Execução da conclusão das tarefas (simula a interação dos usuários)
        prc_concluir_tarefa(4, 2, SYSTIMESTAMP - 4.5); -- Maria Souza (ID 2) conclui a tarefa 4
        prc_concluir_tarefa(5, 5, SYSTIMESTAMP - 1.5); -- Lucas Lima (ID 5) conclui a tarefa 5
        prc_concluir_tarefa(6, 1, SYSTIMESTAMP - 2.5); -- Joao Silva (ID 1) conclui a tarefa 6

        -- c) Tarefas que já nascem EXPIRADAS (não foram feitas a tempo)
        prc_insere_tarefa(7, 'Trocar Agua da Fonte', 15, 'Limpar a fonte de agua e abastecer com agua fresca e gelada', SYSTIMESTAMP - 10, SYSTIMESTAMP - 9, NULL, 3, v_status_expirado, 3); -- Criado por Dr. Marcos (ID 3)
        prc_insere_tarefa(8, 'Escovar Pelo Diariamente', 5, 'Escovacao suave para remover pelos mortos e ajudar na dermatite', SYSTIMESTAMP - 8, SYSTIMESTAMP - 7, NULL, 1, v_status_expirado, 2); -- Criado por Dra. Juliana (ID 2)

        -- Inserção de Atendimentos (Simulação de atendimentos em andamento, concluídos e cancelados/expirados)
        prc_insere_atendimento(NULL, SYSTIMESTAMP - 3, 'Consulta geral de rotina', 120.00, 1, v_status_concluido, v_tipo_consulta, 1); -- Concluído (Dr. Carlos)
        prc_insere_atendimento(NULL, SYSTIMESTAMP - 2, 'Aplicacao de vacina V10', 85.00, 2, v_status_concluido, v_tipo_vacina, 2);     -- Concluído (Dra. Juliana)
        prc_insere_atendimento(NULL, SYSTIMESTAMP - 1, 'Consulta dermatologica especial', 180.00, 3, v_status_concluido, v_tipo_consulta, 3); -- Concluído (Dr. Marcos)
        prc_insere_atendimento(NULL, SYSTIMESTAMP, 'Exame clinico e check-up', 95.00, 4, v_status_pendente, v_tipo_consulta, 1);         -- Pendente (Dr. Carlos)
        prc_insere_atendimento(NULL, SYSTIMESTAMP, 'Consulta de urgência febre', 210.00, 5, v_status_expirado, v_tipo_consulta, 2);       -- Expirado (Dra. Juliana)

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            prc_grava_log('bloco_ref_04', USER, SQLCODE, 'Status ou tipo de atendimento nao encontrado para insercao de tarefas/atendimentos');
            ROLLBACK;
            RAISE;

        WHEN VALUE_ERROR THEN
            prc_grava_log('bloco_ref_04', USER, SQLCODE, 'Erro de valor ao inserir tarefas/atendimentos: ' || SQLERRM);
            ROLLBACK;
            RAISE;

        WHEN OTHERS THEN
            prc_grava_log('bloco_ref_04', USER, SQLCODE, SQLERRM);
            ROLLBACK;
            RAISE;
    END;
END;
/