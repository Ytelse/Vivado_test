-- Part of TDT4255 Computer Design laboratory exercises
-- Group for Computer Architecture and Design
-- Department of Computer and Information Science
-- Norwegian University of Science and Technology

-- Testbench for the MIPSProcessor component
-- Instantiates data and instruction memory, fills them and the register file
-- with initial content loaded from files, initializes an array of expected
-- state updates, enables the processor, and checks continuously that the
-- expected updates arrive in order.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

use work.testutil.all;
use work.defs.all;
use work.framework_util.all;

entity tb_MIPSProcessor is
  generic (
    IMEM_INIT_FILE             : string;
    DMEM_INIT_FILE             : string;
    EXPECTED_UPDATES_INIT_FILE : string;
    LOG_FILE                   : string;
    NUM_EXPECTED_UPDATES       : natural;
    TEST_TIMEOUT_CYCLES        : natural := 1000;
    IDLE_WAIT_CYCLES           : natural := 100);
end tb_MIPSProcessor;

architecture Behavioural of tb_MIPSProcessor is

  --Inputs
  signal clk              : std_logic := '0';
  signal reset            : std_logic := '0';
  signal processor_enable : std_logic := '0';

  -- Processor memory access signals.
  signal proc_imem_address      : imem_addr_t := (others => '0');
  signal proc_pull_imem_data    : imem_data_t := (others => '0');
  signal proc_dmem_address      : dmem_addr_t := (others => '0');
  signal proc_pull_dmem_data    : dmem_data_t := (others => '0');
  signal proc_push_dmem_data    : dmem_data_t := (others => '0');
  signal proc_dmem_write_enable : std_logic   := '0';

  -- Dummy signals, not used in test bench since initialization is done using
  -- files.
  signal hostcomm_pull_imem_data : byte_t := (others => '0');
  signal hostcomm_pull_dmem_data : byte_t := (others => '0');

  -- Signals to peek at the register file (circumvents lack of VHDL 2008
  -- feature "hierarchical names" in Vivado Simulator.)
  signal tb_peek_regfile_write_ports : write_ports_in_t;
  signal rf_debug_in                 : regfile_debug_in_t;
  signal rf_debug_out                : regfile_debug_out_t;

  -- Clock period definitions
  constant CLK_PERIOD : time := 10 ns;

  -- Include one more element than necessary to make indexing work also when
  -- there are zero expected updates.
  type expected_updates_t is
    array (0 to NUM_EXPECTED_UPDATES) of expected_state_update_t;
  signal expected_updates : expected_updates_t;
  signal test_complete    : boolean := false;

  signal mips_proc_in  : mips_processor_in_t;
  signal mips_proc_out : mips_processor_out_t;

begin

-- Instantiate the processor
  Processor : MIPSProcessor
    port map (
      input  => mips_proc_in,
      output => mips_proc_out,

      rf_debug_in  => rf_debug_in,
      rf_debug_out => rf_debug_out);

  mips_proc_in.clk              <= clk;
  mips_proc_in.rst              <= reset;
  mips_proc_in.processor_enable <= processor_enable;
  mips_proc_in.imem_data        <= proc_pull_imem_data;
  mips_proc_in.dmem_data        <= proc_pull_dmem_data;
  proc_imem_address             <= mips_proc_out.imem_address;
  proc_dmem_address             <= mips_proc_out.dmem_address;
  proc_push_dmem_data           <= mips_proc_out.dmem_data;
  proc_dmem_write_enable        <= mips_proc_out.dmem_write_enable;
  tb_peek_regfile_write_ports   <= rf_debug_out.peek_write_ports;

  -- unused regfile debug ports
  rf_debug_in.byte_addr <= (others => '0');
  rf_debug_in.byte      <= (others => '0');
  rf_debug_in.we        <= false;

-- instantiate the instruction memory
  InstrMem : entity work.InstructionMemory
    generic map (
      INIT_FILE => IMEM_INIT_FILE)
    port map (
      clk              => clk,
      processor_enable => processor_enable,

      hostcomm_wen      => '0',
      hostcomm_data_in  => (others => '0'),
      hostcomm_addr     => (others => '1'),
      hostcomm_data_out => hostcomm_pull_imem_data,

      proc_addr     => proc_imem_address,
      proc_data_out => proc_pull_imem_data);

  -- instantiate the data memory
  DataMem : entity work.DataMemory
    generic map (
      INIT_FILE => DMEM_INIT_FILE)
    port map (
      clk              => clk,
      processor_enable => processor_enable,

      hostcomm_wen      => '0',
      hostcomm_data_in  => (others => '0'),
      hostcomm_addr     => (others => '1'),
      hostcomm_data_out => hostcomm_pull_dmem_data,

      proc_wen      => proc_dmem_write_enable,
      proc_data_in  => proc_push_dmem_data,
      proc_addr     => proc_dmem_address,
      proc_data_out => proc_pull_dmem_data);

  -- Clock process definitions
  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;

  -- Ensures that expected state updates occur in order.
  check_expected_updates : process (clk) is
    file log_file            : text open write_mode is LOG_FILE;
    variable log_line        : line;
    variable clock_counter   : natural := 0;
    variable idle_counter    : natural := 0;
    variable should_be_idle  : boolean := false;
    variable update_i        : natural := 0;
    variable expected_update : expected_state_update_t;
    type update_array_t is
      array (0 to (1+RF_NUM_WRITE_PORTS)-1) of expected_state_update_t;
    variable current_updates : update_array_t;
    variable num_updates     : natural := 0;
    variable test_failed     : boolean := false;

    function to_string (
      constant update : in expected_state_update_t) return string is
    begin  -- procedure dmem_update_as_string
      if update.dest = DMEM_UPDATE then
        return string'("update to data memory address " &
                       to_hstring(update.addr) &
                       " with value " & to_hstring(update.value));
      else
        return string'("update to register " & to_string(update.addr) &
                       " with value " & to_hstring(update.value));
      end if;
    end function to_string;

    procedure log_success (
      message : in string) is
    begin  -- procedure log_success
      swrite(log_line, "[OK] In cycle ");
      write(log_line, clock_counter);
      swrite(log_line, ": ");
      write(log_line, message);
      writeline(log_file, log_line);
    end procedure log_success;

    procedure log_failure(
      constant message : in string) is
    begin  -- procedure log_failure
      swrite(log_line, "[FAILURE] In cycle ");
      write(log_line, clock_counter);
      swrite(log_line, ": ");
      write(log_line, message);
      writeline(log_file, log_line);
    end procedure log_failure;

    function "=" (
      upd1 : expected_state_update_t;
      upd2 : expected_state_update_t)
      return boolean is
    begin  -- function "="
      return (upd1.dest = upd2.dest and
              upd1.addr = upd2.addr and
              upd1.value = upd2.value);
    end function "=";

    impure function check_updates_incorrect (
      current_updates  : in update_array_t;
      num_updates      : in natural;
      expected_updates : in expected_updates_t;
      update_i         : in natural) return boolean is

      variable found_expected        : boolean;
      variable found_same_dest       : boolean;
      variable temp_update           : expected_state_update_t;
      variable next_expected         : expected_state_update_t;
      variable same_dest_update      : expected_state_update_t;
      variable any_updates_incorrect : boolean := false;
      variable temp_cur_updates      : update_array_t;

    begin  -- procedure check_update_correctness
      temp_cur_updates := current_updates;

      for i in 0 to num_updates-1 loop
        -- Check if the next sequence of num_updates expected updates match the
        -- num_updates current updates.
        if update_i + i >= NUM_EXPECTED_UPDATES then
          -- In this case, there are more current updates than there are
          -- remaining expected updates. Since the for loop moves any matching
          -- current updates to the front, the remaining sequence of
          -- current_updates will all be updates which did not match any
          -- expected updates, so we can print all of them as unexpected
          -- additional updates.
          log_failure("Unexpected additional " &
                      to_string(temp_cur_updates(i)));
          any_updates_incorrect := true;
        else
          -- Try to find the next expected_updates(i) in temp_cur_updates.
          -- Move a hit to the front of temp_cur_updates to avoid having the same
          -- update check off multiple expected updates.
          -- (and since we don't really need to retain the match, we don't have
          -- to swap with the front but can overwrite with it instead.)
          next_expected   := expected_updates(update_i + i);
          found_expected  := false;
          found_same_dest := false;
          for j in i to num_updates-1 loop
            if next_expected = temp_cur_updates(j) then
              found_expected      := true;
              temp_cur_updates(j) := temp_cur_updates(i);
            elsif next_expected.dest = temp_cur_updates(j).dest then
              found_same_dest  := true;
              same_dest_update := temp_cur_updates(j);
            end if;
          end loop;  -- j
          if found_expected then
            if not any_updates_incorrect then
              -- Only print success statements if no errors have been detected,
              -- to ensure that the final line in the log is a failure line.
              log_success("Got expected " &
                          to_string(next_expected));
            end if;
          else
            -- Did not find the expected update, must print error message.
            -- In case we have several mismatching current updates, we print
            -- any current update matching the expected update destination.
            -- Otherwise, we just print the first mismatching current update.
            if found_same_dest then
              log_failure("Expected next " & to_string(next_expected) &
                          " but got " & to_string(same_dest_update));
            else
              log_failure("Expected next " & to_string(next_expected) &
                          " but got " & to_string(temp_cur_updates(i)));
            end if;
            any_updates_incorrect := true;
          end if;
        end if;
      end loop;  -- i
      return any_updates_incorrect;

    end function check_updates_incorrect;

    procedure read_current_updates (
      variable current_updates : out   update_array_t;
      variable num_updates     : inout natural) is
    begin  -- procedure read_current_update
      num_updates := 0;
      if proc_dmem_write_enable = '1' then
        current_updates(num_updates).dest  := DMEM_UPDATE;
        current_updates(num_updates).addr  := proc_dmem_address;
        current_updates(num_updates).value := proc_push_dmem_data;
        num_updates                        := num_updates + 1;
      end if;
      for i in 0 to RF_NUM_WRITE_PORTS-1 loop
        if tb_peek_regfile_write_ports(i).we then
          current_updates(num_updates).dest := REGFILE_UPDATE;
          current_updates(num_updates).addr := (others => '0');
          current_updates(num_updates).addr(reg_addr_t'range) :=
            tb_peek_regfile_write_ports(i).dst;
          current_updates(num_updates).value :=
            tb_peek_regfile_write_ports(i).value;
          num_updates := num_updates + 1;
        end if;
      end loop;  -- i
    end procedure read_current_updates;

    impure function assert_no_additional_updates (
      num_updates : in natural;
      cur_updates : in update_array_t) return boolean is
    begin  -- procedure   assert_no_additional_updates
      if num_updates >= 1 then
        -- Log all extra unexpected updates for clarity.
        for i in 0 to num_updates-1 loop
          log_failure("Unexpected additional " & to_string(cur_updates(i)));
        end loop;
        return true;
      else
        return false;
      end if;
    end function assert_no_additional_updates;

    impure function check_test_complete (
      idle_counter : natural)
      return boolean is
    begin  -- function check_test_complete
      if idle_counter >= IDLE_WAIT_CYCLES then
        log_success("Waited " & natural'image(idle_counter) & " cycles, " &
                    "got no unexpected updates.");
        --swrite(log_line, "Test success.");
        --writeline(log_file, log_line);
        log_success("Test success.");
        return true;
      else
        return false;
      end if;
    end function check_test_complete;

  begin  -- process check_expected_updates
    if rising_edge(clk) then
      -- Determine whether we have a state update this cycle or not.
      read_current_updates(current_updates, num_updates);

      if update_i >= NUM_EXPECTED_UPDATES then
        -- Got all updates, check that no additional updates arrive.
        test_failed := assert_no_additional_updates(num_updates, current_updates);
        if not test_failed then
          idle_counter  := idle_counter + 1;
          test_complete <= check_test_complete(idle_counter);
        end if;
      elsif num_updates > 0 then
        if processor_enable = '1' then
          -- Check that the update is what we expected.
          test_failed :=
            check_updates_incorrect(current_updates, num_updates,
                                    expected_updates, update_i);
        else
          for i in 0 to num_updates loop
            log_failure("Got " & to_string(current_updates(i)) & " while processor " &
                        "was disabled.");
          end loop;
          test_failed := true;
        end if;
        update_i := update_i + num_updates;
      elsif clock_counter >= TEST_TIMEOUT_CYCLES then
        -- If the test runs for too long, time out.
        -- We put the timeout check in a separate elsif to make sure that we do
        -- not time out during idle state, or when the processor is actively
        -- updating state (infinite updates will eventually lead to an
        -- unexpected update).
        log_failure("Test timeout.");
        test_failed := true;
      end if;
      clock_counter := clock_counter + 1;
      if test_failed then
        test_complete <= true;
      end if;
    end if;
  end process check_expected_updates;

-- Stimulus process
  stim_proc : process
    procedure init_expected_updates_from_file is
      file exp_upd_file     : text open read_mode is EXPECTED_UPDATES_INIT_FILE;
      variable exp_upd_line : line;
      variable dummy_space  : character;
      variable i            : natural := 0;
      variable is_dest_dmem : std_logic;
      variable update_addr  : dmem_addr_t;
      variable update_value : datapath_t;

    begin  -- procedure init_expected_updates_from_file
      while not endfile(exp_upd_file) loop
        if i >= NUM_EXPECTED_UPDATES then
          assert false
            report string'("!!! [TEST SETUP BUG]: " &
                           "more expected updates in init file than specified")
            severity failure;
        else
          readline(exp_upd_file, exp_upd_line);
          read(exp_upd_line, is_dest_dmem);
          read(exp_upd_line, dummy_space);
          read(exp_upd_line, update_addr);
          read(exp_upd_line, dummy_space);
          hread(exp_upd_line, update_value);

          if is_dest_dmem = '0' then
            expected_updates(i).dest <= REGFILE_UPDATE;
          else
            expected_updates(i).dest <= DMEM_UPDATE;
          end if;
          expected_updates(i).addr  <= update_addr;
          expected_updates(i).value <= update_value;

          i := i + 1;
        end if;
      end loop;
      if i /= NUM_EXPECTED_UPDATES then
        assert false
          report string'("!!! [TEST SETUP BUG]: " &
                         "fewer expected updates in init file than specified")
          severity failure;
      end if;
      -- Initialize final dummy spot avoid U-s in the waveform config.
      expected_updates(i).dest  <= DMEM_UPDATE;
      expected_updates(i).addr  <= (others => '1');
      expected_updates(i).value <= (others => '1');
    end procedure init_expected_updates_from_file;

  begin
    init_expected_updates_from_file;

    processor_enable <= '0';
    reset            <= '1';
    wait for 10 * CLK_PERIOD;
    reset            <= '0';

    -- enable the processor
    processor_enable <= '1';

    -- execute until the test completes, due to either failure or success.
    wait until test_complete;

    processor_enable <= '0';

    -- check the results
    assert false report "test complete" severity failure;
  end process;

end;

entity tb is
end entity tb;

architecture Behavioural of tb is

  component tb_MIPSProcessor is
  end component tb_MIPSProcessor;
begin  -- architecture Behavioural

  tb_driver : tb_MIPSProcessor;

end architecture Behavioural;
