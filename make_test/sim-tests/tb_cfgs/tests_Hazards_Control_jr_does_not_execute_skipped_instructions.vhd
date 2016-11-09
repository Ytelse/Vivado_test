configuration tests_Hazards_Control_jr_does_not_execute_skipped_instructions of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/Hazards/Control/jr_does_not_execute_skipped_instructions/init_imem",
          DMEM_INIT_FILE             => "tests/Hazards/Control/jr_does_not_execute_skipped_instructions/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/Hazards/Control/jr_does_not_execute_skipped_instructions/init_exp_updates",
          LOG_FILE                   => "tests/Hazards/Control/jr_does_not_execute_skipped_instructions/test_log",
          NUM_EXPECTED_UPDATES       => 9,
          TEST_TIMEOUT_CYCLES        => 390);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/Hazards/Control/jr_does_not_execute_skipped_instructions/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_Hazards_Control_jr_does_not_execute_skipped_instructions;
