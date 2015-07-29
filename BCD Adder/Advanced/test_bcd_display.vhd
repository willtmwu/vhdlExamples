library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

ENTITY test_bcd_display IS
END test_bcd_display;
 
ARCHITECTURE behavior OF test_bcd_display IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT bcd_display
    PORT(
         clk : in std_logic;
			masterReset : in std_logic;
			byte_in : in  STD_LOGIC_VECTOR(7 downto 0);
			bcd_val : out  STD_LOGIC_VECTOR(11 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal masterReset : std_logic := '0';
   signal byte_in : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal bcd_val : std_logic_vector(11 downto 0) := (others => '0');

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: bcd_display PORT MAP (
          clk => clk,
          masterReset => masterReset,
          byte_in => byte_in,
          bcd_val => bcd_val
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
   process (masterReset, clk) begin		 
		if (masterReset = '1') then
			byte_in <= (others => '0');
		elsif (clk'event and clk = '1') then	
			byte_in <= byte_in + '1';
		end if;	
   end process;

END;
