configuration tests_Flush_flush_avoids_memory_writes of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/Flush/flush_avoids_memory_writes/init_imem",
          DMEM_INIT_FILE             => "tests/Flush/flush_avoids_memory_writes/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/Flush/flush_avoids_memory_writes/init_exp_updates",
          LOG_FILE                   => "tests/Flush/flush_avoids_memory_writes/test_log",
          NUM_EXPECTED_UPDATES       => 8,
          TEST_TIMEOUT_CYCLES        => 660);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/Flush/flush_avoids_memory_writes/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_Flush_flush_avoids_memory_writes;
