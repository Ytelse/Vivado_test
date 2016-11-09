configuration tests_ISA_Memory_sw_basic_address_calculation of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/ISA/Memory/sw/basic_address_calculation/init_imem",
          DMEM_INIT_FILE             => "tests/ISA/Memory/sw/basic_address_calculation/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/ISA/Memory/sw/basic_address_calculation/init_exp_updates",
          LOG_FILE                   => "tests/ISA/Memory/sw/basic_address_calculation/test_log",
          NUM_EXPECTED_UPDATES       => 19,
          TEST_TIMEOUT_CYCLES        => 410);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/ISA/Memory/sw/basic_address_calculation/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_ISA_Memory_sw_basic_address_calculation;
