CREATE OR REPLACE PROCEDURE ATT.FCESP_RET_ABAT_RESG_COTAS(V_tpo_negocio number,V_dta_pgto date)

as

--- Variáveis ---
vn_vlr_tot_desc         number (15,2) :=0;
vn_vlr_resid_abat       number (15,2) :=0;
cod_desc                number (1)    :=0;



--- Abre cursor com o valor solicitado para descontado do resgate ---
cursor vlr_abat is

select distinct
      a.num_matr_partf
from att.fcesp_tab_vlr_abat_resg a
where a.dta_final is null
---and   a.num_matr_partf = 8509 --- teste indivdual
order by 1;


begin
FOR LINHA IN vlr_abat  LOOP

if V_tpo_negocio = 1 then
   cod_desc :=5;
end if;

vn_vlr_tot_desc :=0;

--- recupera o valor descontado do resgate ---
begin

select  ir.vlr_itrprt
into
        vn_vlr_tot_desc
from att.resg_part_capit_fss r,
     att.item_resgate_part ir
where r.num_matr_partf = ir.num_matr_partf
and   r.num_rsgprt = ir.num_rsgprt
and   r.mrc_cancel_rsgprt = 'N'
and   r.num_tpeven = 101
and   ir.num_tpdesc_itrprt = cod_desc
and   r.num_matr_partf = linha.num_matr_partf
and   r.dat_rsgprt = V_dta_pgto;
exception when no_data_found then
          vn_vlr_tot_desc :=0;
end;

vn_vlr_resid_abat := vn_vlr_tot_desc;

      for vlr_resg in (
      select distinct
            a.num_matr_partf,
            a.num_ident_gestor,
            a.vlr_abat
      from att.fcesp_tab_vlr_abat_resg a
      where a.num_matr_partf = linha.num_matr_partf
      and   a.dta_final is null
      order by 1,2
      ) loop


             if vn_vlr_resid_abat  >= vlr_resg.vlr_abat then
                    update att.fcesp_tab_vlr_abat_resg
                     set dta_final = V_dta_pgto,
                         vlr_efet_abat = vlr_resg.vlr_abat
                   where tpo_negocio = V_tpo_negocio
                   and   num_matr_partf = vlr_resg.num_matr_partf
                     and num_ident_gestor = vlr_resg.num_ident_gestor;

                  commit;
             else
                    update att.fcesp_tab_vlr_abat_resg
                     set dta_final = V_dta_pgto,
                         vlr_efet_abat = greatest(0,vn_vlr_resid_abat)
                   where tpo_negocio = V_tpo_negocio
                   and   num_matr_partf = vlr_resg.num_matr_partf
                     and num_ident_gestor = vlr_resg.num_ident_gestor;

                  commit;
              end if;

              vn_vlr_resid_abat := vn_vlr_resid_abat - vlr_resg.vlr_abat;

      end loop;
end loop;
end;
/
