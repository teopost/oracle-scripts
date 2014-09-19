CREATE OR REPLACE PACKAGE NOTIFICATORE
IS
   FUNCTION SendNotification (p_Message IN VARCHAR2, p_UserName IN VARCHAR2, p_Badge in number default 0) RETURN VARCHAR2; 
   procedure help;
END NOTIFICATORE;
/

CREATE OR REPLACE PACKAGE BODY NOTIFICATORE IS

procedure help
is
l_help varchar2(1000);
begin
l_help := '
Procedura per l''invio di Notifiche push - APEX-net srl
rel.1.0 - S. Teodorani
-------------------------------------------------------------
Esempio di utilizzo: 
set serveroutput on
begin
 declare 
   a varchar(2000);
 begin
   a:= NOTIFICATORE.SENDNOTIFICATION(''Testo del messaggio'', ''NomeUtente'', 6);
   dbms_output.put_line(a);
end;
/

Per cmpilare la procedura eseguire:
wrap iname=test.sql oname=test_wrap.sql
';
dbms_output.put_line(l_help);
end;

function soap_call (p_payload  in varchar2, p_target_url in varchar2, p_soap_action in varchar2 default 'process' ) return xmltype
  is
  -- Parte di XML in cui inietto il payload
  c_soap_envelope varchar2(1000):= '
  <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:prog="http://www.progamma.com">
   <soapenv:Header/>
   <soapenv:Body>
    **payload**
   </soapenv:Body>
  </soapenv:Envelope>
  ';

    l_soap_request varchar2(30000);
    l_soap_response varchar2(30000);
    http_req utl_http.req;
    http_resp utl_http.resp;

  begin
    l_soap_request := replace(c_soap_envelope, '**payload**', p_payload);
    
    -- Setto le intestazioni del messaggio
    http_req:= utl_http.begin_request( p_target_url, 'POST', 'HTTP/1.1');
    utl_http.set_header(http_req, 'Content-Type', 'text/xml');
    utl_http.set_header(http_req, 'Content-Length', length(l_soap_request));
    utl_http.set_header(http_req, 'SOAPAction', p_soap_action);
    utl_http.write_text(http_req, l_soap_request);
    
    -- Effettuo la chiamata al servizio
    http_resp:= utl_http.get_response(http_req);
    utl_http.read_text(http_resp, l_soap_response);
    utl_http.end_response(http_resp);

    -- Ritorno l'XML di della response
    return XMLType.createXML( l_soap_response).extract( '/soap:Envelope/soap:Body/child::node()', 'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"');
  end;
 
 /*
 Effettua una chiama soap al notificatore
 Reference: http://technology.amis.nl/blog/3227/rapid-plsql-web-service-client-development-using-soapui-and-utl_http
 Ho utilizzato SoapUI per analizzare l'XML della request (http://www.soapui.org/)
 */
 FUNCTION SendNotification (p_Message IN VARCHAR2, p_Username in VARCHAR2, p_Badge in number default 0) RETURN VARCHAR2
 is
  l_response_payload  XMLType;
  l_payload           varchar2(2000);
  l_payload_namespace varchar2(200);
  l_target_url        varchar2(200);
  l_RetValue          varchar2(2000);
  l_AuthKey           varchar2(36) := '9D281C95-2A1A-4D3C-BA73-B9E1092DDD6C';
  l_AppCode           varchar2(100) := 'UNIBOCCONI';
  l_SoundName         varchar2(100) := 'default';
  l_Badge             varchar2(10) := to_char(p_Badge);
  
  
BEGIN
  
  
  if trim(p_Username) is null then
     raise_application_error(-20001, 'Errore: Lo Username deve essere valorizzato');
  end if;
  

  if trim(p_Message) is null then
     raise_application_error(-20002, 'Errore: Il Messaggio deve essere valorizzato');
  end if;
  
  l_payload_namespace := 'http://notificatore01.cineca.it/ws';
  l_target_url        := 'http://notificatore01.cineca.it/ws/NotificatoreWS.asmx';
  -- Pezzo di XML dentro il body della chiamata
  l_payload          :=
    '<prog:SendNotification soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
         <pAuthKey xsi:type="xsd:string">'|| l_AuthKey || '</pAuthKey>
         <pApplicationKey xsi:type="xsd:string">'|| l_AppCode || '</pApplicationKey>
         <pMessage xsi:type="xsd:string">' || p_Message || '</pMessage>
         <pUserName xsi:type="xsd:string">' || p_Username || '</pUserName>
         <pSound xsi:type="xsd:string">'|| l_SoundName || '</pSound>
         <pBadge xsi:type="xsd:int">'|| l_Badge || '</pBadge>
      </prog:SendNotification>';
      
  l_response_payload := soap_call(l_payload, l_target_url, 'http://www.progamma.com/SendNotification');
  
  -- Uso la chiamata dentro una select per evitare la raise dell'errore che mi verrebbe scatenata da una chiamata
  -- puntuale tipo a:= l_response_payload.extract...
  
  select l_response_payload.extract('//SendNotificationResult/text()','xmlns:tns="http://www.progamma.com/"').getStringVal() into l_RetValue from dual;
  return l_RetValue;  
  
END;

END NOTIFICATORE;
/










