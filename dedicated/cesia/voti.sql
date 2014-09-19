select anagrafica.*, comuni.* from anagrafica, comuni
where nome= 'GIGI' and cognome = 'LAIA'
and COD_ISTAT_DOMICILIA = comuni.cod_istat



select an.pincode, 
	   an.nome, 
	   an.cognome, 
	   an.data_nascita,
       co.CITTA,
	   cm.desc_materia,
	   es.voto,
	   es.flag_lode, 
	   ca.stato ,
	   esame_superato(es.pincode, es.carriera, es.COD_ATE, es.COD_CORSO, es.COD_IND, es.cod_ori, es.cod_materia, es.prog_esame)
from anagrafica an, esame es, carriere ca, classi_materie cm, comuni co
where an.pincode = es.pincode
and an.COD_ISTAT_DOMICILIA = co.cod_istat
and   an.pincode = ca.pincode
and  es.cod_materia = cm.cod_materia
--and an.pincode= '249453'
and an.pincode= '362608'
order by es.prog_esame
