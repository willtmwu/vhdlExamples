LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.std_logic_arith.all; 
 
ENTITY test_fetch_register IS
END test_fetch_register;
 
ARCHITECTURE behavior OF test_fetch_register IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT fetch_register
    PORT(
         mem_addr : IN  std_logic_vector(5 downto 0);
         mem_amount : IN  std_logic_vector(4 downto 0);
         reg_val : OUT  std_logic_vector(127 downto 0);
         masterReset : IN  std_logic;
         clk : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal mem_addr : std_logic_vector(5 downto 0) := (others => '0');
   signal mem_amount : std_logic_vector(4 downto 0) := (others => '0');
   signal masterReset : std_logic := '0';
   signal clk : std_logic := '0';

 	--Outputs
   signal reg_val : std_logic_vector(127 downto 0) := (others => '0');

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
   uut: fetch_register PORT MAP (
          mem_addr => mem_addr,
          mem_amount => mem_amount,
          reg_val => reg_val,
          masterReset => masterReset,
          clk => clk
        );

   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

	mem_addr <= std_logic_vector(ieee.numeric_std.to_unsigned(44, 6));
	mem_amount <= std_logic_vector(ieee.numeric_std.to_unsigned(8, 5));

   -- Stimulus process
   stim_proc: process
   begin		

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
