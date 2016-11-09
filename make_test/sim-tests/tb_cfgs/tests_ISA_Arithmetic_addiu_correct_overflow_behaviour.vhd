configuration tests_ISA_Arithmetic_addiu_correct_overflow_behaviour of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/ISA/Arithmetic/addiu/correct_overflow_behaviour/init_imem",
          DMEM_INIT_FILE             => "tests/ISA/Arithmetic/addiu/correct_overflow_behaviour/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/ISA/Arithmetic/addiu/correct_overflow_behaviour/init_exp_updates",
          LOG_FILE                   => "tests/ISA/Arithmetic/addiu/correct_overflow_behaviour/test_log",
          NUM_EXPECTED_UPDATES       => 6,
          TEST_TIMEOUT_CYCLES        => 290);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/ISA/Arithmetic/addiu/correct_overflow_behaviour/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_ISA_Arithmetic_addiu_correct_overflow_behaviour;
