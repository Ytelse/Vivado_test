configuration tests_Flush_flush_avoids_branches of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/Flush/flush_avoids_branches/init_imem",
          DMEM_INIT_FILE             => "tests/Flush/flush_avoids_branches/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/Flush/flush_avoids_branches/init_exp_updates",
          LOG_FILE                   => "tests/Flush/flush_avoids_branches/test_log",
          NUM_EXPECTED_UPDATES       => 162,
          TEST_TIMEOUT_CYCLES        => 2150);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/Flush/flush_avoids_branches/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_Flush_flush_avoids_branches;
