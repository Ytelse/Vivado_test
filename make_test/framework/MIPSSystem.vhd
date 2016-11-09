-- Part of TDT4255 Computer Design laboratory exercises
-- Group for Computer Architecture and Design
-- Department of Computer and Information Science
-- Norwegian University of Science and Technology

-- MIPSSystem.vhd
-- The MIPS processor system to be used in Exercise 1 and 2 during FPGA
-- testing. The system consists of a MIPSProcessor, two memories
-- and a HostComm module that can be used for controlling the processor
-- state or reading/writing the memories. The hostcomm utility (delivered
-- as part of the exercise) can be used from a host computer for this purpose.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.defs.all;
use work.framework_util.all;

entity MIPSSystem is
  generic (
    GREEN_LED_PATTERN : std_logic_vector(3 downto 0);
    BLUE_LED_PATTERN  : std_logic_vector(3 downto 0);
    RED_LED_PATTERN   : std_logic_vector(3 downto 0));
  port (
    clk, reset   : in  std_logic;
    -- interface towards the UART ports
    UART_Rx      : in  std_logic;
    UART_Tx      : out std_logic;
    -- LED output
    proc_enabled : out std_logic;
    blue_leds    : out std_logic_vector (3 downto 0);
    red_leds     : out std_logic_vector (3 downto 0);
    green_leds   : out std_logic_vector (3 downto 0));
end MIPSSystem;

architecture Behavioural of MIPSSystem is
  -- signals for processor control
  signal processorEnable : std_logic;
  signal processorReset  : std_logic;

  -- signals for instruction memory, processor port (read only!)
  signal procIMemReadData    : imem_data_t;
  signal procIMemAddr        : imem_addr_t;
  -- signals for data memory, processor port
  signal procDMemWriteEnable : std_logic;
  signal procDMemWriteData   : dmem_data_t;
  signal procDMemReadData    : dmem_data_t;
  signal procDMemAddr        : dmem_addr_t;

  -- signals for instruction memory, hostcomm port
  signal hcIMemWriteEnable : std_logic;
  signal hcIMemWriteData   : byte_t;
  signal hcIMemReadData    : byte_t;
  signal hcIMemAddr        : imem_byte_addr_t;
  -- signals for data memory, hostcomm port
  signal hcDMemWriteEnable : std_logic;
  signal hcDMemWriteData   : byte_t;
  signal hcDMemReadData    : byte_t;
  signal hcDMemAddr        : dmem_byte_addr_t;

  signal mips_proc_in  : mips_processor_in_t;
  signal mips_proc_out : mips_processor_out_t;

  signal test_monitor_in  : test_monitor_in_t;
  signal test_monitor_out : test_monitor_out_t;

  -- regfile debug port
  signal hostcomm_reg_byte_address : reg_byte_addr_t;
  signal hostcomm_reg_value_in     : byte_t;
  signal hostcomm_reg_we           : boolean;
  signal hostcomm_reg_read_byte    : byte_t;
  signal rf_debug_in               : regfile_debug_in_t;
  signal rf_debug_out              : regfile_debug_out_t;

  -- test monitor interface
  signal tm_test_status             : byte_t;
  signal tm_test_cycle_counter      : std_logic_vector(15 downto 0);
  signal tm_num_expected_updates_lo : byte_t;
  signal tm_num_expupd_lo_we        : std_logic;
  signal tm_num_expected_updates_hi : byte_t;
  signal tm_num_expupd_hi_we        : std_logic;
  signal tm_max_wait_time_lo        : byte_t;
  signal tm_max_wait_time_lo_we     : std_logic;
  signal tm_max_wait_time_hi        : byte_t;
  signal tm_max_wait_time_hi_we     : std_logic;
  signal unmatched_expected         : expected_state_update_t;
  signal bad_actual                 : expected_state_update_t;
  signal tm_expupd_byte_write_addr  : std_logic_vector(11 downto 0);
  signal tm_expupd_write_value      : byte_t;
  signal tm_expupd_we               : std_logic;

  signal rf_debug_peek_write_ports : write_ports_in_t;
  signal rf_debug_port_byte_addr   : reg_byte_addr_t;
  signal rf_debug_port_value_in    : byte_t;
  signal rf_debug_port_we          : boolean;
  signal rf_debug_read_byte        : byte_t;

begin
-- instantiate the processor
  MIPSProcInst : MIPSProcessor
    port map (
      input  => mips_proc_in,
      output => mips_proc_out,

      rf_debug_in => rf_debug_in,
      rf_debug_out => rf_debug_out);

  mips_proc_in.clk              <= clk;
  mips_proc_in.rst              <= processorReset;
  mips_proc_in.processor_enable <= processorEnable;
  mips_proc_in.imem_data        <= procIMemReadData;
  mips_proc_in.dmem_data        <= procDMemReadData;
  procIMemAddr                  <= mips_proc_out.imem_address;
  procDMemAddr                  <= mips_proc_out.dmem_address;
  procDMemWriteData             <= mips_proc_out.dmem_data;
  procDMemWriteEnable           <= mips_proc_out.dmem_write_enable;

-- instantiate the host communication module
  HostCommInst : entity work.HostComm port map (
    clk                        => clk, reset => reset,
    UART_Rx                    => UART_Rx, UART_Tx => UART_Tx,
    proc_en                    => processorEnable, proc_rst => processorReset,
    -- instruction memory connection
    imem_data_in               => hcIMemReadData, imem_data_out => hcIMemWriteData,
    imem_wr_en                 => hcIMemWriteEnable, imem_addr => hcIMemAddr,
    -- data memory connection
    dmem_data_in               => hcDMemReadData, dmem_data_out => hcDMemWriteData,
    dmem_wr_en                 => hcDMemWriteEnable, dmem_addr => hcDMemAddr,
    -- register file connection
    regfile_addr               => rf_debug_in.byte_addr,
    regfile_write_value        => rf_debug_in.byte,
    regfile_we                 => rf_debug_in.we,
    regfile_read_value         => rf_debug_out.byte_read,
    -- test monitor connections
    tm_test_status             => test_monitor_out.test_status,
    tm_test_cycle_counter      => test_monitor_out.test_cycle_count,
    tm_num_expected_updates_lo => tm_num_expected_updates_lo,
    tm_num_expupd_lo_we        => test_monitor_in.num_exp_updates_we_mask(0),
    tm_num_expected_updates_hi => tm_num_expected_updates_hi,
    tm_num_expupd_hi_we        => test_monitor_in.num_exp_updates_we_mask(1),
    tm_max_wait_time_lo        => test_monitor_in.max_wait_time(7 downto 0),
    tm_max_wait_time_lo_we     => test_monitor_in.max_wait_time_we_mask(0),
    tm_max_wait_time_hi        => test_monitor_in.max_wait_time(15 downto 8),
    tm_max_wait_time_hi_we     => test_monitor_in.max_wait_time_we_mask(1),
    unmatched_expected         => test_monitor_out.unmatched_expected,
    bad_actual                 => test_monitor_out.bad_actual,
    tm_expupd_byte_write_addr  => test_monitor_in.expupd_byte_write_addr,
    tm_expupd_write_value      => test_monitor_in.expupd_write_value,
    tm_expupd_we               => test_monitor_in.expupd_we,
    tm_expupd_re               => test_monitor_in.read_exp_upd_en,
    expupd_read_value          => test_monitor_out.exp_upd_byte,
    tm_num_expupd              => test_monitor_out.num_expupd,
    tm_max_wait_time           => test_monitor_out.max_wait_time
    );
  test_monitor_in.clk                         <= clk;
  test_monitor_in.reset                       <= reset;
  test_monitor_in.num_exp_updates(8)          <= tm_num_expected_updates_hi(0);
  test_monitor_in.num_exp_updates(7 downto 0) <= tm_num_expected_updates_lo;
  test_monitor_in.proc_enable                 <= processorEnable;

  test_monitor_in.updates(0).dest  <= DMEM_UPDATE;
  test_monitor_in.updates(0).addr  <= procDMemAddr;
  test_monitor_in.updates(0).value <= procDMemWriteData;
  test_monitor_in.update_wes(0)    <= procDMemWriteEnable;
  gen_updates : for i in 1 to RF_NUM_WRITE_PORTS generate
    test_monitor_in.updates(i).dest <= REGFILE_UPDATE;

    test_monitor_in.updates(i).addr(reg_addr_t'range) <=
      rf_debug_out.peek_write_ports(i-1).dst;
    test_monitor_in.updates(i).addr(
      dmem_addr_t'length-1 downto reg_addr_t'length) <= (others => '0');

    test_monitor_in.updates(i).value <=
      rf_debug_out.peek_write_ports(i-1).value;

    test_monitor_in.update_wes(i) <=
      '1' when rf_debug_out.peek_write_ports(i-1).we else
      '0';
  end generate gen_updates;

-- instantiate the instruction memory
  InstrMem : entity work.InstructionMemory
    port map (
      clk               => clk,
      processor_enable  => processorEnable,
      hostcomm_wen      => hcIMemWriteEnable,
      hostcomm_data_in  => hcIMemWriteData,
      hostcomm_addr     => hcIMemAddr,
      hostcomm_data_out => hcIMemReadData,
      proc_addr         => procIMemAddr,
      proc_data_out     => procIMemReadData);

  -- instantiate the data memory
  DataMem : entity work.DataMemory

    port map (
      clk               => clk,
      processor_enable  => processorEnable,
      hostcomm_wen      => hcDMemWriteEnable,
      hostcomm_data_in  => hcDMemWriteData,
      hostcomm_addr     => hcDMemAddr,
      hostcomm_data_out => hcDMemReadData,
      proc_wen          => procDMemWriteEnable,
      proc_data_in      => procDMemWriteData,
      proc_addr         => procDMemAddr,
      proc_data_out     => procDMemReadData);

  TestMonitor_1 : entity work.TestMonitor
    port map (
      input  => test_monitor_in,
      output => test_monitor_out);

  -- Drive the yellow status LED to indicate that the processor is running.
  proc_enabled <= processorEnable;

  -- drive the colour LEDs, indicating exercise version:
  --  green lights = exercise 0
  --  blue lights = exercise 1
  --  red lights = exercise 2
  green_leds <= GREEN_LED_PATTERN;
  blue_leds  <= BLUE_LED_PATTERN;
  red_leds   <= RED_LED_PATTERN;

end Behavioural;
