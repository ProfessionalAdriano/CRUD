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

CREATE OR REPLACE PROCEDURE ATT.FCESP_CALC_PCT_ABAT_RESG (  P_COD_EMPRS           ATT.FCESP_TAB_VLR_ABAT_RESG.COD_EMPRS%TYPE
                                                           ,P_NUM_RGTRO_EMPRG     ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_RGTRO_EMPRG%TYPE
                                                           ,P_NUM_CPF_EMPRG       ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_CPF_EMPRG%TYPE
                                                           ,P_TPO_NEGOCIO         ATT.FCESP_TAB_VLR_ABAT_RESG.TPO_NEGOCIO%TYPE --
                                                           ,P_NUM_IDENT_GESTOR    ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_IDENT_GESTOR%TYPE
                                                           ,P_DTA_INCL            ATT.FCESP_TAB_VLR_ABAT_RESG.DTA_INCL%TYPE    --        
                                                           ,P_EXCEPTION           OUT NUMBER)

AS
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA.....: AMADEUS CAPITALIZACAO
-- DESCRICAO...: AUTOMACAO DOS PROCESSOS DE ABATIMENTO DE EMPRESTIMO COM RESGATE DE COTAS NO REGIME PROGRESSIVO
-- ANALISTA....: ADRIANO LIMA
-- DATA CRIACAO: 21/09/2021
-- OBJETO......: ATT.FCESP_CALC_PCT_ABAT_RESG
--
-- ATIVIDADE...: SUST-7876 - AUTOMATIZAR AS ROTINAS DO ABATIMENTO DE EMPRESTIMO COM RESGATE DE COTAS - IMPLEMENTACAO DO LOG DO PROCESSO
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    -- VARIAVEIS:
    VN_VLR_DEPENDENTE       NUMBER        :=0;
    VN_QTDE_DEPEND          NUMBER        :=0;
    VN_VLR_BRUTO_RESG       NUMBER (15,2) :=0;
    VN_VLR_ALIQ_IR          NUMBER (15,4) :=0;
    VN_VLR_DESC_IR          NUMBER (15,2) :=0;
    VN_VLR_IR               NUMBER (15,2) :=0;
    VN_VLR_ISENTO           NUMBER (15,2) :=0;
    VN_VLR_BASE_IR          NUMBER (15,2) :=0;
    VN_VLR_BASE_IR_FINAL    NUMBER (15,2) :=0;
    VN_VLR_RESID_ABAT       NUMBER (15,2) :=0;
    VN_VLR_RESID_ABAT_FINAL NUMBER (15,2) :=0;
    VN_PCT_ABAT_CTA         NUMBER (9,8)  :=0;
    VN_SEQ_ABAT             NUMBER        :=0;
    VN_ACUM_SLD_1           NUMBER (16,2) :=0;
    VN_ACUM_SLD_2           NUMBER (16,2) :=0;
    VN_VLR_RESID_ABAT_1     NUMBER (16,2) :=0;
    VN_VLR_RESID_ABAT_2     NUMBER (16,2) :=0;

    L_PASSO2_OUT            NUMBER :='';
    L_VER_REGR_PASSO2       NUMBER :='';
    L_ETAPA                 NUMBER := 3;
    L_OPERACAO              VARCHAR2(10)  := 'INSERT';
    L_OBS                   VARCHAR2(500) := 'PROCEDURE - FCESP_CALC_PCT_ABAT_RESG';
    L_MODULE                VARCHAR2(255) := '';
    L_OS_USER               VARCHAR2(255) := '';
    L_TERMINAL              VARCHAR2(255) := '';
    L_CURRENT_USER          VARCHAR2(255) := '';
    L_IP_ADDRESS            VARCHAR2(255) := '';
    L_COUNT                 NUMBER        := '';
    L_COD_ETAPA             NUMBER        := 2;
    

    -- VARIAVEIS EXCEPTION:
    L_PASSO2_EXC            EXCEPTION;
    L_EXC_RGTRO             EXCEPTION;
    


   CURSOR VLR_ABAT IS

      SELECT VA.COD_EMPRS,
             VA.NUM_RGTRO_EMPRG,
             VA.NUM_MATR_PARTF,
             AD.COD_TPPCP,
             VA.TPO_NEGOCIO,
             AD.NUM_PLBNF,
             SUM(VA.VLR_ABAT) ABAT_TOTAL
              FROM ATT.FCESP_TAB_VLR_ABAT_RESG VA,
                   ATT.ADESAO_PLANO_PARTIC_FSS AD
      WHERE VA.NUM_MATR_PARTF = AD.NUM_MATR_PARTF
      AND   AD.DAT_FIM_ADPLPR IS NULL
      AND   VA.DTA_FINAL IS NULL
      ---AND   VA.NUM_MATR_PARTF = 72547 --- PARA TESTES INDIVIDUAIS
      AND   VA.TPO_NEGOCIO = P_TPO_NEGOCIO
      GROUP BY VA.COD_EMPRS, VA.NUM_RGTRO_EMPRG, VA.NUM_MATR_PARTF, AD.COD_TPPCP, VA.TPO_NEGOCIO, AD.NUM_PLBNF
      ORDER BY VA.COD_EMPRS, VA.NUM_RGTRO_EMPRG;

  
BEGIN
            -- SUST-7876 - VALIDA SE FOI EFETUADO A SIMULACAO DO RESGATE NO CAPITALIZACAO NA AREA DE EMPRESTIMO:           
            IF (    P_COD_EMPRS        IS NULL OR P_COD_EMPRS = '' 
                 OR P_NUM_RGTRO_EMPRG  IS NULL OR P_NUM_RGTRO_EMPRG = '' 
                 OR P_NUM_CPF_EMPRG    IS NULL OR P_NUM_CPF_EMPRG = '' 
                 OR P_NUM_IDENT_GESTOR IS NULL OR P_NUM_IDENT_GESTOR = '' 
                 OR P_TPO_NEGOCIO      IS NULL OR P_TPO_NEGOCIO = '' 
                 OR P_DTA_INCL         IS NULL OR P_DTA_INCL = '' ) THEN                  
              RAISE L_EXC_RGTRO;                                    
            END IF;
           --                        
           SELECT COUNT(*) AS COUNT
           INTO L_COUNT
            FROM ATT.SIMULACAO_BENEF_FSS             SBF
            INNER JOIN ATT.SIMULACAO_BENEF_CD_FSS    SBCF
                                                     ON (SBF.NUM_MATR_PARTF   = SBCF.NUM_MATR_PARTF)
                                                     AND SBF.NUM_SQNCL_SMLBNF = SBCF.NUM_SQNCL_SMLBNF
            INNER JOIN ATT.SIMULACAO_FUNDO_FSS       SFF
                                                     ON (SBCF.NUM_MATR_PARTF   = SFF.NUM_MATR_PARTF)
                                                     AND SBCF.NUM_SQNCL_SMLBNF = SFF.NUM_SQNCL_SMLBNF
                                                     AND SBCF.DAT_SMLBNF_SMLCD = SFF.DAT_SMLBNF_SMLCD
            INNER JOIN ATT.FCESP_TAB_VLR_ABAT_RESG   FTVA
                                                     ON (SBF.NUM_MATR_PARTF    = FTVA.NUM_MATR_PARTF)

            AND FTVA.COD_EMPRS        = P_COD_EMPRS                        
            AND FTVA.NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG                  
            AND FTVA.NUM_CPF_EMPRG    = P_NUM_CPF_EMPRG                    
            AND FTVA.TPO_NEGOCIO      = P_TPO_NEGOCIO                      
            AND FTVA.NUM_IDENT_GESTOR = P_NUM_IDENT_GESTOR                              
            AND FTVA.DTA_INCL         = TO_DATE(P_DTA_INCL,'DD/MM/RRRR');
            
            
            IF ( L_COUNT <> 0) THEN
            
             -- 
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
                           
               -- GRAVA O LOG DO PROCESSO: 
               UPDATE OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP
               SET DT_INIC_PROCESS = SYSDATE
                  ,COD_LOG_STATUS  = 1
                  ,MODULE          = L_MODULE
                  ,USUARIO         = L_OS_USER
                  ,TERMINAL        = L_TERMINAL
                  ,CURRENT_USER    = L_CURRENT_USER
                  ,IP_ADDRESS      = L_IP_ADDRESS
                  ,OPERACAO        = L_OPERACAO
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
                 RAISE L_PASSO2_EXC;            
            END IF;
            --
            FOR LINHA IN VLR_ABAT  LOOP

                      --- ALIQUOTA DE IR ---
                        IF LINHA.NUM_PLBNF IN (16, 17) THEN
                           VN_VLR_ALIQ_IR    := .15;
                           VN_VLR_DESC_IR    := 0;
                           VN_VLR_DEPENDENTE := 0;
                           VN_QTDE_DEPEND    := 0;
                        ELSE

                      SELECT NVL(MAX(FS.FAT_ALIQT_IRRF/100),0), NVL(MAX(FS.VLR_PRDDZ_IRRF),0)
                               INTO VN_VLR_ALIQ_IR, VN_VLR_DESC_IR
                               FROM FAIXA_SALARIAL_IRRF FS
                              WHERE FS.VLR_FAIXA_IRRF =
                                   (SELECT MIN(F.VLR_FAIXA_IRRF)
                                      FROM FAIXA_SALARIAL_IRRF F
                                     WHERE F.ANO_FAIXA_IRRF*100+F.MES_FAIXA_IRRF = FS.ANO_FAIXA_IRRF*100+FS.MES_FAIXA_IRRF
                                       AND F.VLR_FAIXA_IRRF >= LINHA.ABAT_TOTAL)
                                AND FS.ANO_FAIXA_IRRF*100+FS.MES_FAIXA_IRRF = (SELECT MAX(FF.ANO_FAIXA_IRRF*100+FF.MES_FAIXA_IRRF)
                                                                                 FROM FAIXA_SALARIAL_IRRF FF
                                                                                WHERE FF.ANO_FAIXA_IRRF*100+FF.MES_FAIXA_IRRF <= TO_CHAR(P_DTA_INCL,'YYYYMM'));

                      --- RECUPERA O VALOR DE ABATIMENTO POR DEPENDENTE PARA FINS DE IR ---
                          SELECT T.VLR_PRDDZ_DPDTE
                             INTO  VN_VLR_DEPENDENTE
                             FROM ATT.DEDUCAO_IRRF_DEPEND T
                             WHERE ((T.ANO_DEDUC_IRRF*100)+T.MES_DEDUC_IRRF) =
                                   (SELECT MAX(((T.ANO_DEDUC_IRRF*100)+T.MES_DEDUC_IRRF))
                                           FROM ATT.DEDUCAO_IRRF_DEPEND T);

                      -- DEPENDENTES ---
                      SELECT DISTINCT S.QTD_DPDTEIR_SMLBNF
                      INTO
                             VN_QTDE_DEPEND
                      FROM ATT.SIMULACAO_BENEF_FSS S
                      WHERE S.COD_PROCESS_TPPSML = 7
                      AND   S.NUM_MATR_PARTF = LINHA.NUM_MATR_PARTF
                      AND   S.DAT_CALCUL_SMLBNF = (SELECT MAX(S2.DAT_CALCUL_SMLBNF) FROM ATT.SIMULACAO_BENEF_FSS S2
                                                   WHERE S.NUM_MATR_PARTF = S2.NUM_MATR_PARTF
                                                   AND   S.COD_PROCESS_TPPSML = S2.COD_PROCESS_TPPSML
                                                   AND   S2.DAT_CALCUL_SMLBNF <= P_DTA_INCL);
                      END IF;
                      ---

                      --- CALCULA A SEQUENCIA DO ABATIMENTO ---
                      VN_SEQ_ABAT   :=0;
                      VN_ACUM_SLD_1 :=0;---
                      VN_ACUM_SLD_2 :=0;---
                      SELECT NVL(MAX(AB.NUM_SEQ_ABAT),0)
                      INTO
                             VN_SEQ_ABAT
                      FROM ATT.FCESP_ABAT_EMPREST_SLD_CONTA AB
                      WHERE AB.NUM_MATR_PARTF = LINHA.NUM_MATR_PARTF;


                      VN_VLR_RESID_ABAT := LINHA.ABAT_TOTAL;

                      --- RECUPERA OS VALORES PASSÖVEIS DE RESGATE PARA O CALCULO DO IR 1 PASSAGEM ---
                      FOR VLR_RESG IN (
                      SELECT F.NUM_CTFSS,
                             C.TIP_CTFSS,
                             C.TIP_RESERV_CTFSS,
                             SUBSTR(PR.TIPO_BENEF,2,4) TIPO_BENEF,
                             C.COD_UMARMZ_CTFSS,
                             F.VLR_ATUAL_SMLFND
                      FROM ATT.SIMULACAO_BENEF_FSS S,
                           ATT.SIMULACAO_FUNDO_FSS F,
                           ATT.FCESP_PRIOR_CTA_RESG PR,
                           ATT.CONTA_FSS C
                      WHERE S.NUM_MATR_PARTF = F.NUM_MATR_PARTF
                      AND   S.NUM_SQNCL_SMLBNF = F.NUM_SQNCL_SMLBNF
                      AND   F.NUM_CTFSS = PR.NUM_CTFSS
                      AND   F.NUM_CTFSS = C.NUM_CTFSS
                      AND   PR.NUM_PLBNF = S.NUM_PLBNF
                      AND   S.NUM_MATR_PARTF = LINHA.NUM_MATR_PARTF
                      AND   S.COD_PROCESS_TPPSML = 7
                      AND   F.NUM_CTADEST_SMLFND IS NULL
                      AND   F.NUM_CTFSS IS NOT NULL
                      AND   PR.COD_TPPCP = LINHA.COD_TPPCP
                      AND   PR.TIP_RESERV_CTFSS <> 2
                      AND   S.DAT_CALCUL_SMLBNF = (SELECT MAX(S2.DAT_CALCUL_SMLBNF) FROM ATT.SIMULACAO_BENEF_FSS S2
                                                   WHERE S.NUM_MATR_PARTF = S2.NUM_MATR_PARTF
                                                   AND   S.COD_PROCESS_TPPSML = S2.COD_PROCESS_TPPSML
                                                   AND   S2.DAT_CALCUL_SMLBNF <= P_DTA_INCL)
                      ORDER BY PR.IND_PRIOR_CTA
                      ) LOOP

                        IF VN_VLR_RESID_ABAT <= 0 THEN
                           VN_PCT_ABAT_CTA := 0;
                        ELSE

                            IF VN_VLR_RESID_ABAT  < VLR_RESG.VLR_ATUAL_SMLFND THEN
                               VN_PCT_ABAT_CTA := ROUND(VN_VLR_RESID_ABAT/VLR_RESG.VLR_ATUAL_SMLFND,8);
                            ELSE
                               VN_PCT_ABAT_CTA := 1;
                            END IF;
                            VN_VLR_RESID_ABAT := VN_VLR_RESID_ABAT - VLR_RESG.VLR_ATUAL_SMLFND;
                         END IF;

                      IF VLR_RESG.NUM_CTFSS IN (245,309,266,259,355) AND VN_PCT_ABAT_CTA <> 0 THEN
                      --- VALOR ISENTO ---
                            SELECT DISTINCT S.VLR_NTRIBIRRF_SMLBNF
                            INTO
                                   VN_VLR_ISENTO
                            FROM ATT.SIMULACAO_BENEF_FSS S
                            WHERE S.COD_PROCESS_TPPSML = 7
                            AND   S.NUM_MATR_PARTF = LINHA.NUM_MATR_PARTF
                            AND   S.DAT_CALCUL_SMLBNF = (SELECT MAX(S2.DAT_CALCUL_SMLBNF) FROM ATT.SIMULACAO_BENEF_FSS S2
                                                         WHERE S.NUM_MATR_PARTF = S2.NUM_MATR_PARTF
                                                         AND   S.COD_PROCESS_TPPSML = S2.COD_PROCESS_TPPSML
                                                         AND   S2.DAT_CALCUL_SMLBNF <= P_DTA_INCL);

                            IF VN_VLR_ISENTO > VN_VLR_RESID_ABAT THEN
                               VN_VLR_ISENTO := VN_VLR_ISENTO;
                            ELSE
                               VN_VLR_ISENTO := 0;
                            END IF;

                      VN_VLR_RESID_ABAT_1 := ((LINHA.ABAT_TOTAL - (VN_VLR_DEPENDENTE * VN_QTDE_DEPEND) - (VN_VLR_ISENTO * VN_PCT_ABAT_CTA) - VN_VLR_DESC_IR) / (1-VN_VLR_ALIQ_IR) + (VN_VLR_DEPENDENTE * VN_QTDE_DEPEND)+ (VN_VLR_ISENTO*VN_PCT_ABAT_CTA));
                      ELSE
                      VN_VLR_RESID_ABAT_1 := (((LINHA.ABAT_TOTAL - (VN_VLR_DEPENDENTE * VN_QTDE_DEPEND) - VN_VLR_DESC_IR) / (1-VN_VLR_ALIQ_IR)) + (VN_VLR_DEPENDENTE * VN_QTDE_DEPEND));
                        END IF;
                      END LOOP;


                      VN_PCT_ABAT_CTA :=0;
                      --- RECUPERA OS VALORES PASSÖVEIS DE RESGATE PARA O CALCULO DO IR 2 PASSAGEM ---

                      FOR VLR_RESG IN (
                      SELECT F.NUM_CTFSS,
                             C.TIP_CTFSS,
                             C.TIP_RESERV_CTFSS,
                             SUBSTR(PR.TIPO_BENEF,2,4) TIPO_BENEF,
                             C.COD_UMARMZ_CTFSS,
                             C.NUM_PLBNF_CTFSS,
                             F.VLR_ATUAL_SMLFND
                      FROM ATT.SIMULACAO_BENEF_FSS S,
                           ATT.SIMULACAO_FUNDO_FSS F,
                           ATT.FCESP_PRIOR_CTA_RESG PR,
                           ATT.CONTA_FSS C
                      WHERE S.NUM_MATR_PARTF = F.NUM_MATR_PARTF
                      AND   S.NUM_SQNCL_SMLBNF = F.NUM_SQNCL_SMLBNF
                      AND   F.NUM_CTFSS = PR.NUM_CTFSS
                      AND   F.NUM_CTFSS = C.NUM_CTFSS
                      AND   PR.NUM_PLBNF = S.NUM_PLBNF
                      AND   S.NUM_MATR_PARTF = LINHA.NUM_MATR_PARTF
                      AND   S.COD_PROCESS_TPPSML = 7
                      AND   F.NUM_CTADEST_SMLFND IS NULL
                      AND   F.NUM_CTFSS IS NOT NULL
                      AND   PR.COD_TPPCP = LINHA.COD_TPPCP
                      AND   PR.TIP_RESERV_CTFSS <> 2
                      AND   S.DAT_CALCUL_SMLBNF = (SELECT MAX(S2.DAT_CALCUL_SMLBNF) FROM ATT.SIMULACAO_BENEF_FSS S2
                                                   WHERE S.NUM_MATR_PARTF = S2.NUM_MATR_PARTF
                                                   AND   S.COD_PROCESS_TPPSML = S2.COD_PROCESS_TPPSML
                                                   AND   S2.DAT_CALCUL_SMLBNF <= P_DTA_INCL)
                      ORDER BY PR.IND_PRIOR_CTA
                      ) LOOP

                          IF VN_VLR_RESID_ABAT_1 <= 0 THEN
                             VN_PCT_ABAT_CTA := 0;
                          ELSE

                              IF VN_VLR_RESID_ABAT_1  < VLR_RESG.VLR_ATUAL_SMLFND THEN
                                 VN_PCT_ABAT_CTA := ROUND(VN_VLR_RESID_ABAT_1/VLR_RESG.VLR_ATUAL_SMLFND,8);
                              ELSE
                                 VN_PCT_ABAT_CTA := 1;
                              END IF;
                            /*VN_VLR_RESID_ABAT_1 := VN_VLR_RESID_ABAT_1 - VLR_RESG.VLR_ATUAL_SMLFND;*/
                      END IF;


                    IF VLR_RESG.NUM_CTFSS IN (245,309,266,259,355) /*AND VN_VLR_RESID_ABAT_1 >= VLR_RESG.VLR_ATUAL_SMLFND*/  AND VN_PCT_ABAT_CTA <> 0 THEN

                    --- VALOR ISENTO ---
                          SELECT DISTINCT NVL(SUM(S.VLR_NTRIBIRRF_SMLBNF),0)
                          INTO
                                VN_VLR_ISENTO
                          FROM ATT.SIMULACAO_BENEF_FSS S
                          WHERE S.COD_PROCESS_TPPSML = 7
                          AND   S.NUM_MATR_PARTF = LINHA.NUM_MATR_PARTF
                          AND   S.DAT_CALCUL_SMLBNF = (SELECT MAX(S2.DAT_CALCUL_SMLBNF) FROM ATT.SIMULACAO_BENEF_FSS S2
                                                       WHERE S.NUM_MATR_PARTF = S2.NUM_MATR_PARTF
                                                       AND   S.COD_PROCESS_TPPSML = S2.COD_PROCESS_TPPSML
                                                       AND   S2.DAT_CALCUL_SMLBNF <= P_DTA_INCL);



                    VN_VLR_RESID_ABAT_2 := ((LINHA.ABAT_TOTAL - (VN_VLR_DEPENDENTE * VN_QTDE_DEPEND) - (VN_VLR_ISENTO*VN_PCT_ABAT_CTA) - VN_VLR_DESC_IR) / (1-VN_VLR_ALIQ_IR) + (VN_VLR_DEPENDENTE * VN_QTDE_DEPEND)+(VN_VLR_ISENTO * VN_PCT_ABAT_CTA));
                    ELSE
                    VN_VLR_RESID_ABAT_2 := (((LINHA.ABAT_TOTAL - (VN_VLR_DEPENDENTE * VN_QTDE_DEPEND) - VN_VLR_DESC_IR) / (1-VN_VLR_ALIQ_IR)) + (VN_VLR_DEPENDENTE * VN_QTDE_DEPEND));
                    END IF;
                    VN_VLR_RESID_ABAT_1 := VN_VLR_RESID_ABAT_1 - VLR_RESG.VLR_ATUAL_SMLFND;
                    END LOOP;



                    VN_PCT_ABAT_CTA :=0;
                    --- RECUPERA OS VALORES PASSIVEIS DE RESGATE PARA O CALCULO DO IR 3 PASSAGEM ---

                    FOR VLR_RESG IN (
                    SELECT F.NUM_CTFSS,
                           C.TIP_CTFSS,
                           C.TIP_RESERV_CTFSS,
                           SUBSTR(PR.TIPO_BENEF,2,4) TIPO_BENEF,
                           C.COD_UMARMZ_CTFSS,
                           C.NUM_PLBNF_CTFSS,
                           F.VLR_ATUAL_SMLFND
                    FROM ATT.SIMULACAO_BENEF_FSS S,
                         ATT.SIMULACAO_FUNDO_FSS F,
                         ATT.FCESP_PRIOR_CTA_RESG PR,
                         ATT.CONTA_FSS C
                    WHERE S.NUM_MATR_PARTF = F.NUM_MATR_PARTF
                    AND   S.NUM_SQNCL_SMLBNF = F.NUM_SQNCL_SMLBNF
                    AND   F.NUM_CTFSS = PR.NUM_CTFSS
                    AND   F.NUM_CTFSS = C.NUM_CTFSS
                    AND   PR.NUM_PLBNF = S.NUM_PLBNF
                    AND   S.NUM_MATR_PARTF = LINHA.NUM_MATR_PARTF
                    AND   S.COD_PROCESS_TPPSML = 7
                    AND   F.NUM_CTADEST_SMLFND IS NULL
                    AND   F.NUM_CTFSS IS NOT NULL
                    AND   PR.COD_TPPCP = LINHA.COD_TPPCP
                    AND   PR.TIP_RESERV_CTFSS <> 2
                    AND   S.DAT_CALCUL_SMLBNF = (SELECT MAX(S2.DAT_CALCUL_SMLBNF) FROM ATT.SIMULACAO_BENEF_FSS S2
                                                 WHERE S.NUM_MATR_PARTF = S2.NUM_MATR_PARTF
                                                 AND   S.COD_PROCESS_TPPSML = S2.COD_PROCESS_TPPSML
                                                 AND   S2.DAT_CALCUL_SMLBNF <= P_DTA_INCL)
                    ORDER BY PR.IND_PRIOR_CTA
                    ) LOOP

                            IF VN_VLR_RESID_ABAT_2 <= 0 THEN
                               VN_PCT_ABAT_CTA := 0;
                            ELSE

                                IF VN_VLR_RESID_ABAT_2  < VLR_RESG.VLR_ATUAL_SMLFND THEN
                                   VN_PCT_ABAT_CTA := ROUND(VN_VLR_RESID_ABAT_2/VLR_RESG.VLR_ATUAL_SMLFND,8);
                                ELSE
                                   VN_PCT_ABAT_CTA := 1;
                                END IF;
                                VN_VLR_RESID_ABAT_2 := VN_VLR_RESID_ABAT_2 - VLR_RESG.VLR_ATUAL_SMLFND;
                          END IF;

                        IF VLR_RESG.NUM_CTFSS IN (245,309,266,259,355) AND VN_VLR_ISENTO > ( VLR_RESG.VLR_ATUAL_SMLFND * VN_PCT_ABAT_CTA) THEN
                           VN_PCT_ABAT_CTA :=0;
                        END IF;

                        
                        --- INICIO DA GRAVACAO NA TABELA ALFANDEGA ---
                        INSERT INTO ATT.FCESP_ABAT_EMPREST_SLD_CONTA
                         (NUM_SEQ_ABAT,
                          NUM_MATR_PARTF,
                          NUM_CTFSS,
                          TIP_CTFSS,
                          TIP_RESERV_CTFSS,
                          NUM_PLBNF_CTFSS,
                          COD_UMARMZ_CTFSS,
                          TIP_BNF_CTFSS,
                          VLR_ABAT,
                          TIP_ABAT,
                          PCT_RESG_PARTF
                          )
                        VALUES
                         (VN_SEQ_ABAT + 1,
                          LINHA.NUM_MATR_PARTF,
                          VLR_RESG.NUM_CTFSS,
                          VLR_RESG.TIP_CTFSS,
                          VLR_RESG.TIP_RESERV_CTFSS,
                          VLR_RESG.NUM_PLBNF_CTFSS,
                          VLR_RESG.COD_UMARMZ_CTFSS,
                          VLR_RESG.TIPO_BENEF,
                          LINHA.ABAT_TOTAL,
                          LINHA.TPO_NEGOCIO,
                          VN_PCT_ABAT_CTA
                          );
                          --
                          -- SUST-7876 - GRAVA O LOG DO PROCESSAMENTO APOS APURACAO DOS PERCENTUAIS DE DESCONTOS DAS CONTAS:
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
                                  ,OPERACAO        = L_OPERACAO
                                  ,DT_FIM_PROCESS  = SYSDATE
                                  ,OBSERVACAO      = L_OBS
                                --
                               WHERE COD_ETAPA        = L_ETAPA
                                 AND COD_EMPRS        = P_COD_EMPRS
                                 AND NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG
                                 AND NUM_CPF_EMPRG    = P_NUM_CPF_EMPRG
                                 AND TPO_NEGOCIO      = P_TPO_NEGOCIO
                                 AND NUM_IDENT_GESTOR = P_NUM_IDENT_GESTOR
                                 AND DTA_INCL         = P_DTA_INCL;
                            COMMIT;                        
                        END LOOP;

                    END LOOP;
                    
        EXCEPTION
        
          WHEN L_PASSO2_EXC THEN                   
                  P_EXCEPTION := 1; -- Necessário efetuar a simulação do resgate no Amadeus Capitalização para prosseguir.
                ROLLBACK;
          
          WHEN L_EXC_RGTRO THEN               
                  P_EXCEPTION := 2; --DBMS_OUTPUT.PUT_LINE('Necessário informar todos os paramentros para prosseguir');    
                ROLLBACK;
               
          WHEN OTHERS THEN
          
                  DBMS_OUTPUT.PUT_LINE('CODIGO DO ERRO: ' || SQLCODE || ' MSG: ' ||SQLERRM);
                  DBMS_OUTPUT.PUT_LINE('LINHA: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);                        
                                        
END;   

                     