create or replace package Lang_Integer as 
  /* The package is named loosely after a similar Java class, 
     java.lang.Integer; in addition, all public package functions 
     (except toRadixString() which has no Java equivalent) are named 
     after equivalent Java methods in the java.lang.Integer class. 
  */ 
 
  /* Convert a number to string in given radix. 
     Radix must be in the range [2, 16]. 
  */ 
  function toRadixString(num in number, radix in number) return varchar2; 
  pragma restrict_references (toRadixString, WNDS, WNPS, RNDS, RNPS); 
 
  /* Convert a number to binary string. */ 
  function toBinaryString(num in number) return varchar2; 
  pragma restrict_references (toBinaryString, WNDS, WNPS, RNDS, RNPS); 
 
  /* Convert a number to hexadecimal string. */ 
  function toHexString(num in number) return varchar2; 
  pragma restrict_references (toHexString, WNDS, WNPS, RNDS, RNPS); 
 
  /* Convert a number to octal string. */ 
  function toOctalString(num in number) return varchar2; 
  pragma restrict_references (toOctalString, WNDS, WNPS, RNDS, RNPS); 
 
  /* Convert a string, expressed in decimal, to number. */ 
  function parseInt(s in varchar2) return number; 
  pragma restrict_references (parseInt, WNDS, WNPS, RNDS, RNPS); 
 
  /* Convert a string, expressed in given radix, to number. 
     Radix must be in the range [2, 16]. 
  */ 
  function parseInt(s in varchar2, radix in number) return number; 
  pragma restrict_references (parseInt, WNDS, RNDS); 
end Lang_Integer; 
/ 
 
create or replace package body Lang_Integer as 
  /* Takes a number between 0 and 15, and converts it to a string (character) 
     The toRadixString() function calls this function. 
 
     The caller of this function is responsible for making sure no invalid 
     number is passed as the argument.  Valid numbers include non-negative 
     integer in the radix used by the calling function.  For example, 
     toOctalString() must pass nothing but 0, 1, 2, 3, 4, 5, 6, and 7 as the 
     argument 'num' of digitToString(). 
  */ 
  function digitToString(num in number) return varchar2 as 
    digitStr varchar2(1); 
  begin 
    if (num<10) then 
      digitStr := to_char(num); 
    else 
      digitStr := chr(ascii('A') + num - 10); 
    end if; 
 
    return digitStr; 
  end digitToString; 
 
  /* Takes a character (varchar2(1)) and converts it to a number. 
     The parseInt() function calls this function. 
 
     The caller of this function is responsible for maksing sure no invalid 
     string is passed as the argument.  The caller can do this by first 
     calling the isValidNumStr() function. 
  */ 
  function digitToDecimal(digitStr in varchar2) return number as 
    num number; 
  begin 
    if (digitStr >= '0') and (digitStr <= '9') then 
      num := ascii(digitStr) - ascii('0'); 
    elsif (digitStr >= 'A') and (digitStr <= 'F') then 
      num := ascii(digitStr) - ascii('A') + 10; 
    end if; 
 
    return num; 
  end digitToDecimal; 
 
  /* Checks if the given string represents a valid number in given radix. 
     Returns true if valid; ORA-6502 if invalid. 
  */ 
  function isValidNumStr(str in out varchar2,radix in number) return boolean 
as 
    validChars varchar2(16) := '0123456789ABCDEF'; 
    valid number; 
    len number; 
    i number; 
    retval boolean; 
  begin 
    if (radix<2) or (radix>16) or (radix!=trunc(radix)) then 
      i := to_number('invalid number');  /* Forces ORA-6502 when bad radix. */ 
    end if; 
 
    str := upper(str);  /* a-f ==> A-F */ 
    /* determine valid characters for given radix */ 
    validChars := substr('0123456789ABCDEF', 1, radix); 
    valid := 1; 
    len := length(str); 
    i := 1; 
 
    while (valid !=0) loop 
      valid := instr(validChars, substr(str, i, 1)); 
      i := i + 1; 
    end loop; 
 
    if (valid=0) then 
      retval := false; 
      i := to_number('invalid number');  /* Forces ORA-6502. */ 
    else 
      retval := true; 
    end if; 
 
    return retval; 
  end isValidNumStr; 
 
  /* This function converts a number into a string in given radix. 
     Only non-negative integer should be passed as the argument num, and 
     radix must be a positive integer in [1, 16]. 
     Otherwise, 'ORA-6502: PL/SQL: numeric or value error' is raised. 
  */ 
  function toRadixString(num in number, radix in number) return varchar2 as 
    dividend number; 
    divisor number; 
    remainder number(2); 
    numStr varchar2(2000); 
  begin 
    /* NULL NUMBER -> NULL hex string */ 
    if(num is null) then 
      return null; 
    elsif (num=0) then  /* special case */ 
      return '0'; 
    end if; 
 
    /* invalid number or radix; force ORA-6502: PL/SQL: numeric or value err 
*/ 
    if (num<0) or (num!=trunc(num)) or 
       (radix<2) or (radix>16) or (radix!=trunc(radix)) then 
      numStr := to_char(to_number('invalid number'));  /* Forces ORA-6502. */ 
      return numStr; 
    end if; 
 
    dividend := num; 
    numStr := '';  /* start with a null string */ 
 
    /* the actual conversion loop */ 
    while(dividend != 0) loop 
      remainder := mod(dividend, radix); 
      numStr := digitToString(remainder) || numStr; 
      dividend := trunc(dividend / radix); 
    end loop; 
 
    return numStr; 
  end toRadixString; 
 
  function toBinaryString(num in number) return varchar2 as 
  begin 
    return toRadixString(num, 2); 
  end toBinaryString; 
 
  function toHexString(num in number) return varchar2 as 
  begin 
    return toRadixString(num, 16); 
  end toHexString; 
 
  function toOctalString(num in number) return varchar2 as 
  begin 
    return toRadixString(num, 8); 
  end toOctalString; 
 
  /* The parseInt() function is equivalent to TO_NUMBER() when called 
     without a radix argument.  This is consistent with what Java does. 
  */ 
  function parseInt(s in varchar2) return number as 
  begin 
    return to_number(s); 
  end parseInt; 
 
  /* Converts a string in given radix to a number */ 
  function parseInt(s in varchar2, radix in number) return number as 
    str varchar2(2000); 
    len number; 
    decimalNumber number; 
  begin 
    /* NULL hex string -> NULL NUMBER */ 
    if(s is null) then 
      return null; 
    end if; 
 
    /* Because isValidNumStr() expects a IN OUT parameter, must use an 
       intermediate variable str.  str will be converted to uppercase 
       inside isValidNumStr(). 
    */ 
    str := s; 
    if (isValidNumStr(str, radix) = false) then 
      return -1;  /* Never executes because isValidNumStr forced ORA-6502. */ 
    end if; 
 
    len := length(str); 
    decimalNumber := 0; 
 
    /* the actual conversion loop */ 
    for i in 1..len loop 
      decimalNumber := decimalNumber*radix + digitToDecimal(substr(str, i, 
1)); 
    end loop; 
 
    return decimalNumber; 
  end parseInt; 
end Lang_Integer; 
/ 
 
grant execute on Lang_Integer to public;  /* anyone can use this package */ 



-- ---------------


 create public synonym Lang_Integer for sys.Lang_Integer; 
 
 
 -- ---------------------------
 
 
 create or replace view nt_threads as 
  select Lang_Integer.parseInt(p.spid, 16) "ID_THREAD", 
         p.background "BACKGROUND", 
         b.name "NAME", 
         s.sid "SID", 
         s.serial# "SERIAL#", 
         s.username "USERNAME", 
         s.status "STATUS", 
         s.osuser "OSUSER", 
         s.program "PROGRAM" 
  from v$process p, v$bgprocess b, v$session s 
  where s.paddr = p.addr and b.paddr(+) = p.addr; 
  
  
grant select on nt_threads to dba;

drop public synonym nt_threads; 

create public synonym nt_threads for sys.nt_threads; 