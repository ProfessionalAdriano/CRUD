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

CREATE OR REPLACE PROCEDURE ATT.FCESP_RET_ABAT_RESG_COTAS(  P_COD_EMPRS           ATT.FCESP_TAB_VLR_ABAT_RESG.COD_EMPRS%TYPE
                                                           ,P_NUM_RGTRO_EMPRG     ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_RGTRO_EMPRG%TYPE
                                                           ,P_NUM_CPF_EMPRG       ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_CPF_EMPRG%TYPE
                                                           ,P_TPO_NEGOCIO         ATT.FCESP_TAB_VLR_ABAT_RESG.TPO_NEGOCIO%TYPE --
                                                           ,P_NUM_IDENT_GESTOR    ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_IDENT_GESTOR%TYPE
                                                           ,P_DTA_INCL            ATT.FCESP_TAB_VLR_ABAT_RESG.DTA_INCL%TYPE    --        
                                                           ,P_EXCEPTION           OUT NUMBER
                                                          )
            
AS
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA.....: AMADEUS CAPITALIZACAO
-- DESCRICAO...: AUTOMACAO DOS PROCESSOS DE ABATIMENTO DE EMPRESTIMO COM RESGATE DE COTAS NO REGIME PROGRESSIVO
-- ANALISTA....: ADRIANO LIMA
-- DATA CRIACAO: 23/09/2021
-- OBJETO......: ATT.FCESP_RET_ABAT_RESG_COTAS
--
-- ATIVIDADE...: SUST-7876 - AUTOMATIZAR AS ROTINAS DO ABATIMENTO DE EMPRESTIMO COM RESGATE DE COTAS - IMPLEMENTACAO DO LOG DO PROCESSO
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
    -- VARIABLE TABLE:
    L_REG                ATT.FCESP_TAB_VLR_ABAT_RESG%ROWTYPE;
     
    --- VARIÁVEIS ---
    VN_VLR_TOT_DESC         NUMBER (15,2) :=0;
    VN_VLR_RESID_ABAT       NUMBER (15,2) :=0;
    COD_DESC                NUMBER (1)    :=0;    
    L_VER_REGR_PASSO4       NUMBER        :='';
    L_MODULE                VARCHAR2(255) := '';
    L_OS_USER               VARCHAR2(255) := '';
    L_TERMINAL              VARCHAR2(255) := '';
    L_CURRENT_USER          VARCHAR2(255) := '';
    L_IP_ADDRESS            VARCHAR2(255) := '';
    L_OP                    VARCHAR2(10)  := 'INSERT';
    L_COD_ETAPA             NUMBER        := 4;
    L_OBS                   VARCHAR2(500) := 'PROCEDURE - FCESP_RET_ABAT_RESG_COTAS'; 
    L_COUNT                 NUMBER        := ''; 
        
    -- VARIAVEIS EXCEPTION:
    L_PASSO4_EXC            EXCEPTION;
    L_EXC_RGTRO             EXCEPTION;

        --- ABRE CURSOR COM O VALOR SOLICITADO PARA DESCONTADO DO RESGATE ---
        CURSOR VLR_ABAT IS

        SELECT DISTINCT
              A.NUM_MATR_PARTF
        FROM ATT.FCESP_TAB_VLR_ABAT_RESG A
        WHERE A.DTA_FINAL IS NULL
        ---AND   A.NUM_MATR_PARTF = 8509 --- TESTE INDIVDUAL
        ORDER BY 1;
              
   
        BEGIN
          FOR LINHA IN VLR_ABAT  LOOP

          IF P_TPO_NEGOCIO = 1 THEN
             COD_DESC :=5;
        END IF;

        VN_VLR_TOT_DESC :=0;
                     
        --- RECUPERA O VALOR DESCONTADO DO RESGATE ---
        
BEGIN
                
        BEGIN
                    
              IF (    P_COD_EMPRS        IS NULL OR P_COD_EMPRS = '' 
                   OR P_NUM_RGTRO_EMPRG  IS NULL OR P_NUM_RGTRO_EMPRG = '' 
                   OR P_NUM_CPF_EMPRG    IS NULL OR P_NUM_CPF_EMPRG = '' 
                   OR P_NUM_IDENT_GESTOR IS NULL OR P_NUM_IDENT_GESTOR = '' 
                   OR P_TPO_NEGOCIO      IS NULL OR P_TPO_NEGOCIO = '' 
                   OR P_DTA_INCL         IS NULL OR P_DTA_INCL = '' ) THEN                  
                RAISE L_EXC_RGTRO;                                    
              END IF;
          
              SELECT COUNT(*) AS COUNT
                     INTO L_COUNT
                      FROM       ATT.RESG_PART_CAPIT_FSS      RPCF
                      INNER JOIN ATT.MOV_CONTA_EVENTO_FSS     MCEF
                                                              ON  (RPCF.NUM_SEQ_MVCTEV        = MCEF.NUM_SEQ_MVCTEV)
                      INNER JOIN ATT.ITEM_MOV_CONTA_FSS       IMCF
                                                              ON  (IMCF.NUM_SEQ_MVCTEV        = MCEF.NUM_SEQ_MVCTEV)  
                      INNER JOIN ATT.ITEM_RESGATE_PART        IRP                                                                
                                                              ON  (IRP.NUM_MATR_PARTF         = RPCF.NUM_MATR_PARTF)
                                                              AND (IRP.NUM_RSGPRT             = RPCF.NUM_RSGPRT) 
                      INNER JOIN ATT.SLD_CONTA_PARTIC_FSS     SCPF
                                                              ON  (SCPF.NUM_MATR_PARTF        = RPCF.NUM_MATR_PARTF)
                      INNER JOIN ATT.SCPTBLCRPCABMEMORESGPROG SC                                  
                                                              ON  (SC.NUM_MATR_PARTF          = RPCF.NUM_MATR_PARTF)
                                                              AND (SC.NUM_RSGPRT              = RPCF.NUM_RSGPRT)                                                                                                          
                      INNER JOIN ATT.SCPTBLDRPDETMEMORESGPROG SCP
                                                              ON  (SCP.CRPSEQMEMORIAPROGRESS  = SC.CRPSEQMEMORIAPROGRESS)
                      INNER JOIN ATT.BENEF_RESG_CAPIT_FSS     BRCF                                  
                                                              ON  (BRCF.NUM_MATR_PARTF        = RPCF.NUM_MATR_PARTF)
                                                              AND (BRCF.NUM_RSGPRT            = RPCF.NUM_RSGPRT)
                      INNER JOIN ATT.FCESP_TAB_VLR_ABAT_RESG  FTVA
                                                              ON  (FTVA.NUM_MATR_PARTF        = RPCF.NUM_MATR_PARTF)
                      WHERE FTVA.COD_EMPRS          = P_COD_EMPRS 
                        AND FTVA.NUM_RGTRO_EMPRG    = P_NUM_RGTRO_EMPRG 
                        AND FTVA.NUM_CPF_EMPRG      = P_NUM_CPF_EMPRG 
                        AND FTVA.TPO_NEGOCIO        = P_TPO_NEGOCIO 
                        AND FTVA.NUM_IDENT_GESTOR   = P_NUM_IDENT_GESTOR 
                        AND FTVA.DTA_INCL           = TO_DATE(P_DTA_INCL,'DD/MM/RRRR')
                        AND ROWNUM = 1;
                        
                        
                        
              IF ( L_COUNT <> 0 ) THEN 
                      
                          -- GRAVA O LOG DO PROCESSO:
                          SELECT SYS_CONTEXT('USERENV', 'MODULE')       AS MODULE
                               ,SYS_CONTEXT('USERENV', 'OS_USER')      AS USUARIO
                               ,SYS_CONTEXT('USERENV', 'TERMINAL')     AS TERMINAL
                               ,SYS_CONTEXT('USERENV', 'CURRENT_USER') AS "CURRENT_USER"
                               ,SYS_CONTEXT('USERENV', 'IP_ADDRESS')   AS IP_ADDRESS 
                          INTO  L_MODULE             
                               ,L_OS_USER            
                               ,L_TERMINAL           
                               ,L_CURRENT_USER       
                               ,L_IP_ADDRESS            
                          FROM DUAL;
                          --
                          UPDATE OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP
                          SET DT_INIC_PROCESS = SYSDATE
                             ,COD_LOG_STATUS  = 1
                             ,MODULE          = L_MODULE
                             ,USUARIO         = L_OS_USER
                             ,TERMINAL        = L_TERMINAL
                             ,CURRENT_USER    = L_CURRENT_USER
                             ,IP_ADDRESS      = L_IP_ADDRESS
                             ,OPERACAO        = L_OP
                             ,DT_FIM_PROCESS  = SYSDATE
                             ,OBSERVACAO      = L_OBS
                          --
                          WHERE COD_ETAPA        = L_COD_ETAPA
                            AND COD_EMPRS        = P_COD_EMPRS
                            AND NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG
                            AND NUM_CPF_EMPRG    = P_NUM_CPF_EMPRG
                            AND TPO_NEGOCIO      = P_TPO_NEGOCIO
                            AND NUM_IDENT_GESTOR = P_NUM_IDENT_GESTOR
                            AND DTA_INCL         = TO_DATE(P_DTA_INCL,'DD/MM/RRRR');
                         COMMIT;              
                        
              ELSE
                    RAISE L_PASSO4_EXC;                                                               
              END IF;
                 
        END; 
        --                    
        --
        SELECT  IR.VLR_ITRPRT
        INTO
                VN_VLR_TOT_DESC
        FROM ATT.RESG_PART_CAPIT_FSS R,
             ATT.ITEM_RESGATE_PART IR
        WHERE R.NUM_MATR_PARTF = IR.NUM_MATR_PARTF
        AND   R.NUM_RSGPRT = IR.NUM_RSGPRT
        AND   R.MRC_CANCEL_RSGPRT = 'N'
        AND   R.NUM_TPEVEN = 101
        AND   IR.NUM_TPDESC_ITRPRT = COD_DESC
        AND   R.NUM_MATR_PARTF = LINHA.NUM_MATR_PARTF
        AND   R.DAT_RSGPRT = P_DTA_INCL;
        EXCEPTION WHEN NO_DATA_FOUND THEN
                  VN_VLR_TOT_DESC :=0;
        END;

        VN_VLR_RESID_ABAT := VN_VLR_TOT_DESC;

              FOR VLR_RESG IN (
              SELECT DISTINCT
                    A.NUM_MATR_PARTF,
                    A.NUM_IDENT_GESTOR,
                    A.VLR_ABAT
              FROM ATT.FCESP_TAB_VLR_ABAT_RESG A
              WHERE A.NUM_MATR_PARTF = LINHA.NUM_MATR_PARTF
              AND   A.DTA_FINAL IS NULL
              ORDER BY 1,2
              ) LOOP


                     IF VN_VLR_RESID_ABAT  >= VLR_RESG.VLR_ABAT THEN
                            UPDATE ATT.FCESP_TAB_VLR_ABAT_RESG
                             SET DTA_FINAL = P_DTA_INCL,
                                 VLR_EFET_ABAT = VLR_RESG.VLR_ABAT
                           WHERE TPO_NEGOCIO = P_TPO_NEGOCIO
                           AND   NUM_MATR_PARTF = VLR_RESG.NUM_MATR_PARTF
                             AND NUM_IDENT_GESTOR = VLR_RESG.NUM_IDENT_GESTOR;

                          COMMIT;
                     ELSE
                            UPDATE ATT.FCESP_TAB_VLR_ABAT_RESG
                             SET DTA_FINAL = P_DTA_INCL,
                                 VLR_EFET_ABAT = GREATEST(0,VN_VLR_RESID_ABAT)
                           WHERE TPO_NEGOCIO = P_TPO_NEGOCIO
                           AND   NUM_MATR_PARTF = VLR_RESG.NUM_MATR_PARTF
                             AND NUM_IDENT_GESTOR = VLR_RESG.NUM_IDENT_GESTOR;

                          COMMIT;
                      END IF;

                      VN_VLR_RESID_ABAT := VN_VLR_RESID_ABAT - VLR_RESG.VLR_ABAT;

              END LOOP;
        END LOOP;
        --
        -- SUST-7876 - GRAVA O LOG DO PROCESSAMENTO APOS O CADASTRO SER EFETIVADO:
              SELECT SYS_CONTEXT('USERENV', 'MODULE')       AS MODULE
                    ,SYS_CONTEXT('USERENV', 'OS_USER')      AS USUARIO
                    ,SYS_CONTEXT('USERENV', 'TERMINAL')     AS TERMINAL
                    ,SYS_CONTEXT('USERENV', 'CURRENT_USER') AS "CURRENT_USER"
                    ,SYS_CONTEXT('USERENV', 'IP_ADDRESS')   AS IP_ADDRESS
               INTO  L_MODULE
                    ,L_OS_USER
                    ,L_TERMINAL
                    ,L_CURRENT_USER
                    ,L_IP_ADDRESS
              FROM DUAL; 
              L_COD_ETAPA := 5;       
              --
              -- SUST-7876:
                UPDATE OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP
                 SET DT_INIC_PROCESS = SYSDATE
                    ,COD_LOG_STATUS  = 1
                    ,MODULE          = L_MODULE
                    ,USUARIO         = L_OS_USER
                    ,TERMINAL        = L_TERMINAL
                    ,CURRENT_USER    = L_CURRENT_USER
                    ,IP_ADDRESS      = L_IP_ADDRESS
                    ,OPERACAO        = L_OP
                    ,DT_FIM_PROCESS  = SYSDATE
                    ,OBSERVACAO      = L_OBS
                  --
                 WHERE COD_ETAPA        = L_COD_ETAPA
                   AND COD_EMPRS        = P_COD_EMPRS
                   AND NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG
                   AND NUM_CPF_EMPRG    = P_NUM_CPF_EMPRG
                   AND TPO_NEGOCIO      = P_TPO_NEGOCIO
                   AND NUM_IDENT_GESTOR = P_NUM_IDENT_GESTOR
                   AND DTA_INCL         = P_DTA_INCL;                                                                      
              COMMIT;
              
         EXCEPTION 
        
            WHEN L_PASSO4_EXC THEN                   
                  P_EXCEPTION := 1; -- Necessário processar indicidualmente o resgate das contas do participante no Amadeus Capitalização.
                 ROLLBACK;
                 
            WHEN L_EXC_RGTRO THEN               
               P_EXCEPTION := 2; --DBMS_OUTPUT.PUT_LINE('Necessário informar todos os paramentros para prosseguir');     
                  
            WHEN OTHERS THEN

               DBMS_OUTPUT.PUT_LINE('CODIGO DO ERRO: ' || SQLCODE || ' MSG: ' ||SQLERRM);
               DBMS_OUTPUT.PUT_LINE('LINHA: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);                
        
END;
