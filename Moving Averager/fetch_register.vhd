library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity fetch_register is
    Port ( mem_addr 			: in  STD_LOGIC_VECTOR(5 downto 0);
           mem_amount 		: in  STD_LOGIC_VECTOR(4 downto 0);
           --reg_val_lower 	: out  STD_LOGIC_VECTOR(64 downto 0);
			  --reg_val_upper 	: out  STD_LOGIC_VECTOR(64 downto 0);
			  reg_val 			: out  STD_LOGIC_VECTOR(127 downto 0);
			  masterReset 		: in STD_LOGIC;
			  clk 				: in STD_LOGIC
			  );
end fetch_register;

architecture Behavioral of fetch_register is

type RAM is array (0 to 63) of integer range 0 to 255; 
signal V : RAM := (	12, 23, 222, 12, 231,42, 56, 121, 78,76,
							23, 119, 12, 45, 55,100, 21, 3, 96, 34,
							67, 1,1, 54, 133,55, 0, 5, 88, 64,
							88, 123, 123, 24, 133,99, 25, 44, 98, 66,
							200, 255, 20, 45, 255,255, 255, 255, 255, 54,
							1, 251, 49, 234, 77,23, 33, 94, 66, 88,
							222,12, 73, 75 );

begin

process (masterReset, clk) 

	variable address : integer range 0 to 64;
	variable temp : std_logic_vector(127 downto 0);
begin
	if (masterReset = '1') then
		--reg_val_lower <= (others => '0');
		--reg_val_upper <= (others => '0');
		reg_val <= (others => '0');
	elsif (clk'event and clk = '1') then
		temp := (others => '0');
		for I in 0 to conv_integer( IEEE.std_logic_arith.unsigned(mem_amount-1)) loop
			--lowerAddr := 8*I;
			--upperAddr := lowerAddr + 7;			
			address := conv_integer( IEEE.std_logic_arith.unsigned(mem_addr));
			temp( (8*I + 7) downto 8*I) := std_logic_vector(IEEE.numeric_std.to_unsigned(V(address + I), 8));
			--counter := counter + 1;
		end loop;
		reg_val <= temp;
	end if;
end process;

end Behavioral;