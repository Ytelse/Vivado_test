library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.defs.all;

package framework_util is

  constant IMEM_DATA_BYTES     : natural := IMEM_DATA_WIDTH/BYTE_WIDTH;
  constant IMEM_BYTE_ADDR_BITS : natural :=
    natural(ceil(log2(real(IMEM_DATA_BYTES))));
  constant IMEM_BYTE_ADDR_WIDTH : natural := IMEM_ADDR_WIDTH+IMEM_BYTE_ADDR_BITS;
  subtype imem_byte_addr_t is std_logic_vector(IMEM_BYTE_ADDR_WIDTH-1 downto 0);

  constant DMEM_DATA_BYTES : natural := DMEM_DATA_WIDTH/BYTE_WIDTH;
  constant DMEM_BYTE_ADDR_BITS : natural :=
    natural(ceil(log2(real(DMEM_DATA_WIDTH/BYTE_WIDTH))));
  constant DMEM_BYTE_ADDR_WIDTH : natural := DMEM_ADDR_WIDTH+DMEM_BYTE_ADDR_BITS;
  subtype dmem_byte_addr_t is
    std_logic_vector(DMEM_ADDR_WIDTH+DMEM_BYTE_ADDR_BITS-1 downto 0);
  subtype dmem_write_mask_t is
    std_logic_vector(DMEM_DATA_WIDTH/BYTE_WIDTH-1 downto 0);

  subtype reg_byte_addr_t is std_logic_vector(reg_addr_t'length+1 downto 0);

  component MIPSSystem is
    port (
      clk, reset   : in  std_logic;
      UART_Rx      : in  std_logic;
      UART_Tx      : out std_logic;
      proc_enabled : out std_logic;
      blue_leds    : out std_logic_vector (3 downto 0);
      red_leds     : out std_logic_vector (3 downto 0);
      green_leds   : out std_logic_vector (3 downto 0));
  end component MIPSSystem;

  type state_update_dest_t is (REGFILE_UPDATE, DMEM_UPDATE);

  type expected_state_update_t is record
    dest  : state_update_dest_t;
    addr  : dmem_addr_t;
    value : datapath_t;
  end record expected_state_update_t;

  -- Actual updates: 1 + RF_NUM_WRITE_PORTS
  type update_array_t is array (0 to RF_NUM_WRITE_PORTS) of expected_state_update_t;

  type test_monitor_in_t is record
    clk                     : std_logic;
    reset                   : std_logic;
    num_exp_updates_we_mask : std_logic_vector(1 downto 0);
    num_exp_updates         : std_logic_vector(8 downto 0);
    expupd_we               : std_logic;
    expupd_byte_write_addr  : std_logic_vector(11 downto 0);
    expupd_write_value      : byte_t;
    proc_enable             : std_logic;
    updates                 : update_array_t;
    update_wes              : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
    max_wait_time           : std_logic_vector(15 downto 0);
    max_wait_time_we_mask   : std_logic_vector(1 downto 0);
    read_exp_upd_en : boolean;
  end record test_monitor_in_t;

  type test_monitor_out_t is record
    test_status        : std_logic_vector(7 downto 0);
    test_cycle_count   : std_logic_vector(15 downto 0);
    unmatched_expected : expected_state_update_t;
    bad_actual         : expected_state_update_t;
    exp_upd_byte       : byte_t;
    num_expupd         : std_logic_vector(8 downto 0);
    max_wait_time      : std_logic_vector(15 downto 0);
  end record test_monitor_out_t;

  type test_status_t is (TEST_STATUS_NOT_DONE, TEST_STATUS_SUCCESS,
                         TEST_STATUS_TIMEOUT, TEST_STATUS_UPDATE_WHILE_DISABLED,
                         TEST_STATUS_EXTRA_UPDATE, TEST_STATUS_INCORRECT_UPDATE);

  type test_checks_in_t is record
    actual          : update_array_t;
    update_wes      : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
    proc_en         : boolean;
    expected        : update_array_t;
    should_be_done  : boolean;
  end record test_checks_in_t;

  type test_checks_out_t is record
    is_check_active    : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
    status             : test_status_t;
    found_error        : boolean;
    unmatched_expected : expected_state_update_t;
    bad_actual         : expected_state_update_t;
  end record test_checks_out_t;

  type expected_update_check_in_t is record
    actual           : update_array_t;
    update_wes       : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
    expected         : expected_state_update_t;
    disabled_actuals : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
  end record expected_update_check_in_t;

  type expected_update_check_out_t is record
    is_check_active       : std_logic;
    is_expected_unmatched : std_logic;
    bad_actual            : expected_state_update_t;
    disabled_actuals      : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
  end record expected_update_check_out_t;

end package framework_util;
