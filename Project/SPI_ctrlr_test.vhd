----------------------------------------------------------------------------------
-- Company: 				N/A 
-- Engineer: 				WTMW
-- Create Date:    		22:27:15 09/26/2014 
-- Design Name: 			
-- Module Name:    		SPI_ctrlr_test.vhd
-- Project Name: 			project_nrf
-- Target Devices: 		Nexys 4
-- Tool versions: 		ISE WEBPACK 64-Bit
-- Description: 			Testing NRF state transitions
------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY SPI_ctrlr_test IS
END SPI_ctrlr_test;
 
ARCHITECTURE behavior OF SPI_ctrlr_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT SPI_ctrlr
    PORT(
         clk : IN  std_logic;
         masterReset : IN  std_logic;
         m_en : IN  std_logic;
         m_ready : OUT  std_logic;
			sTransmissionLines : in std_logic_vector(2 downto 0);
         send_now : IN  std_logic;
         send_message : IN  std_logic_vector(55 downto 0);
         send_active : OUT  std_logic;
         recv_dtr : OUT  std_logic;
         recv_message : OUT  std_logic_vector(55 downto 0);
         recv_active : OUT  std_logic;
         hamming_err : IN  std_logic_vector(7 downto 0);
			IRQ : in STD_LOGIC;
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
   signal m_en : std_logic := '0';
   signal send_now : std_logic := '0';
   signal send_message : std_logic_vector(55 downto 0) := (others => '0');
   signal hamming_err : std_logic_vector(7 downto 0) := (others => '0');
   signal MISO : std_logic := '0';
	signal IRQ : std_logic := '1';
	signal sTransmissionLines : std_logic_vector(2 downto 0) := "010";

 	--Outputs
   signal m_ready : std_logic;
   signal send_active : std_logic;
   signal recv_dtr : std_logic;
   signal recv_message : std_logic_vector(55 downto 0);
   signal recv_active : std_logic;
   signal CE : std_logic;
   signal CS : std_logic;
   signal SCLK : std_logic;
   signal MOSI : std_logic;
   signal LED_SPI : std_logic_vector(2 downto 0);

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
 
	-- Instantiate the Unit Under Test (UUT)
   uut: SPI_ctrlr PORT MAP (
          clk => clk,
          masterReset => masterReset,
          m_en => m_en,
          m_ready => m_ready,
			 sTransmissionLines => sTransmissionLines,
          send_now => send_now,
          send_message => send_message,
          send_active => send_active,
          recv_dtr => recv_dtr,
          recv_message => recv_message,
          recv_active => recv_active,
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

   process
   begin		
      wait for clk_period*10;
		masterReset <= '0';
		m_en <= '1';
		wait until M_ready = '1';
		
		-- Module Intialised and Send
		wait for clk_period*10;
		wait until rising_edge(clk);
		send_now <= '1';
		send_message(55 downto 40) <= "1111000010100011";
		wait until rising_edge(clk);
		send_now <= '0';
		wait until send_active = '0';
		wait for clk_period*100;
		
		-- Test Interrupt Reading
		IRQ <= '0';
		wait until rising_edge(clk);
		IRQ <= '1';
		
		wait until recv_active = '1';
		SPI_MISO("11111101", MISO); 
		SPI_MISO("11000001", MISO); 
		wait until falling_edge(SCLK);
		-- Send Through a message, In Hex, start wit basic location
		SPI_MISO(x"FF", MISO);  -- REG
		SPI_MISO(x"00", MISO);  -- 0
		SPI_MISO(x"2B", MISO); 	-- 1
		SPI_MISO(x"8E", MISO); 	-- 2
		SPI_MISO(x"71", MISO);  -- 3
		SPI_MISO(x"6C", MISO);  -- 4 
		SPI_MISO(x"5A", MISO);  -- 5
		SPI_MISO(x"47", MISO);  -- 6
		SPI_MISO(x"36", MISO); 	-- 7
		SPI_MISO(x"2B", MISO);  -- 8
		SPI_MISO(x"1D", MISO);  -- 9
		SPI_MISO(x"2A", MISO);  -- 10
		SPI_MISO(x"47", MISO);  -- 11
		SPI_MISO(x"1D", MISO);  -- 12 
		SPI_MISO(x"93", MISO); 	-- 13
		SPI_MISO(x"2B", MISO); 	-- 14
		SPI_MISO(x"36", MISO); 	-- 15
		SPI_MISO(x"8E", MISO); 	-- 16 
		SPI_MISO(x"5A", MISO); 	-- 17
		SPI_MISO(x"00", MISO); 	-- 18
		SPI_MISO(x"00", MISO); 	-- 19
		SPI_MISO(x"6C", MISO); 	-- 20
		SPI_MISO(x"00", MISO); 	-- 21
		SPI_MISO(x"5A", MISO); 	-- 22
		SPI_MISO(x"00", MISO); 	-- 23
		SPI_MISO(x"47", MISO); 	-- 24
		SPI_MISO(x"00", MISO); 	-- 25
		SPI_MISO(x"36", MISO); 	-- 26
		SPI_MISO(x"00", MISO); 	-- 27
		SPI_MISO(x"2B", MISO); 	-- 28
		SPI_MISO(x"00", MISO); 	-- 29	
		SPI_MISO(x"1D", MISO); 	-- 30
		SPI_MISO(x"00", MISO); 	-- 31
		
		wait for clk_period*30000;
		
      wait;
   end process;

END;
