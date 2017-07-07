library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY test_bcd_counter IS
END test_bcd_counter;
 
ARCHITECTURE behavior OF test_bcd_counter IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT bcd_counter
    PORT(
         rst 		: IN  std_logic;
         en 		: IN  std_logic;
         bcd_out 	: OUT  std_logic_vector(7 downto 0);
         clk 		: IN  std_logic
        );
    END COMPONENT;
	 
   --Inputs
   signal rst 	: std_logic := '0';
   signal clk 	: std_logic := '0';
	signal en 	: std_logic := '1';
	
 	--Outputs
   signal bcd_out : std_logic_vector(7 downto 0)  := (others => '0');

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
	--Internal Signals
	signal counter_check : std_logic_vector(7 downto 0) := (others => '0');
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: bcd_counter PORT MAP (
          rst => rst,
          en => en,
          bcd_out => bcd_out,
          clk => clk
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
   process (clk) begin		
		if (clk'event and clk = '1') then
			counter_check <= counter_check + '1';
			
			if (counter_check = "00000111") then
				assert (bcd_out = "00000111") report "Test Case 1" severity error;
			elsif (counter_check = "00101111") then
				assert (bcd_out = "00100111") report "Test Case 2" severity error;
			end if;
	

		end if;
   end process;

END;
