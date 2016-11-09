configuration tests_ISA_Arithmetic_slt_supports_negative_operands of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/ISA/Arithmetic/slt/supports_negative_operands/init_imem",
          DMEM_INIT_FILE             => "tests/ISA/Arithmetic/slt/supports_negative_operands/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/ISA/Arithmetic/slt/supports_negative_operands/init_exp_updates",
          LOG_FILE                   => "tests/ISA/Arithmetic/slt/supports_negative_operands/test_log",
          NUM_EXPECTED_UPDATES       => 441,
          TEST_TIMEOUT_CYCLES        => 4640);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/ISA/Arithmetic/slt/supports_negative_operands/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_ISA_Arithmetic_slt_supports_negative_operands;
