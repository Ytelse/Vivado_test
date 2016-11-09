library ieee;
library unisim;
library unimacro;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use unisim.vcomponents.all;
use unimacro.vcomponents.all;

use work.defs.all;
use work.framework_util.all;

entity InstructionMemory is

  generic (
    INIT_FILE : string := "NONE");

  port (
    clk              : in std_logic;
    processor_enable : in std_logic;

    hostcomm_wen      : in  std_logic;
    hostcomm_data_in  : in  byte_t;
    hostcomm_addr     : in  imem_byte_addr_t;
    hostcomm_data_out : out byte_t;

    proc_addr     : in  imem_addr_t;
    proc_data_out : out imem_data_t);

end entity InstructionMemory;

architecture Behavioural of InstructionMemory is

  signal hostcomm_imem_data_in_unshifted : unsigned(imem_data_t'range);
  signal hostcomm_imem_data_in : imem_data_t;
  signal hostcomm_imem_addr : imem_addr_t;
  signal hostcomm_byte_sel : natural;
  signal hostcomm_byte_wen_vec : unsigned(IMEM_DATA_BYTES-1 downto 0);
  signal hostcomm_byte_wen_mask : std_logic_vector(IMEM_DATA_BYTES-1 downto 0);

  signal proc_byte_wen_mask : std_logic_vector(IMEM_DATA_BYTES-1 downto 0);

  signal use_hostcomm : boolean;
  signal addr : imem_addr_t;
  signal byte_wen_mask : std_logic_vector(IMEM_DATA_BYTES-1 downto 0);
  signal data_in : imem_data_t;
  signal data_out : imem_data_t;

begin  -- architecture Behavioural

  hostcomm_imem_addr <=
    hostcomm_addr(IMEM_BYTE_ADDR_WIDTH-1 downto IMEM_BYTE_ADDR_BITS);
  hostcomm_byte_sel <=
    natural(to_integer(unsigned(hostcomm_addr(IMEM_BYTE_ADDR_BITS-1 downto 0))));

  -- Fill all bytes
  gen_hostcomm_imem_data_in: for i in 0 to IMEM_DATA_BYTES-1 generate
    hostcomm_imem_data_in((i+1)*BYTE_WIDTH - 1 downto i*BYTE_WIDTH) <= hostcomm_data_in;
  end generate gen_hostcomm_imem_data_in;

  proc_byte_wen_mask <= (others => '0');

  -- Big-endian imem: the most significant byte is addressed by byte-address 0.
  hostcomm_byte_wen_vec <= (IMEM_DATA_BYTES-1 => hostcomm_wen, others => '0');
  hostcomm_byte_wen_mask <=
    std_logic_vector(shift_right(hostcomm_byte_wen_vec, hostcomm_byte_sel));
  --- Drive memory
  use_hostcomm <= processor_enable = '0';

  addr <= hostcomm_imem_addr when use_hostcomm else
          proc_addr;
  byte_wen_mask <= hostcomm_byte_wen_mask when use_hostcomm else
                   proc_byte_wen_mask;
  data_in <= hostcomm_imem_data_in;

  mem_inst : BRAM_SINGLE_MACRO
    generic map (
      BRAM_SIZE   => "36Kb",
      DEVICE => "7SERIES",
      READ_WIDTH  => IMEM_DATA_WIDTH,
      WRITE_WIDTH  => IMEM_DATA_WIDTH,
      INIT_FILE   => INIT_FILE)
    port map (
      clk   => clk,
      DO    => data_out,
      ADDR  => addr,
      DI    => data_in,
      EN    => '1',
      REGCE => '0',
      RST   => '0',
      WE    => byte_wen_mask
    );

  -- Route memory data to output
  proc_data_out <= data_out;
  -- Big-endian imem: the most significant byte is addressed by byte-address 0.
  hostcomm_data_out <=
    data_out((IMEM_DATA_BYTES - hostcomm_byte_sel)*BYTE_WIDTH-1 downto
             (IMEM_DATA_BYTES - hostcomm_byte_sel - 1)*BYTE_WIDTH);

end architecture Behavioural;
