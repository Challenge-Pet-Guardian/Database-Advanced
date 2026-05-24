# Database-Advanced

## 👥 Integrantes

<table>
<tr>
<th>Nome</th>
<th>RM</th>
<th>Turma</th>
<th>GitHub</th>
<th>LinkedIn</th>
</tr>

<tr>
<td>Enzo Okuizumi</td>
<td>561432</td>
<td>2TDSPG</td>
<td><a href="https://github.com/EnzoOkuizumiFiap">EnzoOkuizumiFiap</a></td>
<td><a href="https://www.linkedin.com/in/enzo-okuizumi-b60292256/">Enzo Okuizumi</a></td>
</tr>

<tr>
<td>Lucas Barros Gouveia</td>
<td>566422</td>
<td>2TDSPG</td>
<td><a href="https://github.com/LuzBGouveia">LuzBGouveia</a></td>
<td><a href="https://www.linkedin.com/in/lucas-barros-gouveia-09b147355/">Lucas Barros Gouveia</a></td>
</tr>

<tr>
<td>Milton Marcelino</td>
<td>564836</td>
<td>2TDSPG</td>
<td><a href="https://github.com/MiltonMarcelino">MiltonMarcelino</a></td>
<td><a href="http://linkedin.com/in/milton-marcelino-250298142">Milton Marcelino</a></td>
</tr>

<tr>
<td>Luna de Carvalho Guimarães</td>
<td>562290</td>
<td>2TDSPG</td>
<td><a href="https://github.com/lunaguima">lunaguima</a></td>
<td><a href="https://www.linkedin.com/in/luna-m-guimar%C3%A3es-1850ab173/">Luna M. Guimarães</a></td>
</tr>

<tr>
<td>Gustavo Okada</td>
<td>563428</td>
<td>2TDSPG</td>
<td><a href="https://github.com/Gdev3356">GustavoOkada7268</a></td>
<td><a href="https://www.linkedin.com/in/gustavo-okada-53a3b8359/">Gustavo Okada</a></td>
</tr>

</table>

---

## Repositório Github e Documentação Banco de dados

[Repositório Github](https://github.com/Challenge-Pet-Guardian/Database-Advanced) | [Documentação Banco de dados](/docs/Documentação%20Database%20Advanced%20-%20Pet%20Guardian.pdf)


### 🗄️ Modelagem Lógica e Relacional do Banco de Dados

![Modelo Lógica](docs/Logical.png)


![Modelo Relacional](docs/Relational.png)

---

## Ordem Recomendada de Execução
Para garantir a integridade referencial (chaves estrangeiras) e a criação bem-sucedida de todas as dependências, os arquivos devem ser executados exatamente na seguinte ordem:

1. `01_ddl_tabelas.sql` — Criação de todas as tabelas, índices e constraints de chave primária e estrangeira.
2. `02_ddl_logs.sql` — Criação da estrutura de logs para auditoria de erros (tabela `log_erros`, sequence e trigger).
3. `03_procedures_carga.sql` — Criação das sequences de chaves primárias e das procedures de carga parametrizadas por tabela (incluindo o gravador de logs autônomo).
4. `04_blocos_anonimos_insercao.sql` — Execução de blocos anônimos para inserção da carga de dados de exemplo utilizando as procedures de carga.
5. `05_consultas_joins.sql` — Consultas de testes que comprovam o funcionamento de agrupamento (GROUP BY) e ordenação (ORDER BY) em múltiplas tabelas unidas (JOINs).
6. `06_consulta_valor_anterior_proximo.sql` — Bloco anônimo contendo o relatório utilizando as funções analíticas `LAG` e `LEAD`.
7. `07_relatorios_cursors.sql` — Execução dos 4 relatórios baseados em cursores explícitos e lógica de tomada de decisão.

---

## Modelo Descritivo

### 1. Introdução
Apresentando o **Modelo Descritivo** do banco de dados relacional da plataforma **PetGuardian**, desenvolvido para o banco de dados Oracle. O objetivo deste modelo é documentar a estrutura física de armazenamento, detalhando as tabelas, tipos de dados, chaves primárias (PK), chaves estrangeiras (FK), restrições (constraints) e a finalidade de cada tabela no contexto do sistema.

O modelo está em conformidade com a **3ª Forma Normal (3FN)**, garantindo integridade de dados e eliminando redundâncias.

---

### 2. Dicionário de Dados (Catálogo de Tabelas)

### 2.1. Tabela: USUARIO
Armazena as informações dos responsáveis e usuários principais da plataforma Pet Guardian.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_usuario` | `NUMBER(3)` | Não | PK | Identificador único do usuário. |
| `nome` | `VARCHAR2(100)` | Não | - | Nome completo do usuário. |
| `email` | `VARCHAR2(50)` | Não | - | E-mail de login (único no sistema). |
| `senha` | `VARCHAR2(20)` | Não | - | Senha do usuário. |
| `telefone_id_telefone` | `NUMBER(3)` | Sim | FK | Referência para a tabela `telefone` (Unique Index). |

* **Relacionamentos:**
  * Um Usuário possui um Telefone (1:1 com `telefone`).
  * Um Usuário possui um ou mais Endereços (N:M com `endereco` via `usuario_endereco`).
  * Um Usuário possui um ou mais Pets cadastrados (N:M com `pet` via `usuario_pet`).
  * Um Usuário pode realizar ou registrar Conclusão de Tarefas (1:N com `tarefa`).

---

### 2.2. Tabela: VETERINARIO
Armazena dados cadastrais dos médicos veterinários vinculados ao monitoramento e clínicas.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_veterinario` | `NUMBER(3)` | Não | PK | Identificador único do veterinário. |
| `nome` | `VARCHAR2(100)` | Não | - | Nome completo do profissional. |
| `email` | `VARCHAR2(50)` | Não | - | E-mail de login do veterinário. |
| `senha` | `VARCHAR2(20)` | Não | - | Senha do veterinário. |
| `telefone_id_telefone` | `NUMBER(3)` | Não | FK | Referência única para a tabela `telefone`. |
| `clinica_id_clinica` | `NUMBER(3)` | Sim | FK | Referência para a tabela `clinica`. |

* **Relacionamentos:**
  * Um Veterinário possui um Telefone (1:1 com `telefone`).
  * Um Veterinário pode atuar em uma Clínica (N:1 com `clinica`).
  * Um Veterinário prescreve ou gerencia Tarefas e atende Pets (1:N com `tarefa` e `atendimento`).

---

### 2.3. Tabela: TELEFONE
Armazena números de telefone associados a usuários, veterinários ou clínicas.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_telefone` | `NUMBER(3)` | Não | PK | Identificador único do telefone. |
| `num_ddd` | `VARCHAR2(2)` | Não | - | DDD do telefone (ex: "11"). |
| `num_tel` | `VARCHAR2(9)` | Não | - | Número telefônico (ex: "999998888"). |

* **Relacionamentos:**
  * Um Telefone pode pertencer a um Usuário (1:1 com `usuario`).
  * Um Telefone pode pertencer a um Veterinário (1:1 com `veterinario`).
  * Um Telefone pode pertencer a uma Clínica Veterinária (1:1 com `clinica`).

---

### 2.4. Tabela: ENDERECO
Registra os logradouros físicos onde residem usuários ou onde clínicas veterinárias estão situadas.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_endereco` | `NUMBER(3)` | Não | PK | Identificador único do endereço. |
| `cep` | `VARCHAR2(8)` | Não | - | Código de Endereçamento Postal (somente números). |
| `rua` | `VARCHAR2(150)` | Não | - | Nome do logradouro (rua, avenida, etc.). |
| `numero` | `VARCHAR2(5)` | Não | - | Número do imóvel. |
| `bairro_id_bairro` | `NUMBER(3)` | Não | FK | Referência para a tabela `bairro`. |

* **Relacionamentos:**
  * Um Endereço pertence a um Bairro (N:1 com `bairro`).
  * Um Endereço está vinculado a um Usuário (N:M através de `usuario_endereco`).
  * Um Endereço pode abrigar uma Clínica Veterinária (1:1 com `clinica`).

---

### 2.5. Tabela: BAIRRO
Armazena os bairros associados a uma cidade.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_bairro` | `NUMBER(3)` | Não | PK | Identificador único do bairro. |
| `nome_bairro` | `VARCHAR2(30)` | Não | - | Nome do bairro. |
| `cidade_id_cidade` | `NUMBER(3)` | Não | FK | Referência para a tabela `cidade`. |

* **Relacionamentos:**
  * Um Bairro pertence a uma Cidade (N:1 com `cidade`).
  * Um Bairro possui um ou mais Endereços (1:N com `endereco`).

---

### 2.6. Tabela: CIDADE
Armazena os municípios vinculados a um estado.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_cidade` | `NUMBER(3)` | Não | PK | Identificador único da cidade. |
| `nome_cidade` | `VARCHAR2(30)` | Não | - | Nome da cidade. |
| `estado_id_estado` | `NUMBER(3)` | Não | FK | Referência para a tabela `estado`. |

* **Relacionamentos:**
  * Uma Cidade pertence a um Estado (N:1 com `estado`).
  * Uma Cidade possui um ou mais Bairros (1:N com `bairro`).

---

### 2.7. Tabela: ESTADO
Armazena as unidades federativas (Estados) para compor a localização geográfica dos endereços.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_estado` | `NUMBER(3)` | Não | PK | Identificador único do estado. |
| `nome_estado` | `VARCHAR2(30)` | Não | - | Nome ou sigla representativa do estado (ex: "SP"). |

* **Relacionamentos:**
  * Um Estado possui uma ou mais Cidades (1:N com `cidade`).

---

### 2.8. Tabela: USUARIO_ENDERECO (Tabela Intermediária)
Tabela associativa para resolver o relacionamento de N:M entre Usuários e Endereços.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `usuario_id_usuario` | `NUMBER(3)` | Não | PK, FK | Referência à tabela `usuario`. |
| `endereco_id_endereco` | `NUMBER(3)` | Não | PK, FK | Referência à tabela `endereco`. |

* **Relacionamentos:**
  * Associa a entidade `usuario` com a entidade `endereco` (N:M).

---

### 2.9. Tabela: CLINICA
Representa os estabelecimentos parceiros ou onde os atendimentos ocorrem.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_clinica` | `NUMBER(3)` | Não | PK | Identificador único da clínica. |
| `nome` | `VARCHAR2(30)` | Não | - | Nome fantasia da clínica. |
| `telefone_id_telefone` | `NUMBER(3)` | Não | FK | Referência única para a tabela `telefone`. |
| `endereco_id_endereco` | `NUMBER(3)` | Não | FK | Referência única para a tabela `endereco`. |

* **Relacionamentos:**
  * Uma Clínica possui um Telefone (1:1 com `telefone`).
  * Uma Clínica possui um Endereço (1:1 com `endereco`).
  * Uma Clínica possui um ou mais Veterinários associados (1:N com `veterinario`).

---

### 2.10. Tabela: PET
Armazena os dados dos animais que recebem os cuidados e monitoramento pela plataforma.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_pet` | `NUMBER(3)` | Não | PK | Identificador único do pet. |
| `nome` | `VARCHAR2(30)` | Não | - | Nome do pet. |
| `idade` | `NUMBER(2)` | Não | - | Idade do pet em anos. |
| `sexo` | `VARCHAR2(1)` | Não | - | Sexo do pet. Regra de validação: deve ser `'F'` ou `'M'`. |
| `porte` | `VARCHAR2(10)` | Não | - | Porte físico do pet. Regra: `'GRANDE'`, `'MEDIO'` ou `'PEQUENO'`. |
| `castrado` | `CHAR(1)` | Não | - | Indicador de castração. Deve ser `'S'` (Sim) ou `'N'` (Não). |
| `raca_id_raca` | `NUMBER(3)` | Não | FK | Referência para a tabela `raca`. |

* **Relacionamentos:**
  * Um Pet pertence a uma Raça (N:1 com `raca`).
  * Um Pet pertence a um ou mais Usuários (N:M com `usuario` via `usuario_pet`).
  * Um Pet possui várias Tarefas e Atendimentos associados (1:N com `tarefa` e `atendimento`).

---

### 2.11. Tabela: RACA
Armazena a listagem de raças disponíveis para os pets cadastrados.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_raca` | `NUMBER(3)` | Não | PK | Identificador único da raça. |
| `nome_raca` | `VARCHAR2(30)` | Não | - | Nome da raça (ex: "Labrador", "Persa"). |

* **Relacionamentos:**
  * Uma Raça pode ser associada a um ou mais Pets (1:N com `pet`).

---

### 2.12. Tabela: USUARIO_PET (Tabela Intermediária)
Tabela associativa que resolve o relacionamento N:M entre Usuários e Pets, identificando os responsáveis por cada animal.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `usuario_id_usuario` | `NUMBER(3)` | Não | PK, FK | Referência à tabela `usuario`. |
| `pet_id_pet` | `NUMBER(3)` | Não | PK, FK | Referência à tabela `pet`. |
| `respon_princ` | `CHAR(1)` | Não | - | Define se o usuário é o responsável principal (`'S'` ou `'N'`). |

* **Relacionamentos:**
  * Associa a entidade `usuario` com a entidade `pet` (N:M).

---

### 2.13. Tabela: TAREFA
Representa as tarefas, alarmes e rotinas de cuidados (medicação, alimentação, passeios) criadas para monitorar a saúde dos animais.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_tarefa` | `NUMBER(3)` | Não | PK | Identificador único da tarefa. |
| `titulo` | `VARCHAR2(30)` | Não | - | Título curto da atividade. |
| `pontos_tarefa` | `NUMBER(3)` | Não | - | Pontuação concedida ao responsável ao concluir a tarefa (gamificação). |
| `descricao` | `VARCHAR2(200)` | Não | - | Detalhamento das instruções da tarefa. |
| `criacao` | `TIMESTAMP` | Não | - | Data/hora de registro da tarefa. |
| `prazo` | `TIMESTAMP` | Não | - | Data/hora limite para realização da tarefa. |
| `conclusao` | `TIMESTAMP` | Sim | - | Data/hora em que a tarefa foi executada (preenchida na conclusão). |
| `usuario_id_usuario` | `NUMBER(3)` | Sim | FK | Referência ao usuário que concluiu a tarefa (`usuario`). |
| `pet_id_pet` | `NUMBER(3)` | Não | FK | Referência ao pet alvo da tarefa (`pet`). |
| `status_id_status` | `NUMBER(3)` | Não | FK | Referência ao status atual da tarefa (`status`). |
| `veterinario_id_veterinario` | `NUMBER(3)` | Não | FK | Referência ao veterinário que prescreveu a tarefa (`veterinario`). |

* **Relacionamentos:**
  * Uma Tarefa é prescrita por um Veterinário (N:1 com `veterinario`).
  * Uma Tarefa é direcionada a um Pet (N:1 com `pet`).
  * Uma Tarefa possui um Status de controle (N:1 com `status`).
  * Uma Tarefa pode ser realizada/concluída por um Responsável (N:1 opcional com `usuario`).

---

### 2.14. Tabela: ATENDIMENTO
Armazena a ficha médica dos atendimentos executados pelos veterinários em pets.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_atendimento` | `NUMBER(3)` | Não | PK | Identificador único do atendimento. |
| `data` | `TIMESTAMP` | Não | - | Data e hora em que o atendimento foi realizado. |
| `anotacoes` | `VARCHAR2(300)` | Não | - | Notas clínicas, diagnósticos e indicações do veterinário. |
| `valor` | `NUMBER(10,2)` | Não | - | Valor financeiro cobrado pelo atendimento (utilizado para sumarizações). |
| `pet_id_pet` | `NUMBER(3)` | Não | FK | Referência ao pet atendido (`pet`). |
| `status_id_status` | `NUMBER(3)` | Não | FK | Referência ao status do atendimento (`status`). |
| `tipo_atend_id_tipo_atend` | `NUMBER(3)` | Não | FK | Referência ao tipo do atendimento (`tipo_atend`). |
| `veterinario_id_veterinario` | `NUMBER(3)` | Não | FK | Referência ao veterinário que realizou o atendimento (`veterinario`). |

* **Relacionamentos:**
  * Um Atendimento é realizado por um Veterinário (N:1 com `veterinario`).
  * Um Atendimento é direcionado a um Pet (N:1 com `pet`).
  * Um Atendimento possui um Status clínico (N:1 com `status`).
  * Um Atendimento possui um Tipo de Atendimento (N:1 com `tipo_atend`).

---

### 2.15. Tabela: STATUS
Tabela de referência para armazenar os estados possíveis de tarefas e atendimentos.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_status` | `NUMBER(3)` | Não | PK | Identificador único do status. |
| `nome_status` | `VARCHAR2(15)` | Não | - | Valor descritivo do status. Regra: `'CONCLUIDO'`, `'EXPIRADO'`, ou `'PENDENTE'`. |

* **Relacionamentos:**
  * Um Status pode classificar várias Tarefas ou Atendimentos (1:N com `tarefa` e `atendimento`).

---

### 2.16. Tabela: TIPO_ATEND
Tabela de referência para a tipificação de consultas e atendimentos veterinários.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_tipo_atend` | `NUMBER(3)` | Não | PK | Identificador do tipo de atendimento. |
| `tipo` | `VARCHAR2(30)` | Não | - | Nome do tipo de atendimento (ex: `'CONSULTA'`, `'VACINACAO'`, etc.). |

* **Relacionamentos:**
  * Um Tipo de Atendimento pode ser associado a múltiplos Atendimentos (1:N com `atendimento`).

---

### 2.17. Tabela: LOG_ERROS (Infraestrutura de Auditoria)
Tabela criada especificamente para registrar exceções disparadas dentro de procedures PL/SQL ou blocos anônimos.

| Coluna | Tipo de Dados | Nulo? | Chave | Descrição / Regra |
| :--- | :--- | :--- | :--- | :--- |
| `id_log` | `NUMBER(12)` | Não | PK | Identificador único do log (alimentado pela trigger `trg_log_erros_bi` e sequence `log_erros_seq`). |
| `nome_procedure` | `VARCHAR2(100)` | Não | - | Nome da procedure ou bloco anônimo onde o erro aconteceu. |
| `usuario` | `VARCHAR2(100)` | Não | - | Nome do usuário de banco conectado no momento do erro. |
| `data_erro` | `TIMESTAMP` | Não | - | Data e hora exata da ocorrência do erro (Default: `SYSTIMESTAMP`). |
| `codigo_erro` | `NUMBER` | Sim | - | Código numérico interno da exceção (retornado por `SQLCODE`). |
| `mensagem_erro` | `VARCHAR2(4000)` | Sim | - | Detalhamento descritivo da exceção (retornado por `SQLERRM`). |

* **Relacionamentos:**
  * Tabela de logs de auditoria interna do banco de dados (sem relacionamentos de chave estrangeira externos para evitar dependências circulares em caso de falhas).

---

### 3. Considerações de Normalização (3FN)
Toda a estrutura de dados foi normalizada até a **Terceira Forma Normal (3FN)**:
1. **Primeira Forma Normal (1FN):** Todos os atributos são atômicos (valores indivisíveis) e não existem grupos de repetição (por exemplo, telefones e endereços foram extraídos para tabelas específicas).
2. **Segunda Forma Normal (2FN):** A base atende à 1FN e todas as colunas não-chave dependem totalmente da chave primária inteira (não existindo dependência parcial de chaves compostas em tabelas associativas como `usuario_pet` e `usuario_endereco`).
3. **Terceira Forma Normal (3FN):** A base atende à 2FN e não possui dependências transitivas. Atributos que dependiam de outros campos não-chave (como o bairro, cidade e estado que dependiam transitivamente do endereço) foram desmembrados nas tabelas de suporte `bairro`, `cidade` e `estado`.

---

### 4. Regras de Negócio e Restrições PL/SQL
Além das restrições de integridade física declaradas no DDL (PK, FK, Check Constraints), o sistema implementa validações dinâmicas de regras de negócio através de procedures PL/SQL:

1. **Regra de Conclusão Única de Tarefa (`PRC_CONCLUIR_TAREFA`)**:
   - Uma tarefa de cuidados com o pet (`tarefa`) pode ter no máximo um executor/concluinte.
   - Quando um responsável conclui uma tarefa, o ID do responsável (`usuario_id_usuario`) e o timestamp de conclusão (`conclusao`) são preenchidos, e o status é atualizado para `CONCLUIDO`.
   - Se houver tentativa de concluir uma tarefa que já possui um responsável executor associado, a procedure aborta a execução impedindo a duplicidade e registra a ocorrência na tabela `LOG_ERROS`.

2. **Hierarquia de Responsabilidade de Pets (`USUARIO_PET`)**:
   - Múltiplos responsáveis podem estar associados e cuidar de um mesmo pet (relacionamento N:M).
   - A modelagem e as regras de negócio garantem que cada pet possua apenas um responsável designado como responsável principal (`respon_princ = 'S'`) para fins de tomada de decisões clínicas.

3. **Flexibilidade de Vínculo Profissional (`VETERINARIO`)**:
   - Um médico veterinário pode estar formalmente vinculado a uma clínica cadastrada (`clinica_id_clinica` preenchido).
   - É permitida a atuação do profissional de forma autônoma/independente, deixando o campo `clinica_id_clinica` com valor `NULL`.
