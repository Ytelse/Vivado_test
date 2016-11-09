-- Part of TDT4255 Computer Design laboratory exercises
-- Group for Computer Architecture and Design
-- Department of Computer and Information Science
-- Norwegian University of Science and Technology

-- HostComm.vhd
-- A module which wraps some registers, address mapping logic and
-- a UART-to-register control interface to control TDT4255 exercises.
-- This particular variant is to be used for exercises 1 and 2, and
-- contains the following registers:

-- * Magic word (for identification) at address 0x4000. Always returns 0xCAFEC0DE.
-- * Processor enable register (1-bit) at address 0x0000
-- * Processor reset register (1-bit) at address 0x0001
-- * A number of registers used to run and monitor tests on the FPGA.
--
-- Additionally, memories on the processor is available through the following
-- addresses:
-- * Expected updates for tests at 0x2000
-- * Regfile at 0x3000
-- * Data memory at 0x8000
-- * Instruction memory at 0xC000

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.defs.all;
use work.framework_util.all;

entity HostComm is
  port (
    clk, reset                 : in  std_logic;
    -- interface towards the UART ports
    UART_Rx                    : in  std_logic;
    UART_Tx                    : out std_logic;
    -- interface towards the processor
    proc_en, proc_rst          : out std_logic;
    -- interface towards the instruction memory
    imem_data_in               : in  byte_t;
    imem_data_out              : out byte_t;
    imem_addr                  : out imem_byte_addr_t;
    imem_wr_en                 : out std_logic;
    -- interface towards the data memory
    dmem_data_in               : in  byte_t;
    dmem_data_out              : out byte_t;
    dmem_addr                  : out dmem_byte_addr_t;
    dmem_wr_en                 : out std_logic;
    -- regfile access
    regfile_addr               : out regfile_byte_addr_t;
    regfile_write_value        : out byte_t;
    regfile_we                 : out boolean;
    regfile_read_value         : in  byte_t;
    -- test monitor interface
    tm_test_status             : in  byte_t;
    tm_test_cycle_counter      : in  std_logic_vector(15 downto 0);
    tm_num_expected_updates_lo : out byte_t;
    tm_num_expupd_lo_we        : out std_logic;
    tm_num_expected_updates_hi : out byte_t;
    tm_num_expupd_hi_we        : out std_logic;
    tm_max_wait_time_lo        : out byte_t;
    tm_max_wait_time_lo_we     : out std_logic;
    tm_max_wait_time_hi        : out byte_t;
    tm_max_wait_time_hi_we     : out std_logic;
    unmatched_expected         : in  expected_state_update_t;
    bad_actual                 : in  expected_state_update_t;
    tm_expupd_byte_write_addr  : out std_logic_vector(11 downto 0);
    tm_expupd_write_value      : out byte_t;
    tm_expupd_we               : out std_logic;
    tm_expupd_re               : out boolean;
    expupd_read_value          : in  byte_t;
    tm_num_expupd : in std_logic_vector(8 downto 0);
    tm_max_wait_time : in std_logic_vector(15 downto 0)
    );
end HostComm;

architecture Behavioral of HostComm is
  constant TDT4255_EX1_MAGIC : std_logic_vector(31 downto 0) := x"CAFEC0DE";

  -- addresses for status/control registers
  constant REG_ADDR_PROC_EN                 : std_logic_vector(15 downto 0) := x"0000";
  constant REG_ADDR_PROC_RESET              : std_logic_vector(15 downto 0) := x"0001";
  constant REG_ADDR_TEST_STATUS             : std_logic_vector(15 downto 0) := x"0002";
  constant REG_ADDR_TEST_CYCLE_COUNTER_HI   : std_logic_vector(15 downto 0) := x"0003";
  constant REG_ADDR_TEST_CYCLE_COUNTER_LO   : std_logic_vector(15 downto 0) := x"0004";
  constant REG_ADDR_NUM_EXPECTED_UPDATES_HI : std_logic_vector(15 downto 0) := x"0005";
  constant REG_ADDR_NUM_EXPECTED_UPDATES_LO : std_logic_vector(15 downto 0) := x"0006";
  constant REG_ADDR_MAX_WAIT_TIME_HI        : std_logic_vector(15 downto 0) := x"0007";
  constant REG_ADDR_MAX_WAIT_TIME_LO        : std_logic_vector(15 downto 0) := x"0008";
  constant REG_ADDR_EXPECTED_TYPE           : std_logic_vector(15 downto 0) := x"0009";
  constant REG_ADDR_EXPECTED_ADDR_HI        : std_logic_vector(15 downto 0) := x"000A";
  constant REG_ADDR_EXPECTED_ADDR_LO        : std_logic_vector(15 downto 0) := x"000B";
  constant REG_ADDR_EXPECTED_VALUE0         : std_logic_vector(15 downto 0) := x"000C";
  constant REG_ADDR_EXPECTED_VALUE1         : std_logic_vector(15 downto 0) := x"000D";
  constant REG_ADDR_EXPECTED_VALUE2         : std_logic_vector(15 downto 0) := x"000E";
  constant REG_ADDR_EXPECTED_VALUE3         : std_logic_vector(15 downto 0) := x"000F";
  constant REG_ADDR_ACTUAL_TYPE             : std_logic_vector(15 downto 0) := x"0010";
  constant REG_ADDR_ACTUAL_ADDR_HI          : std_logic_vector(15 downto 0) := x"0011";
  constant REG_ADDR_ACTUAL_ADDR_LO          : std_logic_vector(15 downto 0) := x"0012";
  constant REG_ADDR_ACTUAL_VALUE0           : std_logic_vector(15 downto 0) := x"0013";
  constant REG_ADDR_ACTUAL_VALUE1           : std_logic_vector(15 downto 0) := x"0014";
  constant REG_ADDR_ACTUAL_VALUE2           : std_logic_vector(15 downto 0) := x"0015";
  constant REG_ADDR_ACTUAL_VALUE3           : std_logic_vector(15 downto 0) := x"0016";
  constant REG_ADDR_RESET_DURATION0         : std_logic_vector(15 downto 0) := x"0017";
  constant REG_ADDR_RESET_DURATION1         : std_logic_vector(15 downto 0) := x"0018";
  constant REG_ADDR_RESET_DURATION2         : std_logic_vector(15 downto 0) := x"0019";
  constant REG_ADDR_RESET_DURATION3         : std_logic_vector(15 downto 0) := x"001A";

  -- Base address for expected updates: 0x2000.
  -- (Extent = 512 entries of 8 bytes => max address = 2FFF)
  -- (Note: the top-two bytes are not used.)
  signal is_access_to_expupd : boolean;

  -- Base address for register file: 0x3000. Extent = 32*4 = 128 bytes.
  signal is_access_to_rf : boolean;

  -- addresses for the magic ID register
  constant REG_ADDR_MAGIC0 : std_logic_vector(15 downto 0) := x"4000";
  constant REG_ADDR_MAGIC1 : std_logic_vector(15 downto 0) := x"4001";
  constant REG_ADDR_MAGIC2 : std_logic_vector(15 downto 0) := x"4002";
  constant REG_ADDR_MAGIC3 : std_logic_vector(15 downto 0) := x"4003";

  -- Base address for data memory: 0x8000
  -- Base address for instruction memory: 0xC000

  -- UART register control interface signals
  signal regReadData, regWriteData     : byte_t;
  signal regAddress                    : std_logic_vector(15 downto 0);
  signal regReadEnable, regWriteEnable : std_logic;

  -- control/status registers
  signal procResetSignal, procEnableSignal : std_logic;

  -- Test monitor output registers
  signal tm_test_cycle_counter_lo   : std_logic_vector(7 downto 0);
  signal tm_test_cycle_counter_hi   : std_logic_vector(7 downto 0);
  signal unmatched_expected_dest    : std_logic_vector(7 downto 0);
  signal unmatched_expected_addr_lo : std_logic_vector(7 downto 0);
  signal unmatched_expected_addr_hi : std_logic_vector(7 downto 0);
  signal unmatched_expected_value0  : std_logic_vector(7 downto 0);
  signal unmatched_expected_value1  : std_logic_vector(7 downto 0);
  signal unmatched_expected_value2  : std_logic_vector(7 downto 0);
  signal unmatched_expected_value3  : std_logic_vector(7 downto 0);
  signal bad_actual_dest            : std_logic_vector(7 downto 0);
  signal bad_actual_addr_lo         : std_logic_vector(7 downto 0);
  signal bad_actual_addr_hi         : std_logic_vector(7 downto 0);
  signal bad_actual_value0          : std_logic_vector(7 downto 0);
  signal bad_actual_value1          : std_logic_vector(7 downto 0);
  signal bad_actual_value2          : std_logic_vector(7 downto 0);
  signal bad_actual_value3          : std_logic_vector(7 downto 0);

  signal uart_req, uart_gnt : std_logic;

  signal was_reset      : std_logic;
  signal reset_duration : std_logic_vector(31 downto 0);
begin

  process (clk) is
  begin
    if rising_edge(clk) then
      was_reset <= reset;
      if reset = '1' and was_reset = '0' then
        reset_duration <= (others => '0');
      elsif was_reset = '1' then
        reset_duration <= std_logic_vector(unsigned(reset_duration) + 1);
      end if;
    end if;
  end process;


-- instantiate the UART register controller
  UARTHandlerInst : entity work.uart2BusTop
    -- 16 bits address width (for register addressing over UART)
    generic map (AW => 16)
    port map (
      clr          => reset, clk => clk, serIn => UART_Rx, serOut => UART_Tx,
      intAccessReq => uart_req, intAccessGnt => uart_gnt,
      intRdData    => regReadData, intWrData => regWriteData,
      intAddress   => regAddress, intWrite => regWriteEnable,
      intRead      => regReadEnable
      );


  process (clk) is
  begin
    if rising_edge(clk) then
      uart_gnt <= uart_req;
    end if;
  end process;

  -- register read mux
  regReadData <=
    dmem_data_in                    when regAddress(15 downto 14) = "10" else
    imem_data_in                    when regAddress(15 downto 14) = "11" else
    regfile_read_value              when is_access_to_rf else
    expupd_read_value               when is_access_to_expupd else
    "0000000" & procEnableSignal    when regAddress = REG_ADDR_PROC_EN else
    "0000000" & procResetSignal     when regAddress = REG_ADDR_PROC_RESET else
    tm_test_status                  when regAddress = REG_ADDR_TEST_STATUS else
    tm_test_cycle_counter_hi        when regAddress = REG_ADDR_TEST_CYCLE_COUNTER_HI else
    tm_test_cycle_counter_lo        when regAddress = REG_ADDR_TEST_CYCLE_COUNTER_LO else
    "0000000" & tm_num_expupd(8)    when regAddress = REG_ADDR_NUM_EXPECTED_UPDATES_HI else
    tm_num_expupd(7 downto 0)       when regAddress = REG_ADDR_NUM_EXPECTED_UPDATES_LO else
    tm_max_wait_time(15 downto 8)   when regAddress = REG_ADDR_MAX_WAIT_TIME_HI else
    tm_max_wait_time(7 downto 0)    when regAddress = REG_ADDR_MAX_WAIT_TIME_LO else
    unmatched_expected_dest         when regAddress = REG_ADDR_EXPECTED_TYPE else
    unmatched_expected_addr_hi      when regAddress = REG_ADDR_EXPECTED_ADDR_HI else
    unmatched_expected_addr_lo      when regAddress = REG_ADDR_EXPECTED_ADDR_LO else
    unmatched_expected_value0       when regAddress = REG_ADDR_EXPECTED_VALUE0 else
    unmatched_expected_value1       when regAddress = REG_ADDR_EXPECTED_VALUE1 else
    unmatched_expected_value2       when regAddress = REG_ADDR_EXPECTED_VALUE2 else
    unmatched_expected_value3       when regAddress = REG_ADDR_EXPECTED_VALUE3 else
    bad_actual_dest                 when regAddress = REG_ADDR_ACTUAL_TYPE else
    bad_actual_addr_hi              when regAddress = REG_ADDR_ACTUAL_ADDR_HI else
    bad_actual_addr_lo              when regAddress = REG_ADDR_ACTUAL_ADDR_LO else
    bad_actual_value0               when regAddress = REG_ADDR_ACTUAL_VALUE0 else
    bad_actual_value1               when regAddress = REG_ADDR_ACTUAL_VALUE1 else
    bad_actual_value2               when regAddress = REG_ADDR_ACTUAL_VALUE2 else
    bad_actual_value3               when regAddress = REG_ADDR_ACTUAL_VALUE3 else
    TDT4255_EX1_MAGIC(31 downto 24) when regAddress = REG_ADDR_MAGIC0 else
    TDT4255_EX1_MAGIC(23 downto 16) when regAddress = REG_ADDR_MAGIC1 else
    TDT4255_EX1_MAGIC(15 downto 8)  when regAddress = REG_ADDR_MAGIC2 else
    TDT4255_EX1_MAGIC(7 downto 0)   when regAddress = REG_ADDR_MAGIC3 else
    reset_duration(31 downto 24)    when regAddress = REG_ADDR_RESET_DURATION0 else
    reset_duration(23 downto 16)    when regAddress = REG_ADDR_RESET_DURATION1 else
    reset_duration(15 downto 8)     when regAddress = REG_ADDR_RESET_DURATION2 else
    reset_duration(7 downto 0)      when regAddress = REG_ADDR_RESET_DURATION3 else
    x"00";

-- The peripheral addressing scheme uses only bits 13-0 for dmem/imem byte
-- address selection, so we cannot at present support instruction or data
-- memories with an address width greater than 13 (or well, it could work -
-- but the way we select bits using imem_addr'range will crash if the address
-- width exceeds 16 bits. Keeping this if-generate here just as a safeguard for
-- future updates.)
  correctness_safeguard : if IMEM_ADDR_WIDTH >= 14 or DMEM_ADDR_WIDTH >= 14 generate
    assert false report "imem or dmem too deep" severity failure;
  end generate correctness_safeguard;

  -- instruction memory connections
  imem_wr_en    <= regWriteEnable and (regAddress(15) and regAddress(14)) and (not procEnableSignal);
  imem_addr     <= regAddress(imem_addr'range);
  imem_data_out <= regWriteData;

  -- data memory connections
  dmem_wr_en    <= regWriteEnable and (regAddress(15) and (not regAddress(14))) and (not procEnableSignal);
  dmem_addr     <= regAddress(dmem_addr'range);
  dmem_data_out <= regWriteData;

  -- regfile connections
  is_access_to_rf     <= regAddress(15 downto 12) = x"3";
  regfile_addr        <= regAddress(reg_byte_addr_t'range);
  regfile_we          <= regWriteEnable = '1' and is_access_to_rf;
  regfile_write_value <= regWriteData;

  -- expected updates connections
  is_access_to_expupd       <= regAddress(15 downto 12) = x"2";
  tm_expupd_byte_write_addr <= regAddress(11 downto 0);
  tm_expupd_write_value     <= regWriteData;
  tm_expupd_we              <= regWriteEnable when is_access_to_expupd else '0';
  tm_expupd_re              <= regReadEnable = '1' and is_access_to_expupd;

  -- test monitor config registers
  tm_num_expected_updates_lo <= regWriteData;
  tm_num_expected_updates_hi <= regWriteData;
  tm_max_wait_time_lo        <= regWriteData;
  tm_max_wait_time_hi        <= regWriteData;

  tm_num_expupd_lo_we <=
    regWriteEnable when regAddress = REG_ADDR_NUM_EXPECTED_UPDATES_LO else
    '0';
  tm_num_expupd_hi_we <=
    regWriteEnable when regAddress = REG_ADDR_NUM_EXPECTED_UPDATES_HI else
    '0';
  tm_max_wait_time_lo_we <=
    regWriteEnable when regAddress = REG_ADDR_MAX_WAIT_TIME_LO else
    '0';
  tm_max_wait_time_hi_we <=
    regWriteEnable when regAddress = REG_ADDR_MAX_WAIT_TIME_HI else
    '0';

  tm_test_cycle_counter_lo <= tm_test_cycle_counter(7 downto 0);
  tm_test_cycle_counter_hi <= tm_test_cycle_counter(15 downto 8);
  unmatched_expected_dest <=
    x"01" when unmatched_expected.dest = DMEM_UPDATE else
    x"00";
  unmatched_expected_addr_lo <= unmatched_expected.addr(7 downto 0);
  unmatched_expected_addr_hi(DMEM_ADDR_WIDTH-9 downto 0) <=
    unmatched_expected.addr(DMEM_ADDR_WIDTH - 1 downto 8);
  unmatched_expected_addr_hi(7 downto DMEM_ADDR_WIDTH-8) <= (others => '0');
  unmatched_expected_value0                              <= unmatched_expected.value(31 downto 24);
  unmatched_expected_value1                              <= unmatched_expected.value(23 downto 16);
  unmatched_expected_value2                              <= unmatched_expected.value(15 downto 8);
  unmatched_expected_value3                              <= unmatched_expected.value(7 downto 0);
  bad_actual_dest <=
    x"01" when bad_actual.dest = DMEM_UPDATE else
    x"00";
  bad_actual_addr_lo <= bad_actual.addr(7 downto 0);
  bad_actual_addr_hi(DMEM_ADDR_WIDTH-9 downto 0) <=
    bad_actual.addr(DMEM_ADDR_WIDTH - 1 downto 8);
  bad_actual_addr_hi(7 downto DMEM_ADDR_WIDTH-8) <= (others => '0');
  bad_actual_value0                              <= bad_actual.value(31 downto 24);
  bad_actual_value1                              <= bad_actual.value(23 downto 16);
  bad_actual_value2                              <= bad_actual.value(15 downto 8);
  bad_actual_value3                              <= bad_actual.value(7 downto 0);

  ControlRegs : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        procResetSignal  <= '0';
        procEnableSignal <= '0';
      else
        -- implement the enable signal ctrl register
        if regWriteEnable = '1' and regAddress = REG_ADDR_PROC_EN then
          procEnableSignal <= regWriteData(0);
        end if;
        -- implement the reset signal ctrl register
        if regWriteEnable = '1' and regAddress = REG_ADDR_PROC_RESET then
          procResetSignal <= regWriteData(0);
        end if;
      end if;
    end if;
  end process;
  proc_rst <= procResetSignal;
  proc_en  <= procEnableSignal;


end Behavioral;
