configuration tests_ISA_Arithmetic_lui_correct_semantics of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/ISA/Arithmetic/lui/correct_semantics/init_imem",
          DMEM_INIT_FILE             => "tests/ISA/Arithmetic/lui/correct_semantics/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/ISA/Arithmetic/lui/correct_semantics/init_exp_updates",
          LOG_FILE                   => "tests/ISA/Arithmetic/lui/correct_semantics/test_log",
          NUM_EXPECTED_UPDATES       => 36,
          TEST_TIMEOUT_CYCLES        => 590);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/ISA/Arithmetic/lui/correct_semantics/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_ISA_Arithmetic_lui_correct_semantics;
