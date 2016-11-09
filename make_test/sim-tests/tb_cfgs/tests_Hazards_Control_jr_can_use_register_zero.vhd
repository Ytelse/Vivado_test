configuration tests_Hazards_Control_jr_can_use_register_zero of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/Hazards/Control/jr_can_use_register_zero/init_imem",
          DMEM_INIT_FILE             => "tests/Hazards/Control/jr_can_use_register_zero/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/Hazards/Control/jr_can_use_register_zero/init_exp_updates",
          LOG_FILE                   => "tests/Hazards/Control/jr_can_use_register_zero/test_log",
          NUM_EXPECTED_UPDATES       => 0,
          TEST_TIMEOUT_CYCLES        => 250);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/Hazards/Control/jr_can_use_register_zero/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_Hazards_Control_jr_can_use_register_zero;
