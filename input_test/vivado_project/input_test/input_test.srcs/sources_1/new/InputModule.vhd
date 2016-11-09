----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/03/2016 12:26:53 PM
-- Design Name: 
-- Module Name: TopModule - Behavioral
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
use work.usb_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity InputModule is
    generic (
        RXBUFSIZE_BITS: integer range 7 to 12 := 11;
        TXBUFSIZE_BITS: integer range 7 to 12 := 10 );
        
    Port (
          --Should connect out of board to ulpi interface
          ULPI_data : inout std_logic_vector (7 downto 0);
          ULPI_clk : in std_logic;
          ULPI_dir : in std_logic;
          ULPI_nxt : in std_logic;
          ULPI_rst : in std_logic;
          ULPI_stp : out std_logic;
          
          -- Control signals. Should connect to fpga read module
          RX_ready : in std_logic;
          RX_value : out std_logic;
          RX_data : out std_logic_vector(7 downto 0);
          RX_len : out std_logic_vector(RXBUFSIZE_BITS - 1 downto 0);
          
          --Control signals that are not directly involved in the protocol. Should probably be constants
          reset : in std_logic;
          USB_reset : out std_logic;
          high_speed : out std_logic;
          suspend : out std_logic;
          online : out std_logic
          );
end InputModule;

architecture Behavioral of InputModule is
    signal ULPIstpout : std_logic;
    signal ULPI_data_in : std_logic_vector(7 downto 0);
    signal ULPI_data_out : std_logic_vector(7 downto 0);
    
    signal a : std_logic_vector(7 downto 0);
    signal b : std_logic_vector(7 downto 0);
    
    --utmi signals
    
    signal utmi_txvalid_i : std_logic;
    signal utmi_txready_o : std_logic;
    signal utmi_rxvalid_o : std_logic;
    signal utmi_rxactive_o : std_logic;
    signal utmi_rxerror_o : std_logic;
    signal utmi_data_o : std_logic_vector(7 downto 0);
    signal utmi_data_i : std_logic_vector(7 downto 0);  
    signal utmi_xcvrselect_i : std_logic_vector(1 downto 0);
    signal utmi_termselect_i : std_logic;
    signal utmi_opmode_i : std_logic_vector(1 downto 0);
    signal utmi_dppulldown_i : std_logic := '0';
    signal utmi_dmpulldown_i : std_logic := '0';
    signal utmi_linestate_o : std_logic_vector(1 downto 0);

    signal txval : std_logic := '0';
    signal txdat : std_logic_vector(7 downto 0) := (others => '0');
    signal txrdy : std_logic;
    signal txroom : std_logic_vector(TXBUFSIZE_BITS - 1 downto 0);
    signal txcork : std_logic := '0';
    signal phy_reset : std_logic;

    signal do_highspeed : std_logic := '0';

    --Unused signals
    signal reg_addr_i : std_logic_vector(7 downto 0) := (others => '0');
    signal reg_stb_i : std_logic := '0';
    signal reg_we_i : std_logic := '0';
    signal reg_data_i : std_logic_vector(7 downto 0) := (others => '0');
    
    component ulpi_wrapper is
        port(
        ulpi_clk60_i : in std_logic;
        ulpi_rst_i : in std_logic;
        ulpi_data_i : in std_logic_vector(7 downto 0);
        ulpi_data_o : out std_logic_vector(7 downto 0);
        ulpi_dir_i : in std_logic;
        ulpi_nxt_i : in std_logic;
        ulpi_stp_o : out std_logic;
        
        reg_addr_i : in std_logic_vector(7 downto 0);
        reg_stb_i : in std_logic;
        reg_we_i : in std_logic;
        reg_data_i : in std_logic_vector(7 downto 0);
        reg_data_o : out std_logic_vector(7 downto 0);
        reg_ack_o : out std_logic;
        
        utmi_txvalid_i : in std_logic;
        utmi_txready_o : out std_logic;
        utmi_rxvalid_o : out std_logic;
        utmi_rxactive_o : out std_logic;
        utmi_rxerror_o : out std_logic;
        utmi_data_o : out std_logic_vector(7 downto 0);
        utmi_data_i : in std_logic_vector(7 downto 0);  
        utmi_xcvrselect_i : in std_logic_vector(1 downto 0);
        utmi_termselect_i : in std_logic;
        utmi_opmode_i : in std_logic_vector(1 downto 0);
        utmi_dppulldown_i : in std_logic;
        utmi_dmpulldown_i : in std_logic;
        utmi_linestate_o : out std_logic_vector(1 downto 0)
        
        );
    end component;
    
begin

    high_speed <= do_highspeed;
    utmi_xcvrselect_i(1) <= '0';
    txcork <= '0';
    
    process (ULPI_clk)
    begin
        if(ULPI_clk = '1' and ULPI_clk'event) then
            a <= ulpi_data_out;
            ulpi_data_in <= b;
        end if;
    end process;
    process(ULPI_dir, ULPI_data, a)
    begin 
        if(not (ULPI_dir = '0')) then
            ULPI_data <= "ZZZZZZZZ";
            b <= ULPI_data;
        else
            ULPI_data <= a;
            b <= ULPI_data;
        end if;
    end process;

    ulpi_wrapper_inst : ulpi_wrapper 
        port map (
            ulpi_clk60_i => ULPI_clk,
            ulpi_rst_i => ULPI_rst,
            ulpi_data_i => ULPI_data_in,
            ulpi_data_o => ULPI_data_out,
            ulpi_dir_i => ULPI_dir,
            ulpi_nxt_i => ULPI_nxt,
            ulpi_stp_o => ULPI_stp,
            
            reg_addr_i => reg_addr_i,
            reg_stb_i => reg_stb_i,
            reg_we_i => reg_we_i,
            reg_data_i => reg_data_i,
            
            utmi_txvalid_i => utmi_txvalid_i,
            utmi_txready_o => utmi_txready_o,
            utmi_rxvalid_o => utmi_rxvalid_o,
            utmi_rxactive_o => utmi_rxactive_o,
            utmi_rxerror_o => utmi_rxerror_o,
            utmi_data_o => utmi_data_o,
            utmi_data_i => utmi_data_i,
            utmi_xcvrselect_i => utmi_xcvrselect_i,
            utmi_termselect_i => utmi_termselect_i,
            utmi_opmode_i => utmi_opmode_i,
            utmi_dppulldown_i => utmi_dppulldown_i,
            utmi_dmpulldown_i => utmi_dmpulldown_i,
            utmi_linestate_o => utmi_linestate_o
        );
    
    usb_serial_inst : entity work.usb_serial
        port map(
            CLK => ULPI_clk,
            RESET => reset,
            USBRST => USB_reset,
            HIGHSPEED => do_highspeed,           --TODO this is hardcoded
            SUSPEND => suspend,
            ONLINE => online,
            RXVAL => RX_value,
            RXDAT => RX_data,
            RXRDY => RX_ready,
            RXLEN => RX_len,
            TXVAL => txval,
            TXDAT => txdat,
            TXRDY => txrdy,
            TXROOM => txroom,
            TXCORK => txcork,
    
            PHY_DATAIN => utmi_data_o,
            PHY_DATAOUT => utmi_data_i,
            PHY_TXVALID => utmi_txvalid_i,
            PHY_TXREADY => utmi_txready_o,
            PHY_RXACTIVE => utmi_rxactive_o,
            PHY_RXVALID => utmi_rxvalid_o,
            PHY_RXERROR => utmi_rxerror_o,
            PHY_LINESTATE => utmi_linestate_o,
            PHY_OPMODE => utmi_opmode_i,
            PHY_XCVRSELECT => utmi_xcvrselect_i(0),
            PHY_TERMSELECT => utmi_termselect_i,
            PHY_RESET => phy_reset);

end Behavioral;
