SET SERVEROUTPUT ON;

-- 1) Listar todas as tarefas, sumarizar pontos totais e por status
BEGIN
    DECLARE
        CURSOR c_tarefas IS
            SELECT id_tarefa, titulo, pontos_tarefa, status_id_status FROM tarefa;
        v_total_pontos NUMBER := 0;
    BEGIN
        FOR r IN c_tarefas LOOP
            DBMS_OUTPUT.PUT_LINE('Tarefa: ' || r.titulo || ' | Pontos: ' || r.pontos_tarefa || ' | Status: ' || r.status_id_status);
            v_total_pontos := v_total_pontos + NVL(r.pontos_tarefa,0);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Total de pontos de todas as tarefas: ' || v_total_pontos);
        FOR r2 IN (SELECT s.nome_status, SUM(t.pontos_tarefa) AS soma
                   FROM tarefa t JOIN status s ON t.status_id_status = s.id_status
                   GROUP BY s.nome_status) LOOP
            DBMS_OUTPUT.PUT_LINE('Status: ' || r2.nome_status || ' | Pontos totais: ' || r2.soma);
        END LOOP;
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
        CURSOR c_pets IS SELECT id_pet, nome, castrado FROM pet ORDER BY id_pet;
    BEGIN
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
        CURSOR c_atend IS SELECT id_atendimento, valor FROM atendimento ORDER BY id_atendimento;
    BEGIN
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
        CURSOR c_usuarios IS SELECT id_usuario, nome, telefone_id_telefone FROM usuario ORDER BY nome;
    BEGIN
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