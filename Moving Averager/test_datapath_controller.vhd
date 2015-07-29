LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY test_datapath_controller IS
END test_datapath_controller;
 
ARCHITECTURE behavior OF test_datapath_controller IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT datapath_controller
    PORT(
         window_ctrl : IN  std_logic_vector(1 downto 0);
         masterReset : IN  std_logic;
			mem_addr 	: OUT  STD_LOGIC_VECTOR(5 downto 0);
			window_val : OUT  std_logic_vector(1 downto 0);
			overflow : IN  std_logic;
         clk : IN  std_logic
        );
    END COMPONENT;
	 
   signal window_ctrl : std_logic_vector(1 downto 0) := (others => '0');
   signal masterReset : std_logic := '0';
   signal mem_addr : std_logic_vector(5 downto 0) := (others => '0');
   signal window_val : std_logic_vector(1 downto 0) := (others => '0');
   signal clk : std_logic := '0';
   signal overflow : std_logic := '0';

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: datapath_controller PORT MAP (
          window_ctrl => window_ctrl,
          masterReset => masterReset,
          mem_addr => mem_addr,
          window_val => window_val,
          overflow => overflow,
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
   stim_proc: process (clk) begin		
		if (clk'event and clk = '1') then
		
		
		end if;
		
   end process;

END;
