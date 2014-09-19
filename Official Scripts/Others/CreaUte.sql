undef login

ACCEPT login       CHAR PROMPT 'Nome utente: '

create user &&login
identified by &&login
default tablespace users
temporary tablespace temp
quota unlimited on users;

grant connect, resource to &&login;
