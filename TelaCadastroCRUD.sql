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
   L_VER_REGR_NEG1             NUMBER:='';   
   L_VER_REGR_NEG2             NUMBER:='';   
   L_VER_REGR_NEG3             NUMBER:=''; 
   --L_SITUACAO                 ATT.ADESAO_PLANO_PARTIC_FSS.COD_SITPAR%TYPE:=4;

   -- DECLARACAO EXCEPTION:
   L_EXC_OPER             EXCEPTION;
   L_SITUACAO             EXCEPTION;
   L_COD_TPPCP            EXCEPTION;
   TIP_OPCTRIBIR_ADPLPR   EXCEPTION;


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
        DBMS_OUTPUT.PUT_LINE('CODIGO ERRO: '||SQLCODE|| ' - '||'MSG: '||SQLERRM);
      END IF;

 ELSIF(P_OPER = 'I' OR P_OPER = 'i') THEN
 

         L_NUM_MATR_PARTF := NULL;
         --
           SELECT NUM_MATR_PARTF 
               INTO L_NUM_MATR_PARTF 
            FROM ATT.PARTICIPANTE_FSS
            WHERE NUM_RGTRO_EMPRG = P_NUM_RGTRO_EMPRG;
                  
           -- VALIDA SITUCAO DO PARTICIPANTE:
           SELECT COUNT(*) AS L_VER_REGR_NEG1
               INTO L_VER_REGR_NEG1
            FROM ATT.ADESAO_PLANO_PARTIC_FSS 
            WHERE  COD_SITPAR  = 4
            AND NUM_MATR_PARTF = L_NUM_MATR_PARTF;--91802
            --
            --
            -- VALIDA TIPO DO PARTICIPANTE:
           SELECT COUNT(*) AS L_VER_REGR_NEG2
               INTO L_VER_REGR_NEG2
            FROM ATT.ADESAO_PLANO_PARTIC_FSS 
            WHERE  COD_TPPCP IN (2, 3)
            AND NUM_MATR_PARTF = L_NUM_MATR_PARTF;--91802
            --
            --
            -- VALIDA REGIME DE TRIBRUTACAO:
           SELECT COUNT(*) AS L_VER_REGR_NEG3
               INTO L_VER_REGR_NEG3
            FROM ATT.ADESAO_PLANO_PARTIC_FSS 
            WHERE TIP_OPCTRIBIR_ADPLPR = 2
            AND NUM_MATR_PARTF = L_NUM_MATR_PARTF;--91802 
            

     IF (L_VER_REGR_NEG1 = 0 )THEN
           RAISE L_SITUACAO;
     
     ELSIF (L_VER_REGR_NEG2 = 0 )THEN
           RAISE L_COD_TPPCP;
           
     ELSIF (L_VER_REGR_NEG3 <> 0 )THEN
           RAISE TIP_OPCTRIBIR_ADPLPR;      
     
     ELSE
         DBMS_OUTPUT.PUT_LINE('INSERT');
/*         INSERT INTO ATT.FCESP_TAB_VLR_ABAT_RESG ( COD_EMPRS
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
*/
     END IF;

 --
 --
 ELSIF(P_OPER = 'U' OR P_OPER = 'u') THEN

         --DBMS_OUTPUT.PUT_LINE('UPDATE');
         IF ( P_COD_EMPRS        IS NOT NULL OR
              P_NUM_RGTRO_EMPRG  IS NOT NULL OR
              P_NUM_CPF_EMPRG    IS NOT NULL OR
              P_NUM_IDENT_GESTOR IS NOT NULL OR
              P_TPO_NEGOCIO      IS NOT NULL OR
              P_DTA_INCL         IS NOT NULL ) THEN

             --DBMS_OUTPUT.PUT_LINE('UPDATE');
             UPDATE ATT.FCESP_TAB_VLR_ABAT_RESG
                 SET COD_EMPRS        = P_COD_EMPRS
                    --,NUM_RGTRO_EMPRG  = P_NUM_RGTRO_EMPRG
                    ,NUM_MATR_PARTF   = P_NUM_MATR_PARTF
                    ,NUM_CPF_EMPRG    = P_NUM_CPF_EMPRG
                    ,NUM_IDENT_GESTOR = P_NUM_IDENT_GESTOR
                    ,TPO_NEGOCIO      = P_TPO_NEGOCIO
                    ,VLR_ABAT         = P_VLR_ABAT
                    ,DTA_INCL         = P_DTA_INCL
                    ,DTA_FINAL        = P_DTA_FINAL
                    ,VLR_EFET_ABAT    = P_VLR_EFET_ABAT
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
        
     WHEN L_COD_TPPCP THEN
        DBMS_OUTPUT.PUT_LINE('Só será permitido efetuar cadastro dos participantes Autopatrocinado ou Coligado!');

     WHEN TIP_OPCTRIBIR_ADPLPR THEN
        DBMS_OUTPUT.PUT_LINE('Só será permitido efetuar cadastro de participantes que peretecem ao regime de tribrutação Progressivo!');
           
     WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('CODIGO ERRO: '||SQLCODE|| ' - '||'MSG: '||SQLERRM);
        DBMS_OUTPUT.PUT_LINE('LINHA: '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);


END PROC_CAD_EMPRESTIMO;
