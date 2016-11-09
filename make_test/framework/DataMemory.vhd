library ieee;
library unisim;
library unimacro;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use unisim.vcomponents.all;
use unimacro.vcomponents.all;

use work.defs.all;
use work.framework_util.all;

entity DataMemory is

  generic (
    INIT_FILE : string := "NONE");

  port (
    clk              : in std_logic;
    processor_enable : in std_logic;

    hostcomm_wen      : in  std_logic;
    hostcomm_data_in  : in  byte_t;
    hostcomm_addr     : in  dmem_byte_addr_t;
    hostcomm_data_out : out byte_t;

    proc_wen      : in  std_logic;
    proc_data_in  : in  dmem_data_t;
    proc_addr     : in  dmem_addr_t;
    proc_data_out : out dmem_data_t);

end entity DataMemory;

architecture Behavioural of DataMemory is

  signal proc_byte_wen_mask        : dmem_write_mask_t;
  signal enable_proc_port     : std_logic;
  signal enable_hostcomm_port : std_logic;

  signal hostcomm_dmem_data_in  : dmem_data_t;
  signal hostcomm_dmem_data_out : dmem_data_t;
  signal hostcomm_dmem_addr     : dmem_addr_t;
  signal hostcomm_byte_sel      : natural;
  signal hostcomm_byte_wen_vec  : unsigned(DMEM_DATA_BYTES-1 downto 0);
  signal hostcomm_byte_wen_mask : dmem_write_mask_t;

begin  -- architecture Behavioural

  proc_byte_wen_mask        <= (others => proc_wen);
  enable_proc_port     <= processor_enable;
  enable_hostcomm_port <= not processor_enable;

  hostcomm_dmem_addr <=
    hostcomm_addr(DMEM_BYTE_ADDR_WIDTH-1 downto DMEM_BYTE_ADDR_BITS);
  hostcomm_byte_sel <=
    natural(to_integer(unsigned(hostcomm_addr(DMEM_BYTE_ADDR_BITS-1 downto 0))));

  -- Fill all bytes
  gen_hostcomm_dmem_data_in : for i in 0 to DMEM_DATA_BYTES-1 generate
    hostcomm_dmem_data_in((i+1)*BYTE_WIDTH - 1 downto i*BYTE_WIDTH) <= hostcomm_data_in;
  end generate gen_hostcomm_dmem_data_in;

  proc_byte_wen_mask <= (others => proc_wen);

  -- Big-endian dmem: the most significant byte is addressed by byte-address 0.
  hostcomm_byte_wen_vec <= (DMEM_DATA_BYTES-1 => hostcomm_wen, others => '0');
  hostcomm_byte_wen_mask <=
    std_logic_vector(shift_right(hostcomm_byte_wen_vec, hostcomm_byte_sel));

  mem_inst : BRAM_TDP_MACRO
    generic map (
      BRAM_SIZE     => "36Kb",
      DEVICE        => "7SERIES",
      READ_WIDTH_A  => DMEM_DATA_WIDTH,
      WRITE_WIDTH_A => DMEM_DATA_WIDTH,
      READ_WIDTH_B  => DMEM_DATA_WIDTH,
      WRITE_WIDTH_B => DMEM_DATA_WIDTH,
      INIT_FILE     => INIT_FILE)
    port map (
      clka   => clk,
      DOA    => hostcomm_dmem_data_out,
      ADDRA  => hostcomm_dmem_addr,
      DIA    => hostcomm_dmem_data_in,
      ENA    => enable_hostcomm_port,
      REGCEA => '0',
      RSTA   => '0',
      WEA    => hostcomm_byte_wen_mask,

      clkb   => clk,
      DOB    => proc_data_out,
      ADDRB  => proc_addr,
      DIB    => proc_data_in,
      ENB    => enable_proc_port,
      REGCEB => '0',
      RSTB   => '0',
      WEB    => proc_byte_wen_mask
      );

  -- Big-endian dmem: the most significant byte is addressed by byte-address 0.
  hostcomm_data_out <=
    hostcomm_dmem_data_out(
      (DMEM_DATA_BYTES - hostcomm_byte_sel)*BYTE_WIDTH-1 downto
      (DMEM_DATA_BYTES - hostcomm_byte_sel - 1)*BYTE_WIDTH);

end architecture Behavioural;
