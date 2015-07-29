----------------------------------------------------------------------------------
-- Company: 				N/A 
-- Engineer: 				WTMW
-- Create Date:    		22:27:15 09/26/2014 
-- Design Name: 			
-- Module Name:    		top_controller.vhd
-- Project Name: 			project_nrf
-- Target Devices: 		Nexys 4
-- Tool versions: 		ISE WEBPACK 64-Bit
-- Description:  			Controls memory access and full message sending in 6 packets
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

LIBRARY work;
use work.project_nrf_subprogV2.all;  

entity top_controller is
    Port ( 	
			clk 			: in  STD_LOGIC;
			masterReset 	: in STD_LOGIC; 

			-- Buttons and display for direct memory view
			bSend				: in STD_LOGIC; -- Right Button
			bModeChange		: in STD_LOGIC; -- Up Button
			bEnterData		: in STD_LOGIC; -- Bottom Button
			bCount			: in STD_LOGIC; -- Left Button

			-- Switch send/receive address, base1, base 2, base 3, base 4, partner
			sTransmission 	: in STD_LOGIC_VECTOR(2 downto 0); 	
			-- switch High Speed Transmission
			sHighSpeed		: in STD_LOGIC;						

			displayLower 	: out STD_LOGIC_VECTOR(15 downto 0); -- RECV(1,0) | SEND(1,0)
			displayUpper 	: out STD_LOGIC_VECTOR(15 downto 0); -- MODE(0-A) | COUNT(0-31)
			data_nib			: in std_logic_vector(3 downto 0);

			-- NRF CTRL Lines fed down to SPI_CTRL
			hamming_err : IN  std_logic_vector(7 downto 0);
			IRQ : in std_logic;
			CE : OUT  std_logic;
			CS : OUT  std_logic;
			SCLK : OUT  std_logic;
			MOSI : OUT  std_logic;
			MISO : IN  std_logic;
			LED_SPI : OUT  std_logic_vector(2 downto 0)
    );
end top_controller;

architecture Behavioral of top_controller is
	
	COMPONENT SPI_ctrlr
	PORT(
		clk : IN  std_logic;
		masterReset : IN  std_logic;
		m_en : IN  std_logic;
		m_ready : OUT  std_logic;
		sTransmissionLines	: in STD_LOGIC_VECTOR(2 downto 0);
		send_now : IN  std_logic;
		send_message : IN  std_logic_vector(55 downto 0);
		send_active : OUT  std_logic;
		recv_dtr : OUT  std_logic;
		recv_message : OUT  std_logic_vector(55 downto 0);
		recv_active : OUT  std_logic;
		hamming_err : IN  std_logic_vector(7 downto 0);
		IRQ : in std_logic;
		CE : OUT  std_logic;
		CS : OUT  std_logic;
		SCLK : OUT  std_logic;
		MOSI : OUT  std_logic;
		MISO : IN  std_logic;
		LED_SPI : OUT  std_logic_vector(2 downto 0)
		);
	END COMPONENT;
	
	component RAM_BLOCK -- Array of 64 nibbles
	port( 
        clk 	: in 	std_logic;
        we	 	: in 	std_logic;
        en  	: in 	std_logic;
        addr	: in 	std_logic_vector(5 downto 0);
        d_i 	: in 	std_logic_vector(3 downto 0);
        d_o 	: out std_logic_vector(3 downto 0)
    );
	end COMPONENT;
	
	signal  SEND_CACHE          : std_logic_vector(55 downto 0) := (others => '0');
	signal 	SEND_STRING_WEN		: std_logic := '0';
	signal 	SEND_STRING_EN		: std_logic := '0';
	signal 	SEND_STRING_ADDR	: std_logic_vector(5 downto 0) := (others => '0');
	signal 	SEND_STRING_Di		: std_logic_vector(3 downto 0) := (others => '0');
	signal 	SEND_STRING_Do		: std_logic_vector(3 downto 0);
	signal  SEND_STRING_OFFSET	: integer range 13 downto  0 := 0;
	signal  DATA_ENTER_L        : std_logic := '0';
    
	signal  RECV_CACHE           : std_logic_vector(55 downto 0) := (others => '0');
	signal  RECV_STRING_WEN		: std_logic := '0';
	signal  RECV_STRING_EN		: std_logic := '0';
	signal  RECV_STRING_ADDR	    : std_logic_vector(5 downto 0) := (others => '0');
	signal  RECV_STRING_Di		: std_logic_vector(3 downto 0) := (others => '0');
	signal  RECV_STRING_Do		: std_logic_vector(3 downto 0);

	signal RECV_PACKET_Num		: integer range 15  downto  0 := 6;
	signal RECV_STRING_OFFSET		: integer range 13 downto  0 := 0;

	-- 2 FSM, 1 main controller, 1 change state
	type   DISPLAY_MODE_FSM	is 	(DISPLAY_PAUSED, DISPLAY_SPEED_1, DISPLAY_SPEED_2, DISPLAY_SPEED_3);
	signal DATA_Counter		: integer range 31 downto 0 := 0;
	signal DISPLAY_STATE 	: DISPLAY_MODE_FSM	:= DISPLAY_PAUSED;
	signal DISPLAY_L_BYTE   : std_logic := '0';
	signal DISPLAY_SEND_BYTE    : std_logic_vector(7 downto 0) := (others => '0');
	signal DISPLAY_RECV_BYTE    : std_logic_vector(7 downto 0) := (others => '0');   
	 
	-- Signal Generation for Display
	signal clockScalers 	: std_logic_vector(26 downto 0) := (others => '0');
	signal COUNT_T_SIG	: std_logic	:= '0';
	type 	 COUNT_FSM 		is (COUNT_IDLE, COUNT_HIGH);
	signal COUNT_STATE 	: COUNT_FSM := COUNT_IDLE;

	-- Delay Counter
	constant SPEED_Low 	: integer := 500_000_000; 
	constant SPEED_High	: integer := 930_000;
	signal TRANS_SPEED	: integer range SPEED_LOW downto 0 := 0;
	signal COUNTER_MSG_DELAY : integer range SPEED_LOW downto 0 := 0;

	-- Initialisation Counter
	constant INIT_DELAY 	: integer := 1000_000;
	signal COUNTER_INIT	: integer range INIT_DELAY downto 0 := 0;

	-- Message Counter 
	constant TOTAL_PACKETS	: integer := 6;
	signal MSG_SENT			: integer range TOTAL_PACKETS downto 0 := 0; -- 32 Bytes, 6/Packet = 6 packets total. Header is 0-5

	-- Main FSM
	type TOP_CTRL_FSM is (TOP_CTRL_INIT, TOP_CTRL_IDLE, TOP_CTRL_RECV_CACHE, TOP_CTRL_SEND_CACHE, TOP_CTRL_SEND, TOP_CTRL_SEND_WAIT, TOP_CTRL_DELAY);
	signal TOP_CTRL_STATE : TOP_CTRL_FSM := TOP_CTRL_INIT;

	-- SPI Submodule
	signal SPI_MC_en 			: std_logic := '0';
	signal SPI_MC_ready 		: std_logic;
	signal SPI_C_send_now 		: std_logic := '0';
	signal SPI_C_send_active 	: std_logic;
	signal SPI_C_send_message 	: std_logic_vector(55 downto 0) := (others => '0');
	signal SPI_C_recv_dtr 		: std_logic;
	signal SPI_C_recv_active 	: std_logic;
	signal SPI_C_recv_message 	: std_logic_vector(55 downto 0);

begin
	
	TRANS_SPEED <= SPEED_LOW when sHighSpeed = '0' else SPEED_HIGH;

	displayLower(7 downto 0)    <= DISPLAY_SEND_BYTE;
	displayLower(15 downto  8)  <= DISPLAY_RECV_BYTE;
	displayUpper(7 downto 0) 	<=  to_BCD(std_logic_vector(IEEE.numeric_std.to_unsigned(Data_counter, 5))); --Display BCD of Count
--	with DISPLAY_STATE select
--		displayUpper(15 downto 8) <= 	x"0A" when DISPLAY_PAUSED,
--												x"01" when DISPLAY_SPEED_1,
--												x"02" when DISPLAY_SPEED_2,
--												x"03" when DISPLAY_SPEED_3;
												
	with DISPLAY_STATE select
		displayUpper(11 downto 8) <= 	x"A" when DISPLAY_PAUSED,
												x"1" when DISPLAY_SPEED_1,
												x"2" when DISPLAY_SPEED_2,
												x"3" when DISPLAY_SPEED_3;
		displayUpper(15 downto 12) <= std_logic_vector(IEEE.numeric_std.to_unsigned(RECV_Packet_num, 4));

	-- Main FSM Loop
	process (masterReset, clk) 
		variable upper_vect    : integer range 55 downto 0 := 0;
		variable lower_vect    : integer range 55 downto 0 := 0;
		variable packet_number : integer range 5 downto 0 := 0;
	begin
		if (masterReset = '1') then
			MSG_SENT <= 0;
			COUNTER_MSG_DELAY <= 0;
			COUNTER_INIT <= 0;
			TOP_CTRL_STATE <= TOP_CTRL_INIT;
		elsif rising_edge(clk) then
			case TOP_CTRL_STATE is
				when TOP_CTRL_INIT => 
					if (COUNTER_INIT = INIT_DELAY) then
						if (SPI_MC_Ready = '1') then
                            SEND_STRING_EN <= '1';  -- Enable both RAM Modules
                            RECV_STRING_EN <= '1';
							TOP_CTRL_STATE <= TOP_CTRL_IDLE; -- NRF Chip initialised
						end if;
					else 
						COUNTER_INIT <= COUNTER_INIT + 1;
						SPI_MC_EN <= '1';
					end if;
				when TOP_CTRL_IDLE =>
					if (bSend = '1') then
						MSG_SENT <= 0;
                        SEND_STRING_WEN <= '0';
                        SEND_STRING_ADDR <= (others => '0');
                        SEND_STRING_OFFSET <= 1;
                        TOP_CTRL_STATE <= TOP_CTRL_SEND_CACHE;
					elsif (SPI_C_recv_dtr = '1') then
						-- Filter and store in the data
                        RECV_CACHE      <= SPI_C_recv_message;
                        RECV_STRING_OFFSET <= 0;
								RECV_STRING_WEN <= '0';
								RECV_STRING_ADDR <= (others => '0');
								if ( SPI_C_recv_message(51 downto 48) = "1111" ) then
									RECV_PACKET_Num <= conv_integer( IEEE.std_logic_arith.unsigned(SPI_C_recv_message(55 downto 52)) );
								else 
									RECV_PACKET_Num <= 6;
								end if;
								TOP_CTRL_STATE  <= TOP_CTRL_RECV_CACHE;
					elsif(bEnterData = '1') then
                        SEND_STRING_WEN <= '1';
                        SEND_STRING_Di <= data_nib;
                        if (Data_Enter_L = '0') then
                            SEND_STRING_ADDR <= std_logic_vector(IEEE.numeric_std.to_unsigned(Data_counter*2, 6));
                            DATA_Enter_L <= '1';
                        else 
                            SEND_STRING_ADDR <= std_logic_vector(IEEE.numeric_std.to_unsigned(Data_counter*2+1, 6));
                            DATA_Enter_L <= '0';
                        end if;
                        
                    elsif((COUNT_T_SIG = '1') or (bCount = '1')) then
                        if (Data_counter < 31) then
                            DATA_Counter <= DATA_Counter + 1;
                        else 
                            DATA_Counter <= 0;
                        end if;
                    else
                        SEND_STRING_WEN <= '0';
                        RECV_STRING_WEN <= '0';
                        if (DISPLAY_L_Byte = '0') then
                            SEND_STRING_ADDR <= std_logic_vector(IEEE.numeric_std.to_unsigned(Data_counter*2+1, 6));
									 RECV_STRING_ADDR <= std_logic_vector(IEEE.numeric_std.to_unsigned(Data_counter*2+1, 6));
                            DISPLAY_SEND_BYTE(7 downto 4) <= SEND_STRING_Do;
									 DISPLAY_RECV_BYTE(7 downto 4) <= RECV_STRING_Do;
                            DISPLAY_L_Byte <= '1';
                        else
                            SEND_STRING_ADDR <= std_logic_vector(IEEE.numeric_std.to_unsigned(Data_counter*2, 6)); -- Reverse offset, and multiples due to clock delay
									 RECV_STRING_ADDR <= std_logic_vector(IEEE.numeric_std.to_unsigned(Data_counter*2, 6)); -- Reverse offset, and multiples due to clock delay
									 DISPLAY_SEND_BYTE(3 downto 0) <= SEND_STRING_Do;
										DISPLAY_RECV_BYTE(3 downto 0) <= RECV_STRING_Do;
                            DISPLAY_L_Byte <= '0';
                        end if;
					end if;
                    
                when TOP_CTRL_RECV_CACHE =>
							if( RECV_PACKET_Num <= 5 ) then
								if (RECV_PACKET_NUM = 5) then
									if (RECV_STRING_OFFSET <= 3) then
											RECV_STRING_WEN <= '1';
											lower_vect := RECV_STRING_OFFSET*4;
											upper_vect := ((RECV_STRING_OFFSET+1)*4)-1;												
											RECV_STRING_ADDR <= std_logic_vector(IEEE.numeric_std.to_unsigned(RECV_PACKET_Num*12 + RECV_STRING_OFFSET, 6));
											RECV_STRING_Di <= RECV_CACHE(upper_vect downto lower_vect);
											RECV_STRING_OFFSET <= RECV_STRING_OFFSET + 1;
									  else
											RECV_STRING_WEN <= '0';
											RECV_STRING_OFFSET <= 0;
											-- RECV_STRING_ADDR <= (others => '0');
											TOP_CTRL_STATE <= TOP_CTRL_IDLE;
									  end if;                     
								else 
								  if (RECV_STRING_OFFSET <= 11) then
												RECV_STRING_WEN <= '1';
												lower_vect := RECV_STRING_OFFSET*4;
												upper_vect := ((RECV_STRING_OFFSET+1)*4)-1;												
												RECV_STRING_ADDR <= std_logic_vector(IEEE.numeric_std.to_unsigned(RECV_PACKET_Num*12 + RECV_STRING_OFFSET, 6));
                                    RECV_STRING_Di <= RECV_CACHE(upper_vect downto lower_vect);
												RECV_STRING_OFFSET <= RECV_STRING_OFFSET + 1;
                                else
                                    RECV_STRING_WEN <= '0';
                                    RECV_STRING_OFFSET <= 0;
                                    TOP_CTRL_STATE <= TOP_CTRL_IDLE;
                                end if;                                
								end if;
                    else 
                        if (RECV_STRING_OFFSET <= 13) then
										RECV_STRING_WEN <= '1';
                            lower_vect := RECV_STRING_OFFSET*4;
                            upper_vect := ((RECV_STRING_OFFSET+1)*4)-1;
									 RECV_STRING_ADDR <= std_logic_vector(IEEE.numeric_std.to_unsigned(RECV_STRING_OFFSET, 6));
                            RECV_STRING_Di <= RECV_CACHE(upper_vect downto lower_vect);
									 RECV_STRING_OFFSET <= RECV_STRING_OFFSET + 1;
                        else
                            RECV_STRING_WEN <= '0';
                            RECV_STRING_OFFSET <= 0;
                            TOP_CTRL_STATE <= TOP_CTRL_IDLE;
                        end if;
                    end if;
                when TOP_CTRL_SEND_CACHE => 
                    if ( MSG_SENT = (TOTAL_PACKETS-1) ) then	
                        if (SEND_STRING_OFFSET<=4) then -- Unload from RAM and cache
                            if (SEND_STRING_OFFSET>=2) then
										 upper_vect := ((SEND_STRING_OFFSET-1)*4)-1;	
										 lower_vect := (SEND_STRING_OFFSET-2)*4;
										 SEND_CACHE(upper_vect downto lower_vect) <= SEND_STRING_Do;
									 end if;                        
                            SEND_STRING_ADDR <= std_logic_vector(IEEE.numeric_std.to_unsigned(MSG_SENT*12 + SEND_STRING_OFFSET, 6));
                            SEND_STRING_OFFSET <= SEND_STRING_OFFSET + 1;                            
                        else
                            SEND_STRING_OFFSET <= 1;
                            SEND_CACHE(47 downto 16) <= (others => '0');
                            SEND_CACHE(51 downto 48) <= (others => '1'); -- Byte 6
                            SEND_CACHE(55 downto 52) <= std_logic_vector(IEEE.numeric_std.to_unsigned(MSG_SENT, 4));
                            TOP_CTRL_STATE <= TOP_CTRL_SEND;                        
                        end if;
                    elsif (MSG_SENT <= (TOTAL_PACKETS-2)) then
                        if (SEND_STRING_OFFSET <= 12) then -- Unload from RAM and cache
									 if (SEND_STRING_OFFSET>=2) then
										 upper_vect := ((SEND_STRING_OFFSET-1)*4)-1;	
										 lower_vect := (SEND_STRING_OFFSET-2)*4;
										 SEND_CACHE(upper_vect downto lower_vect) <= SEND_STRING_Do;
									 end if;                            
                            SEND_STRING_ADDR <= std_logic_vector(IEEE.numeric_std.to_unsigned(MSG_SENT*12 + SEND_STRING_OFFSET, 6));
                            SEND_STRING_OFFSET <= SEND_STRING_OFFSET + 1;
                        else 
                            SEND_STRING_OFFSET <= 1;
                            SEND_CACHE(51 downto 48) <= (others => '1'); -- Byte 6
                            SEND_CACHE(55 downto 52) <= std_logic_vector(IEEE.numeric_std.to_unsigned(MSG_SENT, 4));
                            TOP_CTRL_STATE <= TOP_CTRL_SEND;
                        end if;
                    end if;
				when TOP_CTRL_SEND =>
                    SPI_C_send_now <= '1';
                    SPI_C_send_message <= SEND_CACHE;
					TOP_CTRL_STATE <= TOP_CTRL_SEND_WAIT;
				when TOP_CTRL_SEND_WAIT => 
					SPI_C_send_now <= '0';
					if (SPI_C_send_active = '0') then
						TOP_CTRL_STATE <= TOP_CTRL_DELAY;
					end if;
				when TOP_CTRL_DELAY => -- Delay after each packet send
					if (COUNTER_MSG_DELAY = TRANS_SPEED) then
						COUNTER_MSG_DELAY <= 0;
						if (MSG_SENT = TOTAL_PACKETS-1) then
							TOP_CTRL_STATE <= TOP_CTRL_IDLE;
							MSG_SENT <= 0;
						else 
							TOP_CTRL_STATE <= TOP_CTRL_SEND_CACHE;
							MSG_SENT <= MSG_SENT + 1;
						end if;
					else 
						COUNTER_MSG_DELAY <= COUNTER_MSG_DELAY + 1;
					end if;
			end case;
		end if;
	end process;
	
	-- Counting Signal Generation
	process (masterReset, clk) begin
		if (masterReset = '1') then
			COUNT_T_SIG <= '0';
			COUNT_STATE <= COUNT_IDLE;
		elsif rising_edge(clk) then
			case COUNT_STATE is
				when COUNT_IDLE =>
					if (DISPLAY_STATE = DISPLAY_PAUSED) then
						COUNT_T_SIG <= '0';
					elsif (DISPLAY_STATE = DISPLAY_SPEED_1) then
						if (clockScalers(26) = '1') then
							COUNT_T_SIG <= '1';
							COUNT_STATE <= COUNT_HIGH;
						end if;
					elsif (DISPLAY_STATE = DISPLAY_SPEED_2) then
						if (clockScalers(25) = '1') then
							COUNT_T_SIG <= '1';
							COUNT_STATE <= COUNT_HIGH;
						end if;					
					elsif (DISPLAY_STATE = DISPLAY_SPEED_3) then
						if (clockScalers(24) = '1') then
							COUNT_T_SIG <= '1';
							COUNT_STATE <= COUNT_HIGH;
						end if;					
					end if;
				when COUNT_HIGH => 
					COUNT_T_SIG <= '0';
					if (DISPLAY_STATE = DISPLAY_SPEED_1) then
						if (clockScalers(26) = '0') then
							COUNT_STATE <= COUNT_IDLE;
						end if;
					elsif (DISPLAY_STATE = DISPLAY_SPEED_2) then
						if (clockScalers(25) = '0') then
							COUNT_STATE <= COUNT_IDLE;
						end if;					
					elsif (DISPLAY_STATE = DISPLAY_SPEED_3) then
						if (clockScalers(24) = '0') then
							COUNT_STATE <= COUNT_IDLE;
						end if;					
					end if;					
			end case;
		end if;
	end process;
	
	-- DISPLAY_STATE switching 
	process (masterReset, clk) begin
		if (masterReset = '1') then
			DISPLAY_STATE 		<= DISPLAY_PAUSED;
		elsif rising_edge(clk) then
			case DISPLAY_STATE is
				when DISPLAY_PAUSED  => 
					if (bModeChange = '1') then
						DISPLAY_STATE <= DISPLAY_SPEED_1;
					end if;
				when DISPLAY_SPEED_1 =>
					if (bModeChange = '1') then
						DISPLAY_STATE <= DISPLAY_SPEED_2;
					end if;					
				when DISPLAY_SPEED_2 =>
					if (bModeChange = '1') then
						DISPLAY_STATE <= DISPLAY_SPEED_3;
					end if;				
				when DISPLAY_SPEED_3 =>
					if (bModeChange = '1') then
						DISPLAY_STATE <= DISPLAY_PAUSED;
					end if;				
			end case;
		end if;
	end process;
	
	process (clk, masterReset) begin
	  if (masterReset = '1') then
			clockScalers <= "000000000000000000000000000";
	  elsif rising_edge(clk) then
			clockScalers <= clockScalers + '1';
	  end if;
	end process;
	
	SPI_C: SPI_ctrlr PORT MAP (
		clk,
		masterReset,
		SPI_MC_en,
		SPI_MC_ready,
		sTransmission,
		SPI_C_send_now,
		SPI_C_send_message,
		SPI_C_send_active,
		SPI_C_recv_dtr,
		SPI_C_recv_message,
		SPI_C_recv_active,
		hamming_err,
		-- NRF Control Lines
		IRQ,
		CE,
		CS,
		SCLK,
		MOSI,
		MISO,
		LED_SPI
	);
	
	SEND_RAM: RAM_BLOCK PORT MAP (
		clk,
		SEND_STRING_WEN,
		SEND_STRING_EN,
		SEND_STRING_ADDR,
		SEND_STRING_Di,
		SEND_STRING_Do
	);
    
    RECV_RAM: RAM_BLOCK PORT MAP (
		clk,
		RECV_STRING_WEN,
		RECV_STRING_EN,
		RECV_STRING_ADDR,
		RECV_STRING_Di,
		RECV_STRING_Do	
	);
	
end Behavioral;



