LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY test_led_bright IS
END test_led_bright;
 
ARCHITECTURE behavior OF test_led_bright IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT led_bright
    PORT(
         clk : IN  std_logic;
         masterReset : IN  std_logic;
         ready : IN  std_logic;
         accel_val : IN  std_logic_vector(7 downto 0);
         pwm_out : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal masterReset : std_logic := '0';
   signal ready : std_logic := '0';
   signal accel_val : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal pwm_out : std_logic;

   -- Clock period definitions
   constant clk_period : time := 1 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: led_bright PORT MAP (
          clk => clk,
          masterReset => masterReset,
          ready => ready,
          accel_val => accel_val,
          pwm_out => pwm_out
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		ready <= '0';
		wait for clk_period*5;
		
		accel_val <= "00011111";
		ready <= '1';
		
		wait for clk_period*100;
		ready <= '0';
		wait for clk_period*5;
		
		accel_val <= "10001000";
		ready <= '1';
		
		wait for clk_period*100;
		ready <= '0';
		wait for clk_period*5;
		
		accel_val <= "11111100";
		ready <= '1';
		
		wait for clk_period*100;
		ready <= '0';
		wait for clk_period*5;
		
      wait;
   end process;

END;
