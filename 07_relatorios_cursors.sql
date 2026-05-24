SET SERVEROUTPUT ON;

-- 1) Listar todas as tarefas, sumarizar pontos totais e por status
BEGIN
    DECLARE
        CURSOR c_tarefas IS
            SELECT id_tarefa, titulo, pontos_tarefa, status_id_status FROM tarefa;

        v_total_pontos NUMBER := 0;
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM tarefa;

        IF v_count = 0 THEN
            RAISE NO_DATA_FOUND;
        END IF;

        DBMS_OUTPUT.PUT_LINE('=== RELATORIO 1: DETALHAMENTO DE TAREFAS E PONTOS ===');
        FOR r IN c_tarefas LOOP
            DBMS_OUTPUT.PUT_LINE('Tarefa: ' || r.titulo || ' | Pontos: ' || r.pontos_tarefa || ' | Status: ' || r.status_id_status);
            v_total_pontos := v_total_pontos + NVL(r.pontos_tarefa,0);
            
            -- Tomada de decisão baseada nos pontos da tarefa
            IF r.pontos_tarefa >= 20 THEN
                DBMS_OUTPUT.PUT_LINE('   -> Prioridade: ALTA (Impacto relevante no cuidado)');
            ELSIF r.pontos_tarefa >= 10 THEN
                DBMS_OUTPUT.PUT_LINE('   -> Prioridade: MEDIA');
            ELSE
                DBMS_OUTPUT.PUT_LINE('   -> Prioridade: BAIXA');
            END IF;
            DBMS_OUTPUT.PUT_LINE(' '); -- Espaço entre as tarefas
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('---------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Valor Numérico Sumarizado (Total de Pontos): ' || v_total_pontos);
        DBMS_OUTPUT.PUT_LINE('---------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Sumarização de Pontos por Status do Agrupamento:');

        FOR r2 IN (
            SELECT s.nome_status, SUM(t.pontos_tarefa) AS soma
            FROM tarefa t
            JOIN status s ON t.status_id_status = s.id_status
            GROUP BY s.nome_status
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Status: ' || r2.nome_status || ' | Pontos acumulados: ' || r2.soma);
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('---------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Carga Total de Pontos em Tarefas dos Pets de cada Responsável:');
        FOR r3 IN (
            SELECT u.nome, SUM(t.pontos_tarefa) AS soma_cuidador
            FROM usuario u
            JOIN usuario_pet up ON u.id_usuario = up.usuario_id_usuario
            JOIN tarefa t ON up.pet_id_pet = t.pet_id_pet
            GROUP BY u.nome
            ORDER BY soma_cuidador DESC
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Responsável: ' || r3.nome || ' | Pontos sob cuidados: ' || r3.soma_cuidador);
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('---------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Pontos Efetivamente Ganhos por Conclusao de Tarefa (Realizadas):');
        FOR r4 IN (
            SELECT u.nome, SUM(t.pontos_tarefa) AS soma_ganhos
            FROM usuario u
            JOIN tarefa t ON u.id_usuario = t.usuario_id_usuario
            GROUP BY u.nome
            ORDER BY soma_ganhos DESC
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Usuário Executor: ' || r4.nome || ' | Pontos Ganhos: ' || r4.soma_ganhos);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('===================================================');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            prc_grava_log('relatorio_tarefas', USER, SQLCODE, 'Nenhuma tarefa encontrada: ' || SQLERRM);

        WHEN VALUE_ERROR THEN
            prc_grava_log('relatorio_tarefas', USER, SQLCODE, 'Erro de valor no relatório de tarefas: ' || SQLERRM);

        WHEN OTHERS THEN
            prc_grava_log('relatorio_tarefas', USER, SQLCODE, SQLERRM);
    END;
END;
/

-- 2) Listar pets castrados e não castrados usando cursor e decisão
BEGIN
    DECLARE
        CURSOR c_pets IS
            SELECT id_pet, nome, castrado FROM pet ORDER BY id_pet;

        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM pet;

        IF v_count = 0 THEN
            RAISE NO_DATA_FOUND;
        END IF;

        FOR r IN c_pets LOOP
            IF r.castrado = 'S' THEN
                DBMS_OUTPUT.PUT_LINE(r.id_pet || ' - ' || r.nome || ': castrado');

            ELSIF r.castrado = 'N' THEN
                DBMS_OUTPUT.PUT_LINE(r.id_pet || ' - ' || r.nome || ': não castrado');

            ELSE
                DBMS_OUTPUT.PUT_LINE(r.id_pet || ' - ' || r.nome || ': castrado desconhecido');
            END IF;
        END LOOP;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            prc_grava_log('relatorio_pets_castracao', USER, SQLCODE, 'Nenhum pet encontrado: ' || SQLERRM);

        WHEN VALUE_ERROR THEN
            prc_grava_log('relatorio_pets_castracao', USER, SQLCODE, 'Erro de valor no relatório de castração: ' || SQLERRM);

        WHEN OTHERS THEN
            prc_grava_log('relatorio_pets_castracao', USER, SQLCODE, SQLERRM);
    END;
END;
/

-- 3) Listar atendimentos e indicar se valor é alto (>100)
BEGIN
    DECLARE
        CURSOR c_atend IS
            SELECT id_atendimento, valor FROM atendimento ORDER BY id_atendimento;

        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM atendimento;

        IF v_count = 0 THEN
            RAISE NO_DATA_FOUND;
        END IF;

        FOR r IN c_atend LOOP
            IF r.valor > 100 THEN
                DBMS_OUTPUT.PUT_LINE('Atendimento ' || r.id_atendimento || ': valor ALTO (' || TO_CHAR(r.valor,'99999990.00') || ')');

            ELSE
                DBMS_OUTPUT.PUT_LINE('Atendimento ' || r.id_atendimento || ': valor normal (' || TO_CHAR(r.valor,'99999990.00') || ')');
            END IF;
        END LOOP;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            prc_grava_log('relatorio_atendimentos', USER, SQLCODE, 'Nenhum atendimento encontrado: ' || SQLERRM);

        WHEN VALUE_ERROR THEN
            prc_grava_log('relatorio_atendimentos', USER, SQLCODE, 'Erro de valor no relatório de atendimentos: ' || SQLERRM);

        WHEN OTHERS THEN
            prc_grava_log('relatorio_atendimentos', USER, SQLCODE, SQLERRM);
    END;
END;
/

-- 4) Listar usuários e informar se possuem telefone cadastrado
BEGIN
    DECLARE
        CURSOR c_usuarios IS
            SELECT id_usuario, nome, telefone_id_telefone FROM usuario ORDER BY nome;

        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM usuario;

        IF v_count = 0 THEN
            RAISE NO_DATA_FOUND;
        END IF;

        FOR r IN c_usuarios LOOP
            IF r.telefone_id_telefone IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE(r.id_usuario || ' - ' || r.nome || ': possui telefone');

            ELSE
                DBMS_OUTPUT.PUT_LINE(r.id_usuario || ' - ' || r.nome || ': sem telefone');
            END IF;
        END LOOP;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            prc_grava_log('relatorio_usuarios_telefone', USER, SQLCODE, 'Nenhum usuário encontrado: ' || SQLERRM);

        WHEN VALUE_ERROR THEN
            prc_grava_log('relatorio_usuarios_telefone', USER, SQLCODE, 'Erro de valor no relatório de usuários: ' || SQLERRM);

        WHEN OTHERS THEN
            prc_grava_log('relatorio_usuarios_telefone', USER, SQLCODE, SQLERRM);
    END;
END;
/