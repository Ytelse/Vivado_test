configuration tests_Hazards_Control_j_loop_forever_no_following_stores_executed of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/Hazards/Control/j_loop_forever_no_following_stores_executed/init_imem",
          DMEM_INIT_FILE             => "tests/Hazards/Control/j_loop_forever_no_following_stores_executed/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/Hazards/Control/j_loop_forever_no_following_stores_executed/init_exp_updates",
          LOG_FILE                   => "tests/Hazards/Control/j_loop_forever_no_following_stores_executed/test_log",
          NUM_EXPECTED_UPDATES       => 1,
          TEST_TIMEOUT_CYCLES        => 1000);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/Hazards/Control/j_loop_forever_no_following_stores_executed/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_Hazards_Control_j_loop_forever_no_following_stores_executed;
