----------------------------------------------------------------------------------
-- Company: 				N/A 
-- Engineer: 				WTMW
-- Create Date:    		22:27:15 09/26/2014 
-- Design Name: 			
-- Module Name:    		top_controller_test.vhd
-- Project Name: 			project_nrf
-- Target Devices: 		Nexys 4
-- Tool versions: 		ISE WEBPACK 64-Bit
-- Description: 			Testing the RAM loading and full packet sending
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

LIBRARY work;
use work.project_nrf_subprogV2.all;  
 
ENTITY top_controller_test IS
END top_controller_test;
 
ARCHITECTURE behavior OF top_controller_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top_controller
    PORT(
         clk : IN  std_logic;
         masterReset : IN  std_logic;
         bSend : IN  std_logic;
         bModeChange : IN  std_logic;
         bEnterData : IN  std_logic;
         bCount : IN  std_logic;
         sTransmission : IN  std_logic_vector(2 downto 0);
         sHighSpeed : IN  std_logic;
         displayLower : OUT  std_logic_vector(15 downto 0);
         displayUpper : OUT  std_logic_vector(15 downto 0);
         data_nib : IN  std_logic_vector(3 downto 0);
         hamming_err : IN  std_logic_vector(7 downto 0);
         IRQ : IN  std_logic;
         CE : OUT  std_logic;
         CS : OUT  std_logic;
         SCLK : OUT  std_logic;
         MOSI : OUT  std_logic;
         MISO : IN  std_logic;
         LED_SPI : OUT  std_logic_vector(2 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal masterReset : std_logic := '1';
   signal bSend : std_logic := '0';
   signal bModeChange : std_logic := '0';
   signal bEnterData : std_logic := '0';
   signal bCount : std_logic := '0';
   signal sTransmission : std_logic_vector(2 downto 0) := (others => '0');
   signal sHighSpeed : std_logic := '1';
   signal data_nib : std_logic_vector(3 downto 0) := (others => '0');
   signal hamming_err : std_logic_vector(7 downto 0) := (others => '0');
   signal IRQ : std_logic := '1';
   signal MISO : std_logic := '0';

 	--Outputs
   signal displayLower : std_logic_vector(15 downto 0);
   signal displayUpper : std_logic_vector(15 downto 0);
   signal CE : std_logic;
   signal CS : std_logic;
   signal SCLK : std_logic;
   signal MOSI : std_logic;
   signal LED_SPI : std_logic_vector(2 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
	
	procedure ENTER_NIB (
		nib	: in std_logic_vector(3 downto 0) ;
		signal bEnterData 		: out std_logic;
		signal data_nib			: out std_logic_vector(3 downto 0)
		) is 
	begin
		wait until rising_edge(clk);
		bEnterData <= '0';
		wait until rising_edge(clk);
		data_nib <= nib;
		bEnterData <= '1';
		wait until rising_edge(clk);
		bEnterData <= '0';
		wait until rising_edge(clk);
	end ENTER_NIB;
	
	procedure BUTTON_PULSE (
		signal button : out std_logic
		) is 
	begin
		wait until rising_edge(clk);
		button <= '0';
		wait until rising_edge(clk);
		button <= '1';
		wait until rising_edge(clk);
		button <= '0';
		wait until rising_edge(clk);
	end BUTTON_PULSE;

	procedure FILL_RAM (
		signal bEnterData : out std_logic;
		signal bCount : out std_logic;
		signal data_nib: out std_logic_vector( 3 downto 0)
		) is 
	begin
		for i in 0 to 31 loop
			for j in 0 to 1 loop
				if(j=0) then
					ENTER_NIB(to_BCD(std_logic_vector(IEEE.numeric_std.to_unsigned(i, 5)))(3 downto 0), bEnterData,data_nib);
				else 
					ENTER_NIB(to_BCD(std_logic_vector(IEEE.numeric_std.to_unsigned(i, 5)))(7 downto 4), bEnterData,data_nib);
				end if;
			end loop;
			BUTTON_PULSE(bCount);
		end loop;
	end FILL_RAM;
	
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
	
	procedure NRF_MESSAGE (
		byte_0	: in std_logic_vector(7 downto 0) ;
		byte_1	: in std_logic_vector(7 downto 0) ;
		byte_2	: in std_logic_vector(7 downto 0) ;
		byte_3	: in std_logic_vector(7 downto 0) ;
		byte_4	: in std_logic_vector(7 downto 0) ;
		byte_5	: in std_logic_vector(7 downto 0) ;		
		byte_6	: in std_logic_vector(7 downto 0) ;		
		byte_7	: in std_logic_vector(7 downto 0) ;		
		byte_8	: in std_logic_vector(7 downto 0) ;		
		byte_9	: in std_logic_vector(7 downto 0) ;		
		byte_10	: in std_logic_vector(7 downto 0) ;		
		byte_11	: in std_logic_vector(7 downto 0) ;		
		byte_12	: in std_logic_vector(7 downto 0) ;		
		byte_13	: in std_logic_vector(7 downto 0) ;		
		signal MISO 		: out std_logic;
		signal IRQ : out std_logic;
		signal CS : in std_logic
		) is 
	begin
	
		-- Message Arrival, Ensure IRQ is active high
		wait until rising_edge(clk);
		IRQ <= '0';
		wait until rising_edge(clk);
		IRQ <= '1';
		SPI_MISO("11111101", MISO); 
		SPI_MISO("11000001", MISO); 
		wait until falling_edge(SCLK);
		-- Send Through a message, In Hex, start wit basic location
		SPI_MISO(x"FF", MISO);  -- REG
		-- Packet Type
		SPI_MISO(x"00", MISO);  -- 0
		SPI_MISO(x"2B", MISO); 	-- 1
		
		-- ADDR
		SPI_MISO(x"8E", MISO); 	-- 2
		SPI_MISO(x"71", MISO);  -- 3
		SPI_MISO(x"6C", MISO);  -- 4 
		SPI_MISO(x"5A", MISO);  -- 5
		SPI_MISO(x"47", MISO);  -- 6
		SPI_MISO(x"36", MISO); 	-- 7
		SPI_MISO(x"2B", MISO);  -- 8
		SPI_MISO(x"1D", MISO);  -- 9
		
		-- ADDR
		SPI_MISO(x"2A", MISO);  -- 10
		SPI_MISO(x"47", MISO);  -- 11
		SPI_MISO(x"1D", MISO);  -- 12 
		SPI_MISO(x"93", MISO); 	-- 13
		SPI_MISO(x"2B", MISO); 	-- 14
		SPI_MISO(x"36", MISO); 	-- 15
		SPI_MISO(x"8E", MISO); 	-- 16 
		SPI_MISO(x"5A", MISO); 	-- 17
		
		-- Message
		SPI_MISO(Byte_13, MISO); 	-- 18
		SPI_MISO(Byte_12, MISO); 	-- 19
		
		SPI_MISO(Byte_11, MISO); 	-- 20
		SPI_MISO(Byte_10, MISO); 	-- 21
		
		SPI_MISO(Byte_9, MISO); 	-- 22
		SPI_MISO(Byte_8, MISO); 	-- 23
		
		SPI_MISO(Byte_7, MISO); 	-- 24
		SPI_MISO(Byte_6, MISO); 	-- 25
		
		SPI_MISO(Byte_5, MISO); 	-- 26
		SPI_MISO(Byte_4, MISO); 	-- 27
		
		SPI_MISO(Byte_3, MISO); 	-- 28
		SPI_MISO(Byte_2, MISO); 	-- 29	
		
		SPI_MISO(Byte_1, MISO); 	-- 30
		SPI_MISO(Byte_0, MISO); 	-- 31
		
		wait until rising_edge(clk);
		wait for clk_period*1000;
		wait until rising_edge(clk);
	end NRF_MESSAGE;
	
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top_controller PORT MAP (
          clk => clk,
          masterReset => masterReset,
          bSend => bSend,
          bModeChange => bModeChange,
          bEnterData => bEnterData,
          bCount => bCount,
          sTransmission => sTransmission,
          sHighSpeed => sHighSpeed,
          displayLower => displayLower,
          displayUpper => displayUpper,
          data_nib => data_nib,
          hamming_err => hamming_err,
          IRQ => IRQ,
          CE => CE,
          CS => CS,
          SCLK => SCLK,
          MOSI => MOSI,
          MISO => MISO,
          LED_SPI => LED_SPI
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
      wait for clk_period*10;
		masterReset <= '0';
		wait for 10_000_200ns;
		wait until rising_edge(clk);
		wait for clk_period*10;
		
		FILL_RAM(bEnterData, bCount, data_nib);

		wait for clk_period*10;
		BUTTON_PULSE(bSend);

		wait for 55_850_000ns;

--		NRF_MESSAGE (
--		x"B8", -- Byte 0
--		x"A5", -- Byte 1
--		x"93", -- Byte 2
--		x"8E", -- Byte 3
--		x"71", -- Byte 4
--		x"6C", -- Byte 5
--		x"5A", -- Byte 6
--		x"47", -- Byte 7
--		x"36", -- Byte 8
--		x"2B", -- Byte 9
--		x"1D", -- Byte 10
--		x"00", -- Byte 11
--		x"00", -- Byte 12
--		x"FF", -- Byte 13
--		MISO,IRQ,CS
--		);
		
		-- FF 0 0 1D 0 2B 0 36 0 47 0 5A 0 6C 
--		NRF_MESSAGE (
--		x"6C", -- Byte 0
--		x"00", -- Byte 1
--		x"5A", -- Byte 2
--		x"00", -- Byte 3
--		x"47", -- Byte 4
--		x"00", -- Byte 5
--		x"36", -- Byte 6
--		x"00", -- Byte 7
--		x"2B", -- Byte 8
--		x"00", -- Byte 9
--		x"1D", -- Byte 10
--		x"00", -- Byte 11
--		x"00", -- Byte 12
--		x"FF", -- Byte 13
--		MISO,IRQ,CS
--		);
--		
--		-- FF 1D 0 71 0 8E 0 93 1D 0 1D 1D 1D 2B 
--		NRF_MESSAGE (
--		x"2B", -- Byte 0
--		x"1D", -- Byte 1
--		x"1D", -- Byte 2
--		x"1D", -- Byte 3
--		x"00", -- Byte 4
--		x"1D", -- Byte 5
--		x"93", -- Byte 6
--		x"00", -- Byte 7
--		x"8E", -- Byte 8
--		x"00", -- Byte 9
--		x"71", -- Byte 10
--		x"00", -- Byte 11
--		x"1D", -- Byte 12
--		x"FF", -- Byte 13
--		MISO,IRQ,CS
--		);
--		
--		-- FF 2B 1D 36 1D 47 1D 5A 1D 6C 1D 71 1D 8E 
--		NRF_MESSAGE (
--		x"8E", -- Byte 0
--		x"1D", -- Byte 1
--		x"71", -- Byte 2
--		x"1D", -- Byte 3
--		x"6C", -- Byte 4
--		x"1D", -- Byte 5
--		x"5A", -- Byte 6
--		x"1D", -- Byte 7
--		x"47", -- Byte 8
--		x"1D", -- Byte 9
--		x"36", -- Byte 10
--		x"1D", -- Byte 11
--		x"2B", -- Byte 12
--		x"FF", -- Byte 13
--		MISO,IRQ,CS
--		);		
--
--		-- FF 36 1D 93 2B 0 2B 1D 2B 2B 2B 36 2B 47 
--		NRF_MESSAGE (
--		x"47", -- Byte 0
--		x"2B", -- Byte 1
--		x"36", -- Byte 2
--		x"2B", -- Byte 3
--		x"2B", -- Byte 4
--		x"2B", -- Byte 5
--		x"1D", -- Byte 6
--		x"2B", -- Byte 7
--		x"00", -- Byte 8
--		x"2B", -- Byte 9
--		x"93", -- Byte 10
--		x"1D", -- Byte 11
--		x"36", -- Byte 12
--		x"FF", -- Byte 13
--		MISO,IRQ,CS
--		);				
--		
--		-- FF 47 2B 5A 2B 6C 2B 71 2B 8E 2B 93 36 0 
--		NRF_MESSAGE (
--		x"00", -- Byte 0
--		x"36", -- Byte 1
--		x"93", -- Byte 2
--		x"2B", -- Byte 3
--		x"8E", -- Byte 4
--		x"2B", -- Byte 5
--		x"71", -- Byte 6
--		x"2B", -- Byte 7
--		x"6C", -- Byte 8
--		x"2B", -- Byte 9
--		x"5A", -- Byte 10
--		x"2B", -- Byte 11
--		x"47", -- Byte 12
--		x"FF", -- Byte 13
--		MISO,IRQ,CS
--		);	
		
		-- FF 5A 36 1D 36 2B 0 1D 0 2B 0 36 0 47 
		NRF_MESSAGE (
		x"47", -- Byte 0
		x"00", -- Byte 1
		x"36", -- Byte 2
		x"00", -- Byte 3
		x"2B", -- Byte 4
		x"00", -- Byte 5
		x"1D", -- Byte 6
		x"00", -- Byte 7
		x"2B", -- Byte 8
		x"36", -- Byte 9
		x"1D", -- Byte 10
		x"36", -- Byte 11
		x"5A", -- Byte 12
		x"FF", -- Byte 13
		MISO,IRQ,CS
		);		

		
      wait;
   end process;

END;
