----------------------------------------------------------------------------------
-- Company: 				N/A 
-- Engineer: 				WTMW
-- Create Date:    		22:27:15 09/26/2014 
-- Design Name: 			
-- Module Name:    		SPI_Ctrlr.vhd
-- Project Name: 			project_nrf
-- Target Devices: 		Nexys 4
-- Tool versions: 		ISE WEBPACK 64-Bit
-- Description:  			Controls the state of the NRF chip for register read and write, 
--								as well as packet encoding and decoding
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
 
LIBRARY work;
use work.project_nrf_subprogV2.all;  

entity SPI_ctrlr is
    Port ( clk 					: in  STD_LOGIC;
           masterReset 			: in  STD_LOGIC;
			  
			  -- Enable lines
			  m_en					: in 	STD_LOGIC; 	-- EN to enable the module, begin initalisation
			  m_ready				: out STD_LOGIC; 	-- HIGH to say when NRF is ready
			  
			  -- Transmission Seleect Lines
			  sTransmissionLines	: in STD_LOGIC_VECTOR(2 downto 0);
			  
			  -- SEND CMD LINES
			  send_now				: in std_logic; -- HIGH for 1 clock cycle
			  send_message 		: in std_logic_vector(55 downto 0); -- Packet Type(0x20), 4 byte/address. 7 byte payload(Any Identifiers need to be specified by mem controller). Full packet encryption. 
			  send_active			: out STD_LOGIC; 	-- Active in send mode
			  
			  -- RECV CMD LINES
			  recv_dtr				: out STD_LOGIC; -- HIGH 1 clk cycle, latch out the data
			  recv_message			: out STD_LOGIC_VECTOR(55 downto 0); -- Latch out the data per byte
			  recv_active			: out STD_LOGIC; -- Currently still active in latching out the data, undecoded 
			  
			  -- Hamming Error passed in from the switches
			  hamming_err			: in STD_LOGIC_vector(7 downto 0); -- Error passed in from the switches, in top controller
			  
			  -- Control Assignment lines for the NRF chip
			  IRQ 					: in STD_LOGIC; 
			  CE						: out STD_LOGIC;
			  CS 						: out STD_LOGIC;
			  SCLK					: out STD_LOGIC;
			  MOSI					: out STD_LOGIC;
			  MISO					: in  STD_LOGIC;
			  LED_SPI				: out STD_LOGIC_VECTOR(2 downto 0)
		  );
end SPI_ctrlr;

architecture Behavioral of SPI_ctrlr is
			
	 COMPONENT SPI_hw_interface
		PORT(
         clk : IN  std_logic;
         masterReset : IN  std_logic;
         en : IN  std_logic;
         data_byte_in : IN  std_logic_vector(7 downto 0);
         data_byte_out : OUT  std_logic_vector(7 downto 0);
         wen : IN  std_logic;
         ren : IN  std_logic;
         M_active : INOUT  std_logic;
			M_finished : out std_logic;
         regLocation : IN  std_logic_vector(7 downto 0);
         dataAmount : IN  std_logic_vector(5 downto 0);
         CS : OUT  std_logic;
         SCLK : OUT  std_logic;
         MOSI : OUT  std_logic;
         MISO : IN  std_logic
        );
    END COMPONENT;		
			
	-- Initialisation constants
	constant NRF_DEF_CH			: std_logic_vector(7 downto 0) 	:= std_logic_vector(IEEE.numeric_std.to_unsigned(50, 8));
	constant NRF_PACKET_TYPE	: std_logic_vector(7 downto 0) 	:= x"20";
	constant NRF_DEF_SEND_ADDR	: std_logic_vector(39 downto 0) 	:= x"0012345678"; 
	constant NRF_DEF_RECV_ADDR : std_logic_vector(39 downto 0) 	:= x"0042913306"; -- Not used use for NRF_Register, sys default xE7E7E7E7E7
	
	-- Base Station Channels, must reset to configure
	constant NRF_PSNL_CH					: std_logic_vector(7  downto 0) 	:= std_logic_vector(IEEE.numeric_std.to_unsigned(41, 8));
	constant NRF_PSNL_SEND_ADDR		: std_logic_vector(39 downto 0) := x"0042762090";
	constant NRF_PSNL_RECV_ADDR		: std_logic_vector(39 downto 0) := x"0042913306";
	constant NRF_DEF_REG_RECV			: std_logic_vector(39 downto 0) := x"E7E7E7E7E7";
	
	-- ALL Base channel data 
	constant NRF_B1_CH					: std_logic_vector(7  downto 0) 	:= std_logic_vector(IEEE.numeric_std.to_unsigned(43, 8));
	constant NRF_B1_SEND_ADDR			: std_logic_vector(39 downto 0) 	:= x"0012345678"; 
	constant NRF_B2_CH					: std_logic_vector(7  downto 0) 	:= std_logic_vector(IEEE.numeric_std.to_unsigned(46, 8));
	constant NRF_B2_SEND_ADDR			: std_logic_vector(39 downto 0) 	:= x"0012345679"; 
	constant NRF_B3_CH					: std_logic_vector(7  downto 0) 	:= std_logic_vector(IEEE.numeric_std.to_unsigned(48, 8));
	constant NRF_B3_SEND_ADDR			: std_logic_vector(39 downto 0) 	:= x"001234567A"; 
	constant NRF_B4_CH					: std_logic_vector(7  downto 0) 	:= std_logic_vector(IEEE.numeric_std.to_unsigned(50, 8));
	constant NRF_B4_SEND_ADDR			: std_logic_vector(39 downto 0) 	:= x"001234567B"; 
	
	-- Register Location/CMD and Expected Values
	constant NRF_READ_REG		: std_logic_vector(7 downto 0) := x"00";
	constant NRF_WRITE_REG		: std_logic_vector(7 downto 0) := x"20";
	constant NRF_EN_AA         : std_logic_vector(7 downto 0) := x"01"; -- 'Enable Auto Acknowledgment' register address
	constant NRF_RD_RX_PLOAD	: std_logic_vector(7 downto 0) := x"61";
	constant NRF_WR_TX_PLOAD	: std_logic_vector(7 downto 0) := x"A0";
	constant NRF_RX_PW_P0      : std_logic_vector(7 downto 0) := x"11"; -- 'RX payload width, pipe0' register address
	constant NRF_FLUSH_TX		: std_logic_vector(7 downto 0) := x"E1";
	constant NRF_FLUSH_RX		: std_logic_vector(7 downto 0) := x"E2";
	constant NRF_ACTIVATE		: std_logic_vector(7 downto 0) := x"50"; -- Not sure if required	
	constant NRF_CONFIG			: std_logic_vector(7 downto 0) := x"00"; 
	constant NRF_EN_RX_ADDR		: std_logic_vector(7 downto 0) := x"02";
	constant NRF_RF_CH			: std_logic_vector(7 downto 0) := x"05";
	constant NRF_RF_SETUP		: std_logic_vector(7 downto 0) := x"06";
	constant NRF_STATUS 			: std_logic_vector(7 downto 0) := x"07";
	constant NRF_RX_ADDR_P0		: std_logic_vector(7 downto 0) := x"0A";
	constant NRF_TX_ADDR			: std_logic_vector(7 downto 0) := x"10";
	constant NRF_RX_DR			: std_logic_vector(7 downto 0) := x"40";
	constant NRF_TX_DS			: std_logic_vector(7 downto 0) := x"20";
	constant NRF_MAX_RT			: std_logic_vector(7 downto 0) := x"10";
		
	-- Signals for Controller
	type 	 CTRL_FSM is (	CTRL_IDLE,
								CTRL_TX_ADDR, CTRL_RX_ADDR, 
								CTRL_EN_AA, CTRL_EN_RX_ADDR, 
								CTRL_RX_PW_P0, 
								CTRL_RF_CH, 
								CTRL_RF_SETUP, 
								CTRL_NRF_CONFIG,
								
								-- Now finished initialisation and ready for normal operation
								CTRL_MODE_RX, 			-- Re-entry required, for rentry into RX_MODE
								CTRL_FULL_CHECK,		-- Check the Status on LA
								CTRL_READY, 			-- IDLE State after initalisation, Watchdog to enter CHECK_STATUS
								
								CTRL_CHECK_STATUS, 	-- Check Status for FIFO Ready, back to CTRL_READY if no message. Enter READ_RX_FIFO if FIFO ready
								CTRL_READ_RX_FIFO, 	-- READ out the message and decode, ready to latch out the message. Read active begun
								CTRL_FLUSH_RX,			-- Flush Register
								CTRL_CLEAR_STATUS, 	-- Reentry to Mode_RX, after clear by Write 1
								
								CTRL_WRIT_SETUP, 		-- Write to Config to go to TX Mode
								CTRL_WRIT_SEND, 		-- Encrypt Message and Send now, to TX FIFO Buffer
								CTRL_TX_PULSE,			-- Pulse 10us
								CTRL_NRF_SETTLE		-- Settle at least for 800us, for either TX or after CLEAR_STATUS
								
				); -- Implement check methods. Signal RED on error. But continue intialisation
	signal CTRL_STATE 			: CTRL_FSM 							:= CTRL_IDLE;
	constant CTRL_DELAY 			: integer 							:= 100; -- Roughly at least 1 SCLK Between each state execution
	signal CTRL_WAIT_COUNTER	: integer range 100 downto 0 	:= 0;
	
	-- Watchdog signal generation, for CHECK_STATUS entry
	signal 	WD_T_Sig			: std_logic 	:= '0'; 	-- Watch dog siganl ___-___-___-___
	type 		WD_FSM 			is 				(WD_IDLE, WD_SIG);
	signal 	WD_STATE 		: WD_FSM 		:= WD_IDLE;
	signal 	WD_F_Reset		: std_logic 	:= '0'; 	-- Force synchro reset
	constant delay_scaler	: integer 		:= 26; 	-- Change to 26 for actual hardware testing, check on clk scaling
	signal 	clockScalers 	: std_logic_vector(26 downto 0) := (others => '0');
	
	-- Message Buffer 
	subtype 	byte is std_logic_vector(7 downto 0);									-- Byte type
	type 		message_buffer is array(15 downto 0) of byte; 						-- Maximum of 16 byte message, unencoded message
	signal 	NRF_message : message_buffer := (others => (others => '0'));	-- TX message
	signal 	NRF_reply	 : message_buffer := (others => (others => '0'));	-- RX message
	signal 	NRF_L_Check		: std_logic := '0';										-- Sync to write upper or lower
	signal 	message_h_word	: std_logic_vector(15 downto 0) := (others => '0');	
	
	
	-- Signals for SPI Burst Module	
	signal CTRL_PREP			: std_logic := '0'; 								-- To know if SPI data loaded, prepared
	signal CTRL_counter		: integer range 32 downto 0 		:= 0; 	-- Mainly, to count how many bytes to load data in
	signal CTRL_pulse_count	: integer range 1000 downto 0 	:= 0;		-- 10us Exact Pulse
	signal CTRL_settle_count: integer range 80000 downto 0 	:= 0;		-- At least 800us, for base station settling
	
	-- Sub module lines
	signal SPI_en				: std_logic	:= '0';											-- CLK in data
	signal SPI_Byte_in		: std_logic_vector(7 downto 0) := (others => '0');	-- Byte clked in on SPI_EN
	signal SPI_Byte_out		: std_logic_vector(7 downto 0);	-- Byte clked out on SPI_EN
	signal SPI_wen				: std_logic := '0'; 	-- Pulse 1 HIGH Clk to send data
	signal SPI_ren				: std_logic := '0';	-- Pulse 1 HIGH Clk to read from register
	signal SPI_active			: std_logic;			-- Active HIGH
	signal SPI_finish			: std_logic;			-- Pulses OUT on FINISH
	signal SPI_regLocation	: std_logic_vector(7 downto 0) := (others => '0');	-- Register Location to send data
	signal SPI_dataAmount	: std_logic_vector(5 downto 0) := (others => '0');	-- Amount to send, exact bytes 1-32
		
	-- REGISTER SIGNALS
	signal NRF_REG_SET_CH 		: std_logic_vector(7  downto 0) 	:= NRF_DEF_CH;
	signal NRF_REG_SEND_ADDR 	: std_logic_vector(39 downto 0) 	:= NRF_DEF_SEND_ADDR;
	signal NRF_REG_RECV_ADDR 	: std_logic_vector(39 downto 0) 	:= NRF_DEF_REG_RECV;

begin
	M_S: SPI_hw_interface PORT MAP (
		clk, masterReset,
		SPI_en,
		SPI_Byte_in,
		SPI_Byte_out,
		SPI_wen,
		SPI_ren,
		SPI_active,
		SPI_finish,
		SPI_regLocation,
		SPI_dataAmount,
		CS, SCLK, MOSI, MISO		-- NRF Lines
	);

	with sTransmissionLines select
		NRF_REG_SET_CH <= NRF_B1_CH 	when "001",
								NRF_B2_CH 	when "010",
								NRF_B3_CH 	when "011",
								NRF_B4_CH 	when "100",
								NRF_PSNL_CH when "101",
								NRF_DEF_CH 	when others;
								
	with sTransmissionLines select
		NRF_REG_SEND_ADDR	<= NRF_B1_SEND_ADDR 		when "001",
									NRF_B2_SEND_ADDR 		when "010",
									NRF_B3_SEND_ADDR 		when "011",
									NRF_B4_SEND_ADDR 		when "100",
									NRF_PSNL_SEND_ADDR 	when "101",
									NRF_DEF_SEND_ADDR 	when others;
	with sTransmissionLines select
		NRF_REG_RECV_ADDR <= NRF_PSNL_RECV_ADDR 	when "101",
									NRF_DEF_REG_RECV 		when others;

	-- Default TX Payload Headers
	NRF_Message(0) <= NRF_PACKET_TYPE;

	NRF_Message(1) <= NRF_REG_SEND_ADDR(7 downto 0);
	NRF_Message(2) <= NRF_REG_SEND_ADDR(15 downto 8);
	NRF_Message(3) <= NRF_REG_SEND_ADDR(23 downto 16);
	NRF_Message(4) <= NRF_REG_SEND_ADDR(31 downto 24);

	-- Student Number is Switched to LSByte
	NRF_Message(5) <= NRF_DEF_RECV_ADDR(31 downto 24);
	NRF_Message(6) <= NRF_DEF_RECV_ADDR(23 downto 16);
	NRF_Message(7) <= NRF_DEF_RECV_ADDR(15 downto 8);
	NRF_Message(8) <= NRF_DEF_RECV_ADDR(7 downto 0);

	process(clk, masterReset) 
	
	begin
		if(masterReset = '1') then
			CTRL_STATE <= CTRL_IDLE; 	-- IDLE State, uninitialised
			
			CE <= '0';						-- Was 1 on idle, CHECK
			
			SPI_wen <= '0';				-- Submodule Control, WRIT register pulse
			SPI_ren <= '0';				-- Submodule Control, READ register pulse
			
			M_ready 		<= '0';			-- Outside feedback, Controller not yet ready
			SEND_ACTIVE <= '0';			-- Outside feedback, Controller in SEND state
			RECV_ACTIVE <= '0';			-- Outside feedback, Controller in RECV state
			
			RECV_dtr 	 <= '0';				-- DTR Pulse when data on latch (RECV_Message) and ready
			RECV_message <= (others => '0');
			
			CTRL_wait_counter <= 0;		--	State delay counter
			CTRL_prep 			<= '0';	-- State internal synchro, to know when state prepated for re-entry
			CTRL_counter 		<= 0;		-- Byte sent counter
			CTRL_pulse_count 	<= 0;		-- Count for Pulse generation
			CTRL_settle_count <= 0;		-- Settle on state transition
			
			NRF_L_Check <= '0';			-- Signal to synchro upper and lower byte encoded sending
			WD_F_Reset 	<= '0';			-- Force watchdog reset on CTRL_Ready idle re-entry
			
			-- SEND and RECV buffer signals
			message_h_word <= (others => '0');
			--NRF_Reply <= (others => (others => '0'));
			--NRF_Message(9 to 15) <= (others => '0');
			
		elsif rising_edge(clk) then
			case CTRL_STATE is
				when CTRL_IDLE =>
					if(m_en = '1') then
						CE <= '0';
						CTRL_prep <= '0';
						CTRL_STATE <= CTRL_TX_ADDR;
						M_ready <= '0';
						WD_F_Reset <= '0';
						SEND_ACTIVE <= '0';
						RECV_ACTIVE <= '0';
						NRF_L_check <= '0';
						CTRL_counter <= 0;
						CTRL_pulse_count <= 0;
						CTRL_settle_count <= 0;
						recv_dtr <= '0';
						recv_message <= (others => '0');
					else 
						CTRL_STATE <= CTRL_IDLE;
						CE <= '0';			-- WAS '1' on IDLE, CHECK
						SPI_wen <= '0';
						SPI_ren <= '0';
						M_ready <= '0';
						WD_F_Reset <= '0';
						SEND_ACTIVE <= '0';
						RECV_ACTIVE <= '0';
						NRF_L_Check <= '0';
						CTRL_counter <= 0;
						recv_dtr <= '0';
						recv_message <= (others => '0');
						message_h_word <= (others => '0');
						NRF_Reply <= (others => (others => '0'));
					end if;
				when CTRL_TX_ADDR =>
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_RX_ADDR;
						CTRL_PREP <= '0';
						CTRL_counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
					else 
						if (CTRL_PREP = '0') then
							if (CTRL_Counter < 5) then
								SPI_EN <= '1'; -- Enable SPI CLK Module data in, LSB Send
								if (CTRL_Counter = 0) then
									SPI_Byte_in <= NRF_REG_SEND_ADDR(7 downto 0);
								elsif (CTRL_Counter = 1) then
									SPI_Byte_in <= NRF_REG_SEND_ADDR(15 downto 8);
								elsif (CTRL_Counter = 2) then
									SPI_Byte_in <= NRF_REG_SEND_ADDR(23 downto 16);	
								elsif (CTRL_Counter = 3) then
									SPI_Byte_in <= NRF_REG_SEND_ADDR(31 downto 24);
								elsif (CTRL_Counter = 4) then
									SPI_Byte_in <= NRF_REG_SEND_ADDR(39 downto 32);
								end if;
								CTRL_Counter <= CTRL_Counter + 1;
							else
								SPI_EN  <= '0';
								CTRL_PREP <= '1';
								SPI_wen <= '1';
								SPI_Reglocation <= (NRF_TX_ADDR or NRF_WRITE_REG);
								SPI_dataAmount <= "000101"; -- 5 Bytes
							end if;
						else	
							SPI_wen <= '0';
						end if;
					end if;
				when CTRL_RX_ADDR => 
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_EN_AA;
						CTRL_PREP <= '0';
						CTRL_counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 5) then
									SPI_EN <= '1'; -- Enable SPI CLK Module data in, LSB Send
--									SPI_Byte_in <= (others => '0');
									if (CTRL_Counter = 0) then
										SPI_Byte_in <= NRF_REG_RECV_ADDR(7 downto 0);
									elsif (CTRL_Counter = 1) then
										SPI_Byte_in <= NRF_REG_RECV_ADDR(15 downto 8);
									elsif (CTRL_Counter = 2) then
										SPI_Byte_in <= NRF_REG_RECV_ADDR(23 downto 16);	
									elsif (CTRL_Counter = 3) then
										SPI_Byte_in <= NRF_REG_RECV_ADDR(31 downto 24);
									elsif (CTRL_Counter = 4) then
										SPI_Byte_in <= NRF_REG_RECV_ADDR(39 downto 32);
									end if;									
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_RX_ADDR_P0 or NRF_WRITE_REG);
									SPI_dataAmount <= "000101"; -- 5 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;
					end if;
				when CTRL_EN_AA => 
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_EN_RX_ADDR;
						CTRL_PREP <= '0';
						CTRL_counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 1) then
									SPI_EN <= '1'; -- Enable SPI CLK Module data in
									SPI_Byte_in <= (others => '0'); -- Disable Auto.ACK
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_EN_AA or NRF_WRITE_REG);
									SPI_dataAmount <= "000001"; -- 1 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;
					end if;
				when CTRL_EN_RX_ADDR => 
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_RX_PW_P0;
						CTRL_PREP <= '0';
						CTRL_counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 1) then
									SPI_EN <= '1'; -- Enable SPI CLK Module data in
									SPI_Byte_in <= "00000001"; -- Enable Pipe0
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_EN_RX_ADDR or NRF_WRITE_REG);
									SPI_dataAmount <= "000001"; -- 1 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;
					end if;				
				when CTRL_RX_PW_P0 =>
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_RF_CH;
						CTRL_PREP <= '0';
						CTRL_counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
					else
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 1) then
									SPI_EN <= '1'; -- Enable SPI CLK Module data in
									SPI_Byte_in <= "00100000"; -- Enable Pipe0
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_RX_PW_P0 or NRF_WRITE_REG);
									SPI_dataAmount <= "000001"; -- 1 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;
					end if;				
				when CTRL_RF_CH => -- Skipped CE
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_RF_SETUP;
						CTRL_PREP <= '0';
						CTRL_counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 1) then
									SPI_EN <= '1'; -- Enable SPI CLK Module data in
									SPI_Byte_in <= NRF_REG_SET_CH;
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_RF_CH or NRF_WRITE_REG);
									SPI_dataAmount <= "000001"; -- 1 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;
					end if;									
				when CTRL_RF_SETUP =>
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_NRF_CONFIG;
						CTRL_PREP <= '0';
						CTRL_counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 1) then
									SPI_EN <= '1'; -- Enable SPI CLK Module data in
									SPI_Byte_in <= "00000110"; -- TX_PWR:0dBm, Datarate:1Mbps
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_RF_SETUP or NRF_WRITE_REG);
									SPI_dataAmount <= "000001"; -- 1 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;						
					end if;				
				when CTRL_NRF_CONFIG =>
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_MODE_RX;
						CTRL_PREP <= '0';
						CTRL_counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
						CTRL_pulse_count <= 0;
						CTRL_settle_count <= 0;
						recv_dtr <= '0';							-- 
						recv_message <= (others => '0');		-- 
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 1) then
									SPI_EN <= '1'; -- Enable SPI CLK Module data in
									SPI_Byte_in <= x"32"; -- Set PWR_UP bit, enable CRC(2 unsigned chars) & Prim:TX. MAX_RT & TX_DS enabled..
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_CONFIG or NRF_WRITE_REG);
									SPI_dataAmount <= "000001"; -- 1 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;						
					end if;									
				when CTRL_MODE_RX =>
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_FULL_CHECK;
						CTRL_PREP <= '0';
						CTRL_counter <= 0;
						CE <= '1';
						CTRL_WAIT_COUNTER <= 0;
						CTRL_pulse_count <= 0;
						CTRL_settle_count <= 0;
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 1) then
									SPI_EN <= '1'; 		-- Enable SPI CLK Module data in
									SPI_Byte_in <= x"33"; -- Set PWR_UP bit, disable CRC(2 unsigned chars) & Prim:RX. 
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_CONFIG or NRF_WRITE_REG);
									SPI_dataAmount <= "000001"; -- 1 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;
					end if;				
				when CTRL_FULL_CHECK =>
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_READY;
						M_ready <= '1';
						CTRL_PREP <= '0';
						CTRL_counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
						WD_F_RESET <= '1';
						CTRL_SETTLE_COUNT <= 0;
						message_h_word <= (others => '0');
						NRF_Reply <= (others => (others => '0'));
					else
						if (CTRL_SETTLE_COUNT = 13000) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 1) then
									SPI_EN <= '1'; 		-- Enable SPI CLK Module data in
									SPI_Byte_in <= x"ff"; -- Set PWR_UP bit, disable CRC(2 unsigned chars) & Prim:RX. 
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_ren <= '1';
									SPI_Reglocation <= (NRF_CONFIG or NRF_READ_REG);
									SPI_dataAmount <= "000001"; -- 1 Bytes
								end if;
							else	
								SPI_ren <= '0';
							end if;
						else 
							CTRL_SETTLE_COUNT <= CTRL_SETTLE_COUNT + 1;
						end if;						
					end if;				
				when CTRL_READY =>
					if (send_now = '1') then
						CTRL_STATE <= CTRL_WRIT_SETUP;
						SEND_ACTIVE <= '1';
						
						-- Lower Message(0) to Higher Packet(15)
						NRF_Message(9)   <= send_message(55 downto 48);
						NRF_Message(10)  <= send_message(47 downto 40);
						NRF_Message(11)  <= send_message(39 downto 32);
						NRF_Message(12)  <= send_message(31 downto 24);
						NRF_Message(13)  <= send_message(23 downto 16);
						NRF_Message(14)  <= send_message(15 downto  8);
						NRF_Message(15)  <= send_message(7  downto  0);
						
--						NRF_Message(9)   <= send_message(7 downto 0);
--						NRF_Message(10)  <= send_message(15 downto 8);
--						NRF_Message(11)  <= send_message(23 downto 16);
--						NRF_Message(12)  <= send_message(31 downto 24);
--						NRF_Message(13)  <= send_message(39 downto 32);
--						NRF_Message(14)  <= send_message(47 downto 40);
--						NRF_Message(15)  <= send_message(55 downto 48);
						
						message_h_word <= Hamming_Byte_encoder(NRF_Message(0)); -- Set Counter to 1 on follow state
						CTRL_Prep <= '0';
						CTRL_Counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
						
					-- elsif(WD_T_SIG = '1') then
					elsif (IRQ = '0') then
						CTRL_STATE <= CTRL_CHECK_STATUS;
						CTRL_Prep <= '0';
						CTRL_Counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
						RECV_ACTIVE <= '1';
					else 
						WD_F_RESET <= '0';
						SEND_ACTIVE <= '0';
						RECV_ACTIVE <= '0';
						NRF_L_Check <= '0';
						CTRL_pulse_count <= 0;
						CTRL_settle_count <= 0;
					end if;
					
				when CTRL_CHECK_STATUS 	=>
					if (SPI_finish = '1') then 
						CTRL_Counter <= 1; 			-- Synchro for event call
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then 	-- Always have some delay
							if ( (CTRL_PREP = '0') and (CTRL_Counter = 0) ) then
								SPI_Reglocation <= (NRF_STATUS or NRF_READ_REG);
								SPI_dataAmount <= "000001";
								SPI_ren <= '1';
								CTRL_Counter <= 0;
								CTRL_PREP <= '1';
							else 
								if (CTRL_Counter = 0) then
									SPI_ren <= '0';
								elsif (CTRL_Counter = 1) then
									SPI_en <= '1';
									CTRL_Counter <= CTRL_Counter + 1;
								elsif (CTRL_Counter = 2) then
									SPI_en <= '0';
									CTRL_Counter <= CTRL_Counter + 1;
								elsif (CTRL_Counter = 3) then
									if ( (SPI_Byte_out and NRF_RX_DR) = NRF_RX_DR ) then 
										CTRL_STATE <= CTRL_READ_RX_FIFO;
										CTRL_PREP <= '0';
										CTRL_counter <= 0;
										CTRL_WAIT_COUNTER <= 0;
									else
										CTRL_STATE <= CTRL_READY;
										CTRL_PREP <= '0';
										CTRL_counter <= 0;
										CTRL_WAIT_COUNTER <= 0;
									end if;
								end if;
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;						
					end if;							
										
				when CTRL_READ_RX_FIFO	=> 
					if (SPI_finish = '1') then 
						CTRL_Counter <= 1; 			-- Synchro for event call
						CTRL_Prep <= '0';
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then 	-- Always have some delay
							if ( (CTRL_PREP = '0') and (CTRL_Counter = 0) ) then
								SPI_Reglocation<= (NRF_RD_RX_PLOAD or NRF_READ_REG);
								SPI_dataAmount <= "100000";
								SPI_ren 			<= '1';
								CTRL_PREP 		<= '1';
								CTRL_Counter 	<= 0;
							else 
								if (CTRL_Counter = 0) then
									SPI_ren <= '0';
								elsif (CTRL_Counter = 1) then
									SPI_en <= '1';
									CTRL_Counter <= CTRL_Counter + 1;
								elsif (CTRL_Counter = 2) then
									CTRL_Counter <= CTRL_Counter + 1;
								elsif (CTRL_Counter <= 19) then
									if (CTRL_Prep = '0') then
										CTRL_Prep <= '1';
										message_h_word(7 downto 0) <= SPI_Byte_out;

										if (CTRL_Counter > 3) then
											NRF_Reply(CTRL_Counter - 4) <= Hamming_Byte_decoder(message_h_word);
										end if;
									elsif (CTRL_Prep = '1') then
										CTRL_Prep <= '0';
										message_h_word(15 downto 8) <= SPI_Byte_out;
										CTRL_Counter <= CTRL_Counter + 1;
									end if;
								else 
									-- Transition
									CTRL_STATE <= CTRL_FLUSH_RX;
									CTRL_PREP <= '0';
									CTRL_counter <= 0;
									CTRL_WAIT_COUNTER <= 0;
									message_h_word <= (others => '0');
									SPI_en <= '0';
								end if;
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;						
					end if;				
					
				when CTRL_FLUSH_RX =>
					if (SPI_finish = '1') then
						CTRL_STATE 			<= CTRL_CLEAR_STATUS;
						CTRL_PREP 			<= '0';
						CTRL_counter 		<= 0;
						CTRL_WAIT_COUNTER <= 0;
						CE <= '0';
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 1) then
									SPI_EN <= '1'; 			-- Enable SPI CLK Module data in
									SPI_Byte_in <= x"00"; 	-- Clear RX FIFO 
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_FLUSH_RX or NRF_WRITE_REG);
									SPI_dataAmount <= "000001"; -- 1 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;						
					end if;										
					
				when CTRL_CLEAR_STATUS => -- Time to release the message data, dtr and message
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_NRF_SETTLE;
						CTRL_PREP <= '0';
						CTRL_counter <= 0;
						CTRL_WAIT_COUNTER <= 0;
						recv_dtr <= '1';
						
						-- Move out the data						
						recv_message(7  downto  0) <= NRF_REPLY(15);
						recv_message(15 downto  8) <= NRF_REPLY(14);
						recv_message(23 downto 16) <= NRF_REPLY(13);
						recv_message(31 downto 24) <= NRF_REPLY(12);
						recv_message(39 downto 32) <= NRF_REPLY(11);
						recv_message(47 downto 40) <= NRF_REPLY(10);
						recv_message(55 downto 48) <= NRF_REPLY(9);
						
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 1) then
									SPI_EN <= '1';				 		-- Enable SPI CLK Module data in
									SPI_Byte_in <= "01111110"; 	-- Clear RX_DR, TX_DS and MAX_RT by Write 1
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_STATUS or NRF_WRITE_REG);
									SPI_dataAmount <= "000001"; -- 1 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;						
					end if;														
				
				when CTRL_WRIT_SETUP => 
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_WRIT_SEND;
						CTRL_PREP <= '0';
						CTRL_counter <= 1;
						CTRL_WAIT_COUNTER <= 0;
					else 
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 1) then
									SPI_EN <= '1'; -- Enable SPI CLK Module data in
									SPI_Byte_in <= x"32"; --  Set PWR_UP bit, enable CRC(2 unsigned chars) & Prim:TX.
									CTRL_Counter <= CTRL_Counter + 1;
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_CONFIG or NRF_WRITE_REG);
									SPI_dataAmount <= "000001"; -- 1 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;
						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;						
					end if;										
				when CTRL_WRIT_SEND =>
					-- Start with message clking in, 32 bytes
					if (SPI_finish = '1') then
						CTRL_STATE <= CTRL_TX_PULSE;
						CE <= '0';
						CTRL_PREP <= '0';
						CTRL_counter <= 0; -- Amount of bytes sent
						CTRL_WAIT_COUNTER <= 0; -- Wait for CSN DELAY
					else
						if (CTRL_WAIT_COUNTER = CTRL_DELAY) then -- 1 SCLK DELAY
							if (CTRL_PREP = '0') then
								if (CTRL_Counter < 17) then
									if (NRF_L_Check = '0') then
										NRF_L_CHECK <= '1';
										SPI_Byte_in <= message_h_word(7 downto 0)  XOR hamming_err;
									elsif (NRF_L_Check = '1') then
										NRF_L_CHECK <= '0';
										SPI_Byte_in <= message_h_word(15 downto 8) XOR hamming_err;
										if (CTRL_Counter < 16) then
											message_h_word <= Hamming_Byte_encoder(NRF_Message(CTRL_Counter));
										end if;
										CTRL_Counter <= CTRL_Counter + 1;
									end if;
									SPI_EN <= '1'; 		-- Enable SPI CLK Module data in
								else
									SPI_EN  <= '0';
									CTRL_PREP <= '1';
									SPI_wen <= '1';
									SPI_Reglocation <= (NRF_WR_TX_PLOAD);
									SPI_dataAmount <= "100000"; -- 32 Bytes
								end if;
							else	
								SPI_wen <= '0';
							end if;

						else 
							CTRL_WAIT_COUNTER <= CTRL_WAIT_COUNTER + 1;
						end if;						
					end if;				
				when CTRL_TX_PULSE => -- Consider Pulse Delay
					if(CTRL_PULSE_COUNT = 1000)then
						if (CTRL_PREP = '0')  then
							CTRL_Prep <= '1';
							CE <= '1';
							CTRL_STATE <= CTRL_TX_Pulse;
							CTRL_Pulse_count <= 0;
						else 
							CTRL_Prep <= '0';
							CE <= '0';
							CTRL_STATE <= CTRL_NRF_SETTLE;
						end if;
						CTRL_Counter <= 0;
					else 
						CTRL_PULSE_COUNT <= CTRL_PULSE_COUNT + 1;
					end if;
				when CTRL_NRF_SETTLE =>
					if (CTRL_SETTLE_COUNT = 80000) then -- Reduce, delay it is not the issue
						CTRL_SETTLE_COUNT <= 0;
						CTRL_STATE <= CTRL_MODE_RX;
					else 
						CTRL_SETTLE_COUNT <= CTRL_SETTLE_COUNT + 1;
						recv_dtr <= '0';
					end if;
			end case;
		end if;
	end process;
	
	-- Watchdog Process 
	process (clk, masterReset) begin
		if (masterReset = '1') then
			WD_STATE <= WD_IDLE;
			WD_T_SIG <= '0';
		elsif rising_edge(clk) then
			if (WD_F_Reset = '1') then
				WD_STATE <= WD_IDLE;
				WD_T_SIG <= '0';
			else 
				case WD_STATE is
					when WD_IDLE =>
						if (clockScalers(delay_scaler) = '1') then
							WD_STATE <= WD_SIG;
							WD_T_SIG <= '1';
						else
							WD_STATE <= WD_IDLE;
							WD_T_SIG <= '0';
						end if;
					when WD_SIG => 
						WD_T_SIG <= '0';
						if (clockScalers(delay_scaler) = '0') then
							WD_STATE <= WD_IDLE;
						end if;
				end case;
			end if;		
		end if;
	end process;

	-- Scaling Process in all modules, able to obtain whichever scale module needs
	process (clk, masterReset) begin
		if (masterReset = '1') then
			clockScalers <= (others => '0'); 		-- Asynchro Reset
		elsif rising_edge(clk) then
			if (WD_F_Reset = '1') then
				clockScalers <= (others => '0');
			else 
				clockScalers <= clockScalers + '1';
			end if;
		end if;
	end process;	
end Behavioral;