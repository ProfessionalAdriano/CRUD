-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA.....: AMADEUS CAPITALIZACAO
-- DESCRICAO...: AUTOMACAO DOS PROCESSOS DE ABATIMENTO DE EMPRESTIMO COM RESGATE DE COTAS NO REGIME PROGRESSIVO
-- ANALISTA....: ADRIANO LIMA
-- DATA CRIACAO: 08/09/2021
-- OBJETO......: CRIACAO DE SEQUENCE - OWN_FUNCESP.PRE_SEQ_LOG_ABAT_EMPR
-- OBJETIVO....: CONTROLAR A PK DA TABELA DE LOG 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SET ECHO ON
SET TIME ON
SET TIMING ON
SET SQLBL ON
SET SERVEROUTPUT ON SIZE 1000000
SET DEFINE OFF
SHOW USER
SELECT * FROM GLOBAL_NAME;
SELECT INSTANCE_NAME, HOST_NAME FROM V$INSTANCE;
SELECT TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS') DATA FROM DUAL;


CREATE SEQUENCE OWN_FUNCESP.PRE_SEQ_LOG_STATUS
INCREMENT BY 1
START WITH 1
ORDER 
CACHE 10;
--
--
CREATE SEQUENCE OWN_FUNCESP.PRE_SEQ_TBL_ETAPA
INCREMENT BY 1
START WITH 1
ORDER 
CACHE 10;
--
--
CREATE SEQUENCE OWN_FUNCESP.PRE_SEQ_ABAT_EMP
INCREMENT BY 1
START WITH 1
ORDER 
CACHE 10;  
--
--
CREATE SEQUENCE OWN_FUNCESP.PRE_SEQ_TRANSACAO_ABAT_EMP
INCREMENT BY 1
START WITH 1
ORDER 
CACHE 10;  


