SET SERVEROUTPUT ON;

-- Bloco anônimo: para cada pet mostrar nome atual, nome anterior e nome próximo
BEGIN
    DECLARE
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM pet;
        IF v_cnt < 5 THEN
            RAISE NO_DATA_FOUND;
        END IF;
        DBMS_OUTPUT.PUT_LINE('id_pet | nome_atual | nome_anterior | nome_proximo');
        FOR r IN (
            SELECT id_pet,
                   nome AS nome_atual,
                   NVL(LAG(nome) OVER (ORDER BY id_pet), 'Vazio') AS nome_anterior,
                   NVL(LEAD(nome) OVER (ORDER BY id_pet), 'Vazio') AS nome_proximo
            FROM pet
            ORDER BY id_pet
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(r.id_pet || ' | ' || r.nome_atual || ' | ' || r.nome_anterior || ' | ' || r.nome_proximo);
        END LOOP;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            prc_grava_log('bloco_valor_anterior_proximo', USER, SQLCODE, 'Relatório requer ao menos 5 pets cadastrados');

        WHEN VALUE_ERROR THEN
            prc_grava_log('bloco_valor_anterior_proximo', USER, SQLCODE, 'Erro de valor no relatório: ' || SQLERRM);

        WHEN OTHERS THEN
            prc_grava_log('bloco_valor_anterior_proximo', USER, SQLCODE, SQLERRM);
    END;
END;
/

-- Nota: assegure que a tabela PET possua ao menos 5 linhas para relatório com cinco entradas.