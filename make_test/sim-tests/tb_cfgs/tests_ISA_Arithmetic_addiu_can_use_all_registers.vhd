configuration tests_ISA_Arithmetic_addiu_can_use_all_registers of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/ISA/Arithmetic/addiu/can_use_all_registers/init_imem",
          DMEM_INIT_FILE             => "tests/ISA/Arithmetic/addiu/can_use_all_registers/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/ISA/Arithmetic/addiu/can_use_all_registers/init_exp_updates",
          LOG_FILE                   => "tests/ISA/Arithmetic/addiu/can_use_all_registers/test_log",
          NUM_EXPECTED_UPDATES       => 32,
          TEST_TIMEOUT_CYCLES        => 550);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/ISA/Arithmetic/addiu/can_use_all_registers/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_ISA_Arithmetic_addiu_can_use_all_registers;
