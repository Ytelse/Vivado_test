library IEEE;
library UNISIM;

use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use UNISIM.vcomponents.all;

use work.framework_util.all;

entity Top is
  port (
    -- We do not use the 100 MHz clock, other than to generate the 25 MHz
    -- 'clk' signal using the constraints file.
    CLK100MHZ : in std_logic;

    -- The red reset button is active-low. We convert it to active-high before
    -- passing it on to user logic.
    rst_active_low : in  std_logic;
    -- interface towards the UART ports
    UART_Rx        : in  std_logic;
    UART_Tx        : out std_logic;
    -- LED output
    leds           : out std_logic_vector (3 downto 0);
    blue_leds      : out std_logic_vector (3 downto 0);
    red_leds       : out std_logic_vector (3 downto 0);
    green_leds     : out std_logic_vector (3 downto 0);
    -- We use the board switches to control the light intensity.
    switches       : in  std_logic_vector(3 downto 0));
end Top;

architecture Behavioural of Top is
  -- Processor reset signal, active high, derived from button press input.
  signal reset : std_logic;

  -- Signals used to generate the processor design clock.
  signal clk          : std_logic;
  signal feedback_clk : std_logic;

  -- Processor-controlled coloured LED signals.
  -- The coloured LEDs are !@#$ strong, so we dim their light intensity by only
  -- keeping them activity every Xth cycle (configured by the on-board switches).
  signal green_leds_value       : std_logic_vector(3 downto 0);
  signal blue_leds_value        : std_logic_vector(3 downto 0);
  signal red_leds_value         : std_logic_vector(3 downto 0);
  signal colour_led_dimming     : natural;
  signal colour_leds_disabled   : std_logic;
  signal dim_timer              : unsigned(11 downto 0) := (others => '0');
  signal colour_led_dim_timeout : unsigned(11 downto 0);

  -- Specify that we want to keep all the led output registers, to avoid
  -- warnings during Synthesis in Vivado.
  attribute keep               : string;
  attribute keep of blue_leds  : signal is "true";
  attribute keep of red_leds   : signal is "true";
  attribute keep of green_leds : signal is "true";

  -- Yellow LED status signals.
  signal prev_uart_rx                       : std_logic;
  signal prev_uart_tx                       : std_logic;
  signal activity_on_uart_rx                : std_logic;
  signal activity_on_uart_tx                : std_logic;
  signal retain_uart_rx_activity_led_timer  : natural;
  signal retain_uart_tx_activity_led_timer  : natural;
  constant RETAIN_UART_ACTIVITY_LED_TIMEOUT : natural := 25000000;

  signal uart_tx_sniffer : std_logic;
begin

  ------------------------------------------------------------------------------
  -- Instantiate the processor.

  reset <= not rst_active_low;

  MIPSSystem_1 : MIPSSystem
    port map (
      clk          => clk,
      reset        => reset,
      UART_Rx      => UART_Rx,
      UART_Tx      => uart_tx_sniffer,
      proc_enabled => leds(2),
      blue_leds    => blue_leds_value,
      green_leds   => green_leds_value,
      red_leds     => red_leds_value);

  UART_Tx <= uart_tx_sniffer;

  ------------------------------------------------------------------------------
  -- Create a slower clock from the 100 MHz input clock.
  MMCME2_BASE_inst : MMCME2_BASE
    generic map (
      -- Input clock period in ns: 10 ns => 100 MHz.
      CLKIN1_PERIOD   => 10.0,
      -- Multiply by 8 so input freq. is sufficiently high for the MMCME.
      CLKFBOUT_MULT_F => 8.0,
      -- Divide by 32 => Freq. is 25 MHz
      CLKOUT1_DIVIDE  => 32
      )
    port map (
      CLKOUT1  => clk,
      CLKFBOUT => feedback_clk,
      CLKIN1   => CLK100MHZ,
      CLKFBIN  => feedback_clk,
      PWRDWN   => '0',
      RST      => '0'
      );

  ------------------------------------------------------------------------------
  -- Detect activity on the UART Rx/Tx wires.
  process (clk) is
  begin
    if rising_edge(clk) then
      prev_uart_rx <= UART_Rx;
      prev_uart_tx <= uart_tx_sniffer;
    end if;
  end process;

  process (clk) is
  begin
    if rising_edge(clk) then
      if UART_Rx /= prev_uart_rx then
        activity_on_uart_rx               <= '1';
        retain_uart_rx_activity_led_timer <= 0;
      elsif activity_on_uart_rx = '1' then
        if retain_uart_rx_activity_led_timer = RETAIN_UART_ACTIVITY_LED_TIMEOUT then
          activity_on_uart_rx               <= '0';
          retain_uart_rx_activity_led_timer <= 0;
        else
          retain_uart_rx_activity_led_timer <= retain_uart_rx_activity_led_timer + 1;
        end if;
      end if;
    end if;
  end process;

  process (clk) is
  begin
    if rising_edge(clk) then
      if uart_tx_sniffer /= prev_uart_tx then
        activity_on_uart_tx               <= '1';
        retain_uart_tx_activity_led_timer <= 0;
      elsif activity_on_uart_tx = '1' then
        if retain_uart_tx_activity_led_timer = RETAIN_UART_ACTIVITY_LED_TIMEOUT then
          activity_on_uart_tx               <= '0';
          retain_uart_tx_activity_led_timer <= 0;
        else
          retain_uart_tx_activity_led_timer <= retain_uart_tx_activity_led_timer + 1;
        end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- drive the yellow status LEDs. The second LED is controlled by the
  -- processor, indicating whether or not it is enabled.
  leds(3)          <= reset;
  leds(1) <= activity_on_uart_rx;
  leds(0) <= activity_on_uart_tx;

  ------------------------------------------------------------------------------
  -- Dim the coloured LEDs.

  -- Invert the switches to indicate dimming: all switches in default position
  -- is minimal intensity => maximal dimming.
  colour_led_dimming <= natural(to_integer(unsigned(not(switches(2 downto 0)))));

  -- Set the dim timeout value to (2**dim)*16:
  --   if dim = 0b000, dim timeout = 0
  --   if dim = 0b111, dim timeout = 2048
  colour_led_dim_timeout <= shift_left(unsigned'(x"01"), colour_led_dimming) & x"0";
  colour_leds_disabled   <= switches(3);

  --- Dim the coloured LED output.
  process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        dim_timer  <= (others => '0');
        blue_leds  <= (others => '0');
        green_leds <= (others => '0');
        red_leds   <= (others => '0');
      else
        if colour_leds_disabled = '1' or dim_timer /= colour_led_dim_timeout then
          blue_leds  <= (others => '0');
          green_leds <= (others => '0');
          red_leds   <= (others => '0');
        else
          blue_leds  <= blue_leds_value;
          green_leds <= green_leds_value;
          red_leds   <= red_leds_value;
        end if;

        if dim_timer = colour_led_dim_timeout then
          dim_timer <= (others => '0');
        else
          dim_timer <= dim_timer + 1;
        end if;
      end if;
    end if;
  end process;

end Behavioural;
