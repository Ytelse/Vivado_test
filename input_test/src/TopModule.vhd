library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TopModule is
    Port (
          --Should connect out of board to ulpi interface
          ULPI_data : inout std_logic_vector (7 downto 0);
          ULPI_clk : in std_logic;
          ULPI_dir : in std_logic;
          ULPI_nxt : in std_logic;
          ULPI_rst : in std_logic;
          ULPI_stp : out std_logic;
          
          led : out std_logic_vector(7 downto 0)
          );
end TopModule;

architecture Behavioral of TopModule is
    signal RX_ready : std_logic;
    signal RX_value : std_logic;
    signal RX_data : std_logic_vector(7 downto 0);
    signal RX_len : std_logic_vector(10 downto 0);
    
    signal reset : std_logic;
    signal USB_reset : std_logic;
    signal high_speed : std_logic;
    signal suspend : std_logic;
    signal online : std_logic;
    
    -- Internal signal
    signal data_buf : std_logic_vector(7 downto 0);
begin
    
    process(ULPI_clk) is
    begin
        if(rising_edge(ULPI_clk)) then
            -- Only read data when the value signal is high
            if(RX_value = '1') then
                -- Copy data to register
                data_buf <= RX_data;
            end if;
        end if;
    end process; 
    
    reset <= '0';
    RX_ready <= '1'; -- Always want data
    
    led <= data_buf;
    
    input_module_inst : entity work.InputModule
        port map(
            ULPI_data => ULPI_data,
            ULPI_clk => ULPI_clk,
            ULPI_dir => ULPI_dir,
            ULPI_nxt => ULPI_nxt,
            ULPI_rst => ULPI_rst,
            ULPI_stp => ULPI_stp,
            
            -- Control signals. Should connect to fpga read module
            RX_ready => RX_ready,
            RX_value => RX_value,
            RX_data => RX_data,
            RX_len => RX_len,
            
            reset => reset,
            USB_reset => USB_reset,
            high_speed => high_speed,
            suspend => suspend,
            online => online
            );
    
    
end Behavioral;
