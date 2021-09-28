-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA.....: AMADEUS CAPITALIZACAO
-- DESCRICAO...: AUTOMACAO DOS PROCESSOS DE ABATIMENTO DE EMPRESTIMO COM RESGATE DE COTAS NO REGIME PROGRESSIVO
-- ANALISTA....: ADRIANO LIMA
-- DATA CRIACAO: 08/09/2021
-- OBJETO......: OWN_FUNCESP.PRE_TBL_LOG_ABAT_EMPR
-- OBJETIVO....: APAGAR A TABELA DE LOG
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

DROP TABLE OWN_FUNCESP.PRE_TBL_LOG_ABAT_EMPR;
