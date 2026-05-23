-- 05_consultas_joins.sql
-- Blocos anônimos com consultas de join, group by e order by

SET SERVEROUTPUT ON;

-- Bloco 1: listar tarefas por pet e por usuário, com agrupamento
BEGIN
	DBMS_OUTPUT.PUT_LINE('--- Tarefas por Pet (id_tarefa | titulo | pet | criador) ---');
	FOR r IN (
		SELECT t.id_tarefa, t.titulo, p.nome AS nome_pet, u.nome AS nome_usuario
		FROM tarefa t
		JOIN pet p ON t.pet_id_pet = p.id_pet
		LEFT JOIN usuario u ON t.usuario_id_usuario = u.id_usuario
		ORDER BY p.nome, t.titulo
	) LOOP
		DBMS_OUTPUT.PUT_LINE(r.id_tarefa || ' | ' || r.titulo || ' | ' || r.nome_pet || ' | ' || NVL(r.nome_usuario,'(sem responsavel)'));
	END LOOP;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		prc_grava_log('bloco_consulta_01', USER, SQLCODE, 'Nenhum dado encontrado: ' || SQLERRM);
		ROLLBACK;
		RAISE;
	WHEN VALUE_ERROR THEN
		prc_grava_log('bloco_consulta_01', USER, SQLCODE, 'Erro de valor na consulta: ' || SQLERRM);
		ROLLBACK;
		RAISE;
	WHEN OTHERS THEN
		prc_grava_log('bloco_consulta_01', USER, SQLCODE, SQLERRM);
		ROLLBACK;
		RAISE;
END;
/

-- Bloco 2: sumarizações e joins (3 consultas com GROUP BY e ORDER BY)
BEGIN
	DBMS_OUTPUT.PUT_LINE('--- Quantidade de tarefas por status ---');
	FOR r1 IN (
		SELECT s.nome_status, COUNT(*) AS qtd_tarefas
		FROM tarefa t
		JOIN status s ON t.status_id_status = s.id_status
		GROUP BY s.nome_status
		ORDER BY qtd_tarefas DESC
	) LOOP
		DBMS_OUTPUT.PUT_LINE(r1.nome_status || ': ' || r1.qtd_tarefas);
	END LOOP;

	DBMS_OUTPUT.PUT_LINE('--- Valor total de atendimentos por veterinario ---');
	FOR r2 IN (
		SELECT v.nome AS veterinario, NVL(SUM(a.valor),0) AS total_atendimentos
		FROM atendimento a
		JOIN veterinario v ON a.veterinario_id_veterinario = v.id_veterinario
		GROUP BY v.nome
		ORDER BY total_atendimentos DESC
	) LOOP
		DBMS_OUTPUT.PUT_LINE(r2.veterinario || ': R$ ' || TO_CHAR(r2.total_atendimentos,'99999990.00'));
	END LOOP;

	DBMS_OUTPUT.PUT_LINE('--- Quantidade de pets por usuario (responsaveis) ---');
	FOR r3 IN (
		SELECT u.nome AS usuario, COUNT(up.pet_id_pet) AS qtd_pets
		FROM usuario u
		JOIN usuario_pet up ON u.id_usuario = up.usuario_id_usuario
		GROUP BY u.nome
		ORDER BY qtd_pets DESC
	) LOOP
		DBMS_OUTPUT.PUT_LINE(r3.usuario || ': ' || r3.qtd_pets);
	END LOOP;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		prc_grava_log('bloco_consulta_02', USER, SQLCODE, 'Nenhum dado encontrado nas sumarizacoes: ' || SQLERRM);
		ROLLBACK;
		RAISE;
	WHEN VALUE_ERROR THEN
		prc_grava_log('bloco_consulta_02', USER, SQLCODE, 'Erro de valor nas sumarizacoes: ' || SQLERRM);
		ROLLBACK;
		RAISE;
	WHEN OTHERS THEN
		prc_grava_log('bloco_consulta_02', USER, SQLCODE, SQLERRM);
		ROLLBACK;
		RAISE;
END;
/
