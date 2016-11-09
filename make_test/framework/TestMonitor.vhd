library ieee;
library unisim;
library unimacro;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use unisim.vcomponents.all;
use unimacro.vcomponents.all;

use work.defs.all;
use work.framework_util.all;

entity TestMonitor is

  port (
    input  : in  test_monitor_in_t;
    output : out test_monitor_out_t);

end entity TestMonitor;

architecture Behavioural of TestMonitor is

  constant EXP_UPD_WIDTH : natural := 48;
  signal expupd_wen_vec  : std_logic_vector(7 downto 0);
  signal expupd_wen_mask : std_logic_vector(7 downto 0);

  subtype expupd_addr_t is std_logic_vector(8 downto 0);

  signal expupd_write_addr  : expupd_addr_t;
  signal expupd_write_value : std_logic_vector(EXP_UPD_WIDTH-1 downto 0);
  signal expupd_byte_sel    : natural;
  signal expupd_hostcomm_read_addr  : expupd_addr_t;

  type raw_expected_updates_array_t is array (0 to RF_NUM_WRITE_PORTS)
    of std_logic_vector(EXP_UPD_WIDTH-1 downto 0);
  signal raw_expected_updates : raw_expected_updates_array_t;
  signal expected_updates     : update_array_t;

  signal cur_exp_update, next_exp_update : expupd_addr_t;
  type expupd_read_addr_array_t is array (0 to RF_NUM_WRITE_PORTS+1)
    of expupd_addr_t;
  signal expupd_read_addr : expupd_read_addr_array_t;

  signal test_cycle_counter, idle_wait_timer, test_timeout                  : natural;
  signal should_be_done, test_done, test_was_done, test_reset, test_running : boolean;

  signal test_status : test_status_t;

  -- Add a register to the processor activity inputs, to improve design timing
  signal actual_updates_reg : update_array_t;
  signal update_wes_reg     : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
  signal proc_enable_reg    : std_logic;

  -- Test monitor config registers
  signal max_wait_time   : std_logic_vector(15 downto 0);
  signal num_exp_updates : expupd_addr_t;

  -- Test check signals
  signal check_in  : test_checks_in_t;
  signal check_out : test_checks_out_t;
begin  -- architecture Behavioural

  expupd_write_addr <= input.expupd_byte_write_addr(11 downto 3);
  expupd_byte_sel <=
    natural(to_integer(unsigned(input.expupd_byte_write_addr(2 downto 0))));

  expupd_wen_vec <= (EXP_UPD_WIDTH/8 - 1 => input.expupd_we, others => '0');
  expupd_wen_mask <=
    std_logic_vector(shift_right(unsigned(expupd_wen_vec), expupd_byte_sel));

  expupd_hostcomm_read_addr <= expupd_write_addr;

  gen_expupd_write_value : for i in 0 to EXP_UPD_WIDTH/8 - 1 generate
    expupd_write_value(8*(i+1)-1 downto 8*i) <= input.expupd_write_value;
  end generate gen_expupd_write_value;

  gen_exp_update_rams : for i in 0 to RF_NUM_WRITE_PORTS generate

    -- Generate RAM addresses based on next_exp_update, since the BRAMs have
    -- synchronous read.
    gen_hostcomm_read_addr : if i = 0 generate
      expupd_read_addr(i) <=
        expupd_hostcomm_read_addr when input.read_exp_upd_en else
        expupd_addr_t(unsigned(next_exp_update) +
                      to_unsigned(i, expupd_addr_t'length));
      output.exp_upd_byte <=
        "00000" & raw_expected_updates(i)(42 downto 40) when expupd_byte_sel = 0 else
        raw_expected_updates(i)(39 downto 32) when expupd_byte_sel = 1 else
        raw_expected_updates(i)(31 downto 24) when expupd_byte_sel = 2 else
        raw_expected_updates(i)(23 downto 16) when expupd_byte_sel = 3 else
        raw_expected_updates(i)(15 downto 8) when expupd_byte_sel = 4 else
        raw_expected_updates(i)(7 downto 0) when expupd_byte_sel = 5 else
        (others => '0');
    end generate;
    gen_normal_read_addr : if i /= 0 generate
      expupd_read_addr(i) <=
        expupd_addr_t(unsigned(next_exp_update) +
                      to_unsigned(i, expupd_addr_t'length));
    end generate;

    expected_updates_ram : BRAM_SDP_MACRO
      generic map (
        BRAM_SIZE   => "36Kb",
        DEVICE      => "7SERIES",
        WRITE_WIDTH => EXP_UPD_WIDTH,
        READ_WIDTH  => EXP_UPD_WIDTH,
        write_mode  => "READ_FIRST")
      port map (
        DO     => raw_expected_updates(i),
        DI     => expupd_write_value,
        RDADDR => expupd_read_addr(i),
        RDCLK  => input.clk,
        RDEN   => '1',
        REGCE  => '0',
        RST    => '0',
        WE     => expupd_wen_mask,
        WRADDR => expupd_write_addr,
        WRCLK  => input.clk,
        WREN   => '1');

    expected_updates(i).value <=
      datapath_t(raw_expected_updates(i)(31 downto 0));
    expected_updates(i).addr <=
      dmem_addr_t(raw_expected_updates(i)(41 downto 32));
    expected_updates(i).dest <=
      DMEM_UPDATE when raw_expected_updates(i)(42) = '1' else
      REGFILE_UPDATE;
  end generate gen_exp_update_rams;
  expupd_read_addr(RF_NUM_WRITE_PORTS + 1) <= expupd_addr_t(
    unsigned(cur_exp_update) +
    to_unsigned(RF_NUM_WRITE_PORTS + 1, expupd_addr_t'length)
    );

  test_timeout <= natural(to_integer(unsigned(max_wait_time)));
  test_reset <= (input.num_exp_updates_we_mask(0) or
                 input.num_exp_updates_we_mask(1) or
                 input.expupd_we or
                 input.max_wait_time_we_mask(0) or
                 input.max_wait_time_we_mask(1)) = '1';

  test_status <= TEST_STATUS_SUCCESS when idle_wait_timer >= 100 else
                 TEST_STATUS_TIMEOUT when
                   (test_cycle_counter > test_timeout) and not should_be_done else
                 check_out.status when check_out.found_error else
                 TEST_STATUS_EXTRA_UPDATE when
                   next_exp_update > num_exp_updates else
                 TEST_STATUS_NOT_DONE;

  test_done    <= test_status /= TEST_STATUS_NOT_DONE or test_was_done;
  test_running <= proc_enable_reg = '1' and not test_done;

  check_in.actual         <= actual_updates_reg;
  check_in.update_wes     <= update_wes_reg;
  check_in.proc_en        <= proc_enable_reg = '1';
  check_in.expected       <= expected_updates;
  check_in.should_be_done <= should_be_done;
  TestChecks_1 : entity work.TestChecks
    port map (
      input  => check_in,
      output => check_out);

  gen_next_exp_addr: process (
    check_out.is_check_active, expupd_read_addr, cur_exp_update) is
  begin  -- process gen_next_exp_addr
    -- Next update checks: address one past the last expected update which
    -- was matched. Expected updates should always be matched in order, so
    -- the format of the matched_expupds mask should be 000..00, 100...00,
    -- 110..00, 111...00 etc.
    next_exp_update <= cur_exp_update;
    for i in 0 to RF_NUM_WRITE_PORTS loop
      if check_out.is_check_active(i) = '1' then
        next_exp_update <= expupd_addr_t(unsigned(cur_exp_update) +
                                         to_unsigned(i+1, expupd_addr_t'length));
      end if;
    end loop;
  end process gen_next_exp_addr;

  process (input.clk) is
  begin
    if rising_edge(input.clk) then
      if input.reset = '1' then
        cur_exp_update                  <= (others => '0');
        should_be_done                  <= false;
        test_was_done                   <= false;
        test_cycle_counter              <= 0;
        idle_wait_timer                 <= 0;
        max_wait_time                   <= (others => '0');
        num_exp_updates                 <= (others => '0');
        output.test_status              <= x"00";
        output.test_cycle_count         <= (others => '0');
        output.unmatched_expected.dest  <= REGFILE_UPDATE;
        output.unmatched_expected.addr  <= (others => '0');
        output.unmatched_expected.value <= (others => '0');
        output.bad_actual.dest          <= REGFILE_UPDATE;
        output.bad_actual.addr          <= (others => '0');
        output.bad_actual.value         <= (others => '0');
      else
        -- Delayed processor activity to improve timing.
        actual_updates_reg <= input.updates;
        update_wes_reg     <= input.update_wes;
        proc_enable_reg    <= input.proc_enable;

        -- Test monitor config registers
        if input.num_exp_updates_we_mask(0) = '1' then
          num_exp_updates(7 downto 0) <= input.num_exp_updates(7 downto 0);
        end if;
        if input.num_exp_updates_we_mask(1) = '1' then
          num_exp_updates(8) <= input.num_exp_updates(8);
        end if;
        if input.max_wait_time_we_mask(0) = '1' then
          max_wait_time(7 downto 0) <= input.max_wait_time(7 downto 0);
        end if;
        if input.max_wait_time_we_mask(1) = '1' then
          max_wait_time(15 downto 8) <= input.max_wait_time(15 downto 8);
        end if;

        if test_reset then
          cur_exp_update          <= (others => '0');
          should_be_done          <= false;
          test_was_done           <= false;
          test_cycle_counter      <= 0;
          idle_wait_timer         <= 0;
          output.test_status      <= x"00";
          output.test_cycle_count <= (others => '0');
        else
          -- Test control state
          cur_exp_update <= next_exp_update;
          should_be_done <= should_be_done or next_exp_update >= num_exp_updates;
          test_was_done  <= test_was_done or test_done;
          if test_running then
            test_cycle_counter <= test_cycle_counter + 1;
          end if;
          if should_be_done and test_running then
            idle_wait_timer <= idle_wait_timer + 1;
          end if;
          if not test_was_done then
            case test_status is
              when TEST_STATUS_NOT_DONE =>
                output.test_status <= x"00";
              when TEST_STATUS_SUCCESS =>
                output.test_status <= x"01";
              when TEST_STATUS_TIMEOUT =>
                output.test_status <= x"02";
              when TEST_STATUS_UPDATE_WHILE_DISABLED =>
                output.test_status <= x"03";
              when TEST_STATUS_EXTRA_UPDATE =>
                output.test_status <= x"04";
              when TEST_STATUS_INCORRECT_UPDATE =>
                output.test_status <= x"05";
            end case;
            output.test_cycle_count <=
              std_logic_vector(to_unsigned(test_cycle_counter, 16));
            output.unmatched_expected <= check_out.unmatched_expected;
            output.bad_actual         <= check_out.bad_actual;

          end if;
        end if;
      end if;
    end if;
  end process;

  output.num_expupd <= num_exp_updates;
  output.max_wait_time <= max_wait_time;

end architecture Behavioural;
