configuration tests_Hazards_Control_bne_respects_branch_condition of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/Hazards/Control/bne_respects_branch_condition/init_imem",
          DMEM_INIT_FILE             => "tests/Hazards/Control/bne_respects_branch_condition/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/Hazards/Control/bne_respects_branch_condition/init_exp_updates",
          LOG_FILE                   => "tests/Hazards/Control/bne_respects_branch_condition/test_log",
          NUM_EXPECTED_UPDATES       => 151,
          TEST_TIMEOUT_CYCLES        => 4450);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/Hazards/Control/bne_respects_branch_condition/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_Hazards_Control_bne_respects_branch_condition;
