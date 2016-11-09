configuration tests_Stalls_execute_stalled_instructions_exactly_once of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/Stalls/execute_stalled_instructions_exactly_once/init_imem",
          DMEM_INIT_FILE             => "tests/Stalls/execute_stalled_instructions_exactly_once/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/Stalls/execute_stalled_instructions_exactly_once/init_exp_updates",
          LOG_FILE                   => "tests/Stalls/execute_stalled_instructions_exactly_once/test_log",
          NUM_EXPECTED_UPDATES       => 24,
          TEST_TIMEOUT_CYCLES        => 660);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/Stalls/execute_stalled_instructions_exactly_once/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_Stalls_execute_stalled_instructions_exactly_once;
