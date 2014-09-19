/*
Il comando seguente disabilita l'errore oracle ORA-24005 che non
permette al package di sistema DBMS_AQADM di droppare un oggetto che si chiama come uno esistente
su sys ma su owner diverso.

Ciao

*/

ALTER session set events '10851 trace name context forever, level 2';

drop table cineca.DEF$_AQCALL;