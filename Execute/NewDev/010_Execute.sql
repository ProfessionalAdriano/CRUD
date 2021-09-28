-- 
SELECT * FROM OWN_FUNCESP.PRE_TBL_LOG_STATUS;
SELECT * FROM OWN_FUNCESP.PRE_TBL_ETAPA;                                           
-- TABELAS DE LOG:
SELECT * FROM OWN_FUNCESP.PRE_TBL_LOG_PROCESSO_ABAT_EMP WHERE DT_INIC_PROCESS >= TRUNC(SYSDATE);  
SELECT * FROM OWN_FUNCESP.PRE_TBL_LOG_TRANSACAO_ABAT_EMP WHERE DT_INIC_PROCESS >= TRUNC(SYSDATE); 
--
SELECT * FROM ATT.FCESP_TAB_VLR_ABAT_RESG  WHERE NUM_RGTRO_EMPRG = 2084694; --FOR UPDATE;  


-- INSERT:
DECLARE

  L_RETURN_CURSOR   SYS_REFCURSOR;
  L_EXCEPTION       NUMBER; 

BEGIN
  -- TESTE DO INSERT:
  OWN_FUNCESP.PROC_CAD_EMPRESTIMO( 'I' -- S,I,U,D
                                   ,40
                                   ,2084694   
                                   ,88453
                                   ,36357703885
                                   ,191001225
                                   ,1
                                   ,1000.00
                                   ,TO_DATE('30/09/2020','DD/MM/RRRR')
                                   ,NULL
                                   ,NULL
                                   ,L_RETURN_CURSOR
                                   ,L_EXCEPTION
                                  );
                                  
  DBMS_OUTPUT.PUT_LINE(L_EXCEPTION);                                                                    
END;
-----------------------------------
-----------------------------------
-- UPDATE:
DECLARE

  L_RETURN_CURSOR SYS_REFCURSOR;   
  L_EXCEPTION     NUMBER; 
  
BEGIN
  -- TESTE DO UPDATE:
  OWN_FUNCESP.PROC_CAD_EMPRESTIMO(P_OPER             => 'U',  -- S,I,U,D             
                                  P_COD_EMPRS        => 40,                                 
                                  P_NUM_RGTRO_EMPRG  => 2084694,          
                                  P_NUM_MATR_PARTF   => 88453,
                                  P_NUM_CPF_EMPRG    => 36357703885,      
                                  P_NUM_IDENT_GESTOR => 191001225,        
                                  P_TPO_NEGOCIO      => 1,                
                                  P_VLR_ABAT         => 7000.00,
                                  P_DTA_INCL         => TO_DATE('30/09/2020','DD/MM/RRRR'),  
                                  P_DTA_FINAL        => NULL, 
                                  P_VLR_EFET_ABAT    => NULL,
                                  P_RETURN_CURSOR    => L_RETURN_CURSOR,
                                  P_EXCEPTION        => L_EXCEPTION
                                  );
                                  
  DBMS_OUTPUT.PUT_LINE(L_EXCEPTION);                                                                   
END;
-----------------------------------
-----------------------------------
-- DELETE:
DECLARE

  L_RETURN_CURSOR SYS_REFCURSOR;   
  L_EXCEPTION     NUMBER; 
  
BEGIN
  -- TESTE DO UPDATE:
  OWN_FUNCESP.PROC_CAD_EMPRESTIMO(P_OPER             => 'D',              
                                  P_COD_EMPRS        => 40,                                 
                                  P_NUM_RGTRO_EMPRG  => 2084694,          
                                  P_NUM_MATR_PARTF   => 88453,
                                  P_NUM_CPF_EMPRG    => 36357703885,      
                                  P_NUM_IDENT_GESTOR => 191001225,        
                                  P_TPO_NEGOCIO      => 1,                
                                  P_VLR_ABAT         => 7000.00,
                                  P_DTA_INCL         => TO_DATE('30/09/2020','DD/MM/RRRR'), 
                                  P_DTA_FINAL        => NULL, 
                                  P_VLR_EFET_ABAT    => NULL,
                                  P_RETURN_CURSOR    => L_RETURN_CURSOR,
                                  P_EXCEPTION        => L_EXCEPTION
                                  );
                                  
  DBMS_OUTPUT.PUT_LINE(L_EXCEPTION);                                                                   
END;

		-----------------------------------
		-----------------------------------
			---  CENARIO DE ERROS:
		-----------------------------------
		-----------------------------------


-- SIMULACAO DO RESGATE: EMPRESTIMO
DECLARE
 
   L_EXCEPTION     NUMBER; 
 
BEGIN
    ATT.FCESP_CALC_PCT_ABAT_RESG( 40    
                                 ,2084694
                                 ,36357703885
                                 ,1
                                 ,191001225
                                 ,TO_DATE('30/09/2020','DD/MM/RRRR')
                                 , L_EXCEPTION);
    
    DBMS_OUTPUT.PUT_LINE(L_EXCEPTION);
END;
-----------------------------------
-----------------------------------
-- PROCESSAMENTO INDIVIDUAL: CAPITALIZACAO
DECLARE
 
   L_EXCEPTION     NUMBER; 
 
BEGIN
    ATT.FCESP_RET_ABAT_RESG_COTAS( 40    
                                 ,2084694
                                 ,36357703885
                                 ,1
                                 ,191001225
                                 ,TO_DATE('30/09/2020','DD/MM/RRRR')
                                 , L_EXCEPTION);
    
    DBMS_OUTPUT.PUT_LINE(L_EXCEPTION);
END;




































