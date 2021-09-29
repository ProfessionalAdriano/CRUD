-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA.....: AMADEUS CAPITALIZACAO
-- DESCRICAO...: AUTOMACAO DOS PROCESSOS DE ABATIMENTO DE EMPRESTIMO COM RESGATE DE COTAS NO REGIME PROGRESSIVO
-- ANALISTA....: ADRIANO LIMA
-- DATA CRIACAO: 08/09/2021
-- OBJETO......: OWN_FUNCESP.PRE_TBL_LOG_ABAT_EMPR
-- OBJETIVO....: MONITORAR O PROCESSO ATRAVES DA TABELA DE LOG ABAIXO
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



CREATE TABLE OWN_FUNCESP.PRE_TBL_LOG_STATUS(  COD_LOG_STATUS  NUMBER(18) NOT NULL
                                             ,DCR_STATUS      VARCHAR2(255) NOT NULL --1 - PROCESSADO, 2 - PENDENTE, 3 - ERRO
                                            );
                                            

CREATE TABLE OWN_FUNCESP.PRE_TBL_ETAPA( COD_ETAPA  NUMBER(18) NOT NULL
                                       ,DCR_ETAPA  VARCHAR2(255) NOT NULL -- CADASTRO, SIMUL_RESG, APUR_DESC_CONT, PROCESS_RESG_IND, EFET_CADASTRO
                                       );

CREATE TABLE OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP ( COD_LOG_ABAT               NUMBER(18)   NOT NULL
                                                        ,DT_INIC_PROCESS            TIMESTAMP(6) NOT NULL
                                                        ,COD_LOG_STATUS             NUMBER(18)   NOT NULL
                                                        ,COD_ETAPA                  NUMBER(18)   NOT NULL
                                                        ,COD_EMPRS                  NUMBER(3)    NOT NULL
                                                        ,NUM_RGTRO_EMPRG            NUMBER(10)   NOT NULL
                                                        ,NUM_CPF_EMPRG              NUMBER(11)   NOT NULL
                                                        ,TPO_NEGOCIO                NUMBER(2)    NOT NULL
                                                        ,NUM_IDENT_GESTOR           NUMBER(9)    NOT NULL
                                                        ,DTA_INCL                   DATE         NOT NULL                                                                                                                                                                          
                                                        ,MODULE                     VARCHAR2(255)
                                                        ,USUARIO                    VARCHAR2(255)
                                                        ,TERMINAL                   VARCHAR2(255)
                                                        ,CURRENT_USER               VARCHAR2(255)
                                                        ,IP_ADDRESS                 VARCHAR2(255)
                                                        ,OPERACAO                   VARCHAR2(255) -- INSERT, UPDATE, DELETE
                                                        ,DT_FIM_PROCESS             TIMESTAMP(6)                                                        
                                                        ,OBSERVACAO                 VARCHAR2(500)        
                                                        );  
														

CREATE TABLE OWN_FUNCESP.PRE_TBL_LOG_TRANSACAO_ABAT_EMP( COD_LOG_TRANS        NUMBER(18)    NOT NULL
                                                        ,DT_INIC_PROCESS      TIMESTAMP(6)  NOT NULL
                                                        ,COD_OP               CHAR(1)       NOT NULL  
                                                        ,DCR_DML              VARCHAR2(4000)
                                                        ,VALOR_NOVO           VARCHAR2(4000)
                                                        ,VALOR_ANTIGO         VARCHAR2(4000)                                                                  
                                                        ,MODULE               VARCHAR2(255)
                                                        ,USUARIO              VARCHAR2(255)
                                                        ,TERMINAL             VARCHAR2(255)
                                                        ,CURRENT_USER         VARCHAR2(255)
                                                        ,IP_ADDRESS           VARCHAR2(255)
                                                        ,DT_FIM_PROCESS       TIMESTAMP(6)
                                                        ,OBSERVACAO           VARCHAR2(255) 
                                                        );                      
