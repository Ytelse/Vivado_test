configuration tests_ISA_Arithmetic_addiu_sign_extends_immediate of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/ISA/Arithmetic/addiu/sign_extends_immediate/init_imem",
          DMEM_INIT_FILE             => "tests/ISA/Arithmetic/addiu/sign_extends_immediate/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/ISA/Arithmetic/addiu/sign_extends_immediate/init_exp_updates",
          LOG_FILE                   => "tests/ISA/Arithmetic/addiu/sign_extends_immediate/test_log",
          NUM_EXPECTED_UPDATES       => 231,
          TEST_TIMEOUT_CYCLES        => 2540);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/ISA/Arithmetic/addiu/sign_extends_immediate/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_ISA_Arithmetic_addiu_sign_extends_immediate;
