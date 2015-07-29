----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:09:07 08/08/2014 
-- Design Name: 
-- Module Name:    clockedRegister - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clockedRegister is
    Port ( D : in  STD_LOGIC_VECTOR (15 downto 0);
           E : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           Q : out  STD_LOGIC_VECTOR (15 downto 0)
			  );
end clockedRegister;

architecture Behavioral of clockedRegister is
begin
	PROCESS( reset, clk)BEGIN
		if reset = '0' then
			Q <= (others => '0');
		elsif clk'event and clk = '1' then
			if (E = '1') then
				Q <= D;
			end if;
		end if;
	END PROCESS;
end Behavioral; 

