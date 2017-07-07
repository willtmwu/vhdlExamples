----------------------------------------------------------------------------------
-- Company: 				N/A 
-- Engineer: 				WTMW
-- Create Date:    		22:27:15 09/26/2014 
-- Design Name: 			
-- Module Name:    		hardware_interface.vhd
-- Project Name: 			project_nrf
-- Target Devices: 		Nexys 4
-- Tool versions: 		ISE WEBPACK 64-Bit
-- Description:  			Interface to PIN/PORT and combines/split signals
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

LIBRARY work;
use work.project_nrf_subprog.all; 

entity hardware_interface is
	Port (  	ssegAnode 		: out  STD_LOGIC_VECTOR (7 downto 0);
            ssegCathode 	: out  STD_LOGIC_VECTOR (7 downto 0);
				
            slideSwitches 	: in  STD_LOGIC_VECTOR (15 downto 0);
            pushButtons 	: in  STD_LOGIC_VECTOR (4 downto 0);
				
            LEDs 				: out  STD_LOGIC_VECTOR (15 downto 0);
				clk100mhz 		: in STD_LOGIC;
				
            logic_analyzer : out STD_LOGIC_VECTOR (7 downto 0);
				RGB1_Red 		: OUT std_logic;
				RGB1_Green 		: OUT std_logic;
				RGB1_Blue 		: OUT std_logic;
				RGB2_Red 		: OUT std_logic;
				RGB2_Green 		: OUT std_logic;
				RGB2_Blue 		: OUT std_logic;
				
				JD_I				: in STD_LOGIC_VECTOR(1 downto 0);
				JD_O				: out std_logic_vector(5 downto 0)
		);
end hardware_interface;

architecture Behavioral of hardware_interface is
	component ssegDriver port (
		clk : in std_logic;
		rst : in std_logic;
		cathode_p : out std_logic_vector(7 downto 0);
		anode_p : out std_logic_vector(7 downto 0);
		digit1_p : in std_logic_vector(3 downto 0);
		digit2_p : in std_logic_vector(3 downto 0);
		digit3_p : in std_logic_vector(3 downto 0);
		digit4_p : in std_logic_vector(3 downto 0);
		digit5_p : in std_logic_vector(3 downto 0);
		digit6_p : in std_logic_vector(3 downto 0);
		digit7_p : in std_logic_vector(3 downto 0);
		digit8_p : in std_logic_vector(3 downto 0)
		); 
	end component;

    --Central Button
	signal masterReset 	: std_logic := '0';
	signal buttonLeft 	: std_logic := '0';
	signal buttonRight 	: std_logic := '0';
	signal buttonUp 		: std_logic := '0';
	signal buttonDown 	: std_logic := '0';
	-- Create 1 HIGH CLK signal, for button debouncing
	type   DEBOUNCE_FSM 	is (DB_IDLE, DB_HIGH);
	signal bLeftSig 		: std_logic := '0';
	signal bLeft_state	: DEBOUNCE_FSM := DB_IDLE;
	signal bRightSig		: std_logic := '0';
	signal bRight_state	: DEBOUNCE_FSM := DB_IDLE;
	signal bUpSig 			: std_logic := '0';
	signal bUp_state		: DEBOUNCE_FSM := DB_IDLE;
	signal bDownSig 		: std_logic := '0';
	signal bDown_state	: DEBOUNCE_FSM := DB_IDLE;
	
	signal displayLower 	: std_logic_vector(15 downto 0) := (others => '0');
	signal displayUpper 	: std_logic_vector(15 downto 0) := (others => '0');
	signal clockScalers 	: std_logic_vector(26 downto 0) := (others => '0');

	signal hamming_error : std_logic_vector(7 downto 0) := (others => '0');
	signal data_nib		: std_logic_vector(3 downto 0) := (others => '0');
	signal LED_UART 		: std_logic_vector(2 downto 0) := (others => '0');
	signal LED_SPI 		: std_logic_vector(2 downto 0) := (others => '0'); 
	
	signal MISO : std_logic := '0'; 	-- In Lines JD_I
	signal MOSI : std_logic;			-- OUT line JD_O	
	signal SCLK : std_logic;			-- OUT
	signal CS 	: std_logic;			-- OUT
	signal CE 	: std_logic;			-- OUT
	signal IRQ	: std_logic := '0';	-- OUT

	signal sTransmissionChange 	: std_logic_vector(2 downto 0) := (others => '0');
	signal sHighSpeedTrans			: std_logic := '0';
	COMPONENT top_controller
	    Port ( 	
				clk 				: in  STD_LOGIC;
				masterReset 	: in STD_LOGIC; 
				bSend				: in STD_LOGIC; -- Right Button
				bModeChange		: in STD_LOGIC; -- Up Button
				bEnterData		: in STD_LOGIC; -- Bottom Button
				bCount			: in STD_LOGIC; -- Left Button
				sTransmission 	: in STD_LOGIC_VECTOR(2 downto 0); 
				sHighSpeed		: in STD_LOGIC;					

				displayLower 	: out STD_LOGIC_VECTOR(15 downto 0); 
				displayUpper 	: out STD_LOGIC_VECTOR(15 downto 0); 
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
	END COMPONENT;
	
begin
	D1 : ssegDriver port map (
		clk => clockScalers(11),
		rst => masterReset,
		cathode_p => ssegCathode,
		anode_p 	=> ssegAnode,
		digit1_p => displayLower (3 downto 0),
		digit2_p => displayLower (7 downto 4),
		digit3_p => displayLower (11 downto 8),
		digit4_p => displayLower (15 downto 12),
		digit5_p => displayUpper (3 downto 0),
		digit6_p => displayUpper (7 downto 4),
		digit7_p => displayUpper (11 downto 8),
		digit8_p => displayUpper (15 downto 12)
	); 

	-- Central Button
	masterReset <= pushButtons(4);
	buttonLeft  <= pushButtons(3);
	buttonRight <= pushButtons(0);
	buttonUp    <= pushButtons(2);
	buttonDown  <= pushButtons(1);
   
	-- Button Debouncing -- Generate HIGH for 1 CLK Cycle
	-- LEFT Button 
	process begin
		if (masterReset = '1') then
			bLeftSig <= '0';
			bLeft_State <= DB_IDLE;
		elsif rising_edge(clk100mHz) then
			case bLeft_State is
				when DB_IDLE =>
					if (buttonLeft = '1') then
						bLeftSig <= '1';
						bLeft_State <= DB_HIGH;
					else 
						bLeftSig <= '0';
						bLeft_State <= DB_IDLE;
					end if;
				when DB_HIGH => 
					bLeftSig <= '0';
					if (buttonLeft = '0') then
						bLeft_State <= DB_IDLE;
					end if;
			end case;
		end if;
	end process;
	
	-- Right Button 
	process begin
		if (masterReset = '1') then
			bRightSig <= '0';
			bRight_State <= DB_IDLE;
		elsif rising_edge(clk100mHz) then
			case bRight_State is
				when DB_IDLE =>
					if (buttonright = '1') then
						bRightSig <= '1';
						bRight_State <= DB_HIGH;
					else 
						bRightSig <= '0';
						bRight_State <= DB_IDLE;
					end if;
				when DB_HIGH => 
					bRightSig <= '0';
					if (buttonRight = '0') then
						bRight_State <= DB_IDLE;
					end if;
			end case;
		end if;
	end process;	 
	
	-- Up Button 
	process begin
		if (masterReset = '1') then
			bUpSig <= '0';
			bUp_State <= DB_IDLE;
		elsif rising_edge(clk100mHz) then
			case bUp_State is
				when DB_IDLE =>
					if (buttonUp = '1') then
						bUpSig <= '1';
						bUp_State <= DB_HIGH;
					else 
						bUpSig <= '0';
						bUp_State <= DB_IDLE;
					end if;
				when DB_HIGH => 
					bUpSig <= '0';
					if (buttonUp = '0') then
						bUp_State <= DB_IDLE;
					end if;
			end case;
		end if;
	end process;	 
	
	-- Down Button 
	process begin
		if (masterReset = '1') then
			bDownSig <= '0';
			bDown_State <= DB_IDLE;
		elsif rising_edge(clk100mHz) then
			case bDown_State is
				when DB_IDLE =>
					if (buttonDown = '1') then
						bDownSig <= '1';
						bDown_State <= DB_HIGH;
					else 
						bDownSig <= '0';
						bDown_State <= DB_IDLE;
					end if;
				when DB_HIGH => 
					bDownSig <= '0';
					if (buttonDown = '0') then
						bDown_State <= DB_IDLE;
					end if;
			end case;
		end if;
	end process;	 
	 
	process (clk100mhz, masterReset) begin
        if (masterReset = '1') then
            clockScalers <= "000000000000000000000000000";
        elsif rising_edge(clk100mhz) then
            clockScalers <= clockScalers + '1';
        end if;
	end process;

	LEDs (15 downto 0) <= clockScalers(26 downto 11);
	logic_analyzer (7 downto 0) <= clockScalers(26 downto 19);

	-- Tri-Colour Debug LED
	hamming_error 	<= slideSwitches(11 downto 4);
	data_nib 		<= slideSwitches(3  downto 0);
	sTransmissionChange <= slideSwitches(15 downto 13);
	sHighSpeedTrans <= slideSwitches(12);
	RGB1_Red 		<= LED_UART(0);
	RGB1_Green 		<= LED_UART(1);
	RGB1_Blue 		<= LED_UART(2);
	RGB2_Red 		<= LED_SPI(0);
	RGB2_Green 		<= LED_SPI(1);
	RGB2_Blue 		<= LED_SPI(2);
	
	-- SPI Control Lines
	MISO 		<= JD_I(0); 
	JD_O(0) 	<= MOSI; 
	JD_O(1) 	<= SCLK; 
	JD_O(2) 	<= CS; 
	JD_O(3) 	<= CE; 
	IRQ 		<= JD_I(1); 
	JD_O(4) 	<= '0'; 	
	JD_O(5) 	<= '0'; 		
	
	CT_S : top_controller PORT MAP (
		clk100mHz,
		masterReset,
		bRightSig,
		bUpSig,
		bDownSig,
		bLeftSig,
		sTransmissionChange,
		sHighSpeedTrans,
		displayLower,
		displayUpper,
		data_nib,
		hamming_error,
		IRQ,
		CE,
		CS,
		SCLK,
		MOSI,
		MISO,
		LED_SPI
	);
	
end Behavioral;