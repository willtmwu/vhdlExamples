----------------------------------------------------------------------------------
-- Company: 				N/A 
-- Engineer: 				WTMW
-- Create Date:    		22:27:15 09/26/2014 
-- Design Name: 			
-- Module Name:    		SPI_hardware_interface.vhd
-- Project Name: 			project_nrf
-- Target Devices: 		Nexys 4
-- Tool versions: 		ISE WEBPACK 64-Bit
-- Description: 	This module handles the CS for SPI_NRF
--						CS - Low active
--						CPOL = 0 (CPOL_LOW)
--						CPHA = 0 (CPHA_1Edge)
--						MSB Transfer
--										
--						Burst mode reads and writes
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_hw_interface is
	Generic (
			master_clk 			: integer := 100_000_000;					-- Default 100Mhz clk
			SCLK_rate	 		: integer := 1_000_000						-- Default 1Mhz SCLK
		);
	Port ( 	clk 				: in  	STD_LOGIC;
				masterReset 	: in  	STD_LOGIC;
				en 				: in 		STD_LOGIC; 	-- EN to latch in/out the data, must remain active for whole duration
				data_byte_in 	: in  	STD_LOGIC_VECTOR(7 downto 0);	-- Read in byte by byte to internal buffer before sending, always 32 bytes for msg must be given. If no data at least 0x00
				data_byte_out	: out 	STD_LOGIC_VECTOR(7 downto 0);	-- Write the full message bytes back out to SPI controller. 

				wen				: in  	STD_LOGIC;	-- HIGH for 1 clk to send all within send buffer
				ren				: in 		STD_LOGIC; 	-- HIGH for 1 clk to start read process, before returning to idle
				M_active			: out 	STD_LOGIC;	-- HIGH when active in either send or receive mode
				M_finished		: out STD_LOGIC; 		-- HIGH for 1 clk when finished
				regLocation 	: in  	STD_LOGIC_VECTOR(7 downto 0);	-- Location to write/read to, must include CMD bit 
				dataAmount 		: in  	STD_LOGIC_VECTOR(5 downto 0); -- Amount to write or read, to/form, 32 bytes max

				-- NRF Chip control lines, CE pulses and transitions done by controller
				CS 					: out STD_LOGIC;
				SCLK					: out STD_LOGIC;
				MOSI					: out STD_LOGIC;
				MISO					: in  STD_LOGIC
			);
end SPI_hw_interface;

architecture Behavioral of SPI_hw_interface is

-- clkScalers for different SCLK if required
signal clockScalers 	: std_logic_vector(26 downto 0) := (others => '0');
signal forceReset 	: std_logic := '0';

-- For data loading/unloading
type DATA_FSM is (DATA_IDLE, DATA_LOAD);
signal DATA_STATE : DATA_FSM := DATA_IDLE;
signal counter : integer range 31 downto 0 := 0;

subtype byte is std_logic_vector(7 downto 0);
type message is array(31 downto 0) of byte; -- Maximum of 32 byte message
signal send_buffer : message := (others => (others => '0'));
signal recv_buffer : message := (others => (others => '0'));

-- For general dynamic sending
type SPI_FSM is (SPI_IDLE, SPI_REG, SPI_DATA_SEND, SPI_DATA_RECV);
signal SPI_STATE 		: SPI_FSM := SPI_IDLE;
signal data_shifter 	: std_logic_vector(7 downto 0)  := (others => '0'); 	-- Byte to shift out
signal reg_location_I: std_logic_vector(7 downto 0)  := (others => '0'); 	-- Byte given by controller
signal data_amount_I : integer range 32 downto 0 := 0; 							-- Amount given by controller, max 32 bytes 
signal data_counter_I: integer range 33 downto 0 := 0; 							-- Counting bytes sent or received
signal bit_shifter 	: std_logic_vector(7 downto 0) := (others => '1'); 	-- Tracking bits shifted out
signal toRead 			: std_logic := '0'; 												-- toRead or write to the NRF. 
signal toWrite 		: std_logic := '0';
signal CS_I 			: std_logic := '1'; 												-- Internal CS [CSN] link to outside

-- Scaling SCLK time signal and period
signal SCLK_I 			: std_logic := '0'; -- Internal link
signal SCLK_h 			: std_logic := '0'; -- Half SCLK synchro signal
signal SCLK_f			: std_logic	:= '0'; -- Full SCLK period synchro signal 
constant SCLK_limit  	: integer := master_CLK/SCLK_rate - 2; 	-- For counter, -2 to fix timing issues
constant SCLK_half   	: integer := master_CLK/SCLK_rate/2 - 2; 	-- For counter, half the SCLK Period
signal   SCLK_counter 	: integer range SCLK_limit downto 0 := 0;	-- SCLK Period counter
type     SCLK_FSM 		is (SCLK_IDLE, SCLK_WAIT); -- Scaler Process FSM
signal   SCLK_STATE_H 		: SCLK_FSM := SCLK_IDLE;
signal   SCLK_STATE_F 		: SCLK_FSM := SCLK_IDLE;

begin

	-- Direct signal connections
	CS <= CS_I;
	SCLK <= SCLK_I;

	-- always start with reg location, then write or read specified amount. Manually bit-bash SCLK
	process (masterReset, clk) begin
		if (masterReset = '1') then 
			SPI_STATE 	<= SPI_IDLE;
			MOSI 			<= '0';
			SCLK_I 		<= '0';
			M_active 	<= '0';
			M_finished 	<= '0';
			-- recv_buffer <= (others => (others => '0'));
		elsif rising_edge(clk) then
			case SPI_STATE is
				when SPI_IDLE =>
					if (wen = '1' or ren = '1') then
						SPI_STATE	<= SPI_REG;
						toRead 		<= ren; 	-- Temporary, will need to reset after the reg location transition state
						toWrite 		<= wen;
						M_active <= '1'; 		-- Signal to outside
						
						-- Load in the data
						reg_location_I <= regLocation(6 downto 0) & '0'; -- Sending out the MSB already
						data_amount_I <= to_Integer(unsigned(dataAmount));
						data_counter_I <= 0;
						CS_I <= '0';
						forceReset <= '1';
						
						-- Begin data shift out
						MOSI <= regLocation(7); -- MSB Shifting 
						bit_shifter <= bit_shifter(6 downto 0) & '0';
					else
						SPI_STATE <= SPI_IDLE;
						M_active <= '0';
						data_amount_I <= 0;
						forceReset <= '0';
						bit_shifter <= (others => '1');
						CS_I <= '1';
						SCLK_I <= '0';
						MOSI <= '0';
						M_finished <= '0';
					end if;					
				when SPI_REG =>
					forceReset <= '0';
					if (SCLK_H = '1') then
						SCLK_I <= '1'; -- half delay, middle of BIT shifting. Pull SCLK high
					elsif (SCLK_F = '1') then
						 SCLK_I <= '0'; -- Transition bit now
						 if( bit_shifter = "10000000") then -- 
							bit_shifter <= (others => '1');
							MOSI <= reg_location_I(7); -- Last Bit to send off
							if(toWrite = '1')then
								SPI_STATE <= SPI_DATA_SEND;
								data_shifter <= send_buffer(0);
								data_counter_I <= 1;
							elsif (toRead = '1') then
								SPI_STATE <= SPI_DATA_RECV;
								data_counter_I <= 0;
							end if;
							-- toRead <= '0'; needed to force 1 SCLK delay
							toWrite <= '0';
						else 
							MOSI <= reg_location_I(7);
							reg_location_I <= reg_location_I(6 downto 0) & '0';
							bit_shifter <= bit_shifter(6 downto 0) & '0';
						end if;
					end if;
				when SPI_DATA_SEND => 
					if (SCLK_H = '1') then	
						if ( (data_counter_I = data_amount_I+1) and (bit_shifter = "11111110") ) then -- This is for the half delayed CS/CE
							SPI_STATE <= SPI_IDLE;
							M_active <= '0';
							M_finished <= '1';
							data_counter_I <= 0;
							CS_I <= '1';
							SCLK_I <= '0';
						else 
							SCLK_I <= '1'; -- half delay
						end if;
					elsif (SCLK_F = '1') then
						SCLK_I <= '0';
						if ( bit_shifter = "10000000" ) then
							-- clk in new byte, increment counter
							MOSI <= data_shifter(7);
							bit_shifter <= (others => '1');
							if (data_counter_I <= 31) then
								data_shifter <= send_buffer(data_counter_I);
							end if;
							data_counter_I <= data_counter_I + 1;
						else 
							MOSI <= data_shifter(7);
							data_shifter <= data_shifter(6 downto 0) & '0';
							bit_shifter <= bit_shifter(6 downto 0) & '0';
						end if;
					end if;
				when SPI_DATA_RECV =>
					if (SCLK_H = '1') then
						if (data_counter_I = data_amount_I) then
							SPI_STATE <= SPI_IDLE;
							M_active <= '0';
							M_finished <= '1';
							CS_I <= '1';
							data_counter_I <= 0;
							SCLK_I <= '0';
						else 
							SCLK_I <= '1'; -- half delay
						end if;
					elsif (SCLK_F = '1') then
						SCLK_I <= '0'; -- full delay
						MOSI <= '1'; -- Change back to 1 when final NRF Link
						
						if (toRead = '1') then
							toRead <= '0';
							bit_shifter <= (others => '1');
						elsif ( bit_shifter = "00000000" ) then
							-- clk in new byte, increment counter
							recv_buffer(data_counter_I) <= data_shifter;
							data_counter_I <= data_counter_I + 1;
							bit_shifter <= "11111110";
						else 
							bit_shifter <= bit_shifter(6 downto 0) & '0';
						end if;						
						data_shifter(0) <= MISO; -- Always shifting in new data
						data_shifter(7 downto 1) <= data_shifter(6 downto 0);
					end if;					
			end case;
		end if;
	end process;
	
	-- Scaling Process in all modules, able to obtain whichever scale module needs
	process (clk, masterReset) begin
		if (masterReset = '1') then
			clockScalers <= (others => '0'); 		-- Asynchro Reset
		elsif rising_edge(clk) then
			if(forceReset = '1') then 
				clockScalers <= (others => '0'); 	-- Synchro Reset
			else 
				clockScalers <= clockScalers + '1';
			end if;
		end if;
	end process;	

	-- Load in the data, must remain in enable till all required data is loaded in. If no data, 0x00 should be clked in. 
	-- Cap at BUFF_MAX to prevent issues
	process (clk, masterReset) begin
		if (masterReset = '1') then
			DATA_STATE <= DATA_IDLE;
			counter <= 0;
			-- send_buffer <= (others => (others => '0'));
			data_byte_out <= (others => '0');
		elsif rising_edge(clk) then
			case DATA_STATE is
				when DATA_IDLE =>
					if(en = '1') then
						DATA_STATE <= DATA_LOAD;
						if (counter <= 31) then
							send_buffer(counter) <= data_byte_in;
							data_byte_out <= recv_buffer(counter);
						else
							data_byte_out <= (others => '0');
						end if;
						counter <= counter + 1;
					else 
						DATA_STATE <= DATA_IDLE;
						data_byte_out <= (others => '0');
					end if;
				when DATA_LOAD =>
					if (en = '0') then
						DATA_STATE <= DATA_IDLE;
						counter <= 0;
					else 
						if (counter <= 31) then
							send_buffer(counter) <= data_byte_in;
							data_byte_out <= recv_buffer(counter);
						else
							data_byte_out <= (others => '0');
						end if;
						counter <= counter + 1;
					end if;
			end case;
		end if;
	end process;
	
	-- Different type of scaling process, 1 clk HIGH type scaling. Tested SCLK is OK
	-- ___-___-___-___
	-- FSM SCALE 
	-- SCLK scale
	process (clk, masterReset) begin
		if (masterReset = '1') then
			SCLK_STATE_F <= SCLK_IDLE;
			SCLK_F <= '0';
			SCLK_counter <= 0;
		elsif rising_edge(clk) then
			if (forceReset = '1') then
				SCLK_STATE_F <= SCLK_IDLE;
				SCLK_F <= '0';
				SCLK_counter <= 1;
			else 
				case SCLK_STATE_F is
					when SCLK_IDLE =>
						if (SCLK_counter = SCLK_limit) then
							SCLK_STATE_F <= SCLK_WAIT;
							SCLK_F <= '1';
						else 
							SCLK_STATE_F <= SCLK_IDLE;
							SCLK_F <= '0';
							SCLK_counter <= SCLK_counter + 1;
						end if;
					when SCLK_WAIT =>
						SCLK_F <= '0';
						SCLK_STATE_F <= SCLK_IDLE;
						SCLK_counter <= 0;
				end case;
			end if;
		end if;
	end process;
	
	--SCLK 0.5 Scale
	process (clk, masterReset) begin
		if (masterReset='1') then
			SCLK_STATE_H <= SCLK_IDLE;
			SCLK_H <= '0';
		elsif rising_edge(clk) then
			if (forceReset = '1') then
				SCLK_STATE_H <= SCLK_IDLE;
				SCLK_H <= '0';
			else 
				case SCLK_STATE_H is
					when SCLK_IDLE =>
						if (SCLK_counter = SCLK_half) then
							SCLK_STATE_H <= SCLK_WAIT;
							SCLK_H <= '1';
						else 
							SCLK_STATE_H <= SCLK_IDLE;
							SCLK_H <= '0';
						end if;
					when SCLK_WAIT =>
						SCLK_H <= '0';
						SCLK_STATE_H <= SCLK_IDLE;
				end case;				
			end if;
		end if;
	end process;
	
end Behavioral;


