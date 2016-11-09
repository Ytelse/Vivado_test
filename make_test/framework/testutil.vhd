library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;

use work.defs.all;

package testutil is

  function to_hchar (
    constant nibble : std_logic_vector(3 downto 0))
    return character;

  function to_hstring (
    constant vector : in std_logic_vector) return string;

  function to_string (
    constant vector : in std_logic_vector) return string;

  procedure swrite (
    variable dest_line : inout line;
    constant val       : in    string);

end package testutil;

package body testutil is

  function to_hchar (
    constant nibble : std_logic_vector(3 downto 0))
    return character is

    variable cur_nibble_value : integer;
    variable other_std_logic_values : std_logic_vector(0 to 6) := "XU-ZWLH";
  begin  -- function to_hchar
    case nibble is
      when "0000" => return '0';
      when "0001" => return '1';
      when "0010" => return '2';
      when "0011" => return '3';
      when "0100" => return '4';
      when "0101" => return '5';
      when "0110" => return '6';
      when "0111" => return '7';
      when "1000" => return '8';
      when "1001" => return '9';
      when "1010" => return 'A';
      when "1011" => return 'B';
      when "1100" => return 'C';
      when "1101" => return 'D';
      when "1110" => return 'E';
      when "1111" => return 'F';
      when others => null;
    end case;
    for j in 0 to other_std_logic_values'length-1 loop
      for i in 0 to 3 loop
        if nibble(i) = other_std_logic_values(j) then
          case other_std_logic_values(j) is
            when 'X' => return 'X';
            when 'U' => return 'U';
            when '-' => return '-';
            when 'Z' => return 'Z';
            when 'W' => return 'W';
            when 'L' => return 'L';
            when 'H' => return 'H';
          end case;
        end if;
      end loop;
    end loop;
    return 'X';
  end function to_hchar;

  function max (
    constant v1, v2 : integer)
    return integer is
  begin  -- function max
    if v1 > v2 then
      return v1;
    end if;
    return v2;
  end function max;

  function to_hstring (
    constant vector : in std_logic_vector) return string is

    variable num_bits             : real    := real(vector'length);
    variable num_chars            : integer := max(1, integer(ceil(num_bits/real(4))));
    variable num_complete_nibbles : integer := integer(floor(num_bits/real(4)));
    variable tempstr              : string(1 to 2+num_chars);
    variable cur_char_index       : integer;
    variable cur_nibble           : std_logic_vector(3 downto 0);
    variable cur_nibble_value     : integer;
  begin
    tempstr(1 to 2) := "0x";
    cur_char_index  := 3;
    if vector'length = 0 then
      tempstr(3) := '0';
    else
      if num_chars > num_complete_nibbles then
        cur_nibble := (others => '0');
        cur_nibble(vector'length-1 - 4*num_complete_nibbles downto 0) :=
          vector(vector'length-1 downto 4*num_complete_nibbles);
        tempstr(cur_char_index) := to_hchar(cur_nibble);
        cur_char_index          := cur_char_index + 1;
      end if;
      for j in num_complete_nibbles downto 1 loop
        cur_nibble              := vector(4*j-1 downto 4*(j-1));
        tempstr(cur_char_index) := to_hchar(cur_nibble);
        cur_char_index          := cur_char_index + 1;
      end loop;  -- j
    end if;
    return tempstr;
  end function to_hstring;

  function to_string (
    constant vector : in std_logic_vector)
    return string is
    variable value : integer;
  begin  -- function to_string
    value := to_integer(unsigned(vector));
    return integer'image(value);
  end function to_string;

  procedure swrite (
    variable dest_line : inout line;
    constant val       : in    string) is
  begin
    write(dest_line, val);
  end procedure swrite;

end package body testutil;
