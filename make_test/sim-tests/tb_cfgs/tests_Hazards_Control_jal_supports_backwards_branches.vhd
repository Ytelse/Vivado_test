configuration tests_Hazards_Control_jal_supports_backwards_branches of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/Hazards/Control/jal_supports_backwards_branches/init_imem",
          DMEM_INIT_FILE             => "tests/Hazards/Control/jal_supports_backwards_branches/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/Hazards/Control/jal_supports_backwards_branches/init_exp_updates",
          LOG_FILE                   => "tests/Hazards/Control/jal_supports_backwards_branches/test_log",
          NUM_EXPECTED_UPDATES       => 22,
          TEST_TIMEOUT_CYCLES        => 450);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/Hazards/Control/jal_supports_backwards_branches/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_Hazards_Control_jal_supports_backwards_branches;
