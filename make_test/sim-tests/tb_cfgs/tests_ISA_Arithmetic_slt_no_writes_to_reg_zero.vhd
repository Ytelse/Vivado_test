configuration tests_ISA_Arithmetic_slt_no_writes_to_reg_zero of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/ISA/Arithmetic/slt/no_writes_to_reg_zero/init_imem",
          DMEM_INIT_FILE             => "tests/ISA/Arithmetic/slt/no_writes_to_reg_zero/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/ISA/Arithmetic/slt/no_writes_to_reg_zero/init_exp_updates",
          LOG_FILE                   => "tests/ISA/Arithmetic/slt/no_writes_to_reg_zero/test_log",
          NUM_EXPECTED_UPDATES       => 1,
          TEST_TIMEOUT_CYCLES        => 290);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/ISA/Arithmetic/slt/no_writes_to_reg_zero/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_ISA_Arithmetic_slt_no_writes_to_reg_zero;
