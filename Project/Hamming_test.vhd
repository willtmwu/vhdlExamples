----------------------------------------------------------------------------------
-- Company: 				N/A 
-- Engineer: 				WTMW
-- Create Date:    		22:27:15 09/26/2014 
-- Design Name: 			
-- Module Name:    		Hamming_tests.vhd
-- Project Name: 			project_nrf
-- Target Devices: 		Nexys 4
-- Tool versions: 		ISE WEBPACK 64-Bit
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
 
LIBRARY work;
use work.project_nrf_subprog.all; 
 
ENTITY Hamming_test IS
END Hamming_test;
 
ARCHITECTURE behavior OF Hamming_test IS 
	-- Test Signals
	signal data_nib 		: std_logic_vector(3 downto 0) := "0000";
	signal encoded_byte	: std_logic_vector(7 downto 0) := "00000000";
	signal err_vector		: std_logic_vector(7 downto 0) := "00000001";
	signal decoded_nib	: std_logic_vector(3 downto 0) := "0000";

   -- CLK Signals
   signal clk 				: std_logic := '0';
	constant clk_period 	: time := 10 ns;
   signal masterReset 	: std_logic := '1';
BEGIN
   -- Clock process definitions
   clk_process :process
   begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process begin
		wait for clk_period*10;
		for I in 1 to 16 loop
			for I in 1 to 8 loop
				wait until rising_edge(clk);
				encoded_byte <= Hamming_hByte_encoder(data_nib);
				wait for clk_period;
				encoded_byte <= encoded_byte XOR err_vector;
				err_vector <= err_vector(6 downto 0) & '0';
				wait for clk_period;
				decoded_nib  <= Hamming_hByte_decoder(encoded_byte);
				wait for clk_period;				
			end loop;
			data_nib <= data_nib + '1';
			err_vector <= "00000001";
			wait for clk_period*2;
		end loop;
   end process;
END;
