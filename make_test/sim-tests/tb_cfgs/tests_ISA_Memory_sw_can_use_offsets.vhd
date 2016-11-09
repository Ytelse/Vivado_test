configuration tests_ISA_Memory_sw_can_use_offsets of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/ISA/Memory/sw/can_use_offsets/init_imem",
          DMEM_INIT_FILE             => "tests/ISA/Memory/sw/can_use_offsets/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/ISA/Memory/sw/can_use_offsets/init_exp_updates",
          LOG_FILE                   => "tests/ISA/Memory/sw/can_use_offsets/test_log",
          NUM_EXPECTED_UPDATES       => 22,
          TEST_TIMEOUT_CYCLES        => 440);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/ISA/Memory/sw/can_use_offsets/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_ISA_Memory_sw_can_use_offsets;
