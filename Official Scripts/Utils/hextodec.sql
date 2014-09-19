rem -----------------------------------------------------------------------
rem Filename:   hex2dec.sql
rem Purpose:    Function to convert a Hex number to Decimal
rem Author:     Anonymous
rem -----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION hex2dec (hexnum in char) RETURN number IS
  i                 number;
  digits            number;
  result            number := 0;
  current_digit     char(1);
  current_digit_dec number;
BEGIN
  digits := length(hexnum);
  for i in 1..digits loop
     current_digit := SUBSTR(hexnum, i, 1);
     if current_digit in ('A','B','C','D','E','F') then
        current_digit_dec := ascii(current_digit) - ascii('A') + 10;
     else
        current_digit_dec := to_number(current_digit);
     end if;
     result := (result * 16) + current_digit_dec;
  end loop;
  return result;
END hex2dec;
/
show errors

