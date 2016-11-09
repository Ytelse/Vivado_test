library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.framework_util.all;

entity TestChecks is

  port (
    input  : in  test_checks_in_t;
    output : out test_checks_out_t);

end entity TestChecks;

architecture Behavioural of TestChecks is

  signal any_update            : boolean;
  signal any_unexpected_update : boolean;

  signal unmatched_expected      : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
  signal unmatched_expected_fold : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
  signal update_wes_fold         : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
  type disabled_actual_array_t is array (0 to RF_NUM_WRITE_PORTS)
    of std_logic_vector(0 to RF_NUM_WRITE_PORTS);

  type expected_update_check_in_array_t is array (0 to RF_NUM_WRITE_PORTS)
    of expected_update_check_in_t;
  signal expected_update_checks_in : expected_update_check_in_array_t;

  -- One extra to help boot-strap the chain of out => in => out => ...
  type expected_update_check_out_array_t is array (0 to RF_NUM_WRITE_PORTS+1)
    of expected_update_check_out_t;
  signal expected_update_checks_out : expected_update_check_out_array_t;

begin  -- architecture Behavioural

  unmatched_expected_fold(0) <= unmatched_expected(0);
  update_wes_fold(0)         <= input.update_wes(0);
  gen_or_reductions : for i in 1 to RF_NUM_WRITE_PORTS generate
    unmatched_expected_fold(i) <=
      unmatched_expected_fold(i-1) or unmatched_expected(i);
    update_wes_fold(i) <= update_wes_fold(i-1) or input.update_wes(i);
  end generate gen_or_reductions;
  any_update <= update_wes_fold(RF_NUM_WRITE_PORTS) = '1';

  output.status <=
    TEST_STATUS_UPDATE_WHILE_DISABLED when any_update and not input.proc_en else
    TEST_STATUS_EXTRA_UPDATE          when any_update and input.should_be_done else
    TEST_STATUS_INCORRECT_UPDATE;

  output.found_error <= (any_update and
                         (not input.proc_en or input.should_be_done)) or
                        any_unexpected_update;

  any_unexpected_update <= unmatched_expected_fold(RF_NUM_WRITE_PORTS) = '1';

  -- Use expected_update_checks_out(0).disabled_actuals as a recursion base.
  expected_update_checks_out(0).disabled_actuals      <= (others => '0');
  -- Tie the other fields of this array element to zero.
  expected_update_checks_out(0).is_check_active <= '0';
  expected_update_checks_out(0).is_expected_unmatched <= '0';
  expected_update_checks_out(0).bad_actual <= (
    dest  => REGFILE_UPDATE,
    addr  => (others => '0'),
    value => (others => '0')
    );

  gen_expected_update_checks : for i in 0 to RF_NUM_WRITE_PORTS generate
    expected_update_checks_in(i).actual     <= input.actual;
    expected_update_checks_in(i).update_wes <= input.update_wes;
    expected_update_checks_in(i).expected   <= input.expected(i);
    expected_update_checks_in(i).disabled_actuals <=
      expected_update_checks_out(i).disabled_actuals;
    ExpectedUpdateCheck_1 : entity work.ExpectedUpdateCheck
      port map (
        input  => expected_update_checks_in(i),
        output => expected_update_checks_out(i+1));
    unmatched_expected(i) <=
      expected_update_checks_out(i+1).is_expected_unmatched;
    output.is_check_active(i) <= expected_update_checks_out(i+1).is_check_active;
  end generate gen_expected_update_checks;

  process (input.expected, expected_update_checks_out) is
  begin
    output.unmatched_expected <= input.expected(RF_NUM_WRITE_PORTS);
    output.bad_actual <=
      expected_update_checks_out(RF_NUM_WRITE_PORTS+1).bad_actual;
    for i in RF_NUM_WRITE_PORTS downto 1 loop
      if expected_update_checks_out(i).is_expected_unmatched = '1' then
        output.unmatched_expected <= input.expected(i-1);
        output.bad_actual         <= expected_update_checks_out(i).bad_actual;
      end if;
    end loop;  -- i
  end process;

end architecture Behavioural;
