configuration Top_cfg of Top is
  for Behavioural
    for all : MIPSSystem
      use entity work.MIPSSystem
        generic map (
          GREEN_LED_PATTERN => "0000",
          BLUE_LED_PATTERN  => "1111",
          RED_LED_PATTERN   => "0000");
      for Behavioural
        for all : MIPSProcessor
          use entity work.MIPSProcessor(Pipelined);
        end for;
      end for;
    end for;
  end for;
end configuration Top_cfg;
