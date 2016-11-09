library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.framework_util.all;

entity ExpectedUpdateCheck is
  port (
    input : in expected_update_check_in_t;
    output : out expected_update_check_out_t);

end entity ExpectedUpdateCheck;

architecture Behavioural of ExpectedUpdateCheck is

  signal is_active_actual : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
  signal is_active_actual_fold : std_logic_vector(0 to RF_NUM_WRITE_PORTS+1);
  signal is_matching_actual : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
  signal is_matching_actual_fold : std_logic_vector(0 to RF_NUM_WRITE_PORTS+1);
  signal is_first_matching_actual : std_logic_vector(0 to RF_NUM_WRITE_PORTS);
  signal is_already_matched : std_logic_vector(0 to RF_NUM_WRITE_PORTS+1);

  signal any_active_actual : boolean;
  signal no_matching_actual : boolean;
begin  -- architecture Behavioural

  is_already_matched(0) <= '0';
  is_active_actual_fold(0) <= is_active_actual(0);
  is_matching_actual_fold(0) <= is_matching_actual(0);
  gen_bitmasks: for i in 0 to RF_NUM_WRITE_PORTS generate
    is_active_actual(i) <= input.update_wes(i) and
                           not input.disabled_actuals(i);
    is_matching_actual(i) <=
      is_active_actual(i) when (input.actual(i) = input.expected) else
      '0';

    is_first_matching_actual(i) <= is_matching_actual(i) and
                                   not is_already_matched(i);
    is_already_matched(i+1) <=
      is_first_matching_actual(i) or is_already_matched(i);
    is_active_actual_fold(i+1) <=
      is_active_actual_fold(i) or is_active_actual(i);
    is_matching_actual_fold(i+1) <=
      is_matching_actual_fold(i) or is_matching_actual(i);
  end generate gen_bitmasks;

  any_active_actual <= is_active_actual_fold(RF_NUM_WRITE_PORTS+1) = '1';
  no_matching_actual <= is_matching_actual_fold(RF_NUM_WRITE_PORTS+1) = '0';

  output.is_check_active <= '1' when any_active_actual else '0';
  output.is_expected_unmatched <=
    '1' when any_active_actual and no_matching_actual else '0';
  output.disabled_actuals <= input.disabled_actuals or is_first_matching_actual;

  process (input.actual, is_active_actual) is
  begin
    output.bad_actual <= input.actual(RF_NUM_WRITE_PORTS);
    for i in RF_NUM_WRITE_PORTS-1 downto 0 loop
      if is_active_actual(i) = '1' then
        output.bad_actual <= input.actual(i);
      end if;
    end loop;
  end process;

end architecture Behavioural;
