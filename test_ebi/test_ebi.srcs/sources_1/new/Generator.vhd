
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity Generator is
    Port ( clk : in STD_LOGIC;
           EBId : out STD_LOGIC_VECTOR (15 downto 0));
end Generator;

architecture Behavioral of Generator is
    signal counter : std_logic_vector(15 downto 0) := (others => '0');
    signal slow_counter : std_logic_vector(15 downto 0) := (others => '0');
    signal compare_value : std_logic_vector(15 downto 0) := (others => '1');
    signal next_count : std_logic_vector(15 downto 0);
    signal do_count_slow : boolean;
begin

    do_count_slow <= unsigned(counter) >= unsigned(compare_value);
    next_count <= std_logic_vector(unsigned(counter) + 1) when not do_count_slow
        else (others => '0');
        
    process(clk) is
    begin
        if(rising_edge(clk)) then
            counter <= next_count;
        end if;    
        if(rising_edge(clk) and do_count_slow) then
            slow_counter <= std_logic_vector(unsigned(slow_counter) + 1);
        end if;
    end process;
    
    EBId <= slow_counter;

end Behavioral;
