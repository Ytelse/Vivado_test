library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package defs is

  constant DATAPATH_WIDTH      : integer := 32;
  constant NUM_REGISTERS       : integer := 32;
  constant REGISTER_ADDR_WIDTH : integer :=
    integer(ceil(log2(real(NUM_REGISTERS-1 + 1))));

  constant IMEM_DATA_WIDTH : integer := 32;
  constant IMEM_ADDR_WIDTH : integer := 10;
  constant IMEM_DEPTH      : integer := 512;  -- 2^10

  constant INSTRUCTION_WIDTH : integer := 32;

  constant DMEM_DATA_WIDTH : integer := 32;
  constant DMEM_ADDR_WIDTH : integer := 10;
  constant DMEM_DEPTH      : integer := 1024;  -- 2^10

  subtype datapath_t is std_logic_vector(DATAPATH_WIDTH-1 downto 0);
  subtype reg_addr_t is std_logic_vector(REGISTER_ADDR_WIDTH-1 downto 0);

  subtype imem_data_t is std_logic_vector(IMEM_DATA_WIDTH-1 downto 0);
  subtype imem_addr_t is std_logic_vector(IMEM_ADDR_WIDTH-1 downto 0);

  subtype instruction_data_t is std_logic_vector(INSTRUCTION_WIDTH-1 downto 0);

  subtype dmem_data_t is std_logic_vector(DMEM_DATA_WIDTH-1 downto 0);
  subtype dmem_addr_t is std_logic_vector(DMEM_ADDR_WIDTH-1 downto 0);

  constant PC_START_ADDR : imem_addr_t := (others => '0');

  type regfile_write_port_in_t is record
    dst   : reg_addr_t;
    we    : boolean;
    value : datapath_t;
  end record regfile_write_port_in_t;

  constant RF_NUM_READ_PORTS  : natural := 2;
  constant RF_NUM_WRITE_PORTS : natural := 1;

  type read_ports_in_t is array(0 to RF_NUM_READ_PORTS-1) of reg_addr_t;
  type write_ports_in_t is
    array(0 to RF_NUM_WRITE_PORTS-1) of regfile_write_port_in_t;
  type read_ports_out_t is array (0 to RF_NUM_READ_PORTS-1) of datapath_t;


  -- The debug connections to the register file are used to initialize it
  -- before running tests, as well as to implement test checks based on what
  -- values are written to the register file. For solving the exercises, you
  -- only have to use the normal "input" and "output" ports of the RegisterFile
  -- component defined below, and not the "debug_input" and "debug_output"
  -- ports.
  constant BYTE_WIDTH : natural := 8;
  subtype byte_t is std_logic_vector(7 downto 0);

  subtype regfile_byte_addr_t is std_logic_vector(reg_addr_t'length+1 downto 0);

  type regfile_debug_in_t is record
    byte_addr : regfile_byte_addr_t;
    byte      : byte_t;
    we        : boolean;
  end record regfile_debug_in_t;

  type regfile_debug_out_t is record
    peek_write_ports : write_ports_in_t;
    byte_read        : byte_t;
  end record regfile_debug_out_t;

  type mips_processor_in_t is record
    clk              : std_logic;
    rst              : std_logic;
    processor_enable : std_logic;
    imem_data        : imem_data_t;
    dmem_data        : dmem_data_t;
  end record mips_processor_in_t;

  type mips_processor_out_t is record
    imem_address      : imem_addr_t;
    dmem_data         : dmem_data_t;
    dmem_address      : dmem_addr_t;
    dmem_write_enable : std_logic;
  end record mips_processor_out_t;

  component MIPSProcessor is
    port (
      input  : in  mips_processor_in_t;
      output : out mips_processor_out_t;

      rf_debug_in  : in  regfile_debug_in_t;
      rf_debug_out : out regfile_debug_out_t);
  end component MIPSProcessor;

  type regfile_in_t is record
    clk         : std_logic;
    rst         : std_logic;
    read_ports  : read_ports_in_t;
    write_ports : write_ports_in_t;
  end record regfile_in_t;

  type regfile_out_t is record
    read_ports : read_ports_out_t;
  end record regfile_out_t;

  component RegisterFile is
    generic (
      REGS_INIT_FILE : string  := "";
      ENABLE_INIT    : boolean := false);
    port (
      input  : in  regfile_in_t;
      output : out regfile_out_t;

      debug_input  : in  regfile_debug_in_t;
      debug_output : out regfile_debug_out_t);
  end component RegisterFile;

end package defs;

