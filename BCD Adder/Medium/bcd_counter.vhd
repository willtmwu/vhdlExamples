--Continuously count every clk tick while enable is active

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bcd_counter is
port (	rst 		: in std_logic;
			en 		: in std_logic;
			-- 2 BCD Digits
			bcd_out 	: out std_logic_vector(7 downto 0);
			clk 		: in std_logic
		);
end bcd_counter;

architecture Behavioral of bcd_counter is

COMPONENT bcd_2_adder port (
			Carry_in : in std_logic;			
			Carry_out : out std_logic;
			Adig0: in STD_LOGIC_VECTOR (3 downto 0);
			Adig1: in STD_LOGIC_VECTOR (3 downto 0);
			Bdig0: in STD_LOGIC_VECTOR (3 downto 0);
			Bdig1: in STD_LOGIC_VECTOR (3 downto 0);
			Sdig0: out STD_LOGIC_VECTOR (3 downto 0);
			Sdig1: out STD_LOGIC_VECTOR (3 downto 0)
		);
end component;

--Inputs
signal digit_A : std_logic_vector (7 downto 0) := (others => '0');
signal digit_B : std_logic_vector (7 downto 0) := (others => '0');
signal carry_in : std_logic := '0';

--Outputs
signal carry_out : std_logic;
signal sum : std_logic_vector (7 downto 0);

--signal counter : std_logic_vector (7 downto 0) := (others => '0');

begin

	m1: bcd_2_adder port map(	carry_in, carry_out, 
										digit_A(3 downto 0), digit_A(7 downto 4), 
										digit_B(3 downto 0), digit_B(7 downto 4), 
										sum(3 downto 0)    , sum(7 downto 4) );

	bcd_out <= sum;
	
	process (clk, rst, en) begin
		if (rst = '1') then
			--counter <= (others => '0');
			digit_A <= (others => '0');
			carry_in <= '0';
			digit_B(0) <= '0';			
		elsif (clk'event and clk = '1') then
			digit_A <= sum;
			carry_in <= carry_out;
			if (en = '1') then
				digit_B(0) <= '1';
			else
				digit_B(0) <= '0';			
				--digit_B <= (others => '0');
			end if;
		end if;
	end process;

end Behavioral;

