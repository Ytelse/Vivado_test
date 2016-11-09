configuration tests_ISA_Control_jr_calculates_correct_branch_target of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/ISA/Control/jr/calculates_correct_branch_target/init_imem",
          DMEM_INIT_FILE             => "tests/ISA/Control/jr/calculates_correct_branch_target/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/ISA/Control/jr/calculates_correct_branch_target/init_exp_updates",
          LOG_FILE                   => "tests/ISA/Control/jr/calculates_correct_branch_target/test_log",
          NUM_EXPECTED_UPDATES       => 78,
          TEST_TIMEOUT_CYCLES        => 870);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/ISA/Control/jr/calculates_correct_branch_target/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_ISA_Control_jr_calculates_correct_branch_target;
