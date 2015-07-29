----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:14:34 08/06/2014 
-- Design Name: 
-- Module Name:    and2gate - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity and2gate is
    Port ( in1 : in  STD_LOGIC;
           in2 : in  STD_LOGIC;
           outAnd : out  STD_LOGIC);
end and2gate;

architecture Behavioral of and2gate is

begin
outAnd <= in1 and in2;

end Behavioral;

