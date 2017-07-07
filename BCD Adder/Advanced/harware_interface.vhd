library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity hardware_interface is
	Port (   ssegAnode : out  STD_LOGIC_VECTOR (7 downto 0);
            ssegCathode : out  STD_LOGIC_VECTOR (7 downto 0);
            slideSwitches : in  STD_LOGIC_VECTOR (15 downto 0);
            pushButtons : in  STD_LOGIC_VECTOR (4 downto 0);
            LEDs : out  STD_LOGIC_VECTOR (15 downto 0);
				clk100mhz : in STD_LOGIC;
            logic_analyzer : out STD_LOGIC_VECTOR (7 downto 0);
				aclMISO 	: IN std_logic;
				aclMOSI  : OUT std_logic;
				aclSCLK  : OUT std_logic;
				aclCS : OUT std_logic;
				RGB1_Red : OUT std_logic;
				RGB1_Green : OUT std_logic;
				RGB1_Blue : OUT std_logic
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

	component spi_accel port ( 
		clk100MHz 	   : in   STD_LOGIC;
		masterReset 	: in   STD_LOGIC;
		CS 				: out  STD_LOGIC;
		SCLK 			   : out  STD_LOGIC;
		MOSI 			   : out  STD_LOGIC;
		MISO 			   : in   STD_LOGIC;
		READY 			: out  STD_LOGIC;
		X_VAL 			: out  STD_LOGIC_VECTOR(7 downto 0);
		Y_VAL 			: out  STD_LOGIC_VECTOR(7 downto 0);
		Z_VAL 			: out  STD_LOGIC_VECTOR(7 downto 0)
		);
	end component;
	
	 component led_bright port(
         clk 			: IN  std_logic;
         masterReset : IN  std_logic;
         ready 		: IN  std_logic;
         accel_val 	: IN  std_logic_vector(7 downto 0);
         pwm_out 		: OUT  std_logic
        );
    end component;
	
	component bcd_display port ( 
			clk : in std_logic;
			masterReset : in std_logic;
			byte_in : in  STD_LOGIC_VECTOR(7 downto 0);
			bcd_val : out  STD_LOGIC_VECTOR(11 downto 0)
			);
	end component;
	
    --Central Button
	signal masterReset : std_logic;
	signal buttonLeft : std_logic;
	signal buttonRight : std_logic;
	signal buttonUp : std_logic;
   signal buttonDown : std_logic;

	signal displayLower : std_logic_vector(15 downto 0);
	signal displayUpper : std_logic_vector(15 downto 0);
	signal clockScalers : std_logic_vector (26 downto 0);
	
	-- Component Signals
   signal CS 		: std_logic := '1';
   signal SCLK 	: std_logic := '0';
   signal MOSI 	: std_logic := '0';
	signal MISO 	: std_logic := '0';
   signal READY 	: std_logic := '0';
   signal X_VAL 	: std_logic_vector(7 downto 0) 	:= (others => '0');
   signal Y_VAL 	: std_logic_vector(7 downto 0) 	:= (others => '0');
   signal Z_VAL 	: std_logic_vector(7 downto 0) 	:= (others => '0');
	signal X_VAL_D : std_logic_vector(11 downto 0) 	:= (others => '0');
   signal Y_VAL_D : std_logic_vector(11 downto 0) 	:= (others => '0');
   signal Z_VAL_D : std_logic_vector(11 downto 0) 	:= (others => '0');
   signal X_PWM 	: std_logic := '0'; 
	signal Y_PWM 	: std_logic := '0';
	signal Z_PWM 	: std_logic := '0';
	
begin	
	--Central Button
	masterReset <= pushButtons(4);
	buttonLeft  <= pushButtons(3);
	buttonRight <= pushButtons(0);
	buttonUp    <= pushButtons(2);
	buttonDown  <= pushButtons(1);
    
	LEDs (15 downto 8) <= clockScalers(26 downto 19);
	--logic_analyzer (7 downto 0) <= clockScalers(26 downto 19);
    
	process (clk100mhz, masterReset) begin
        if (masterReset = '1') then
            clockScalers <= "000000000000000000000000000";
        elsif (clk100mhz'event and clk100mhz = '1')then
            clockScalers <= clockScalers + '1';
        end if;
	end process;

	u1 : ssegDriver port map (
		clk => clockScalers(11),
		rst => masterReset,
		cathode_p => ssegCathode,
		anode_p => ssegAnode,
		digit1_p => displayLower (3 downto 0),
		digit2_p => displayLower (7 downto 4),
		digit3_p => displayLower (11 downto 8),
		digit4_p => displayLower (15 downto 12),
		digit5_p => displayUpper (3 downto 0),
		digit6_p => displayUpper (7 downto 4),
		digit7_p => displayUpper (11 downto 8),
		digit8_p => displayUpper (15 downto 12)
	); 

	m1 : spi_accel port map (clk100Mhz, masterReset, CS, SCLK, MOSI, MISO, READY, X_VAL, Y_VAL, Z_VAL);
	logic_analyzer(0) <= clk100Mhz;
	logic_analyzer(1) <= masterReset;
	logic_analyzer(2) <= CS;
	logic_analyzer(3) <= SCLK;	
	logic_analyzer(4) <= MOSI;	
	logic_analyzer(5) <= MISO;	
	logic_analyzer(6) <= READY;	
	--logic_analyzer(7) <= '0';
	
	--Accel Linking
	aclCS <= CS;
	aclSCLK <= SCLk;
	aclMOSI <= MOSI;
	MISO <= aclMISO;	

--	displayLower(15 downto 8) <= X_VAL;
--	displayLower(7 downto 0) <= Y_VAL;
--	displayUpper(7 downto 0) <= Z_VAL;
	D1 : bcd_display port map (Ready, masterReset, X_VAL,  X_VAL_D);
	D2 : bcd_display port map (Ready, masterReset, Y_VAL,  Y_VAL_D);
	D3 : bcd_display port map (Ready, masterReset, Z_VAL,  Z_VAL_D);
	
	--PWM Linking
	P1 : led_bright port map(clk100Mhz, masterReset, ready, X_VAL, X_PWM);
	P2 : led_bright port map(clk100Mhz, masterReset, ready, Y_VAL, Y_PWM);
	P3 : led_bright port map(clk100Mhz, masterReset, ready, Z_VAL, Z_PWM);
	
	--LEDBAR and PWM Linking
	process ( slideSwitches(15 downto 13) ) begin 
		if ( (slideSwitches(15) = '0') and (slideSwitches(14) = '0') and (slideSwitches(13) = '1')) then
			LEDs(7 downto 0) <= Y_VAL;
			displayLower(11 downto 0) <= Y_VAL_D;
			logic_analyzer(7) <= Y_PWM;
			RGB1_Red   <= '0';
			RGB1_Green <= Y_PWM;
			RGB1_Blue  <= '0';
		elsif ( (slideSwitches(15) = '0') and (slideSwitches(14) = '1') and (slideSwitches(13) = '0')) then
			LEDs(7 downto 0) <= X_VAL;
			displayLower(11 downto 0) <= X_VAL_D;
			logic_analyzer(7) <= X_PWM;
			RGB1_Red   <= X_PWM;
			RGB1_Green <= '0';
			RGB1_Blue  <= '0';
		elsif ( (slideSwitches(15) = '1') and (slideSwitches(14) = '0') and (slideSwitches(13) = '0')) then
			LEDs(7 downto 0) <= Z_VAL;
			displayLower(11 downto 0) <= Z_VAL_D;
			logic_analyzer(7) <= Z_PWM;
			RGB1_Red   <= '0';
			RGB1_Green <= '0';
			RGB1_Blue  <= Z_PWM;
		elsif ( (slideSwitches(15) = '1') and (slideSwitches(14) = '1') and (slideSwitches(13) = '1')) then
			LEDs(7 downto 0) <= "10101010";
			RGB1_Red   <= X_PWM;
			RGB1_Green <= Y_PWM;
			RGB1_Blue  <= Z_PWM;
		else
			LEDs(7 downto 0) <= (others => '0');
			RGB1_Red <= '0';
			RGB1_Green <= '0';
			RGB1_Blue <= '0';
		end if;
	end process;
end Behavioral;