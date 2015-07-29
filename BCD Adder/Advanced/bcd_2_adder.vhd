library IEEE;
use IEEE.std_logic_1164.all;

entity bcd_2_adder is
    port (
			Carry_in : in std_logic;			
			Carry_out : out std_logic;
			Adig0: in STD_LOGIC_VECTOR (3 downto 0);
			Adig1: in STD_LOGIC_VECTOR (3 downto 0);
			Bdig0: in STD_LOGIC_VECTOR (3 downto 0);
			Bdig1: in STD_LOGIC_VECTOR (3 downto 0);
			Sdig0: out STD_LOGIC_VECTOR (3 downto 0);
			Sdig1: out STD_LOGIC_VECTOR (3 downto 0)
		);
end bcd_2_adder;

architecture bcd_2_adder_arch of bcd_2_adder is

COMPONENT bcd_1_adder  port (
        A: in STD_LOGIC_VECTOR (3 downto 0);
        B: in STD_LOGIC_VECTOR (3 downto 0);
        C_IN: in STD_LOGIC;
        SUM: out STD_LOGIC_VECTOR (3 downto 0);
        C_OUT: out STD_LOGIC
    );
end component;

signal C_out1 : std_logic := '0';

BEGIN 

u1: bcd_1_adder PORT MAP(Adig0, Bdig0, Carry_in, Sdig0, C_out1);
u2: bcd_1_adder PORT MAP(Adig1, Bdig1, C_out1, Sdig1, Carry_out);

end bcd_2_adder_arch;
