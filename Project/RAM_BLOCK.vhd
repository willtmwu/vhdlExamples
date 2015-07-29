----------------------------------------------------------------------------------
-- Company: 				N/A 
-- Engineer: 				WTMW
-- Create Date:    		22:27:15 09/26/2014 
-- Design Name: 			
-- Module Name:    		RAM_BLOCK.vhd
-- Project Name: 			project_nrf
-- Target Devices: 		Nexys 4
-- Tool versions: 		ISE WEBPACK 64-Bit
-- Description:  			RAM block for 64 Nibbles
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity RAM_BLOCK is
	port( clk 	: in std_logic;
			we	 	: in std_logic;
			en  	: in std_logic;
			addr	: in std_logic_vector(5 downto 0);
			d_i 	: in std_logic_vector(3 downto 0);
			d_o 	: out std_logic_vector(3 downto 0));
	end RAM_BLOCK;
	
architecture syn of RAM_BLOCK is
	type ram_type is array (63 downto 0) of std_logic_vector (3 downto 0);
	signal RAM: ram_type := (others => (others => '0')); 

begin
	process (clk) begin
		if rising_edge(clk) then
			if en = '1' then
				if (addr <= 63) then
					if we = '1' then
						RAM(conv_integer(addr))<=d_i;
					end if;
					d_o<=RAM(conv_integer(addr));
				end if;
			end if;
		end if;
	end process;
end syn;