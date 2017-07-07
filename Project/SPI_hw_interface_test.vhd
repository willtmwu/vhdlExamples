----------------------------------------------------------------------------------
-- Company: 				N/A 
-- Engineer: 				WTMW
-- Create Date:    		22:27:15 09/26/2014 
-- Design Name: 			
-- Module Name:    		SPI_hardware_interface_test.vhd
-- Project Name: 			project_nrf
-- Target Devices: 		Nexys 4
-- Tool versions: 		ISE WEBPACK 64-Bit
-- Description: 			Testing MOSI and MISO 
--								for at edge case of 32byte burst read and write
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
 
ENTITY SPI_hw_interface_test IS
END SPI_hw_interface_test;
 
ARCHITECTURE behavior OF SPI_hw_interface_test IS 
 
    COMPONENT SPI_hw_interface
    PORT(
         clk : IN  std_logic;
         masterReset : IN  std_logic;
         en : IN  std_logic;
         data_byte_in : IN  std_logic_vector(7 downto 0);
         data_byte_out : OUT  std_logic_vector(7 downto 0);
         wen : IN  std_logic;
         ren : IN  std_logic;
         M_active : OUT  std_logic;
			M_finished : out std_logic;
         regLocation : IN  std_logic_vector(7 downto 0);
         dataAmount : IN  std_logic_vector(5 downto 0);
         CS : OUT  std_logic;
         SCLK : OUT  std_logic;
         MOSI : OUT  std_logic;
         MISO : IN  std_logic
        );
    END COMPONENT;
    
   --Inputs
   signal clk : std_logic := '0';
   signal masterReset : std_logic := '0';
   signal en : std_logic := '0';
   signal data_byte_in : std_logic_vector(7 downto 0) := (others => '0');
   signal wen : std_logic := '0';
   signal ren : std_logic := '0';
   signal regLocation : std_logic_vector(7 downto 0) := (others => '0');
   signal dataAmount : std_logic_vector(5 downto 0) := (others => '0');
   signal MISO : std_logic := '0';

 	--Outputs
   signal data_byte_out : std_logic_vector(7 downto 0) := (others => '0');
   signal CS : std_logic;
   signal SCLK : std_logic;
   signal MOSI : std_logic;
	signal M_finished : std_logic;
	signal M_active : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
	
	--Procedure should mimic NRF, will need to clock out 
	procedure SPI_MISO (
		byte_in	: in std_logic_vector(7 downto 0) ;
		signal MISO 		: out std_logic
		) is 
	begin
		for i in 7 downto 0 loop
			MISO <= byte_in(i);
			wait until falling_edge(SCLK);
		end loop;
	end SPI_MISO;
	
BEGIN
 
   uut: SPI_hw_interface PORT MAP (
          clk => clk,
          masterReset => masterReset,
          en => en,
          data_byte_in => data_byte_in,
          data_byte_out => data_byte_out,
          wen => wen,
          ren => ren,
          M_active => M_active,
			 M_finished => M_finished,
          regLocation => regLocation,
          dataAmount => dataAmount,
          CS => CS,
          SCLK => SCLK,
          MOSI => MOSI,
          MISO => MISO
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
	
   -- Stimulus process
   stim_proc: process
   begin		
		wait until rising_edge(clk);
		masterReset <= '1';
      wait for clk_period*5;
		wait until rising_edge(clk);
		masterReset <= '0';
		
		-- PART ONE Retest Sending, 3 Bytes
		wait until rising_edge(clk);
		en <= '1';
		data_byte_in <= "11001001";
		wait until rising_edge(clk);
		data_byte_in <= "00111001";
		wait until rising_edge(clk);
		data_byte_in <= "10011011";
		wait until rising_edge(clk);
		data_byte_in <= (others => '0'); -- Check data is in
		en <= '0';
		
		regLocation <= "10001011"; 
		dataAmount <= "000011"; -- 3 bytes to send
		wen <= '1';					-- Pulse WEN
		wait until rising_edge(clk);
		wen <= '0';
		
		wait for clk_period*1000;
		wait until M_finished = '1';
		wait for clk_period*10;
		
		-- PART TWO Retest Sending, 32 Bytes
		wait for clk_period*5;
		masterReset <= '0';
		wait until rising_edge(clk);
		en <= '1';
		data_byte_in <= "10000001";		-- 0
		wait until rising_edge(clk);
		data_byte_in <= "10000011"; 		-- 1
		wait until rising_edge(clk);
		data_byte_in <= "10000101";		-- 2
		wait until rising_edge(clk);
		data_byte_in <= "10000111"; 		-- 3
		wait until rising_edge(clk);
		data_byte_in <= "10001001"; 		-- 4
		wait until rising_edge(clk);
		data_byte_in <= "10001011";		-- 5
		wait until rising_edge(clk);
		data_byte_in <= "10001101";		-- 6
		wait until rising_edge(clk);
		data_byte_in <= "10001111";		-- 7
		wait until rising_edge(clk);
		data_byte_in <= "10010001";		-- 8
		wait until rising_edge(clk);
		data_byte_in <= "10010011"; 		-- 9
		wait until rising_edge(clk);
		data_byte_in <= "10010101";		-- 10
		wait until rising_edge(clk);
		data_byte_in <= "10010111";		-- 11
		wait until rising_edge(clk);
		data_byte_in <= "10011001";		--	12
		wait until rising_edge(clk);
		data_byte_in <= "10011011";		-- 13
		wait until rising_edge(clk);
		data_byte_in <= "10011101";		-- 14
		wait until rising_edge(clk);
		data_byte_in <= "10011111";		-- 15
		wait until rising_edge(clk);
		data_byte_in <= "10100001";		-- 16
		wait until rising_edge(clk);
		data_byte_in <= "10100011";		-- 17
		wait until rising_edge(clk);
		data_byte_in <= "10100101";		-- 18
		wait until rising_edge(clk);
		data_byte_in <= "10100111";		-- 19
		wait until rising_edge(clk);
		data_byte_in <= "10101001";		-- 20
		wait until rising_edge(clk);
		data_byte_in <= "10101011";		-- 21
		wait until rising_edge(clk);
		data_byte_in <= "10101101";		-- 22
		wait until rising_edge(clk);
		data_byte_in <= "10101111";		-- 23
		wait until rising_edge(clk);
		data_byte_in <= "10110001";		-- 24
		wait until rising_edge(clk);
		data_byte_in <= "10110011";		-- 25
		wait until rising_edge(clk);
		data_byte_in <= "10110101";		-- 26
		wait until rising_edge(clk);
		data_byte_in <= "10110111";		-- 27
		wait until rising_edge(clk);
		data_byte_in <= "10111001";		-- 28
		wait until rising_edge(clk);
		data_byte_in <= "10111011";		-- 29 
		wait until rising_edge(clk);
		data_byte_in <= "10111101";		-- 30
		wait until rising_edge(clk);
		data_byte_in <= "10111111";		-- 31
		wait until rising_edge(clk);
		data_byte_in <= (others => '0'); -- Check data is in
		en <= '0'; -- Data is loaded in properly
		regLocation <= "10101011"; 
		dataAmount <= "100000"; -- 32 bytes to send
		wen <= '1';					-- Pulse WEN
		wait until rising_edge(clk);
		wen <= '0';
		
		
		-- PART 3 Test Reading, 4 Bytes
		wait for clk_period*1000;
		wait until M_finished = '1';
		wait for clk_period*10;
		wait until rising_edge(clk);
		regLocation <= "11101011"; 
		dataAmount <= "000100"; -- 4 bytes to read
		ren <= '1';
		wait until rising_edge(clk);
		ren <= '0';
		SPI_MISO("11111110", MISO); -- Dummy Shift
		SPI_MISO("10110011", MISO); -- Byte 1
		SPI_MISO("10011000", MISO); -- Byte 2
		SPI_MISO("10101101", MISO); -- Byte 3
		SPI_MISO("11101111", MISO); -- Byte 3
		
		-- CLK out the data
		wait until M_finished = '1';
		wait for clk_period*10;
		wait until rising_edge(clk); -- Clocking out is delayed 1 clk cycle, be careful
		en <= '1';
		wait for clk_period*6;
		wait until rising_edge(clk);
		en <= '0';
		-- Tested OK , 4 bytes now 32 byte test

		-- PART 4 Test Reading, 32 Bytes
		wait for clk_period*10;
		wait until rising_edge(clk);
		regLocation <= "10110111"; 
		dataAmount <= "100000"; -- 4 bytes to read
		ren <= '1';
		wait until rising_edge(clk);
		ren <= '0';
		SPI_MISO("11111111", MISO); -- Dummy Shift
		SPI_MISO("10000001", MISO); -- Byte 0
		SPI_MISO("10000011", MISO); -- Byte 1
		SPI_MISO("10000101", MISO); -- Byte 2
		SPI_MISO("10000111", MISO); -- Byte 3
		SPI_MISO("10001001", MISO); -- Byte 4
		SPI_MISO("10001011", MISO); -- Byte 5
		SPI_MISO("10001101", MISO); -- Byte 6
		SPI_MISO("10001111", MISO); -- Byte 7
		SPI_MISO("10010001", MISO); -- Byte 8
		SPI_MISO("10010011", MISO); -- Byte 9
		SPI_MISO("10010101", MISO); -- Byte 10
		SPI_MISO("10010111", MISO); -- Byte 11
		SPI_MISO("10011001", MISO); -- Byte 12
		SPI_MISO("10011011", MISO); -- Byte 13
		SPI_MISO("10011101", MISO); -- Byte 14
		SPI_MISO("10011111", MISO); -- Byte 15
		SPI_MISO("10100001", MISO); -- Byte 16
		SPI_MISO("10100011", MISO); -- Byte 17
		SPI_MISO("10100101", MISO); -- Byte 18
		SPI_MISO("10100111", MISO); -- Byte 19
		SPI_MISO("10101001", MISO); -- Byte 20
		SPI_MISO("10101011", MISO); -- Byte 21
		SPI_MISO("10101101", MISO); -- Byte 22
		SPI_MISO("10101111", MISO); -- Byte 23
		SPI_MISO("10110001", MISO); -- Byte 24
		SPI_MISO("10110011", MISO); -- Byte 25
		SPI_MISO("10110101", MISO); -- Byte 26
		SPI_MISO("10110111", MISO); -- Byte 27
		SPI_MISO("10111001", MISO); -- Byte 28
		SPI_MISO("10111011", MISO); -- Byte 29
		SPI_MISO("10111101", MISO); -- Byte 30
		SPI_MISO("10111111", MISO); -- Byte 31
		
		-- CLK out the data
		wait until M_finished = '1';
		wait for clk_period*10;
		wait until rising_edge(clk); -- Clocking out is delayed 1 clk cycle, be careful
		en <= '1';
		 wait for clk_period*32; -- Last Clocked byte is also remains for 1 clk cycle
		wait until rising_edge(clk);
		en <= '0';
		
		-- TEST OK 
		
      wait;
   end process;

END;
