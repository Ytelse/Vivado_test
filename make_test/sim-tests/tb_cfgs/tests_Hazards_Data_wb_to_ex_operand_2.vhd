configuration tests_Hazards_Data_wb_to_ex_operand_2 of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "tests/Hazards/Data/wb_to_ex_operand_2/init_imem",
          DMEM_INIT_FILE             => "tests/Hazards/Data/wb_to_ex_operand_2/init_dmem",
          EXPECTED_UPDATES_INIT_FILE => "tests/Hazards/Data/wb_to_ex_operand_2/init_exp_updates",
          LOG_FILE                   => "tests/Hazards/Data/wb_to_ex_operand_2/test_log",
          NUM_EXPECTED_UPDATES       => 69,
          TEST_TIMEOUT_CYCLES        => 1290);
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
          for Pipelined
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "tests/Hazards/Data/wb_to_ex_operand_2/init_regfile",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration tests_Hazards_Data_wb_to_ex_operand_2;
