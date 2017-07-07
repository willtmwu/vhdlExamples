LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
 
ENTITY test_pwm IS
END test_pwm;
 
ARCHITECTURE behavior OF test_pwm IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT pwm
    PORT(
         clk : IN  std_logic;
         masterReset : IN  std_logic;
         en : IN  std_logic;
         duty : IN  std_logic_vector(7 downto 0);
         pwm_out : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal masterReset : std_logic := '0';
   signal en : std_logic := '0';
   signal duty : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal pwm_out : std_logic;

   -- Clock period definitions
   constant clk_period : time := 1 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: pwm 

	PORT MAP (
          clk => clk,
          masterReset => masterReset,
          en => en,
          duty => duty,
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
		en <= '1';
		wait for clk_period*1;
		duty <= "00011111";
		wait for clk_period*2;
		en <= '0';
		wait for clk_period*100;
		
		en <= '1';
		wait for clk_period*1;
		duty <= "10001000";
		wait for clk_period*5;
		en <= '0';
		wait for clk_period*100;
		
		en <= '1';
		wait for clk_period*1;
		duty <= "11111100";
		wait for clk_period*1;
		en <= '0';
		wait for clk_period*100;
		
		en <= '1';
		wait for clk_period*1;
		duty <= "00000010";
		wait for clk_period*1;
		en <= '0';
		wait for clk_period*100;
		
		en <= '1';
		wait for clk_period*1;
		duty <= "00000001";
		wait for clk_period*1;
		en <= '0';
		wait for clk_period*100;
      wait;
		
   end process;

END;
