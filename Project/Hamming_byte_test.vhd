----------------------------------------------------------------------------------
-- Company: 				N/A 
-- Engineer: 				WTMW
-- Create Date:    		22:27:15 09/26/2014 
-- Design Name: 			
-- Module Name:    		Hamming_byte_test.vhd
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
 
ENTITY Hamming_byte_test IS
END Hamming_byte_test;
 
ARCHITECTURE behavior OF Hamming_byte_test IS 
	-- Test Signals
	signal data_byte 			: std_logic_vector(7 downto 0) := "00100101";
	signal encoded_h_word	: std_logic_vector(15 downto 0) := (others => '0');
	signal err_h_word			: std_logic_vector(15 downto 0) := "1000000010000000";
	signal decoded_byte		: std_logic_vector(7 downto 0) := (others => '0');

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
   process 
	
	begin
		wait for clk_period*10;
			encoded_h_word <= Hamming_Byte_encoder(data_byte);
			wait for clk_period;	
			encoded_h_word <= encoded_h_word XOR err_h_word;
			wait for clk_period;
			decoded_byte  	<= Hamming_Byte_decoder(encoded_h_word);
			wait for clk_period;					
			
		wait for clk_period*10;
		wait;
   end process;
	
END;
