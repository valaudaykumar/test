----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------LEAD & Subordintate-------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------

select distinct c.contract_nbr, 'LEAD', c.status,  REPLACE (CO.LEAD_CONTRACT_NBR, '-', '') MC_CONTRACT_NUMBER from change_order co, contract c
where REPLACE (CO.LEAD_CONTRACT_NBR, '-', '') in
    (
    select distinct REPLACE (CO.LEAD_CONTRACT_NBR, '-', '')  from change_order co, contract c
        where REPLACE (CO.LEAD_CONTRACT_NBR, '-', '') not in (select contract_number from bill)
        and c.contract_nbr = co.contract_nbr
        --and CONTRACT_TYPE not in('Extended Warranty', 'Service Earned Rev', 'PSA' ) 
        and length(REPLACE (CO.LEAD_CONTRACT_NBR, '-', '')) = 8
        and REPLACE (CO.LEAD_CONTRACT_NBR, '-', '') in (
                    select contract_nbr from contract where c.status !='CLOSED'
                    and CONTRACT_TYPE not in('Extended Warranty', 'Service Earned Rev', 'PSA')
                    and mc_contract_number is null
         ) 
        and c.status !='CLOSED'
        and c.mc_contract_number is null
)
and c.contract_nbr not in (select contract_number from bill)
and c.contract_nbr = co.contract_nbr
and c.status != 'CLOSED'
union
select distinct REPLACE (CO.LEAD_CONTRACT_NBR, '-', ''), 'LEAD', c.status,  REPLACE (CO.LEAD_CONTRACT_NBR, '-', '') MC_CONTRACT_NUMBER  
from change_order co, contract c
where REPLACE (CO.LEAD_CONTRACT_NBR, '-', '') not in (select contract_number from bill)
and c.contract_nbr = co.contract_nbr
--and CONTRACT_TYPE not in('Extended Warranty', 'Service Earned Rev', 'PSA' ) 
and length(REPLACE (CO.LEAD_CONTRACT_NBR, '-', '')) = 8
and REPLACE (CO.LEAD_CONTRACT_NBR, '-', '') in (
            select contract_nbr from contract where c.status !='CLOSED'
            and CONTRACT_TYPE not in('Extended Warranty', 'Service Earned Rev', 'PSA')
            and mc_contract_number is null
 ) 
and c.status !='CLOSED'
and c.mc_contract_number is null

----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------- MCC & EQP-------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------

select * from (
select c.contract_nbr,'MCC',c.status,c.mc_contract_number
--,max(bill_date), bill_submitted_by
from contract c, location l, contract_f cf, master_contract_f mcf
--, bill b
where mc_contract_number is not null
and upper(c.status) != 'CLOSED'
and c.location_id = l.location_id
and c.contract_nbr = cf.contract_nbr
and c.contract_nbr not like '_J%'
--and b.contract_number = c.contract_nbr
and (length(c.contract_nbr) = 8 OR c.contract_type = 'PSA')
and mcf.MASTER_CONTRACT_NBR = c.mc_contract_number
and (nvl(mcf.ar_billed_ctd, 0)+nvl(mcf.ar_billed_ctd_ew, 0)) = 0
and c.contract_nbr not in (
select contract_number from (
 select contract_number, sum(totals_net_due) from bill
    where contract_number in (
    select contract_nbr from contract
    where mc_contract_number in (
    select mc_contract_number from master_contract_f
    where (nvl(ar_billed_ctd, 0)+nvl(ar_billed_ctd_ew, 0)) = 0))
    group by contract_number
    having(sum(totals_net_due) != 0)
))
--and c.contract_nbr not in (select contract_number from bill)
union
select contract_nbr,'EQP',STATUS,mc_contract_number from (
select c.contract_nbr, count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE),c.status,c.mc_contract_number from 
(SELECT *
   FROM om_order_line oml
  WHERE    NVL (oml.item_nbr, '0000') <> '9004'
        OR (    oml.item_nbr = '9004'
            AND oml.OM_LINE_STATUS != 'CANCELLED'
            AND NOT EXISTS
                       (SELECT *
                          FROM om_order_line o1
                         WHERE     1 = 1
                               AND OM_LINE_STATUS != 'CANCELLED'
                               AND o1.item_nbr <> '9004'
                               AND oml.CONTRACT_NBR = o1.CONTRACT_NBR
                               AND oml.YW_ORDER_NBR = o1.YW_ORDER_NBR))) 
om, 
master_contract_f mcf, contract c
where om_line_status != 'CANCELLED'
and c.contract_nbr in (select c.contract_nbr from contract c, contract_f cf where contract_subtype='Pure Equipment' and cf.contract_nbr = c.contract_nbr 
and (nvl(cf.ar_billed_ctd, 0)+nvl(cf.ar_billed_ctd_ew, 0)) = 0
and c.status != ('CLOSED')
and c.contract_nbr not like '_J%')
and (((nvl(mcf.ar_billed_ctd, 0)+nvl(mcf.ar_billed_ctd_ew, 0)) = 0 and c.mc_contract_number is not null) or c.mc_contract_number is null)
and not exists (select 1 from bill b where b.contract_number = om.contract_nbr)
and c.contract_nbr = om.contract_nbr
and c.mc_contract_number = mcf.master_contract_nbr(+)
--AND C.CONTRACT_NBR = '5N010286'
group by c.contract_nbr,c.status,c.mc_contract_number
having count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE) > 1)
)
where mc_contract_number not in (
                select c.mc_contract_number from bill b, contract c
                where contract_number in (
                        select contract_nbr from contract
                        where mc_contract_number in (select mc_contract_number from (
                            select c.contract_nbr,'MCC',c.status,c.mc_contract_number
                            --,max(bill_date), bill_submitted_by
                            from contract c, location l, contract_f cf, master_contract_f mcf
                            --, bill b
                            where mc_contract_number is not null
                            and upper(c.status) != 'CLOSED'
                            and c.location_id = l.location_id
                            and c.contract_nbr = cf.contract_nbr
                            and c.contract_nbr not like '_J%'
                            --and b.contract_number = c.contract_nbr
                            and (length(c.contract_nbr) = 8 OR c.contract_type = 'PSA')
                            and mcf.MASTER_CONTRACT_NBR = c.mc_contract_number
                            and (nvl(mcf.ar_billed_ctd, 0)+nvl(mcf.ar_billed_ctd_ew, 0)) = 0
                            and c.contract_nbr not in (
                            select contract_number from (
                             select contract_number, sum(totals_net_due) from bill
                                where contract_number in (
                                select contract_nbr from contract
                                where mc_contract_number in (
                                select mc_contract_number from master_contract_f
                                where (nvl(ar_billed_ctd, 0)+nvl(ar_billed_ctd_ew, 0)) = 0))
                                group by contract_number
                                having(sum(totals_net_due) != 0)
                            ))
                            --and c.contract_nbr not in (select contract_number from bill)
                            union
                            select contract_nbr,'EQP',STATUS,mc_contract_number from (
                            select c.contract_nbr, count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE),c.status,c.mc_contract_number from 
                (SELECT *
                   FROM om_order_line oml
                  WHERE    NVL (oml.item_nbr, '0000') <> '9004'
                    OR (    oml.item_nbr = '9004'
                        AND oml.OM_LINE_STATUS != 'CANCELLED'
                        AND NOT EXISTS
                               (SELECT *
                              FROM om_order_line o1
                             WHERE     1 = 1
                                   AND OM_LINE_STATUS != 'CANCELLED'
                                   AND o1.item_nbr <> '9004'
                                   AND oml.CONTRACT_NBR = o1.CONTRACT_NBR
                                   AND oml.YW_ORDER_NBR = o1.YW_ORDER_NBR)) 
                ) om, 
                master_contract_f mcf, contract c
                            where om_line_status != 'CANCELLED'
                            and c.contract_nbr in (select c.contract_nbr from contract c, contract_f cf where contract_subtype='Pure Equipment' and cf.contract_nbr = c.contract_nbr 
                            and (nvl(cf.ar_billed_ctd, 0)+nvl(cf.ar_billed_ctd_ew, 0)) = 0
                            and c.status != ('CLOSED')
                            and c.contract_nbr not like '_J%')
                            and c.tax_code not in ('05', '15')
                            and (((nvl(mcf.ar_billed_ctd, 0)+nvl(mcf.ar_billed_ctd_ew, 0)) = 0 and c.mc_contract_number is not null) or c.mc_contract_number is null)
                            and not exists (select 1 from bill b where b.contract_number = om.contract_nbr)
                            and c.contract_nbr = om.contract_nbr
                            and c.mc_contract_number = mcf.master_contract_nbr(+)
                            --AND C.CONTRACT_NBR = '5N010286'
                            group by c.contract_nbr,c.status,c.mc_contract_number
                            having count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE) > 1)
                            )
                        )
                )
                and b.contract_number = c.contract_nbr
                and b.status != '1100'
          )
order by MC_CONTRACT_NUMBER

----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------Standalone EQP-------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------



select contract_nbr,'EQP',STATUS,mc_contract_number from (
select c.contract_nbr, count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE),c.status,c.mc_contract_number from 
(SELECT *
   FROM om_order_line oml
  WHERE    NVL (oml.item_nbr, '0000') <> '9004'
        OR (    oml.item_nbr = '9004'
            AND oml.OM_LINE_STATUS != 'CANCELLED'
            AND NOT EXISTS
                       (SELECT *
                          FROM om_order_line o1
                         WHERE     1 = 1
                               AND OM_LINE_STATUS != 'CANCELLED'
                               AND o1.item_nbr <> '9004'
                               AND oml.CONTRACT_NBR = o1.CONTRACT_NBR
                               AND oml.YW_ORDER_NBR = o1.YW_ORDER_NBR))
) om, 
master_contract_f mcf, contract c
where om_line_status != 'CANCELLED'
and c.contract_nbr in (select c.contract_nbr from contract c, contract_f cf where contract_subtype='Pure Equipment' and cf.contract_nbr = c.contract_nbr 
and (nvl(cf.ar_billed_ctd, 0)+nvl(cf.ar_billed_ctd_ew, 0)) = 0
and c.status != ('CLOSED')
and c.contract_nbr not like '_J%')
and c.tax_code not in ('05', '15')
and (((nvl(mcf.ar_billed_ctd, 0)+nvl(mcf.ar_billed_ctd_ew, 0)) = 0 and c.mc_contract_number is not null) or c.mc_contract_number is null)
and not exists (select 1 from bill b where b.contract_number = om.contract_nbr and status <> '1100')
and c.contract_nbr = om.contract_nbr
and c.mc_contract_number = mcf.master_contract_nbr(+)
and mc_contract_number is null
--AND C.CONTRACT_NBR = '5N010286'
group by c.contract_nbr,c.status,c.mc_contract_number
having count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE) > 1)

----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------WIP MCC & EQP-------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------


select mc_contract_number, 
DECODE (b.STATUS,
               '1000', 'On-Hold',
               '1100', 'Work In Progress',
               '0011', 'Waiting Approval',
               '1102', 'Pending Posting',
               '1103', 'Posting Error',
               '0010', 'Posted',
               '0001', 'Distributed', b.STATUS) STATUS, 
 c.contract_nbr, b.bill_id, b.bill_submitted_by, gu.EMAIL_ADDRESS, gu.first_name, gu.last_name from bill b, contract_f c, contract d, gw_user gu
where b.status in ('1100') and c.contract_nbr = b.contract_number
and c.contract_nbr = d.contract_nbr
and nvl(c.ar_billed_ctd, 0) = 0
and d.mc_contract_number is not null
and b.bill_submitted_by =  gu.global_id
and d.mc_contract_number in (
               select mc_contract_number from (
                select c.contract_nbr,'MCC',c.status,c.mc_contract_number
                --,max(bill_date), bill_submitted_by
                from contract c, location l, contract_f cf, master_contract_f mcf
                --, bill b
                where mc_contract_number is not null
                and upper(c.status) != 'CLOSED'
                and c.location_id = l.location_id
                and c.contract_nbr = cf.contract_nbr
                and c.contract_nbr not like '_J%'
                --and c.tax_code not in ('05', '15')
                --and b.contract_number = c.contract_nbr
                and (length(c.contract_nbr) = 8 OR c.contract_type = 'PSA')
                and mcf.MASTER_CONTRACT_NBR = c.mc_contract_number
                and (nvl(mcf.ar_billed_ctd, 0)+nvl(mcf.ar_billed_ctd_ew, 0)) = 0
                and c.contract_nbr not in (
                select contract_number from (
                 select contract_number, sum(totals_net_due) from bill
                    where contract_number in (
                    select contract_nbr from contract
                    where mc_contract_number in (
                    select mc_contract_number from master_contract_f
                    where (nvl(ar_billed_ctd, 0)+nvl(ar_billed_ctd_ew, 0)) = 0))
                    group by contract_number
                    having(sum(totals_net_due) != 0)
                ))
                --and c.contract_nbr not in (select contract_number from bill)
                union
                select contract_nbr,'EQP',STATUS,mc_contract_number from (
                select c.contract_nbr, count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE),c.status,c.mc_contract_number from 
        (SELECT *
           FROM om_order_line oml
          WHERE    NVL (oml.item_nbr, '0000') <> '9004'
            OR (    oml.item_nbr = '9004'
                AND oml.OM_LINE_STATUS != 'CANCELLED'
                AND NOT EXISTS
                       (SELECT *
                      FROM om_order_line o1
                     WHERE     1 = 1
                           AND OM_LINE_STATUS != 'CANCELLED'
                           AND o1.item_nbr <> '9004'
                           AND oml.CONTRACT_NBR = o1.CONTRACT_NBR
                           AND oml.YW_ORDER_NBR = o1.YW_ORDER_NBR)) 
        ) om, 
        master_contract_f mcf, contract c
                where om_line_status != 'CANCELLED'
                and c.contract_nbr in (select c.contract_nbr from contract c, contract_f cf where contract_subtype='Pure Equipment' and cf.contract_nbr = c.contract_nbr 
                and (nvl(cf.ar_billed_ctd, 0)+nvl(cf.ar_billed_ctd_ew, 0)) = 0
                and c.status != ('CLOSED')
                and c.contract_nbr not like '_J%')
                and (((nvl(mcf.ar_billed_ctd, 0)+nvl(mcf.ar_billed_ctd_ew, 0)) = 0 and c.mc_contract_number is not null) or c.mc_contract_number is null)
                and not exists (select 1 from bill b where b.contract_number = om.contract_nbr)
                and c.contract_nbr = om.contract_nbr
                and c.mc_contract_number = mcf.master_contract_nbr(+)
                --AND C.CONTRACT_NBR = '5N010286'
                group by c.contract_nbr,c.status,c.mc_contract_number
                having count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE) > 1)
                )
                where mc_contract_number not in (select c.mc_contract_number from bill b, contract c
                where contract_number in (
                        select contract_nbr from contract
                        where mc_contract_number in (select mc_contract_number from (
                            select c.contract_nbr,'MCC',c.status,c.mc_contract_number
                            --,max(bill_date), bill_submitted_by
                            from contract c, location l, contract_f cf, master_contract_f mcf
                            --, bill b
                            where mc_contract_number is not null
                            and upper(c.status) != 'CLOSED'
                            and c.location_id = l.location_id
                            and c.contract_nbr = cf.contract_nbr
                            and c.contract_nbr not like '_J%'
                            --and b.contract_number = c.contract_nbr
                            and (length(c.contract_nbr) = 8 OR c.contract_type = 'PSA')
                            and mcf.MASTER_CONTRACT_NBR = c.mc_contract_number
                            and (nvl(mcf.ar_billed_ctd, 0)+nvl(mcf.ar_billed_ctd_ew, 0)) = 0
                            and c.contract_nbr not in (
                            select contract_number from (
                             select contract_number, sum(totals_net_due) from bill
                                where contract_number in (
                                select contract_nbr from contract
                                where mc_contract_number in (
                                select mc_contract_number from master_contract_f
                                where (nvl(ar_billed_ctd, 0)+nvl(ar_billed_ctd_ew, 0)) = 0))
                                group by contract_number
                                having(sum(totals_net_due) != 0)
                            ))
                            --and c.contract_nbr not in (select contract_number from bill)
                            union
                            select contract_nbr,'EQP',STATUS,mc_contract_number from (
                            select c.contract_nbr, count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE),c.status,c.mc_contract_number from 
                (SELECT *
                   FROM om_order_line oml
                  WHERE    NVL (oml.item_nbr, '0000') <> '9004'
                    OR (    oml.item_nbr = '9004'
                        AND oml.OM_LINE_STATUS != 'CANCELLED'
                        AND NOT EXISTS
                               (SELECT *
                              FROM om_order_line o1
                             WHERE     1 = 1
                                   AND OM_LINE_STATUS != 'CANCELLED'
                                   AND o1.item_nbr <> '9004'
                                   AND oml.CONTRACT_NBR = o1.CONTRACT_NBR
                                   AND oml.YW_ORDER_NBR = o1.YW_ORDER_NBR))
                ) om, 
                master_contract_f mcf, contract c
                            where om_line_status != 'CANCELLED'
                            and c.contract_nbr in (select c.contract_nbr from contract c, contract_f cf where contract_subtype='Pure Equipment' and cf.contract_nbr = c.contract_nbr 
                            and (nvl(cf.ar_billed_ctd, 0)+nvl(cf.ar_billed_ctd_ew, 0)) = 0
                            and c.status != ('CLOSED')
                            and c.contract_nbr not like '_J%')
                            and (((nvl(mcf.ar_billed_ctd, 0)+nvl(mcf.ar_billed_ctd_ew, 0)) = 0 and c.mc_contract_number is not null) or c.mc_contract_number is null)
                            and not exists (select 1 from bill b where b.contract_number = om.contract_nbr)
                            and c.contract_nbr = om.contract_nbr
                            and c.mc_contract_number = mcf.master_contract_nbr(+)
                            --AND C.CONTRACT_NBR = '5N010286'
                            group by c.contract_nbr,c.status,c.mc_contract_number
                            having count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE) > 1)
                            )
                        )
                )
                and b.contract_number = c.contract_nbr
                and b.status != '1100')
)

----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------EQP-----------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------

select contract_nbr,
DECODE (b.STATUS,
               '1000', 'On-Hold',
               '1100', 'Work In Progress',
               '0011', 'Waiting Approval',
               '1102', 'Pending Posting',
               '1103', 'Posting Error',
               '0010', 'Posted',
               '0001', 'Distributed', b.STATUS) STATUS, 
b.contract_number,b.bill_id,b.bill_submitted_by
, gu.EMAIL_ADDRESS, gu.first_name, gu.last_name 
from (
select c.contract_nbr, count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE),c.status,c.mc_contract_number from 
(SELECT *
   FROM om_order_line oml
  WHERE    NVL (oml.item_nbr, '0000') <> '9004'
        OR (    oml.item_nbr = '9004'
            AND oml.OM_LINE_STATUS != 'CANCELLED'
            AND NOT EXISTS
                       (SELECT *
                          FROM om_order_line o1
                         WHERE     1 = 1
                               AND OM_LINE_STATUS != 'CANCELLED'
                               AND o1.item_nbr <> '9004'
                               AND oml.CONTRACT_NBR = o1.CONTRACT_NBR
                               AND oml.YW_ORDER_NBR = o1.YW_ORDER_NBR)) 
) om, 
master_contract_f mcf, contract c
where om_line_status != 'CANCELLED'
and c.contract_nbr in (select c.contract_nbr from contract c, contract_f cf where contract_subtype='Pure Equipment' and cf.contract_nbr = c.contract_nbr 
and (nvl(cf.ar_billed_ctd, 0)+nvl(cf.ar_billed_ctd_ew, 0)) = 0
and c.status != ('CLOSED')
and c.contract_nbr not like '_J%')
and (((nvl(mcf.ar_billed_ctd, 0)+nvl(mcf.ar_billed_ctd_ew, 0)) = 0 and c.mc_contract_number is not null) or c.mc_contract_number is null)
and exists (select 1 from bill b where b.contract_number = om.contract_nbr and status = '1100')
and c.contract_nbr = om.contract_nbr
and c.mc_contract_number = mcf.master_contract_nbr(+)
and c.tax_code not in ('05', '15')
and mc_contract_number is null
--AND C.CONTRACT_NBR = '5N010286'
group by c.contract_nbr,c.status,c.mc_contract_number
having count(distinct SHIP_TO_COUNTRY || '-' || SHIP_TO_STATE || '-' || SHIP_TO_POSTAL_CODE) > 1) y
,bill b
,gw_user  gu
where y.contract_nbr = b.contract_number 
and gu.global_id = b.bill_submitted_by

--------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------Sanity Check-------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------




select * from bill
where contract_number in ('3PY10029','3PY30011','40970078','4PY20012','4PY30011','5N950134','72367334','82367332','82367335','84707229','2PY20024','3PY10023','40870189','52367336','5N950159','82367331','4ED10002','46690014','4EB10052','49190054','50440065','50590118','50590119','51280127','52100078','5EH50006','5E630034','52730072','5EF80016','5N010161','5N010162','5N010255','5N010256','5N010287','5N010287','5N010364','5N010365','5N010364','5N010441','5N020111','5N010499','5N010563','5N010562','5N010642','5N010643','5N030405','5N030404','5N030403','5N030451','5N030450','5N040257','1-22591496877','5N040467','5N040467','5N040466','5N040472','5N040478','5N040476','1-25575384659','5N040484','5N040485','5N040483','5N040482','5N060061','5N060060','5N060132','5N060131','5N060144','5N060145','5N070137','5N070138','5N070144','5N070145','5N0A0061','5N0A0062','5N0A0085','5N0A0084','5N0A0107','5N0A0106','5N0A0115','5N0A0114','5N0A0121','5N0A0122','1-25538873271','5N0A0127','5N0A0126','1-25538398577','5N0C0017','5N0C0020','5N0C0125','5N0C0126','5N0C0202','5N0C0201','1-25065434520','5N0D0126','5N0D0139','1-25248584130','5N0G0351','1-25593196023','5N0G0407','5N0G0453','1-25547304174','5N0J0172','5N0J0171','5N0J0195','5N0J0194','5N0K0283','5N0K0284','5N0K0287','5N0K0286','5N0K0390','5N0K0389','5N0K0411','5N0K0416','5N0K0409','5N0K0415','5N0M0298','5N0M0299','5N0M0300','5N0P0094','5N0P0094','5N0P0093','1-23619074162','5N0R0092','1-18700986710','1-18766240563','5N0R0109','5N0R0142','1-18810883534','5N0R0242','5N0R0243','5N0R0353','1-21983862317','1-22623585992','5N0R0527','1-24615436193','5N0R0643','1-24544251278','5N0R0699','5N0R0731','5N0R0730','5N0R0737','5N0R0741','5N0T0098','5N0T0099','5N0T0182','5N0T0180','5N0T0181','5N0T0184','5N0T0185','5N0T0227','5N0T0228','5N0U0023','5N0U0022','1-23537120864','5N0V0177','1-23560846003','5N0V0179','5N0V0207','5N0V0217','1-25148189549','5N0X0240','5N0X0236','5N0X0238','5N0Z0140','5N120091','5N120156','5N120156','5N130157','5N130156','5N160231','1-25182854582','5N1B0057','5N1D0110','5N1D0108','5N1D0109','5N1D0114','5N1D0112','5N1D0113','5N200242','5N200243','1-25124715490','5N200278','5N200284','1-25417268849','5N200289','5N200288','5N220123','5N220124','5N230133','1-21544361473','5N230239','5N250210','5N250209','5N250211','5N250218','5N250219','5N260016','5N260018','5N260037','5N260035','5N270398','5N270397','5N270412','5N270412','1-25591408663','5N280104','5N280103','5N280109','5N280108','5N280107','5N300058','5N300057','5N310161','5N310160','5N310232','5N310233','5N310232','5N330260','1-22584055215','5N330260','5N330312','5N450168','5N330332','51520067','5N330351','5N340007','5N340006','5N450177','5N450173','5N450192','5N450190','5N450191','5N520250','5N520249','5N540014','5N540013','5N560097','5N560097','5N560098','5N560117','5N560116','5N580263','5N580264','5N580273','5N580274','5N590135','1-22399553264','1-25410323486','5N590188','1-24967433947','5N640405','5N640422','1-25499816461','5N660144','5N660143','5N700109','5N700110','5N710117','5N710118','5N720119','5N720120','5N720353','5N720354','5N740155','5N740156','5N740171','5N740170','5N740186','1-25597261063','1-24617957357','5N760180','5N810509','5N810508','1-23590539773','5N830261','5N830268','5N830320','5N830319','5N830406','5N830405','5N830428','5N830427','5N840101','5N840100','5N850056','5N850055','1-19688729578','5N850124','5N850125','5N850099','5N850098','5N850137','5N850138','5N850158','5N850157','5N850187','5N850186','1-25595890390','5N850215','5N850210','5N850209','1-18814063191','5N880110','1-22616687042','5N880109','5N880152','5N880158','5N880157','5N890005','5N890006','5N890098','5N890097','5N890213','5N890212','1-25074811096','5N890215','5N890215','5N890219','5N890220','5N890229','5N890228','5N900014','5N900186','1-25251623517','5N920271','5N920272','5N920274','5N920275','5N930172','5N930173','5N930173','5N930182','5N930183','5N930187','5N930188','5N930188','5N930192','5N930193','5N940112','5N940113','5N940165','5N940166','5N940199','5N940200','5N940210','5N940209','5N940217','5N940217','5N940218','5N940222','5N940223','5N950155','5N950154','5N970189','5N970190','5N970329','5N970330','5N970347','5N970348','5N970357','5N970356','1-19558527597','5N990050','61520040','61520041','5N030446','5N030445','5N030447','6N030051','6N030052','6N030053','6N030050','6N040037','6N040036','6N040042','6N040043','6N040048','6N040047','6N040066','1-26536665170','6N050005','6N050006','6N060011','1-26324271804','6N070012','6N070013','6N090017','6N090018','1-26519013051','6N0A0017','1-26420184927','6N0A0019','1-26426378582','6N0A0022','6N0A0021','6N0A0031','1-26467942172','1-26469435103','6N0A0032','6N0A0033','1-26467941807','6N0B0003','6N0B0004','6N0B0005','6N0B0007','6N0B0008','6N0C0024','6N0C0025','6N0C0041','6N0C0040','6N0D0023','6N0D0024','6N0G0060','6N0G0062','6N0G0061','6N0J0028','6N0J0027','6N0N0006','6N0N0005','6N0T0020','6N0T0019','6N0U0008','6N0U0007','6N0U0019','6N0U0020','6N0V0003','6N0V0002','6N0X0032','6N0X0031','6N100029','6N100028','6N160035','1-26536198283','6N160029','6N1B0009','6N1B0010','6N200014','6N200015','6N200023','6N200024','6N200022','1-26395278402','6N200028','6N200028','6N200029','6N230002','6N230003','6N230014','6N230015','6N230027','6N230026','6N250002','6N250003','6N250017','6N250016','6N250019','6N250020','6N320018','6N320017','6N330032','6N730014','6N420034','6N420033','6N420034','6N520006','6N520007','6N520015','6N520016','6N520048','6N520049','6N540002','6N540003','6N580032','6N580033','6N590011','6N590010','6N610022','6N610021','6N610033','1-26531997873','6N640043','1-26415774932','1-26419867595','6N640036','6N660009','6N660005','6N660008','6N660007','6N670006','6N670007','6N680008','6N710010','6N710009','6N730012','6N730011','6N740017','6N740016','6N790004','6N790005','6N830030','6N830031','6N840009','6N840008','1-26210941154','6N850043','6N850042','1-26325384554','6N850026','6N850027','6N850035','6N850037','6N850036','6N860010','1-26465262798','6N870013','6N870014','1-26540111329','6N880006','6N900005','6N900004','6N900005','6N900006','6N900010','6N900009','6N900008','6N900021','6N900022','6N900029','6N900029','6N900028','6N900030','6N920010','6N920009','6N920029','6N920028','6N920038','6N920037','6N930003','6N930004','6N930009','6N930008','6N940010','6N940011','6N940031','6N940030','6N950018','6N950019','3EC30059','5N030184','5N060072','5N070099','5N0B0113','5N0G0383','5N0R0774','5N0R0781','5N0V0215','5N0X0276','5N150074','5N230172','5N250221','5N330356','5N330370','5N330374','5N480226','5N640174','5N710086','5N990160','5PYC0031','5PYC0035','5PYC0036','6N160018','6PYC0002','4EC30031','4EC30063','5N0G0384','5N0P0096','5N0X0275','5N130174','5N280061','5N330323','5N650113','5N660072','5N660120','5N860097','5N940119','5N940172','6N0D0021','6N0Y0005','6N920015')

select * from bill
where contract_number in 
(select contract_nbr from contract
where mc_contract_number in ('2PY20024','3PY10023','3PY10029','3PY30011','40870189','40970078','4PY20012','4PY30011','5N950159','MC46690013','MC49190050','MC50440062','MC50590114','MC51280126','MC52100077','MC59330041','MC5EF80014','MC5N010160','MC5N010254','MC5N010285','MC5N010363','MC5N010440','MC5N010497','MC5N010561','MC5N010641','MC5N030402','MC5N030448','MC5N040255','MC5N040317','MC5N040465','MC5N040471','MC5N040475','MC5N040480','MC5N040481','MC5N060059','MC5N060130','MC5N060142','MC5N070136','MC5N070143','MC5N0A0060','MC5N0A0082','MC5N0A0105','MC5N0A0113','MC5N0A0120','MC5N0A0124','MC5N0A0125','MC5N0C0014','MC5N0C0124','MC5N0C0200','MC5N0D0125','MC5N0D0138','MC5N0G0350','MC5N0G0452','MC5N0J0170','MC5N0J0193','MC5N0K0282','MC5N0K0285','MC5N0K0388','MC5N0K0405','MC5N0K0406','MC5N0M0297','MC5N0P0092','MC5N0R0093','MC5N0R0108','MC5N0R0141','MC5N0R0241','MC5N0R0352','MC5N0R0526','MC5N0R0644','MC5N0R0698','MC5N0R0729','MC5N0R0736','MC5N0T0097','MC5N0T0179','MC5N0T0183','MC5N0T0226','MC5N0U0020','MC5N0V0174','MC5N0V0178','MC5N0V0205','MC5N0V0216','MC5N0X0235','MC5N0Z0138','MC5N120089','MC5N120154','MC5N130155','MC5N160230','MC5N1B0052','MC5N1D0107','MC5N1D0111','MC5N200241','MC5N200273','MC5N200283','MC5N200287','MC5N220122','MC5N230131','MC5N230238','MC5N250207','MC5N250217','MC5N260014','MC5N260034','MC5N270396','MC5N270399','MC5N280102','MC5N280106','MC5N300056','MC5N310159','MC5N310231','MC5N330259','MC5N330310','MC5N330331','MC5N330350','MC5N340005','MC5N450172','MC5N450189','MC5N520248','MC5N540012','MC5N560096','MC5N560107','MC5N580261','MC5N580272','MC5N590134','MC5N590209','MC5N640404','MC5N640421','MC5N660142','MC5N700108','MC5N710116','MC5N720118','MC5N720352','MC5N740154','MC5N740169','MC5N740185','MC5N760174','MC5N810507','MC5N830260','MC5N830310','MC5N830404','MC5N830426','MC5N840099','MC5N850054','MC5N850086','MC5N850097','MC5N850136','MC5N850154','MC5N850185','MC5N850203','MC5N850208','MC5N880036','MC5N880105','MC5N880106','MC5N880149','MC5N880156','MC5N890004','MC5N890096','MC5N890211','MC5N890214','MC5N890218','MC5N890227','MC5N900009','MC5N900185','MC5N920270','MC5N920273','MC5N930171','MC5N930181','MC5N930186','MC5N930191','MC5N940111','MC5N940164','MC5N940198','MC5N940208','MC5N940216','MC5N940221','MC5N950149','MC5N970188','MC5N970326','MC5N970346','MC5N970352','MC5N990049','MC61520039','MC6N030001','MC6N030048','MC6N040034','MC6N040041','MC6N040046','MC6N040065','MC6N050004','MC6N060010','MC6N070011','MC6N090013','MC6N0A0014','MC6N0A0018','MC6N0A0020','MC6N0A0026','MC6N0A0029','MC6N0A0030','MC6N0B0002','MC6N0B0006','MC6N0C0023','MC6N0C0039','MC6N0D0022','MC6N0G0059','MC6N0J0026','MC6N0N0001','MC6N0T0018','MC6N0U0006','MC6N0U0018','MC6N0V0001','MC6N0X0030','MC6N100026','MC6N160027','MC6N1B0002','MC6N200013','MC6N200020','MC6N200021','MC6N200027','MC6N230001','MC6N230013','MC6N230025','MC6N250001','MC6N250015','MC6N250018','MC6N320016','MC6N330031','MC6N420032','MC6N520005','MC6N520014','MC6N520047','MC6N540001','MC6N580031','MC6N590009','MC6N610020','MC6N610032','MC6N640023','MC6N640035','MC6N660004','MC6N660006','MC6N670005','MC6N680005','MC6N710008','MC6N730010','MC6N740015','MC6N790003','MC6N830029','MC6N840007','MC6N850009','MC6N850017','MC6N850033','MC6N850034','MC6N860009','MC6N870012','MC6N880005','MC6N900003','MC6N900007','MC6N900020','MC6N900027','MC6N920008','MC6N920027','MC6N920036','MC6N930002','MC6N930007','MC6N940009','MC6N940029','MC6N950017')
)



select distinct contract_nbr ,YW_ORDER_NBR,   SHIP_TO_COUNTRY , SHIP_TO_STATE , SHIP_TO_POSTAL_CODE , DECODE(ITEM_NBR, '9004', '9004', 'X') from om_order_line
where contract_nbr in ('5N0B0113','5N710086','4EC30063','5N0X0275','5N280061','5N660072','5N660120')
order by 1 
