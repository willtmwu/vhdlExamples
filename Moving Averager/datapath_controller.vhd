library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity datapath_controller is
    Port ( 	window_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
				masterReset : in STD_LOGIC;
				
				mem_addr 	: OUT  STD_LOGIC_VECTOR(5 downto 0);
				window_val : OUT  std_logic_vector(1 downto 0);
				overflow : IN  std_logic;
				
				clk : in  STD_LOGIC
				);
end datapath_controller;

architecture Behavioral of datapath_controller is
	signal counter : std_logic_vector (5 downto 0) := (others => '0');
begin
	mem_addr <= counter;
	process (masterReset, clk ) begin
		if (masterReset = '1') then
			counter <= (others => '0');
			window_val <= "01";
		elsif (clk'event and clk = '1') then
			counter <= counter + '1';
			window_val <= window_ctrl;
		end if;
	end process;
	
end Behavioral;

