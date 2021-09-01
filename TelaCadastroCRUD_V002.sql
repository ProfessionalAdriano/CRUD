CREATE OR REPLACE PROCEDURE OWN_FUNCESP.PROC_CAD_EMPRESTIMO(  P_OPER               CHAR -- (I - INSERT, U - UPDATE, S - SELECT, D - DELETE)
                                                             ,P_COD_EMPRS          ATT.FCESP_TAB_VLR_ABAT_RESG.COD_EMPRS%TYPE
                                                             ,P_NUM_RGTRO_EMPRG    ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_RGTRO_EMPRG%TYPE
                                                             ,P_NUM_MATR_PARTF     ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_MATR_PARTF%TYPE
                                                             ,P_NUM_CPF_EMPRG      ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_CPF_EMPRG%TYPE
                                                             ,P_NUM_IDENT_GESTOR   ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_IDENT_GESTOR%TYPE
                                                             ,P_TPO_NEGOCIO        ATT.FCESP_TAB_VLR_ABAT_RESG.TPO_NEGOCIO%TYPE
                                                             ,P_VLR_ABAT           ATT.FCESP_TAB_VLR_ABAT_RESG.VLR_ABAT%TYPE
                                                             ,P_DTA_INCL           ATT.FCESP_TAB_VLR_ABAT_RESG.DTA_INCL%TYPE
                                                             ,P_DTA_FINAL          ATT.FCESP_TAB_VLR_ABAT_RESG.DTA_FINAL%TYPE
                                                             ,P_VLR_EFET_ABAT      ATT.FCESP_TAB_VLR_ABAT_RESG.VLR_EFET_ABAT%TYPE
                                                             ) IS


   L_COD_EMPRS          ATT.FCESP_TAB_VLR_ABAT_RESG.COD_EMPRS%TYPE;
   L_NUM_RGTRO_EMPRG    ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_RGTRO_EMPRG%TYPE;
   L_NUM_MATR_PARTF     ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_MATR_PARTF%TYPE;
   L_NUM_CPF_EMPRG      ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_CPF_EMPRG%TYPE;
   L_NUM_IDENT_GESTOR   ATT.FCESP_TAB_VLR_ABAT_RESG.NUM_IDENT_GESTOR%TYPE;
   L_TPO_NEGOCIO        ATT.FCESP_TAB_VLR_ABAT_RESG.TPO_NEGOCIO%TYPE;
   L_VLR_ABAT           ATT.FCESP_TAB_VLR_ABAT_RESG.VLR_ABAT%TYPE;
   L_DTA_INCL           ATT.FCESP_TAB_VLR_ABAT_RESG.DTA_INCL%TYPE;
   L_DTA_FINAL          ATT.FCESP_TAB_VLR_ABAT_RESG.DTA_FINAL%TYPE;
   L_VLR_EFET_ABAT      ATT.FCESP_TAB_VLR_ABAT_RESG.VLR_EFET_ABAT%TYPE;

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


     FUNCTION FNC_VALIDA_REGRA( P_NUM_MATR_PARTF ATT.PARTICIPANTE_FSS.NUM_MATR_PARTF%TYPE
                               ,P_CALC NUMBER )
      RETURN NUMBER IS 
      
      L_COD_SITPAR                   ATT.ADESAO_PLANO_PARTIC_FSS.COD_SITPAR%TYPE; 
      L_COD_TPPCP                    ATT.ADESAO_PLANO_PARTIC_FSS.COD_TPPCP%TYPE;
      L_TIP_OPCTRIBIR_ADPLPR         ATT.ADESAO_PLANO_PARTIC_FSS.TIP_OPCTRIBIR_ADPLPR%TYPE;
      

      
      BEGIN 
      
         IF (P_CALC = 1 )THEN 
        
             -- VALIDA SITUCAO DO PARTICIPANTE:
             SELECT COD_SITPAR              
                 INTO L_COD_SITPAR          
              FROM ATT.ADESAO_PLANO_PARTIC_FSS 
              WHERE NUM_MATR_PARTF = P_NUM_MATR_PARTF;
             
             CASE
                 WHEN L_COD_SITPAR IS NOT NULL THEN RETURN L_COD_SITPAR; 
                 WHEN L_COD_SITPAR NOT IN (4) THEN RAISE L_SITUACAO;                
                 WHEN L_COD_SITPAR IS NULL THEN RAISE L_SITUACAO_NULL;
                 --           
             END CASE;
            
         ELSIF (P_CALC = 2 )THEN
           
             -- VALIDA TIPO DO PARTICIPANTE:
             SELECT COD_TPPCP
                 INTO L_COD_TPPCP
               FROM ATT.ADESAO_PLANO_PARTIC_FSS
               WHERE NUM_MATR_PARTF = P_NUM_MATR_PARTF;
                 
             CASE    
                WHEN L_COD_TPPCP IS NOT NULL THEN RETURN L_COD_TPPCP;
                WHEN L_COD_TPPCP NOT IN (2, 3) THEN RAISE L_TIPO; 
                WHEN L_COD_TPPCP IS NULL THEN RAISE L_TIPO_NULL;                                               
             END CASE;    
              
         ELSIF (P_CALC = 3)THEN
         
             -- VALIDA REGIME DE TRIBUTACAO:
             SELECT TIP_OPCTRIBIR_ADPLPR      
                 INTO L_TIP_OPCTRIBIR_ADPLPR
                FROM ATT.ADESAO_PLANO_PARTIC_FSS
                WHERE NUM_MATR_PARTF = P_NUM_MATR_PARTF;
             
              CASE
                 WHEN L_TIP_OPCTRIBIR_ADPLPR IS NOT NULL THEN RETURN L_TIP_OPCTRIBIR_ADPLPR;
                 WHEN L_TIP_OPCTRIBIR_ADPLPR IN (2) THEN RAISE L_REG_TRIBUTACAO;   
                 WHEN L_TIP_OPCTRIBIR_ADPLPR IS NULL THEN RAISE L_REG_TRIBUTACAO_NULL;
                                 
              END CASE;  
         END IF;  
                 
         EXCEPTION       
               
          WHEN OTHERS THEN 
                     
               DBMS_OUTPUT.PUT_LINE('CODIGO DO ERRO: ' || SQLCODE || ' MSG: ' ||SQLERRM);
               DBMS_OUTPUT.PUT_LINE('LINHA: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);        
              
      END FNC_VALIDA_REGRA;
        

BEGIN


 IF (P_OPER = 'S' OR P_OPER = 's') THEN

      IF (P_NUM_RGTRO_EMPRG IS NOT NULL) THEN

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
          INTO L_COD_EMPRS
              ,L_NUM_RGTRO_EMPRG
              ,L_NUM_MATR_PARTF
              ,L_NUM_CPF_EMPRG
              ,L_NUM_IDENT_GESTOR
              ,L_TPO_NEGOCIO
              ,L_VLR_ABAT
              ,L_DTA_INCL
              ,L_DTA_FINAL
              ,L_VLR_EFET_ABAT
          FROM ATT.FCESP_TAB_VLR_ABAT_RESG
            WHERE NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG;

              --
              -- TESTANDO VARIAVEIS:
              DBMS_OUTPUT.PUT_LINE('COD_EMPRS'        ||': ' ||L_COD_EMPRS        || CHR(13)||
                                   'NUM_RGTRO_EMPRG'  ||': ' ||L_NUM_RGTRO_EMPRG  || CHR(13)||
                                   'NUM_MATR_PARTF'   ||': ' ||L_NUM_MATR_PARTF   || CHR(13)||
                                   'NUM_CPF_EMPRG'    ||': ' ||L_NUM_CPF_EMPRG    || CHR(13)||
                                   'NUM_IDENT_GESTOR' ||': ' ||L_NUM_IDENT_GESTOR || CHR(13)||
                                   'TPO_NEGOCIO'      ||': ' ||L_TPO_NEGOCIO      || CHR(13)||
                                   'VLR_ABAT'         ||': ' ||L_VLR_ABAT         || CHR(13)||
                                   'DTA_INCL'         ||': ' ||L_DTA_INCL         || CHR(13)||
                                   'DTA_FINAL'        ||': ' ||L_DTA_FINAL        || CHR(13)||
                                   'VLR_EFET_ABAT'    ||': ' ||L_VLR_EFET_ABAT    || CHR(13));

      -- QUANDO INFORMADO A APENAS A DATA INICIO SERA EXEIBIDO O HISTORICO DO PARTICIPANTE NA TELA:
      ELSIF(P_DTA_INCL IS NOT NULL) THEN


         FOR RG IN ( SELECT  COD_EMPRS
                            ,NUM_RGTRO_EMPRG
                            ,NUM_MATR_PARTF
                            ,NUM_CPF_EMPRG
                            ,NUM_IDENT_GESTOR
                            ,TPO_NEGOCIO
                            ,VLR_ABAT
                            ,DTA_INCL
                            ,DTA_FINAL
                            ,VLR_EFET_ABAT
                        INTO L_COD_EMPRS
                            ,L_NUM_RGTRO_EMPRG
                            ,L_NUM_MATR_PARTF
                            ,L_NUM_CPF_EMPRG
                            ,L_NUM_IDENT_GESTOR
                            ,L_TPO_NEGOCIO
                            ,L_VLR_ABAT
                            ,L_DTA_INCL
                            ,L_DTA_FINAL
                            ,L_VLR_EFET_ABAT
                         FROM ATT.FCESP_TAB_VLR_ABAT_RESG
                           WHERE DTA_INCL = P_DTA_INCL
                             ORDER BY 1) LOOP

                              -- TESTANDO VARIAVEIS:
                              DBMS_OUTPUT.PUT_LINE('COD_EMPRS'        ||': ' ||RG.COD_EMPRS        || CHR(13)||
                                                   'NUM_RGTRO_EMPRG'  ||': ' ||RG.NUM_RGTRO_EMPRG  || CHR(13)||
                                                   'NUM_MATR_PARTF'   ||': ' ||RG.NUM_MATR_PARTF   || CHR(13)||
                                                   'NUM_CPF_EMPRG'    ||': ' ||RG.NUM_CPF_EMPRG    || CHR(13)||
                                                   'NUM_IDENT_GESTOR' ||': ' ||RG.NUM_IDENT_GESTOR || CHR(13)||
                                                   'TPO_NEGOCIO'      ||': ' ||RG.TPO_NEGOCIO      || CHR(13)||
                                                   'VLR_ABAT'         ||': ' ||RG.VLR_ABAT         || CHR(13)||
                                                   'DTA_INCL'         ||': ' ||RG.DTA_INCL         || CHR(13)||
                                                   'DTA_FINAL'        ||': ' ||RG.DTA_FINAL        || CHR(13)||
                                                   'VLR_EFET_ABAT'    ||': ' ||RG.VLR_EFET_ABAT    || CHR(13));

                            END LOOP;

      ELSE
         DBMS_OUTPUT.PUT_LINE('CODIGO DO ERRO: ' || SQLCODE || ' MSG: ' ||SQLERRM);
         DBMS_OUTPUT.PUT_LINE('LINHA: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      END IF;

      ELSIF(P_OPER = 'I' OR P_OPER = 'i') THEN
 

         L_NUM_MATR_PARTF := NULL;
         --
           SELECT NUM_MATR_PARTF 
               INTO L_NUM_MATR_PARTF 
            FROM ATT.PARTICIPANTE_FSS
            WHERE NUM_RGTRO_EMPRG = P_NUM_RGTRO_EMPRG;                  
            
     L_VER_REGR_SITUACAO           := FNC_VALIDA_REGRA(L_NUM_MATR_PARTF, 1); 
     L_VER_REGR_TIPO               := FNC_VALIDA_REGRA(L_NUM_MATR_PARTF, 2);
     L_VER_REGR_TRIBUTACAO         := FNC_VALIDA_REGRA(L_NUM_MATR_PARTF, 3);
             
     
     IF L_VER_REGR_SITUACAO NOT IN (4)   THEN RAISE L_SITUACAO;
     --
     ELSIF L_VER_REGR_TIPO NOT IN (2, 3) THEN RAISE L_TIPO;
     --
     ELSIF L_VER_REGR_TRIBUTACAO IN (2)  THEN RAISE L_REG_TRIBUTACAO;
     --
     ELSE            
         --DBMS_OUTPUT.PUT_LINE('EFETUAR CADASTRO');
                     INSERT INTO ATT.FCESP_TAB_VLR_ABAT_RESG ( COD_EMPRS
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
                                               ( P_COD_EMPRS
                                                ,P_NUM_RGTRO_EMPRG
                                                ,P_NUM_MATR_PARTF
                                                ,P_NUM_CPF_EMPRG
                                                ,P_NUM_IDENT_GESTOR
                                                ,P_TPO_NEGOCIO
                                                ,P_VLR_ABAT
                                                ,P_DTA_INCL
                                                ,P_DTA_FINAL
                                                ,P_VLR_EFET_ABAT);
                                         COMMIT;
                                           
     END IF;
     
 --
 --
 ELSIF(P_OPER = 'U' OR P_OPER = 'u') THEN

         -- ATUALIZACAO DE DADOS:
         IF (P_NUM_RGTRO_EMPRG IS NULL OR P_COD_EMPRS = '') THEN
             ROLLBACK;
             RAISE L_EXC_RGTRO;
         ELSE
         
             --DBMS_OUTPUT.PUT_LINE('UPDATE');
             UPDATE ATT.FCESP_TAB_VLR_ABAT_RESG   
             SET COD_EMPRS         = NVL(P_COD_EMPRS, COD_EMPRS)
                ,NUM_CPF_EMPRG     = NVL(P_NUM_CPF_EMPRG, NUM_CPF_EMPRG)
                ,NUM_IDENT_GESTOR  = NVL(P_NUM_IDENT_GESTOR, NUM_IDENT_GESTOR)
                ,TPO_NEGOCIO       = NVL(P_TPO_NEGOCIO, TPO_NEGOCIO)
                ,VLR_ABAT          = NVL(P_VLR_ABAT, VLR_ABAT)
                ,DTA_INCL          = NVL(P_DTA_INCL, DTA_INCL)
                ,DTA_FINAL         = NVL(P_DTA_FINAL, DTA_FINAL)
                ,VLR_EFET_ABAT     = NVL(P_VLR_EFET_ABAT, VLR_EFET_ABAT)
                --
             WHERE NUM_RGTRO_EMPRG = P_NUM_RGTRO_EMPRG;
            COMMIT;
             
         END IF;               
 --
 --
 ELSIF(P_OPER = 'D' OR P_OPER = 'd') THEN

                              DBMS_OUTPUT.PUT_LINE('DELETE');
 --
 --
  ELSE
    RAISE L_EXC_OPER;
  END IF;

 EXCEPTION

     WHEN L_EXC_OPER THEN
        RAISE_APPLICATION_ERROR(-20999,'ATENÇÃO! Operação diferente de I, D, U, ou S', FALSE);   
                 
          WHEN L_SITUACAO THEN
               DBMS_OUTPUT.PUT_LINE('Só será permitido efetuar cadastro dos participantes que encontram-se desligado!');                
          --
          WHEN L_SITUACAO_NULL THEN
               DBMS_OUTPUT.PUT_LINE('Necessário cadastrar a situação do participante na tabela de ADESAO_PLANO_FSS para prosseguir!');                    
               
          WHEN L_TIPO THEN
               DBMS_OUTPUT.PUT_LINE('Só será permitido efetuar cadastro dos participantes Autopatrocinado ou Coligado!');

          WHEN L_TIPO_NULL THEN                   
               DBMS_OUTPUT.PUT_LINE('Necessário cadastrar o tipo do participante na tebela ADESAO_PLANO_FSS para prosseguir!');
               
          WHEN L_REG_TRIBUTACAO THEN
               DBMS_OUTPUT.PUT_LINE('Só será permitido efetuar cadastro de participantes que peretecem ao regime de tribrutação Progressivo!');           

          WHEN L_REG_TRIBUTACAO_NULL THEN                                  
               DBMS_OUTPUT.PUT_LINE('Necessário cadastrar o regime de tributação do participante na tebela ADESAO_PLANO_FSS para prosseguir!');
               
          WHEN L_EXC_RGTRO THEN
               DBMS_OUTPUT.PUT_LINE('Falha na atualização dos dados, informar o numero do registro do participante para prosseguir.');
                         
         WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('CODIGO ERRO: '||SQLCODE|| ' - '||'MSG: '||SQLERRM);
               DBMS_OUTPUT.PUT_LINE('LINHA: '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);



END PROC_CAD_EMPRESTIMO;
