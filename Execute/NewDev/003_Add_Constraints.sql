-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA.....: AMADEUS CAPITALIZACAO
-- DESCRICAO...: AUTOMACAO DOS PROCESSOS DE ABATIMENTO DE EMPRESTIMO COM RESGATE DE COTAS NO REGIME PROGRESSIVO
-- ANALISTA....: ADRIANO LIMA
-- DATA CRIACAO: 08/09/2021
-- OBJETO......: OWN_FUNCESP.PRE_TBL_LOG_ABAT_EMPR
-- OBJETIVO....: ADICIONAR RESTRICOES NA TABLE DE LOG DO PROCESSO
-- CHECK.......: P - PROCESSADO, E - ERRO, A - ABEND
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

ALTER TABLE OWN_FUNCESP.PRE_TBL_LOG_STATUS
ADD CONSTRAINT FC_PRE_PRK_LOG_STATUS PRIMARY KEY (COD_LOG_STATUS); 
--
ALTER TABLE OWN_FUNCESP.PRE_TBL_ETAPA
ADD CONSTRAINT FC_PRE_PRK_ETAPA PRIMARY KEY (COD_ETAPA); 
--
ALTER TABLE OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP
ADD CONSTRAINT FC_PRE_PRK_LOG_PROCESSO PRIMARY KEY (COD_LOG_ABAT); 
--
ALTER TABLE OWN_FUNCESP.PRE_TBL_LOG_TRANSACAO_ABAT_EMP
ADD CONSTRAINT FC_PRE_PRK_LOG_TRANSACAO_ABAT PRIMARY KEY (COD_LOG_TRANS);
--
ALTER TABLE OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP
ADD CONSTRAINT FC_PRE_PRK_LOG_PROCESSO_FK1 FOREIGN KEY (COD_LOG_STATUS)
REFERENCES OWN_FUNCESP.PRE_TBL_LOG_STATUS (COD_LOG_STATUS);                                                        
--
ALTER TABLE OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP
ADD CONSTRAINT FC_PRE_PRK_LOG_PROCESSO_FK2 FOREIGN KEY (COD_ETAPA)
REFERENCES OWN_FUNCESP.PRE_TBL_ETAPA (COD_ETAPA);
--
ALTER TABLE OWN_FUNCESP.PRE_TBL_LOG_TRANSACAO_ABAT_EMP
ADD CONSTRAINT FC_PRE_CKC_LOG_TRANSACAO_ABAT 
CHECK(COD_OP IN ('I','U','D'));


