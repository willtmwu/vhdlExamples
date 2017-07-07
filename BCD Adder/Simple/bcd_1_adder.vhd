library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity bcd_1_adder is
    port (
        A: in STD_LOGIC_VECTOR (3 downto 0);
        B: in STD_LOGIC_VECTOR (3 downto 0);
        C_IN: in STD_LOGIC;
        SUM: out STD_LOGIC_VECTOR (3 downto 0);
        C_OUT: out STD_LOGIC
    );
end bcd_1_adder;

--algorithm 
-- If A + B <= 9 then -- assume both A and B are valid BCD numbers 
-- RESULT = A + B ; 
-- CARRY = 0 ; 
-- else 
-- RESULT = A + B + 6 ; 
-- CARRY = 1; 
-- end if ; 

architecture bcd_1_adder_arch of bcd_1_adder is
begin
	--BCD adder logic
	process (A,B,C_IN) 
		variable temp : std_logic_vector(3 downto 0);
		variable overflow : boolean;
		begin
		temp := A + B + C_IN;
		overflow := A(0) and B(0) and A(1) and B(1) and A(2) and B(2) and A(3) and B(3) and C_IN;

		if (temp <= 9) then		
			SUM <= temp + overflow*6;
			C_OUT <= overflow;
		else 
			SUM <= (temp + 6);
			C_OUT <= '1';
		end if;
		
		
--		if (A >0 and B >0 and A + B < 9) then
--			SUM <= temp+6;
--			C_OUT <= '1';
--		else 
--			if ( temp <= 9 ) then
--				SUM <= temp;
--				C_OUT <= '0';
--			else
--				SUM <= (temp + 6);
--				C_OUT <= '1';
--			end if;
--		end if;
		
--		if ( ('0'&A) + ('0'&B) + C_IN <= 9 ) then
--			SUM <= (A + B + C_IN);
--			C_OUT <= '0';
--		else
--			SUM <= (A + B + C_IN + 6);
--			C_OUT <= '1';
--		end if;
		
	end process;
	
end bcd_1_adder_arch;
