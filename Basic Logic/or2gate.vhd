--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    12:13:17 03/04/06
-- Design Name:    
-- Module Name:    and2gate - Behavioral
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity or2gate is
    Port ( in1 : in std_logic;
           in2 : in std_logic;
           outOr : out std_logic);
end or2gate;

architecture Behavioral of or2gate is

begin

	outOr <= in1 or in2 ; 

end Behavioral;
