CREATE OR REPLACE PROCEDURE ATT.FCESP_calc_pct_abat_resg(V_tpo_negocio number,V_dta_pgto date)

as

--- Variáveis ---
vn_vlr_dependente   number :=0;
vn_qtde_depend      number :=0;
vn_vlr_bruto_resg   number (15,2) :=0;
vn_vlr_aliq_ir      number (15,4) :=0;
vn_vlr_desc_ir      number (15,2) :=0;
vn_vlr_IR           number (15,2) :=0;
vn_vlr_isento       number (15,2) :=0;
vn_vlr_base_ir      number (15,2) :=0;
vn_vlr_base_ir_final number (15,2):=0;
vn_vlr_resid_abat   number (15,2) :=0;
vn_vlr_resid_abat_final number (15,2) :=0;
vn_pct_abat_cta     number (9,8)  :=0;
vn_seq_abat         number  :=0;
vn_acum_sld_1       number (16,2) :=0;---
vn_acum_sld_2       number (16,2) :=0;---
vn_vlr_resid_abat_1 number (16,2) :=0;---
vn_vlr_resid_abat_2 number (16,2) :=0;---


cursor vlr_abat is

SELECT va.cod_emprs,
       va.num_rgtro_emprg,
       va.num_matr_partf,
       ad.cod_tppcp,
       va.tpo_negocio,
       ad.num_plbnf,
       sum(va.vlr_abat) abat_total
        FROM att.fcesp_tab_vlr_abat_resg va,
             att.adesao_plano_partic_fss ad
where va.num_matr_partf = ad.num_matr_partf
and   ad.dat_fim_adplpr is null
and   va.dta_final is null
---and   va.num_matr_partf = 72547 --- para testes individuais
and   va.tpo_negocio = V_tpo_negocio
group by va.cod_emprs, va.num_rgtro_emprg, va.num_matr_partf, ad.cod_tppcp, va.tpo_negocio, ad.num_plbnf
order by va.cod_emprs, va.num_rgtro_emprg;

begin
FOR LINHA IN vlr_abat  LOOP

--- alíquota de IR ---
  if linha.num_plbnf in (16, 17) then
     vn_vlr_aliq_ir := .15;
     vn_vlr_desc_IR := 0;
     vn_vlr_dependente := 0;
     vn_qtde_depend := 0;
  else

select nvl(max(fs.fat_aliqt_irrf/100),0), nvl(max(fs.vlr_prddz_irrf),0)
         into vn_vlr_aliq_ir, vn_vlr_desc_IR
         from faixa_salarial_irrf fs
        where fs.vlr_faixa_irrf =
             (select min(f.vlr_faixa_irrf)
                from faixa_salarial_irrf f
               where f.ano_faixa_irrf*100+f.mes_faixa_irrf = fs.ano_faixa_irrf*100+fs.mes_faixa_irrf
                 and f.vlr_faixa_irrf >= linha.abat_total)
          and fs.ano_faixa_irrf*100+fs.mes_faixa_irrf = (select max(ff.ano_faixa_irrf*100+ff.mes_faixa_irrf)
                                                           from faixa_salarial_irrf ff
                                                          where ff.ano_faixa_irrf*100+ff.mes_faixa_irrf <= to_char(V_dta_pgto,'YYYYMM'));

--- Recupera o valor de abatimento por dependente para fins de IR ---
    select t.vlr_prddz_dpdte
       into  vn_vlr_dependente
       from att.deducao_irrf_depend t
       where ((t.ano_deduc_irrf*100)+t.mes_deduc_irrf) =
             (select max(((t.ano_deduc_irrf*100)+t.mes_deduc_irrf))
                     from att.deducao_irrf_depend t);

-- dependentes ---
select distinct s.qtd_dpdteir_smlbnf
into
       vn_qtde_depend
from att.simulacao_benef_fss s
where s.cod_process_tppsml = 7
and   s.num_matr_partf = linha.num_matr_partf
and   s.dat_calcul_smlbnf = (select max(s2.dat_calcul_smlbnf) from att.simulacao_benef_fss s2
                             where s.num_matr_partf = s2.num_matr_partf
                             and   s.cod_process_tppsml = s2.cod_process_tppsml
                             and   s2.dat_calcul_smlbnf <= V_dta_pgto);
end if;
---

--- calcula a sequencia do abatimento ---
vn_seq_abat   :=0;
vn_acum_sld_1 :=0;---
vn_acum_sld_2 :=0;---
select nvl(max(ab.num_seq_abat),0)
into
       vn_seq_abat
from att.fcesp_abat_emprest_sld_conta ab
where ab.num_matr_partf = linha.num_matr_partf;


vn_vlr_resid_abat := linha.abat_total;

--- recupera os valores passíveis de resgate para o cálculo do IR 1ª passagem ---
for vlr_resg in (
select f.num_ctfss,
       c.tip_ctfss,
       c.tip_reserv_ctfss,
       substr(pr.TIPO_BENEF,2,4) tipo_benef,
       c.cod_umarmz_ctfss,
       f.vlr_atual_smlfnd
from att.simulacao_benef_fss s,
     att.simulacao_fundo_fss f,
     att.fcesp_prior_cta_resg pr,
     att.conta_fss c
where s.num_matr_partf = f.num_matr_partf
and   s.num_sqncl_smlbnf = f.num_sqncl_smlbnf
and   f.num_ctfss = pr.num_ctfss
and   f.num_ctfss = c.num_ctfss
and   pr.NUM_PLBNF = s.num_plbnf
and   s.num_matr_partf = linha.num_matr_partf
and   s.cod_process_tppsml = 7
and   f.num_ctadest_smlfnd is null
and   f.num_ctfss is not null
and   pr.cod_tppcp = linha.cod_tppcp
and   pr.TIP_RESERV_CTFSS <> 2
and   s.dat_calcul_smlbnf = (select max(s2.dat_calcul_smlbnf) from att.simulacao_benef_fss s2
                             where s.num_matr_partf = s2.num_matr_partf
                             and   s.cod_process_tppsml = s2.cod_process_tppsml
                             and   s2.dat_calcul_smlbnf <= V_dta_pgto)
order by pr.ind_prior_cta
) loop

  if vn_vlr_resid_abat <= 0 then
     vn_pct_abat_cta := 0;
  else

      if vn_vlr_resid_abat  < vlr_resg.vlr_atual_smlfnd then
         vn_pct_abat_cta := round(vn_vlr_resid_abat/vlr_resg.vlr_atual_smlfnd,8);
      else
         vn_pct_abat_cta := 1;
      end if;
      vn_vlr_resid_abat := vn_vlr_resid_abat - vlr_resg.vlr_atual_smlfnd;
   end if;

if vlr_resg.num_ctfss in (245,309,266,259,355) and vn_pct_abat_cta <> 0 then
--- Valor isento ---
      select distinct s.vlr_ntribirrf_smlbnf
      into
             vn_vlr_isento
      from att.simulacao_benef_fss s
      where s.cod_process_tppsml = 7
      and   s.num_matr_partf = linha.num_matr_partf
      and   s.dat_calcul_smlbnf = (select max(s2.dat_calcul_smlbnf) from att.simulacao_benef_fss s2
                                   where s.num_matr_partf = s2.num_matr_partf
                                   and   s.cod_process_tppsml = s2.cod_process_tppsml
                                   and   s2.dat_calcul_smlbnf <= V_dta_pgto);

      if vn_vlr_isento > vn_vlr_resid_abat then
         vn_vlr_isento := vn_vlr_isento;
      else
         vn_vlr_isento := 0;
      end if;

vn_vlr_resid_abat_1 := ((linha.abat_total - (vn_vlr_dependente * vn_qtde_depend) - (vn_vlr_isento * vn_pct_abat_cta) - vn_vlr_desc_IR) / (1-vn_vlr_aliq_ir) + (vn_vlr_dependente * vn_qtde_depend)+ (vn_vlr_isento*vn_pct_abat_cta));
else
vn_vlr_resid_abat_1 := (((linha.abat_total - (vn_vlr_dependente * vn_qtde_depend) - vn_vlr_desc_IR) / (1-vn_vlr_aliq_ir)) + (vn_vlr_dependente * vn_qtde_depend));
  end if;
end loop;


vn_pct_abat_cta :=0;
--- recupera os valores passíveis de resgate para o cálculo do IR 2ª passagem ---

for vlr_resg in (
select f.num_ctfss,
       c.tip_ctfss,
       c.tip_reserv_ctfss,
       substr(pr.TIPO_BENEF,2,4) tipo_benef,
       c.cod_umarmz_ctfss,
       c.num_plbnf_ctfss,
       f.vlr_atual_smlfnd
from att.simulacao_benef_fss s,
     att.simulacao_fundo_fss f,
     att.fcesp_prior_cta_resg pr,
     att.conta_fss c
where s.num_matr_partf = f.num_matr_partf
and   s.num_sqncl_smlbnf = f.num_sqncl_smlbnf
and   f.num_ctfss = pr.num_ctfss
and   f.num_ctfss = c.num_ctfss
and   pr.NUM_PLBNF = s.num_plbnf
and   s.num_matr_partf = linha.num_matr_partf
and   s.cod_process_tppsml = 7
and   f.num_ctadest_smlfnd is null
and   f.num_ctfss is not null
and   pr.cod_tppcp = linha.cod_tppcp
and   pr.TIP_RESERV_CTFSS <> 2
and   s.dat_calcul_smlbnf = (select max(s2.dat_calcul_smlbnf) from att.simulacao_benef_fss s2
                             where s.num_matr_partf = s2.num_matr_partf
                             and   s.cod_process_tppsml = s2.cod_process_tppsml
                             and   s2.dat_calcul_smlbnf <= V_dta_pgto)
order by pr.ind_prior_cta
) loop

    if vn_vlr_resid_abat_1 <= 0 then
       vn_pct_abat_cta := 0;
    else

        if vn_vlr_resid_abat_1  < vlr_resg.vlr_atual_smlfnd then
           vn_pct_abat_cta := round(vn_vlr_resid_abat_1/vlr_resg.vlr_atual_smlfnd,8);
        else
           vn_pct_abat_cta := 1;
        end if;
        /*vn_vlr_resid_abat_1 := vn_vlr_resid_abat_1 - vlr_resg.vlr_atual_smlfnd;*/
  end if;


if vlr_resg.num_ctfss in (245,309,266,259,355) /*and vn_vlr_resid_abat_1 >= vlr_resg.vlr_atual_smlfnd*/  and vn_pct_abat_cta <> 0 then

--- Valor isento ---
      select distinct nvl(sum(s.vlr_ntribirrf_smlbnf),0)
      into
            vn_vlr_isento
      from att.simulacao_benef_fss s
      where s.cod_process_tppsml = 7
      and   s.num_matr_partf = linha.num_matr_partf
      and   s.dat_calcul_smlbnf = (select max(s2.dat_calcul_smlbnf) from att.simulacao_benef_fss s2
                                   where s.num_matr_partf = s2.num_matr_partf
                                   and   s.cod_process_tppsml = s2.cod_process_tppsml
                                   and   s2.dat_calcul_smlbnf <= V_dta_pgto);



vn_vlr_resid_abat_2 := ((linha.abat_total - (vn_vlr_dependente * vn_qtde_depend) - (vn_vlr_isento*vn_pct_abat_cta) - vn_vlr_desc_IR) / (1-vn_vlr_aliq_ir) + (vn_vlr_dependente * vn_qtde_depend)+(vn_vlr_isento * vn_pct_abat_cta));
else
vn_vlr_resid_abat_2 := (((linha.abat_total - (vn_vlr_dependente * vn_qtde_depend) - vn_vlr_desc_IR) / (1-vn_vlr_aliq_ir)) + (vn_vlr_dependente * vn_qtde_depend));
end if;
vn_vlr_resid_abat_1 := vn_vlr_resid_abat_1 - vlr_resg.vlr_atual_smlfnd;
end loop;



vn_pct_abat_cta :=0;
--- recupera os valores passíveis de resgate para o cálculo do IR 3ª passagem---

for vlr_resg in (
select f.num_ctfss,
       c.tip_ctfss,
       c.tip_reserv_ctfss,
       substr(pr.TIPO_BENEF,2,4) tipo_benef,
       c.cod_umarmz_ctfss,
       c.num_plbnf_ctfss,
       f.vlr_atual_smlfnd
from att.simulacao_benef_fss s,
     att.simulacao_fundo_fss f,
     att.fcesp_prior_cta_resg pr,
     att.conta_fss c
where s.num_matr_partf = f.num_matr_partf
and   s.num_sqncl_smlbnf = f.num_sqncl_smlbnf
and   f.num_ctfss = pr.num_ctfss
and   f.num_ctfss = c.num_ctfss
and   pr.NUM_PLBNF = s.num_plbnf
and   s.num_matr_partf = linha.num_matr_partf
and   s.cod_process_tppsml = 7
and   f.num_ctadest_smlfnd is null
and   f.num_ctfss is not null
and   pr.cod_tppcp = linha.cod_tppcp
and   pr.TIP_RESERV_CTFSS <> 2
and   s.dat_calcul_smlbnf = (select max(s2.dat_calcul_smlbnf) from att.simulacao_benef_fss s2
                             where s.num_matr_partf = s2.num_matr_partf
                             and   s.cod_process_tppsml = s2.cod_process_tppsml
                             and   s2.dat_calcul_smlbnf <= V_dta_pgto)
order by pr.ind_prior_cta
) loop

    if vn_vlr_resid_abat_2 <= 0 then
       vn_pct_abat_cta := 0;
    else

        if vn_vlr_resid_abat_2  < vlr_resg.vlr_atual_smlfnd then
           vn_pct_abat_cta := round(vn_vlr_resid_abat_2/vlr_resg.vlr_atual_smlfnd,8);
        else
           vn_pct_abat_cta := 1;
        end if;
        vn_vlr_resid_abat_2 := vn_vlr_resid_abat_2 - vlr_resg.vlr_atual_smlfnd;
  end if;

if vlr_resg.num_ctfss in (245,309,266,259,355) and vn_vlr_isento > ( vlr_resg.vlr_atual_smlfnd * vn_pct_abat_cta) then
   vn_pct_abat_cta :=0;
end if;


--- início da gravação na tabela alfândega ---

insert into att.fcesp_abat_emprest_sld_conta
 (NUM_SEQ_ABAT,
  num_matr_partf,
  num_ctfss,
  tip_ctfss,
  tip_reserv_ctfss,
  num_plbnf_ctfss,
  cod_umarmz_ctfss,
  tip_bnf_ctfss,
  vlr_abat,
  tip_abat,
  pct_resg_partf
  )
values
 (vn_seq_abat + 1,
  linha.num_matr_partf,
  vlr_resg.num_ctfss,
  vlr_resg.tip_ctfss,
  vlr_resg.tip_reserv_ctfss,
  vlr_resg.num_plbnf_ctfss,
  vlr_resg.cod_umarmz_ctfss,
  vlr_resg.tipo_benef,
  linha.abat_total,
  linha.tpo_negocio,
  vn_pct_abat_cta
  );

commit;
end loop;


end loop;

end;
/
