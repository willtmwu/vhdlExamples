--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:25:06 08/14/2014
-- Design Name:   
-- Module Name:   C:/Xilinx/14.7/workspace/prac3/test_bcd_1_adder.vhd
-- Project Name:  prac3
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: bcd_1_adder
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 
ENTITY test_bcd_1_adder IS
END test_bcd_1_adder;
 
ARCHITECTURE behavior OF test_bcd_1_adder IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT bcd_1_adder
    PORT(
         A : IN  std_logic_vector(3 downto 0);
         B : IN  std_logic_vector(3 downto 0);
         C_IN : IN  std_logic;
         SUM : OUT  std_logic_vector(3 downto 0);
         C_OUT : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal A : std_logic_vector(3 downto 0) := (others => '0');
   signal B : std_logic_vector(3 downto 0) := (others => '0');
   signal C_IN : std_logic := '0';

 	--Outputs
   signal SUM : std_logic_vector(3 downto 0);
   signal C_OUT : std_logic;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: bcd_1_adder PORT MAP (
          A => A,
          B => B,
          C_IN => C_IN,
          SUM => SUM,
          C_OUT => C_OUT
        );
 
   -- Stimulus process
   stim_proc: process begin		
	A <= (others => '0');
	B <= (others => '0');
	C_IN <= '0';
	wait for 10ps;
	
	for I in 0 to 7 loop
		wait for 1ps;
		for J in 0 to 7 loop
			wait for 1ps;
			for K in 0 to 1 loop
				wait for 1ps;
				--Black Box testing
				
					--0 input
					if (A = "0000" and B = "0000" and C_IN = '0') then
						assert (sum = "0000") report "bad gate - stuck at 0S0" severity error;
						assert (C_OUT = '0') report "bad gate - stuck at 0C0" severity error;
					elsif (A = "0000" and B = "0000" and C_IN = '1') then
						assert (sum = "0001") report "bad gate - stuck at 0S1" severity error;
						assert (C_OUT = '0') report "bad gate - stuck at 0C1" severity error;
						
					--less than 9
					elsif (A = "0100" and B = "0001" and C_IN = '0') then
						assert (sum = "0101") report "bad gate - stuck at less than 9S0" severity error;
						assert (C_OUT = '0') report "bad gate - stuck at less than 9C0" severity error;
					elsif (A = "0100" and B = "0001" and C_IN = '1') then
						assert (sum = "0110") report "bad gate - stuck at less than 9S1" severity error;
						assert (C_OUT = '0') report "bad gate - stuck at less than 9C1" severity error;
						
					--At 9
					elsif (A = "0101" and B = "0100" and C_IN = '0') then
						assert (sum = "1001") report "bad gate - stuck at 9S0" severity error;
						assert (C_OUT = '0') report "bad gate - stuck at 9C0" severity error;
					elsif (A = "0100" and B = "0100" and C_IN = '1') then
						assert (sum = "1001") report "bad gate - stuck at 9S1" severity error;
						assert (C_OUT = '0') report "bad gate - stuck at 9C1" severity error;
						
					--More than 9
					elsif (A = "0111" and B = "0100" and C_IN = '0') then
						assert (sum = "0111") report "bad gate - stuck at more than 9S0" severity error;
						assert (C_OUT = '1') report "bad gate - stuck at more than 9C0" severity error;
					elsif (A = "0111" and B = "0100" and C_IN = '1') then
						assert (sum = "0010") report "bad gate - stuck at more than 9S1" severity error;
						assert (C_OUT = '1') report "bad gate - stuck at more than 9C1" severity error;
				
					--More than 7 + 9
					elsif (A = "0111" and B = "1001" and C_IN = '0') then
						assert (sum = "0110") report "bad gate - stuck at 7S0" severity error;
						assert (C_OUT = '1') report "bad gate - stuck at 7C0" severity error;
					elsif (A = "0111" and B = "1001" and C_IN = '1') then
						assert (sum = "0111") report "bad gate - stuck at 7S1" severity error;
						assert (C_OUT = '1') report "bad gate - stuck at 7C1" severity error;
					
					--More than 8 + 9
					elsif (A = "1000" and B = "1001" and C_IN = '0') then
						assert (sum = "0111") report "bad gate - stuck at 7S0" severity error;
						assert (C_OUT = '1') report "bad gate - stuck at 7C0" severity error;
					elsif (A = "1000" and B = "1001" and C_IN = '1') then
						assert (sum = "1000") report "bad gate - stuck at 7S1" severity error;
						assert (C_OUT = '1') report "bad gate - stuck at 7C1" severity error;
					end if; 
					
				C_IN <= NOT(C_IN);
			end loop;
			B <= B + '1';
		end loop;
		A <= A + '1';
	end loop;
	wait;	
   end process;
END;
