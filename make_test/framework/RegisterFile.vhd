-- Part of TDT4255 Computer Design laboratory exercises
-- Group for Computer Architecture and Design
-- Department of Computer and Information Science
-- Norwegian University of Science and Technology

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

use work.defs.all;

-- This entity is more complex than a regular register file would be, to enable
-- testing both in simulation and on the FPGA. The bits pertaining to normal
-- register file operation are the input/output ports, the regfile_t and
-- regfile signal definition, the gen_read_ports process and the
-- synthesizable_write process.
entity RegisterFile is
  generic (
    REGS_INIT_FILE : string := "";
    ENABLE_INIT : boolean := false);
  port (
    input : in regfile_in_t;
    output : out regfile_out_t;

    debug_input : in regfile_debug_in_t;
    debug_output : out regfile_debug_out_t);

end entity RegisterFile;

architecture Behavioural of RegisterFile is
  type regfile_t is array(0 to NUM_REGISTERS-1) of datapath_t;

  signal regfile : regfile_t := (others => (others => '0'));

  signal debug_read_value  : datapath_t;
  signal debug_reg_addr    : reg_addr_t;
  signal debug_write_value : datapath_t;
  signal debug_byte_sel    : std_logic_vector(1 downto 0);
begin  -- architecture Behavioural

  gen_read_ports : for i in 0 to RF_NUM_READ_PORTS-1 generate
    output.read_ports(i) <= regfile(to_integer(unsigned(input.read_ports(i))));
  end generate gen_read_ports;

  synthesizable_write: if not ENABLE_INIT generate
    write_regs : process (input.clk) is
    begin  -- process write_regs
      if rising_edge(input.clk) then
        if input.rst = '1' then
          regfile <= (others => (others => '0'));
        else
          for i in 0 to RF_NUM_WRITE_PORTS-1 loop
            if input.write_ports(i).we then
              regfile(to_integer(unsigned(input.write_ports(i).dst))) <=
                input.write_ports(i).value;
            end if;
          end loop;  -- i
          if debug_input.we then
            regfile(to_integer(unsigned(debug_reg_addr))) <= debug_write_value;
          end if;
        end if;
      end if;
    end process write_regs;
  end generate synthesizable_write;

  debug_output.peek_write_ports <= input.write_ports;

  debug_reg_addr <= debug_input.byte_addr(regfile_byte_addr_t'length-1 downto 2);
  debug_byte_sel <= debug_input.byte_addr(1 downto 0);
  debug_read_value <= regfile(to_integer(unsigned(debug_reg_addr)));
  process (debug_read_value, debug_byte_sel, debug_input.byte) is
  begin
    debug_write_value <= debug_read_value;
    case debug_byte_sel is
      when "00" =>
        debug_write_value(31 downto 24) <= debug_input.byte;
        debug_output.byte_read <= debug_read_value(31 downto 24);
      when "01" =>
        debug_write_value(23 downto 16) <= debug_input.byte;
        debug_output.byte_read <= debug_read_value(23 downto 16);
      when "10" =>
        debug_write_value(15 downto 8) <= debug_input.byte;
        debug_output.byte_read <= debug_read_value(15 downto 8);
      when "11" =>
        debug_write_value(7 downto 0) <= debug_input.byte;
        debug_output.byte_read <= debug_read_value(7 downto 0);
      when others => null;
    end case;
  end process;

-- synthesis translate_off
  file_based_init: if ENABLE_INIT generate
    write_regs: process (input.clk) is
      file memfile          : text open read_mode is REGS_INIT_FILE;
      variable reginit_line : line;
      variable regnum       : integer;
      variable value        : datapath_t;
      variable dummy_space  : character;

      variable private_regfile : regfile_t := (others => (others => '0'));
    begin  -- process write_regs

      -- Will only run once, since variables are not reset.
      while not endfile(memfile) loop
        readline(memfile, reginit_line);
        if reginit_line /= null and reginit_line'length > 0 then
          read(reginit_line, regnum);
          read(reginit_line, dummy_space);
          hread(reginit_line, value);
          private_regfile(regnum) := value;
        end if;
      end loop;

      -- Will function like normal.
      if rising_edge(input.clk) then
        for i in 0 to RF_NUM_WRITE_PORTS-1 loop
          if input.write_ports(i).we then
            private_regfile(to_integer(unsigned(input.write_ports(i).dst))) :=
              input.write_ports(i).value;
          end if;
        end loop;
        if debug_input.we then
          private_regfile(to_integer(unsigned(debug_reg_addr))) :=
            debug_write_value;
        end if;

        regfile <= private_regfile;
      end if;
    end process write_regs;
  end generate file_based_init;
-- synthesis translate_on

end architecture Behavioural;
