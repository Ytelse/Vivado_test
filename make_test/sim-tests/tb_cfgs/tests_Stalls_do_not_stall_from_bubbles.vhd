configuration tests_Stalls_do_not_stall_from_bubbles of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/Stalls/do_not_stall_from_bubbles/init_imem",
          DMEM_INIT_FILE             => "tests/Stalls/do_not_stall_from_bubbles/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/Stalls/do_not_stall_from_bubbles/init_exp_updates",
          LOG_FILE                   => "tests/Stalls/do_not_stall_from_bubbles/test_log",
          NUM_EXPECTED_UPDATES       => 9,
          TEST_TIMEOUT_CYCLES        => 400);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/Stalls/do_not_stall_from_bubbles/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_Stalls_do_not_stall_from_bubbles;
