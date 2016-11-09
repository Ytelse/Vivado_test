configuration tests_Flush_no_inadvertent_flushes of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/Flush/no_inadvertent_flushes/init_imem",
          DMEM_INIT_FILE             => "tests/Flush/no_inadvertent_flushes/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/Flush/no_inadvertent_flushes/init_exp_updates",
          LOG_FILE                   => "tests/Flush/no_inadvertent_flushes/test_log",
          NUM_EXPECTED_UPDATES       => 53,
          TEST_TIMEOUT_CYCLES        => 1080);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/Flush/no_inadvertent_flushes/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_Flush_no_inadvertent_flushes;
