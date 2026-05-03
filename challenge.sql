-- ==========================================
-- CHALLENGE CLYVO - PET CARE DATABASE
-- Database Schema for Pet Care & Family Management
-- ==========================================

-- ========== TABLE: USER ==========
-- Usuários da plataforma
CREATE TABLE user (
    id_user INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE
);

-- ========== TABLE: PET ==========
-- Animais de estimação
CREATE TABLE pet (
    id_pet INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    especie VARCHAR(100) NOT NULL,  -- Cachorro, Gato
    raca VARCHAR(100),
    data_nascimento DATE,
    peso_kg DECIMAL(5, 2),
    genero ENUM('M', 'F'),
    informacoes VARCHAR(300),
    foto_url VARCHAR(500),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE
);

-- ========== TABLE: USER_PET ==========
-- Relacionamento M:N entre usuários e pets (Família do Pet)
-- Um usuário pode ter vários pets
-- Um pet pode ser cuidado por vários usuários

-- Papel do usuário em relação ao pet:
-- DONO: responsável principal
-- MEMBROS: membro da família que cuida
-- VETERINARIO: clínica/veterinário associado

CREATE TABLE user_pet (
    id_user_pet INT AUTO_INCREMENT PRIMARY KEY,
    id_user INT NOT NULL,
    id_pet INT NOT NULL,
    papel ENUM('DONO', 'MEMBROS', 'VETERINARIO') DEFAULT 'MEMBROS',
    data_adicao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_user) REFERENCES user(id_user) ON DELETE CASCADE,
    FOREIGN KEY (id_pet) REFERENCES pet(id_pet) ON DELETE CASCADE,
    UNIQUE KEY unique_user_pet (id_user, id_pet)
);

-- ========== TABLE: TASK ==========
-- Tarefas de cuidado para o pet
CREATE TABLE task (
    id_task INT AUTO_INCREMENT PRIMARY KEY,
    id_pet INT NOT NULL,
    id_user_criador INT NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    descricao VARCHAR(300),
    tipo ENUM('MEDICACAO', 'ALIMENTACAO', 'EXERCICIO', 'LIMPEZA', 'VETERINARIO', 'OUTRO') NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_vencimento DATE,
    recorrencia ENUM('UNICA', 'DIARIA', 'SEMANAL', 'MENSAL') DEFAULT 'UNICA',
    ativo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_pet) REFERENCES pet(id_pet) ON DELETE CASCADE,
    FOREIGN KEY (id_user_criador) REFERENCES user(id_user) ON DELETE SET NULL
);

-- ========== TABLE: TASK_COMPLETION ==========
-- Registro de conclusão de tarefas (para day streak)
CREATE TABLE task_completion (
    id_completion INT AUTO_INCREMENT PRIMARY KEY,
    id_task INT NOT NULL,
    id_user_responsavel INT NOT NULL,
    data_conclusao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacoes VARCHAR(300),
    FOREIGN KEY (id_task) REFERENCES task(id_task) ON DELETE CASCADE,
    FOREIGN KEY (id_user_responsavel) REFERENCES user(id_user) ON DELETE SET NULL
);

-- ========== TABLE: DAY_STREAK ==========
-- Registro de sequência de dias de cuidado
CREATE TABLE day_streak (
    id_streak INT AUTO_INCREMENT PRIMARY KEY,
    id_pet INT NOT NULL,
    id_user INT NOT NULL,
    dias_consecutivos INT DEFAULT 1,
    data_inicio DATE NOT NULL,
    ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    quebrado BOOLEAN DEFAULT FALSE,
    data_quebra DATE,
    FOREIGN KEY (id_pet) REFERENCES pet(id_pet) ON DELETE CASCADE,
    FOREIGN KEY (id_user) REFERENCES user(id_user) ON DELETE CASCADE,
    UNIQUE KEY unique_user_pet_streak (id_user, id_pet)
);

-- ========== TABLE: CLINICA ==========
-- Clínicas veterinárias
CREATE TABLE clinica (
    id_clinica INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    telefone VARCHAR(20),
    endereco VARCHAR(100),
    cidade VARCHAR(100),
    estado VARCHAR(2),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE
);

-- ========== TABLE: CONSULTA ==========
-- Consultas veterinárias
CREATE TABLE consulta (
    id_consulta INT AUTO_INCREMENT PRIMARY KEY,
    id_pet INT NOT NULL,
    id_clinica INT,
    id_veterinario INT,
    data_consulta DATETIME NOT NULL,
    tipo ENUM('ROTINA', 'EMERGENCIA', 'VACINACAO', 'CIRURGIA') DEFAULT 'ROTINA',
    descricao VARCHAR(300),
    prescricao VARCHAR(300),
    proxima_consulta DATE,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pet) REFERENCES pet(id_pet) ON DELETE CASCADE,
    FOREIGN KEY (id_clinica) REFERENCES clinica(id_clinica) ON DELETE SET NULL,
    FOREIGN KEY (id_veterinario) REFERENCES user(id_user) ON DELETE SET NULL
);

-- ========== TABLE: MEDICAMENTO ==========
-- Histórico de medicamentos
CREATE TABLE medicamento (
    id_medicamento INT AUTO_INCREMENT PRIMARY KEY,
    id_pet INT NOT NULL,
    nome VARCHAR(255) NOT NULL,
    dosagem VARCHAR(100),
    frequencia VARCHAR(100),  -- Ex: "2 vezes ao dia"
    data_inicio DATE,
    data_fim DATE,
    prescricao_id INT,
    notas VARCHAR(300),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pet) REFERENCES pet(id_pet) ON DELETE CASCADE,
    FOREIGN KEY (prescricao_id) REFERENCES consulta(id_consulta) ON DELETE SET NULL
);

-- ========== TABLE: VACINA ==========
-- Registro de vacinação
CREATE TABLE vacina (
    id_vacina INT AUTO_INCREMENT PRIMARY KEY,
    id_pet INT NOT NULL,
    nome_vacina VARCHAR(255) NOT NULL,
    data_aplicacao DATE NOT NULL,
    proxima_dose DATE,
    veterinario VARCHAR(255),
    numero_lote VARCHAR(100),
    notas VARCHAR(300),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pet) REFERENCES pet(id_pet) ON DELETE CASCADE
);

-- ========== INDEXES ==========
CREATE INDEX idx_user_email ON user(email);
CREATE INDEX idx_pet_ativo ON pet(ativo);
CREATE INDEX idx_user_pet_user ON user_pet(id_user);
CREATE INDEX idx_user_pet_pet ON user_pet(id_pet);
CREATE INDEX idx_task_pet ON task(id_pet);
CREATE INDEX idx_task_completion_task ON task_completion(id_task);
CREATE INDEX idx_day_streak_pet_user ON day_streak(id_pet, id_user);
CREATE INDEX idx_consulta_pet ON consulta(id_pet);
CREATE INDEX idx_consulta_clinica ON consulta(id_clinica);

-- ========== VIEWS ==========

-- View: Pets com número de cuidadores
CREATE VIEW vw_pet_cuidadores AS
SELECT 
    p.id_pet,
    p.nome AS pet_nome,
    p.especie,
    COUNT(DISTINCT up.id_user) AS numero_cuidadores,
    GROUP_CONCAT(u.nome SEPARATOR ', ') AS cuidadores
FROM pet p
LEFT JOIN user_pet up ON p.id_pet = up.id_pet AND up.ativo = TRUE
LEFT JOIN user u ON up.id_user = u.id_user
GROUP BY p.id_pet;

-- View: Tarefas pendentes por pet
CREATE VIEW vw_tarefas_pendentes AS
SELECT 
    t.id_task,
    p.id_pet,
    p.nome AS pet_nome,
    t.titulo,
    t.tipo,
    t.data_vencimento,
    u.nome AS criador
FROM task t
JOIN pet p ON t.id_pet = p.id_pet
LEFT JOIN user u ON t.id_user_criador = u.id_user
WHERE t.ativo = TRUE 
  AND (t.data_vencimento >= CURDATE() OR t.data_vencimento IS NULL);

-- ========== STORED PROCEDURES ==========

-- Procedure para atualizar day streak
DELIMITER $$

CREATE PROCEDURE atualizar_day_streak(
    IN p_id_pet INT,
    IN p_id_user INT,
    IN p_dias INT
)
BEGIN
    DECLARE v_dias_atuais INT;
    
    -- Buscar o dia streak atual
    SELECT dias_consecutivos INTO v_dias_atuais
    FROM day_streak
    WHERE id_pet = p_id_pet AND id_user = p_id_user
    LIMIT 1;
    
    IF v_dias_atuais IS NULL THEN
        -- Inserir novo registro
        INSERT INTO day_streak (id_pet, id_user, dias_consecutivos, data_inicio)
        VALUES (p_id_pet, p_id_user, p_dias, CURDATE());
    ELSE
        -- Atualizar registro existente
        UPDATE day_streak
        SET dias_consecutivos = v_dias_atuais + p_dias,
            ultima_atualizacao = NOW()
        WHERE id_pet = p_id_pet AND id_user = p_id_user;
    END IF;
END$$

DELIMITER ;

-- Procedure para quebrar day streak
DELIMITER $$

CREATE PROCEDURE quebrar_day_streak(
    IN p_id_pet INT,
    IN p_id_user INT
)
BEGIN
    UPDATE day_streak
    SET quebrado = TRUE,
        data_quebra = CURDATE()
    WHERE id_pet = p_id_pet AND id_user = p_id_user;
END$$

DELIMITER ;
