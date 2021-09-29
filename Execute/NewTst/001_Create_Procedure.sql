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


CREATE OR REPLACE PROCEDURE OWN_FUNCESP.PROC_CAD_EMPRESTIMO(  P_OPER               IN CHAR -- (I - INSERT, U - UPDATE, S - SELECT, D - DELETE)
                                                             ,P_COD_EMPRS          IN ATT.FCESP_TAB_VLR_ABAT_RESG.COD_EMPRS%TYPE
                                                             ,P_NUM_RGTRO_EMPRG    IN ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_RGTRO_EMPRG%TYPE
                                                             ,P_NUM_MATR_PARTF     IN ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_MATR_PARTF%TYPE
                                                             ,P_NUM_CPF_EMPRG      IN ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_CPF_EMPRG%TYPE
                                                             ,P_NUM_IDENT_GESTOR   IN ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_IDENT_GESTOR%TYPE
                                                             ,P_TPO_NEGOCIO        IN ATT.FCESP_TAB_VLR_ABAT_RESG.TPO_NEGOCIO%TYPE
                                                             ,P_VLR_ABAT           IN ATT.FCESP_TAB_VLR_ABAT_RESG.VLR_ABAT%TYPE
                                                             ,P_DTA_INCL           IN ATT.FCESP_TAB_VLR_ABAT_RESG.DTA_INCL%TYPE
                                                             ,P_DTA_FINAL          IN ATT.FCESP_TAB_VLR_ABAT_RESG.DTA_FINAL%TYPE
                                                             ,P_VLR_EFET_ABAT      IN ATT.FCESP_TAB_VLR_ABAT_RESG.VLR_EFET_ABAT%TYPE
                                                             ,P_RETURN_CURSOR      OUT SYS_REFCURSOR
                                                             ,P_EXCEPTION          OUT NUMBER                                                         
                                                             ) IS

/* **************************************************************************************************************************
| Data da Criacao...........: 02/09/2021
| Analista..................: Adriano Lima (F02860)
| Demanda...................: SUST-7876 - Automacao de Recorrentes
| Descricao.................: Criar procedure que contemple operacoes de CRUD
| Objetos...................: OWN_FUNCESP.PROC_CAD_EMPRESTIMO
| Ambiente..................: PROD
************************************************************************************************************************* */

   -- VARIABLE TYPE TABLE:                                                                                                                                                                                                                                                                                                                                                                                                                                                           
   L_REG                ATT.FCESP_TAB_VLR_ABAT_RESG%ROWTYPE;   
   L_REG_DEL            ATT.FCESP_TAB_VLR_ABAT_RESG%ROWTYPE;   
   --
   L_MODULE             VARCHAR2(255) := '';
   L_OS_USER            VARCHAR2(255) := '';
   L_TERMINAL           VARCHAR2(255) := '';
   L_CURRENT_USER       VARCHAR2(255) := '';
   L_IP_ADDRESS         VARCHAR2(255) := '';
   L_OP                 VARCHAR2(10)  := 'INSERT';
   L_INSERT             VARCHAR2(4000):= '';
   L_ATRIBUTO           VARCHAR2(4000):= 'COD_EMPRS;NUM_RGTRO_EMPRG;NUM_MATR_PARTF;NUM_CPF_EMPRG;NUM_IDENT_GESTOR;TPO_NEGOCIO;VLR_ABAT;DTA_INCL;DTA_FINAL;VLR_EFET_ABAT';
   L_OBS                VARCHAR2(500) := 'PROCEDURE - PROC_CAD_EMPRESTIMO'; 
   --
   L_DCR_DML            VARCHAR2(4000):= '';
   L_VALOR_NOVO         VARCHAR2(4000):= '';
   L_VALOR_ANTIGO       VARCHAR2(4000):= '';
   --
   L_VER_REGR_SITUACAO     NUMBER:='';   
   L_VER_REGR_TIPO         NUMBER:='';   
   L_VER_REGR_TRIBUTACAO   NUMBER:=''; 

   
   -- DECLARACAO EXCEPTION: 
   L_EXC_OPER              EXCEPTION;     
   L_SITUACAO              EXCEPTION;
   L_TIPO                  EXCEPTION;
   L_REG_TRIBUTACAO        EXCEPTION;
   --
   L_SITUACAO_NULL         EXCEPTION; 
   L_TIPO_NULL             EXCEPTION;
   L_REG_TRIBUTACAO_NULL   EXCEPTION;   
   L_EXC_RGTRO             EXCEPTION;
   L_EXC_PKS               EXCEPTION;
   L_EXC_INSERT            EXCEPTION;
   L_EXC_READ              EXCEPTION;        
   L_EXC_DAT_FIM_ADPLPR    EXCEPTION;
   L_EXC_COD_EMPRS         EXCEPTION;
   NO_DATE_FOUND           EXCEPTION;
   

     FUNCTION FNC_VALIDA_REGRA( P_NUM_MATR_PARTF ATT.PARTICIPANTE_FSS.NUM_MATR_PARTF%TYPE
                               ,P_CALC NUMBER )
      RETURN NUMBER IS 
      
        L_COD_SITPAR                   ATT.ADESAO_PLANO_PARTIC_FSS.COD_SITPAR%TYPE; 
        L_COD_TPPCP                    ATT.ADESAO_PLANO_PARTIC_FSS.COD_TPPCP%TYPE;
        L_TIP_OPCTRIBIR_ADPLPR         ATT.ADESAO_PLANO_PARTIC_FSS.TIP_OPCTRIBIR_ADPLPR%TYPE;            
        L_DAT_FIM_ADPLPR               ATT.ADESAO_PLANO_PARTIC_FSS.DAT_FIM_ADPLPR%TYPE; 
      
        -- DECLARACAO EXCEPTION:      
        L_EXC_DAT_FIM_ADPLPR           EXCEPTION;
      
      BEGIN 
      
         IF (P_CALC = 1 )THEN 
        
             -- VALIDA SITUCAO DO PARTICIPANTE:
             SELECT COD_SITPAR,     DAT_FIM_ADPLPR              
                 INTO L_COD_SITPAR, L_DAT_FIM_ADPLPR          
              FROM ATT.ADESAO_PLANO_PARTIC_FSS 
              WHERE NUM_MATR_PARTF = P_NUM_MATR_PARTF
              AND DAT_ULTCTB_ADPLPR IS NOT NULL;
              
             
             CASE
                 WHEN L_DAT_FIM_ADPLPR IS NOT NULL THEN RAISE L_EXC_DAT_FIM_ADPLPR;
                 WHEN L_COD_SITPAR     IS NOT NULL THEN RETURN L_COD_SITPAR; 
                 WHEN L_COD_SITPAR     NOT IN (4) THEN RAISE L_SITUACAO;                
                 WHEN L_COD_SITPAR     IS NULL THEN RAISE L_SITUACAO_NULL;
                 
                 --           
             END CASE;
            
         ELSIF (P_CALC = 2 )THEN
           
             -- VALIDA TIPO DO PARTICIPANTE:
             SELECT COD_TPPCP, DAT_FIM_ADPLPR
                 INTO L_COD_TPPCP, L_DAT_FIM_ADPLPR
               FROM ATT.ADESAO_PLANO_PARTIC_FSS
               WHERE NUM_MATR_PARTF = P_NUM_MATR_PARTF
               AND DAT_ULTCTB_ADPLPR IS NOT NULL;
                 
             CASE    
                WHEN L_DAT_FIM_ADPLPR IS NOT NULL THEN RAISE L_EXC_DAT_FIM_ADPLPR;
                WHEN L_COD_TPPCP      IS NOT NULL THEN RETURN L_COD_TPPCP;
                WHEN L_COD_TPPCP      NOT IN (2, 3) THEN RAISE L_TIPO; 
                WHEN L_COD_TPPCP      IS NULL THEN RAISE L_TIPO_NULL;
                                                               
             END CASE;    
              
         ELSIF (P_CALC = 3)THEN
         
             -- VALIDA REGIME DE TRIBUTACAO:
             SELECT TIP_OPCTRIBIR_ADPLPR, DAT_FIM_ADPLPR      
                 INTO L_TIP_OPCTRIBIR_ADPLPR, L_DAT_FIM_ADPLPR
                FROM ATT.ADESAO_PLANO_PARTIC_FSS
                WHERE NUM_MATR_PARTF = P_NUM_MATR_PARTF
                AND DAT_ULTCTB_ADPLPR IS NOT NULL;                
             
              CASE
                 WHEN L_DAT_FIM_ADPLPR        IS NOT NULL THEN RAISE L_EXC_DAT_FIM_ADPLPR;
                 WHEN L_TIP_OPCTRIBIR_ADPLPR  IS NOT NULL THEN RETURN L_TIP_OPCTRIBIR_ADPLPR;
                 WHEN L_TIP_OPCTRIBIR_ADPLPR  IN (2) THEN RAISE L_REG_TRIBUTACAO;   
                 WHEN L_TIP_OPCTRIBIR_ADPLPR  IS NULL THEN RAISE L_REG_TRIBUTACAO_NULL;                                                  
              END CASE;  
         END IF;  
                 
         EXCEPTION       
         
          WHEN L_EXC_DAT_FIM_ADPLPR THEN
               --DBMS_OUTPUT.PUT_LINE('Plano do participante não está ativo!'); 
                P_EXCEPTION := 1;
        ROLLBACK;
         --
          WHEN OTHERS THEN 
                     
               DBMS_OUTPUT.PUT_LINE('CODIGO DO ERRO: ' || SQLCODE || ' MSG: ' ||SQLERRM);
               DBMS_OUTPUT.PUT_LINE('LINHA: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);        
              
      END FNC_VALIDA_REGRA;
        

BEGIN


 IF (UPPER(P_OPER) = 'S') THEN

            IF (    P_NUM_RGTRO_EMPRG IS NULL OR P_NUM_RGTRO_EMPRG = ''
                 OR P_DTA_INCL        IS NULL OR P_DTA_INCL = '') THEN
                  RAISE L_EXC_READ;
            
            ELSE
                -- 1 
                OPEN P_RETURN_CURSOR FOR
                  SELECT COD_EMPRS
                        ,NUM_RGTRO_EMPRG
                        ,NUM_MATR_PARTF
                        ,NUM_CPF_EMPRG
                        ,NUM_IDENT_GESTOR
                        ,TPO_NEGOCIO
                        ,VLR_ABAT
                        ,DTA_INCL
                        ,DTA_FINAL
                        ,VLR_EFET_ABAT
                    FROM ATT.FCESP_TAB_VLR_ABAT_RESG
                      WHERE NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG
                        AND DTA_INCL         = TO_DATE(P_DTA_INCL, 'DD/MM/RRRR');
            END IF;

      ELSIF(UPPER(P_OPER) = 'I') THEN
 
            IF ( P_COD_EMPRS IS NULL OR P_COD_EMPRS = '' 
                 OR P_NUM_RGTRO_EMPRG IS NULL OR P_NUM_RGTRO_EMPRG = '') THEN
                   ROLLBACK;
                  RAISE L_EXC_COD_EMPRS; 
                  
            ELSE                  
                 L_REG.NUM_MATR_PARTF := NULL;                  
                 --
                 SELECT NUM_MATR_PARTF 
                     INTO L_REG.NUM_MATR_PARTF 
                  FROM ATT.PARTICIPANTE_FSS
                  WHERE NUM_RGTRO_EMPRG = P_NUM_RGTRO_EMPRG
                  AND COD_EMPRS         = P_COD_EMPRS;                                   
            END IF;
                             
            
     L_VER_REGR_SITUACAO           := FNC_VALIDA_REGRA(L_REG.NUM_MATR_PARTF, 1); 
     L_VER_REGR_TIPO               := FNC_VALIDA_REGRA(L_REG.NUM_MATR_PARTF, 2);
     L_VER_REGR_TRIBUTACAO         := FNC_VALIDA_REGRA(L_REG.NUM_MATR_PARTF, 3);
             
     
     IF L_VER_REGR_SITUACAO NOT IN (4)   THEN RAISE L_SITUACAO;
     --
     ELSIF L_VER_REGR_TIPO NOT IN (2, 3) THEN RAISE L_TIPO;
     --
     ELSIF L_VER_REGR_TRIBUTACAO IN (2)  THEN RAISE L_REG_TRIBUTACAO;
     --
     ELSE        
         
         IF (    P_COD_EMPRS        IS NULL OR P_COD_EMPRS = '' 
              OR P_NUM_RGTRO_EMPRG  IS NULL OR P_NUM_RGTRO_EMPRG = '' 
              OR P_NUM_CPF_EMPRG    IS NULL OR P_NUM_CPF_EMPRG = '' 
              OR P_NUM_IDENT_GESTOR IS NULL OR P_NUM_IDENT_GESTOR = '' 
              OR P_TPO_NEGOCIO      IS NULL OR P_TPO_NEGOCIO = '' 
              OR P_DTA_INCL         IS NULL OR P_DTA_INCL = '') THEN
             ROLLBACK;
              RAISE L_EXC_INSERT;
         ELSE 
  
         --         
         --DBMS_OUTPUT.PUT_LINE('EFETUAR CADASTRO');
         INSERT INTO ATT.FCESP_TAB_VLR_ABAT_RESG (  COD_EMPRS
                                                   ,NUM_RGTRO_EMPRG
                                                   ,NUM_MATR_PARTF
                                                   ,NUM_CPF_EMPRG
                                                   ,NUM_IDENT_GESTOR
                                                   ,TPO_NEGOCIO
                                                   ,VLR_ABAT
                                                   ,DTA_INCL
                                                   ,DTA_FINAL
                                                   ,VLR_EFET_ABAT)
                                             VALUES
                                                 (  P_COD_EMPRS
                                                   ,P_NUM_RGTRO_EMPRG
                                                   ,P_NUM_MATR_PARTF             -- YES
                                                   ,P_NUM_CPF_EMPRG
                                                   ,P_NUM_IDENT_GESTOR
                                                   ,P_TPO_NEGOCIO
                                                   ,P_VLR_ABAT                   -- YES
                                                   ,P_DTA_INCL
                                                   ,NVL(P_DTA_FINAL, NULL)       -- YES
                                                   ,NVL(P_VLR_EFET_ABAT, NULL)   -- YES
                                                  ); 
                                                  
         L_INSERT := P_COD_EMPRS        || ';' || 
                     P_NUM_RGTRO_EMPRG  || ';' || 
                     P_NUM_MATR_PARTF   || ';' || 
                     P_NUM_CPF_EMPRG    || ';' || 
                     P_NUM_IDENT_GESTOR || ';' ||  
                     P_TPO_NEGOCIO      || ';' || 
                     P_VLR_ABAT         || ';' ||
                     P_DTA_INCL         || ';' ||
                     P_DTA_FINAL        || ';' ||
                     P_VLR_EFET_ABAT    || ';';                    
         --
         -- LOG DO PROCESSAMENTO:                           
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
         INSERT INTO OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP(DT_INIC_PROCESS, COD_LOG_STATUS, COD_ETAPA, COD_EMPRS, NUM_RGTRO_EMPRG, NUM_CPF_EMPRG, TPO_NEGOCIO, NUM_IDENT_GESTOR, DTA_INCL, MODULE, USUARIO, TERMINAL, CURRENT_USER, IP_ADDRESS, OPERACAO, DT_FIM_PROCESS, OBSERVACAO)
                             			                      VALUES 
											                                        (SYSDATE, 1, 1, P_COD_EMPRS, P_NUM_RGTRO_EMPRG, P_NUM_CPF_EMPRG , P_TPO_NEGOCIO, P_NUM_IDENT_GESTOR, P_DTA_INCL, L_MODULE, L_OS_USER, L_TERMINAL, L_CURRENT_USER, L_IP_ADDRESS, L_OP, SYSDATE, L_OBS);
         --
         INSERT INTO OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP(DT_INIC_PROCESS, COD_LOG_STATUS, COD_ETAPA, COD_EMPRS, NUM_RGTRO_EMPRG, NUM_CPF_EMPRG, TPO_NEGOCIO, NUM_IDENT_GESTOR, DTA_INCL, MODULE, USUARIO, TERMINAL, CURRENT_USER, IP_ADDRESS, OPERACAO, DT_FIM_PROCESS, OBSERVACAO)
                             			                      VALUES 
											                                        (SYSDATE, 2, 2, P_COD_EMPRS, P_NUM_RGTRO_EMPRG, P_NUM_CPF_EMPRG , P_TPO_NEGOCIO, P_NUM_IDENT_GESTOR, P_DTA_INCL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);													 
         --
         INSERT INTO OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP(DT_INIC_PROCESS, COD_LOG_STATUS, COD_ETAPA, COD_EMPRS, NUM_RGTRO_EMPRG, NUM_CPF_EMPRG, TPO_NEGOCIO, NUM_IDENT_GESTOR, DTA_INCL, MODULE, USUARIO, TERMINAL, CURRENT_USER, IP_ADDRESS, OPERACAO, DT_FIM_PROCESS, OBSERVACAO)
                             			                      VALUES 
											                                        (SYSDATE, 2, 3, P_COD_EMPRS, P_NUM_RGTRO_EMPRG, P_NUM_CPF_EMPRG , P_TPO_NEGOCIO, P_NUM_IDENT_GESTOR, P_DTA_INCL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);													 													 
         --
         INSERT INTO OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP(DT_INIC_PROCESS, COD_LOG_STATUS, COD_ETAPA, COD_EMPRS, NUM_RGTRO_EMPRG, NUM_CPF_EMPRG, TPO_NEGOCIO, NUM_IDENT_GESTOR, DTA_INCL, MODULE, USUARIO, TERMINAL, CURRENT_USER, IP_ADDRESS, OPERACAO, DT_FIM_PROCESS, OBSERVACAO)
                             			                      VALUES 
											                                        (SYSDATE, 2, 4, P_COD_EMPRS, P_NUM_RGTRO_EMPRG, P_NUM_CPF_EMPRG , P_TPO_NEGOCIO, P_NUM_IDENT_GESTOR, P_DTA_INCL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);													 													 													 
         --
         INSERT INTO OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP(DT_INIC_PROCESS, COD_LOG_STATUS, COD_ETAPA, COD_EMPRS, NUM_RGTRO_EMPRG, NUM_CPF_EMPRG, TPO_NEGOCIO, NUM_IDENT_GESTOR, DTA_INCL, MODULE, USUARIO, TERMINAL, CURRENT_USER, IP_ADDRESS, OPERACAO, DT_FIM_PROCESS, OBSERVACAO)
                             			                      VALUES 
											                                        (SYSDATE, 2, 5, P_COD_EMPRS, P_NUM_RGTRO_EMPRG, P_NUM_CPF_EMPRG , P_TPO_NEGOCIO, P_NUM_IDENT_GESTOR, P_DTA_INCL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);													 													 													 
        
        --        
        -- LOG DA TRANSACAO:
        INSERT INTO OWN_FUNCESP.PRE_TBL_LOG_TRANSACAO_ABAT_EMP(  DT_INIC_PROCESS
                                                                ,COD_OP 
                                                                ,DCR_DML
                                                                ,VALOR_NOVO
                                                                ,VALOR_ANTIGO
                                                                ,MODULE
                                                                ,USUARIO
                                                                ,TERMINAL
                                                                ,CURRENT_USER
                                                                ,IP_ADDRESS
                                                                ,DT_FIM_PROCESS
                                                                ,OBSERVACAO
                                                               )
                                                        VALUES (  SYSDATE
                                                                 ,P_OPER  
                                                                 ,L_ATRIBUTO
                                                                 ,L_INSERT
                                                                 ,''
                                                                 ,L_MODULE             
                                                                 ,L_OS_USER            
                                                                 ,L_TERMINAL           
                                                                 ,L_CURRENT_USER       
                                                                 ,L_IP_ADDRESS                                                                 
                                                                 ,SYSDATE
                                                                 ,L_OBS
                                                                ); 
                                                                                                                                                                                             
                                                                                                                                
         END IF;                                  
     END IF;         
     COMMIT;
 --
 --
 ELSIF(UPPER(P_OPER) = 'U') THEN

         -- ATUALIZACAO DE DADOS:
         IF (    P_COD_EMPRS        IS NULL OR P_COD_EMPRS = '' 
              OR P_NUM_RGTRO_EMPRG  IS NULL OR P_NUM_RGTRO_EMPRG = '' 
              OR P_NUM_CPF_EMPRG    IS NULL OR P_NUM_CPF_EMPRG = '' 
              OR P_NUM_IDENT_GESTOR IS NULL OR P_NUM_IDENT_GESTOR = '' 
              OR P_TPO_NEGOCIO      IS NULL OR P_TPO_NEGOCIO = '' 
              OR P_DTA_INCL         IS NULL OR P_DTA_INCL = '' ) THEN
              ROLLBACK;
             RAISE L_EXC_RGTRO;
         ELSE
         
            SELECT COD_EMPRS, NUM_RGTRO_EMPRG, NUM_MATR_PARTF, NUM_CPF_EMPRG,  NUM_IDENT_GESTOR, TPO_NEGOCIO, VLR_ABAT, DTA_INCL, DTA_FINAL, VLR_EFET_ABAT
            INTO L_REG.COD_EMPRS, L_REG.NUM_RGTRO_EMPRG, L_REG.NUM_MATR_PARTF, L_REG.NUM_CPF_EMPRG,  L_REG.NUM_IDENT_GESTOR, L_REG.TPO_NEGOCIO, L_REG.VLR_ABAT, L_REG.DTA_INCL, L_REG.DTA_FINAL, L_REG.VLR_EFET_ABAT
            FROM ATT.FCESP_TAB_VLR_ABAT_RESG
             WHERE COD_EMPRS         = P_COD_EMPRS
                AND NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG
                AND NUM_CPF_EMPRG    = P_NUM_CPF_EMPRG
                AND NUM_IDENT_GESTOR = P_NUM_IDENT_GESTOR
                AND TPO_NEGOCIO      = P_TPO_NEGOCIO
                AND DTA_INCL         = P_DTA_INCL;
         
         
             --DBMS_OUTPUT.PUT_LINE('UPDATE');
             UPDATE ATT.FCESP_TAB_VLR_ABAT_RESG   
             SET COD_EMPRS         = NVL(P_COD_EMPRS, COD_EMPRS)
                ,NUM_RGTRO_EMPRG   = NVL(P_NUM_RGTRO_EMPRG, NUM_RGTRO_EMPRG)
                ,NUM_MATR_PARTF    = NVL(P_NUM_MATR_PARTF, NUM_MATR_PARTF)
                ,NUM_CPF_EMPRG     = NVL(P_NUM_CPF_EMPRG, NUM_CPF_EMPRG)
                ,NUM_IDENT_GESTOR  = NVL(P_NUM_IDENT_GESTOR, NUM_IDENT_GESTOR)
                ,TPO_NEGOCIO       = NVL(P_TPO_NEGOCIO, TPO_NEGOCIO)
                ,VLR_ABAT          = NVL(P_VLR_ABAT, VLR_ABAT)
                ,DTA_INCL          = NVL(P_DTA_INCL, DTA_INCL)
                ,DTA_FINAL         = NVL(P_DTA_FINAL, DTA_FINAL)
                ,VLR_EFET_ABAT     = NVL(P_VLR_EFET_ABAT, VLR_EFET_ABAT)
                --
             WHERE COD_EMPRS         = P_COD_EMPRS
                AND NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG
                AND NUM_CPF_EMPRG    = P_NUM_CPF_EMPRG
                AND NUM_IDENT_GESTOR = P_NUM_IDENT_GESTOR
                AND TPO_NEGOCIO      = P_TPO_NEGOCIO
                AND DTA_INCL         = P_DTA_INCL;   
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
             --
             -- LOG DA TRANSACAO:
             L_DCR_DML      := 'COD_EMPRS;NUM_RGTRO_EMPRG;NUM_MATR_PARTF;NUM_CPF_EMPRG;NUM_IDENT_GESTOR;TPO_NEGOCIO;VLR_ABAT;DTA_INCL;DTA_FINAL;VLR_EFET_ABAT';
             L_VALOR_NOVO   := P_COD_EMPRS || ';' || P_NUM_RGTRO_EMPRG || ';' || P_NUM_MATR_PARTF || ';' || P_NUM_CPF_EMPRG    || ';' || P_NUM_IDENT_GESTOR || ';' || P_TPO_NEGOCIO || ';' || P_VLR_ABAT || ';' || P_DTA_INCL || ';' || P_DTA_FINAL || ';' || P_VLR_EFET_ABAT || ';';
             L_VALOR_ANTIGO := L_REG.COD_EMPRS || ';' || L_REG.NUM_RGTRO_EMPRG || ';' || L_REG.NUM_MATR_PARTF || ';' ||L_REG.NUM_CPF_EMPRG || ';' || L_REG.NUM_IDENT_GESTOR || ';' || L_REG.TPO_NEGOCIO || ';' || L_REG.VLR_ABAT || ';' ||L_REG.DTA_INCL || ';' || L_REG.DTA_FINAL || ';' || L_REG.VLR_EFET_ABAT || ';'; 
             --
             INSERT INTO OWN_FUNCESP.PRE_TBL_LOG_TRANSACAO_ABAT_EMP(  DT_INIC_PROCESS
                                                                     ,COD_OP 
                                                                     ,DCR_DML
                                                                     ,VALOR_NOVO
                                                                     ,VALOR_ANTIGO
                                                                     ,MODULE
                                                                     ,USUARIO
                                                                     ,TERMINAL
                                                                     ,CURRENT_USER
                                                                     ,IP_ADDRESS
                                                                     ,DT_FIM_PROCESS
                                                                     ,OBSERVACAO
                                                                   )
                                                            VALUES (  SYSDATE
                                                                     ,P_OPER  
                                                                     ,L_DCR_DML
                                                                     ,L_VALOR_NOVO
                                                                     ,L_VALOR_ANTIGO
                                                                     ,L_MODULE             
                                                                     ,L_OS_USER            
                                                                     ,L_TERMINAL           
                                                                     ,L_CURRENT_USER       
                                                                     ,L_IP_ADDRESS                                                                 
                                                                     ,SYSDATE
                                                                     ,L_OBS
                                                                    ); 

            COMMIT;
             
         END IF;               
 --
 --
 ELSIF(UPPER(P_OPER) = 'D') THEN
            
                              
         IF (    P_COD_EMPRS        IS NULL OR P_COD_EMPRS = '' 
              OR P_NUM_RGTRO_EMPRG  IS NULL OR P_NUM_RGTRO_EMPRG = '' 
              OR P_NUM_CPF_EMPRG    IS NULL OR P_NUM_CPF_EMPRG = '' 
              OR P_NUM_IDENT_GESTOR IS NULL OR P_NUM_IDENT_GESTOR = '' 
              OR P_TPO_NEGOCIO      IS NULL OR P_TPO_NEGOCIO = '' 
              OR P_DTA_INCL         IS NULL OR P_DTA_INCL = '' ) THEN
               ROLLBACK;
               RAISE L_EXC_PKS;   --           
         ELSE 
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
         --                      
             SELECT   COD_EMPRS
                    , NUM_RGTRO_EMPRG
                    , NUM_MATR_PARTF
                    , NUM_CPF_EMPRG
                    , NUM_IDENT_GESTOR
                    , TPO_NEGOCIO
                    , VLR_ABAT
                    , DTA_INCL
                    , DTA_FINAL
                    , VLR_EFET_ABAT
               INTO   L_REG.COD_EMPRS
                    , L_REG.NUM_RGTRO_EMPRG
                    , L_REG.NUM_MATR_PARTF
                    , L_REG.NUM_CPF_EMPRG
                    , L_REG.NUM_IDENT_GESTOR
                    , L_REG.TPO_NEGOCIO
                    , L_REG.VLR_ABAT
                    , L_REG.DTA_INCL
                    , L_REG.DTA_FINAL
                    , L_REG.VLR_EFET_ABAT
              FROM ATT.FCESP_TAB_VLR_ABAT_RESG
               WHERE COD_EMPRS       = P_COD_EMPRS
                AND NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG
                AND NUM_MATR_PARTF   = P_NUM_MATR_PARTF                
                AND NUM_CPF_EMPRG    = P_NUM_CPF_EMPRG
                AND NUM_IDENT_GESTOR = P_NUM_IDENT_GESTOR
                AND TPO_NEGOCIO      = P_TPO_NEGOCIO
                AND VLR_ABAT         = P_VLR_ABAT
                AND DTA_INCL         = P_DTA_INCL;                                                                          
             --                  
             DELETE FROM ATT.FCESP_TAB_VLR_ABAT_RESG
             WHERE COD_EMPRS         = P_COD_EMPRS
                AND NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG
                AND NUM_CPF_EMPRG    = P_NUM_CPF_EMPRG
                AND NUM_IDENT_GESTOR = P_NUM_IDENT_GESTOR
                AND TPO_NEGOCIO      = P_TPO_NEGOCIO
                AND DTA_INCL         = P_DTA_INCL;                                                      
               --
               -- LOG DA TRANSACAO:                                                                                 
               L_DCR_DML      := 'COD_EMPRS;NUM_RGTRO_EMPRG;NUM_MATR_PARTF;NUM_CPF_EMPRG;NUM_IDENT_GESTOR;TPO_NEGOCIO;VLR_ABAT;DTA_INCL;DTA_FINAL;VLR_EFET_ABAT';            
               L_VALOR_ANTIGO := L_REG.COD_EMPRS || ';' || L_REG.NUM_RGTRO_EMPRG || ';' || L_REG.NUM_MATR_PARTF || ';' ||L_REG.NUM_CPF_EMPRG || ';' || L_REG.NUM_IDENT_GESTOR || ';' || L_REG.TPO_NEGOCIO || ';' || L_REG.VLR_ABAT || ';' ||L_REG.DTA_INCL || ';' || L_REG.DTA_FINAL || ';' || L_REG.VLR_EFET_ABAT || ';'; 
               INSERT INTO OWN_FUNCESP.PRE_TBL_LOG_TRANSACAO_ABAT_EMP(  DT_INIC_PROCESS
                                                                       ,COD_OP 
                                                                       ,DCR_DML
                                                                       ,VALOR_NOVO
                                                                       ,VALOR_ANTIGO
                                                                       ,MODULE
                                                                       ,USUARIO
                                                                       ,TERMINAL
                                                                       ,CURRENT_USER
                                                                       ,IP_ADDRESS
                                                                       ,DT_FIM_PROCESS
                                                                       ,OBSERVACAO
                                                                     )
                                                              VALUES (  SYSDATE
                                                                       ,P_OPER  
                                                                       ,L_DCR_DML
                                                                       ,''
                                                                       ,L_VALOR_ANTIGO 
                                                                       ,L_MODULE             
                                                                       ,L_OS_USER            
                                                                       ,L_TERMINAL           
                                                                       ,L_CURRENT_USER       
                                                                       ,L_IP_ADDRESS                                                                 
                                                                       ,SYSDATE
                                                                       ,L_OBS
                                                                      );  
                                                                 COMMIT;   
             --             
             L_VALOR_NOVO   := L_REG_DEL.COD_EMPRS || ';' || L_REG_DEL.NUM_RGTRO_EMPRG || ';' || L_REG_DEL.NUM_MATR_PARTF || ';' ||L_REG_DEL.NUM_CPF_EMPRG || ';' || L_REG_DEL.NUM_IDENT_GESTOR || ';' || L_REG_DEL.TPO_NEGOCIO || ';' || L_REG_DEL.VLR_ABAT || ';' ||L_REG_DEL.DTA_INCL || ';' || L_REG_DEL.DTA_FINAL || ';' || L_REG_DEL.VLR_EFET_ABAT || ';';                                                                 
             --
             SELECT COD_EMPRS, NUM_RGTRO_EMPRG, NUM_MATR_PARTF, NUM_CPF_EMPRG,  NUM_IDENT_GESTOR, TPO_NEGOCIO, VLR_ABAT, DTA_INCL, DTA_FINAL, VLR_EFET_ABAT
               INTO L_REG_DEL.COD_EMPRS, L_REG_DEL.NUM_RGTRO_EMPRG, L_REG_DEL.NUM_MATR_PARTF, L_REG_DEL.NUM_CPF_EMPRG,  L_REG_DEL.NUM_IDENT_GESTOR, L_REG_DEL.TPO_NEGOCIO, L_REG_DEL.VLR_ABAT, L_REG_DEL.DTA_INCL, L_REG_DEL.DTA_FINAL, L_REG_DEL.VLR_EFET_ABAT
              FROM ATT.FCESP_TAB_VLR_ABAT_RESG
               WHERE COD_EMPRS       = P_COD_EMPRS
                AND NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG
                AND NUM_MATR_PARTF   = P_NUM_MATR_PARTF                
                AND NUM_CPF_EMPRG    = P_NUM_CPF_EMPRG
                AND NUM_IDENT_GESTOR = P_NUM_IDENT_GESTOR
                AND TPO_NEGOCIO      = P_TPO_NEGOCIO
                AND VLR_ABAT         = P_VLR_ABAT
                AND DTA_INCL         = P_DTA_INCL
                AND DTA_FINAL        = P_DTA_FINAL
                AND VLR_EFET_ABAT    = P_VLR_EFET_ABAT;                                                                                    
                --
                UPDATE OWN_FUNCESP.PRE_TBL_LOG_TRANSACAO_ABAT_EMP PT
                   SET PT.VALOR_NOVO = L_VALOR_NOVO                  
                 WHERE PT.COD_LOG_TRANS IN ( SELECT MAX(PTL.COD_LOG_TRANS) AS COD_LOG_TRANS
                                               FROM OWN_FUNCESP.PRE_TBL_LOG_TRANSACAO_ABAT_EMP PTL
                                                WHERE PTL.COD_OP = 'D'  
                                            );   
                             
               COMMIT;                                                                  
         END IF;
         --           
 --
 --
  ELSE
    RAISE L_EXC_OPER;
  END IF;

 EXCEPTION

     WHEN L_EXC_OPER THEN
               --RAISE_APPLICATION_ERROR(-20999,'ATENÇÃO! Operação diferente de I, D, U, ou S', FALSE);   
               P_EXCEPTION := 2;
               ROLLBACK;
               
          WHEN L_EXC_READ THEN
               --DBMS_OUTPUT.PUT_LINE('Para efetuar a consulta, é necessário informar o número do registro e a data de início');                
               P_EXCEPTION := 3;       
               ROLLBACK;                                    
               
          WHEN L_SITUACAO THEN
               --DBMS_OUTPUT.PUT_LINE('Só será permitido efetuar cadastro dos participantes que encontram-se desligado!');                
               P_EXCEPTION := 4;                                           
               ROLLBACK;
               
          WHEN L_SITUACAO_NULL THEN
               --DBMS_OUTPUT.PUT_LINE('Necessário cadastrar a situação do participante na tabela de ADESAO_PLANO_FSS para prosseguir!');                    
               P_EXCEPTION := 5;                              
               ROLLBACK;
               
          WHEN L_TIPO THEN
               --DBMS_OUTPUT.PUT_LINE('Só será permitido efetuar cadastro dos participantes Autopatrocinado ou Coligado!');
               P_EXCEPTION := 6;               
               ROLLBACK;

          WHEN L_TIPO_NULL THEN                   
               --DBMS_OUTPUT.PUT_LINE('Necessário cadastrar o tipo do participante na tebela ADESAO_PLANO_FSS para prosseguir!');
               P_EXCEPTION := 7;
               ROLLBACK;
               
          WHEN L_REG_TRIBUTACAO THEN
               --DBMS_OUTPUT.PUT_LINE('Só será permitido efetuar cadastro de participantes que peretecem ao regime de tribrutação Progressivo!');           
               P_EXCEPTION := 8;               
               ROLLBACK;               

          WHEN L_REG_TRIBUTACAO_NULL THEN                                  
               --DBMS_OUTPUT.PUT_LINE('Necessário cadastrar o regime de tributação do participante na tebela ADESAO_PLANO_FSS para prosseguir!');
               P_EXCEPTION := 9;               
               ROLLBACK;
               
          WHEN L_EXC_RGTRO THEN
               --DBMS_OUTPUT.PUT_LINE('Falha na atualização dos dados, necessário informar o numero do registro do participante para prosseguir.');
               P_EXCEPTION := 10;               
               ROLLBACK;               

          WHEN NO_DATE_FOUND THEN
               --DBMS_OUTPUT.PUT_LINE('Registros removidos com sucesso!');                         
               P_EXCEPTION := 11;               
               --ROLLBACK;               

          WHEN L_EXC_PKS THEN
               --DBMS_OUTPUT.PUT_LINE('Falha na exlusão dos dados, necessário informar o código da empresa, nº do registro, nº CPF, Nº de identificação do gestor, tipo de negócio e a data de início.');                                        
               P_EXCEPTION := 12;               
               ROLLBACK;
                             
          WHEN L_EXC_COD_EMPRS THEN
               --DBMS_OUTPUT.PUT_LINE('Necessário informar o código e o registro do funcionário para prosseguir!');                                                       
               P_EXCEPTION := 13;               
               ROLLBACK;
                                             
          WHEN L_EXC_INSERT THEN         
              -- P_EXCEPTION := -9999 
              P_EXCEPTION := 14;  
              ROLLBACK;                                                          
/*                 DBMS_OUTPUT.PUT_LINE('Para efetuar o cadastro é necessário informar os seguintes dados:' || CHR(13) || CHR(13) ||
                                      'COD_EMPRS'        || CHR(13) ||
                                      'NUM_RGTRO_EMPRG'  || CHR(13) ||
                                      'NUM_CPF_EMPRG'    || CHR(13) ||
                                      'NUM_IDENT_GESTOR' || CHR(13) ||
                                      'TPO_NEGOCIO'      || CHR(13) ||
                                      'DTA_INCL');  */  
          WHEN DUP_VAL_ON_INDEX THEN
              --DBMS_OUTPUT.PUT_LINE('Para efetuar o cadastro, não será permitido duplicidade de dados: ORA-00001: unique constraint!'); 
              P_EXCEPTION := 15;                      
              ROLLBACK;                  
                         
         WHEN OTHERS THEN
               DBMS_OUTPUT.NEW_LINE();
               DBMS_OUTPUT.PUT_LINE('CODIGO ERRO: '||SQLCODE|| ' - '||'MSG: '||SQLERRM);
               DBMS_OUTPUT.PUT_LINE('LINHA: '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);

END PROC_CAD_EMPRESTIMO;
