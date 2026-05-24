-- 05_consultas_joins.sql
-- Blocos anônimos com consultas de join, group by e order by
-- Ambos os blocos utilizam pelo menos 3 consultas com JOIN, GROUP BY e ORDER BY no total.

SET SERVEROUTPUT ON;

-- Bloco 1: Consultas de agrupamento de tarefas por pet e por veterinário
BEGIN
	DBMS_OUTPUT.PUT_LINE('=== BLOCO 1: AGRUPAMENTOS DE TAREFAS ===');
	
	DBMS_OUTPUT.PUT_LINE('--- 1) Quantidade de Tarefas por Pet ---');
	FOR r1 IN (
		SELECT p.nome AS nome_pet, COUNT(t.id_tarefa) AS qtd_tarefas
		FROM tarefa t
		JOIN pet p ON t.pet_id_pet = p.id_pet
		GROUP BY p.nome
		ORDER BY qtd_tarefas DESC, p.nome ASC
	) LOOP
		DBMS_OUTPUT.PUT_LINE('Pet: ' || r1.nome_pet || ' | Qtd Tarefas: ' || r1.qtd_tarefas);
	END LOOP;

	DBMS_OUTPUT.PUT_LINE('--- 2) Quantidade de Tarefas Criadas por Veterinario ---');
	FOR r2 IN (
		SELECT v.nome AS nome_veterinario, COUNT(t.id_tarefa) AS qtd_tarefas
		FROM tarefa t
		JOIN veterinario v ON t.veterinario_id_veterinario = v.id_veterinario
		GROUP BY v.nome
		ORDER BY qtd_tarefas DESC, v.nome ASC
	) LOOP
		DBMS_OUTPUT.PUT_LINE('Vet Criador: ' || r2.nome_veterinario || ' | Qtd Tarefas Criadas: ' || r2.qtd_tarefas);
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

-- Bloco 2: Sumarizações de status, faturamento de consultas e posse de pets
BEGIN
	DBMS_OUTPUT.PUT_LINE('=== BLOCO 2: SUMARIZACOES E METRICAS ===');

	DBMS_OUTPUT.PUT_LINE('--- 3) Quantidade de tarefas por status ---');
	FOR r1 IN (
		SELECT s.nome_status, COUNT(*) AS qtd_tarefas
		FROM tarefa t
		JOIN status s ON t.status_id_status = s.id_status
		GROUP BY s.nome_status
		ORDER BY qtd_tarefas DESC
	) LOOP
		DBMS_OUTPUT.PUT_LINE(r1.nome_status || ': ' || r1.qtd_tarefas);
	END LOOP;

	DBMS_OUTPUT.PUT_LINE('--- 4) Valor total de atendimentos por veterinario ---');
	FOR r2 IN (
		SELECT v.nome AS veterinario, NVL(SUM(a.valor),0) AS total_atendimentos
		FROM atendimento a
		JOIN veterinario v ON a.veterinario_id_veterinario = v.id_veterinario
		GROUP BY v.nome
		ORDER BY total_atendimentos DESC
	) LOOP
		DBMS_OUTPUT.PUT_LINE(r2.veterinario || ': R$ ' || TO_CHAR(r2.total_atendimentos,'99999990.00'));
	END LOOP;

	DBMS_OUTPUT.PUT_LINE('--- 5) Quantidade de pets por usuario (responsaveis) ---');
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
