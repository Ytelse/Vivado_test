----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2016 04:38:14 PM
-- Design Name: 
-- Module Name: TopUlpiTest - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TopUlpiTest is
    Port (ULPI_data : in std_logic_vector(7 downto 0);
          ULPI_clk : in std_logic;
          ULPI_dir : in std_logic;
          ULPI_nxt : in std_logic;
          ULPI_rst : in std_logic;
          ULPI_stp : out std_logic;
          
          LED_array : out std_logic_vector(7 downto 0));
end TopUlpiTest;

architecture Behavioral of TopUlpiTest is

begin

    ULPI_stp <= '0';
    
    LED_array(7) <= ULPI_clk;
    LED_array(6) <= ULPI_dir;
    LED_array(5) <= ULPI_nxt;
    LED_array(4) <= ULPI_rst;
    LED_array(3 downto 0) <= ULPI_data (3 downto 0);
    
end Behavioral;
