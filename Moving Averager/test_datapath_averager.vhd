library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

ENTITY test_datapath_averager IS
END test_datapath_averager;
 
ARCHITECTURE behavior OF test_datapath_averager IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT datapath_averager
    PORT(
         mem_addr 	: IN  STD_LOGIC_VECTOR(5 downto 0);
         window_val : IN  std_logic_vector(1 downto 0);
         overflow : OUT  std_logic;
         clk : IN  std_logic;
         masterReset : IN  std_logic;
			input_val : OUT  std_logic_vector(7 downto 0);
         average_val : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal mem_addr : std_logic_vector( 5 downto 0) := "000000";
   signal window_val : std_logic_vector(1 downto 0) := (others => '0');
   signal clk : std_logic := '0';
   signal masterReset : std_logic := '0';

	--BiDirs
   signal overflow : std_logic := '0';

 	--Outputs
	signal input_val : std_logic_vector(7 downto 0) := (others => '0');
   signal average_val : std_logic_vector(7 downto 0) := (others => '0');

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
	signal counter : std_logic_vector( 5 downto 0)  := (others => '0');
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: datapath_averager PORT MAP (
          mem_addr => mem_addr,
          window_val => window_val,
          overflow => overflow,
          clk => clk,
          masterReset => masterReset,
			 input_val => input_val,
          average_val => average_val
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
	--mem_addr <= "000001";
	mem_addr <= counter;
	window_val <= "01";

   -- Stimulus process
   stim_proc: process (clk) begin	
		if (masterReset = '1') then 
			counter <= (others => '0');
		elsif (clk'event and clk = '1') then
			counter <= counter + '1';
		end if;
   end process;
	
	process begin		
		wait for clk_period*10;
		masterReset <= '1';
		wait until CLK'event and CLK='1';
		
		masterReset <= '1';
		
		
		wait for clk_period*3;
		
		masterReset <= '0';
		wait until CLK'event and CLK='1';
		masterReset <= '0';
		
		wait for clk_period*50;
			
   end process;



END;
