library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity hardware_interface is
	Port (  ssegAnode : out  STD_LOGIC_VECTOR (7 downto 0);
            ssegCathode : out  STD_LOGIC_VECTOR (7 downto 0);
            slideSwitches : in  STD_LOGIC_VECTOR (15 downto 0);
            pushButtons : in  STD_LOGIC_VECTOR (4 downto 0);
            LEDs : out  STD_LOGIC_VECTOR (15 downto 0);
				clk100mhz : in STD_LOGIC;
            logic_analyzer : out STD_LOGIC_VECTOR (7 downto 0);
				JC : out STD_LOGIC_VECTOR (7 downto 0);
				JD : out STD_LOGIC_VECTOR (7 downto 0)
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

	component datapath_averager Port ( 
			mem_addr 			: in  STD_LOGIC_VECTOR(5 downto 0);
			window_val 		: in  STD_LOGIC_VECTOR(1 downto 0);
			overflow 			: out  STD_LOGIC;
			clk 				: in  STD_LOGIC;
			masterReset 		: in STD_LOGIC;
			input_val 		: out  STD_LOGIC_VECTOR(7 downto 0);
			average_val 		: out  STD_LOGIC_VECTOR(7 downto 0)
			);
	end component;
	
	component datapath_controller Port ( 	
				window_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
				masterReset : in STD_LOGIC;
				mem_addr 	: OUT  STD_LOGIC_VECTOR(5 downto 0);
				window_val : OUT  std_logic_vector(1 downto 0);
				overflow : IN  std_logic;
				clk : in  STD_LOGIC
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
	
    --Clock scaled signals
	signal clk2Hz : std_logic;
    
	 --Bridging Signals
	signal window_ctrl :  STD_LOGIC_VECTOR(1 downto 0):="01";
	signal mem_addr 	:   STD_LOGIC_VECTOR(5 downto 0):=(others => '0');
	signal window_val :   std_logic_vector(1 downto 0) :=(others => '0');
	signal overflow :   std_logic := '0';
	signal input_val : std_logic_vector (7 downto 0) := (others => '0');	
	signal average_val : std_logic_vector (7 downto 0) := (others => '0');
	 
begin
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
	
	m1 : datapath_controller port map (window_ctrl, masterReset, mem_addr, window_val, overflow, clk2Hz);
	m2 : datapath_averager port map (mem_addr, window_val, overflow, clk2Hz, masterReset, input_val, average_val);
	
    --Central Button
	masterReset <= pushButtons(4);
	buttonLeft  <= pushButtons(3);
	buttonRight <= pushButtons(0);
	buttonUp    <= pushButtons(2);
	buttonDown  <= pushButtons(1);
    
	LEDs (15 downto 0) <= clockScalers(26 downto 11);
	logic_analyzer (7 downto 0) <= clockScalers(26 downto 19);

	clk2Hz <= clockScalers(19);
    
	process (clk100mhz, masterReset) begin
			if (masterReset = '1') then				
            clockScalers <= "000000000000000000000000000";
        elsif (clk100mhz'event and clk100mhz = '1')then
            clockScalers <= clockScalers + '1';
        end if;
	end process;

	--Window Ctrl and Debugging
	window_ctrl(0) <= slideSwitches(14) when (buttonDown'event and buttonDown = '1') else '0';
	window_ctrl(1) <= slideSwitches(15) when (buttonDown'event and buttonDown = '1') else '1';
	
	--window_ctrl <= "01";
	
	--logic_analyzer(6 downto 0) <= average_val (6 downto 0);
	--logic_analyzer(7) <= clk2hz;
	
	displayLower(7 downto 0) <= average_val;
	displayLower(15 downto 8) <= input_val;
	
	displayUpper(5 downto 0) <= mem_addr;
	displayUpper(15 downto 14) <= window_val;
	
	JC <= input_val;
	JD <= average_val;
	
end Behavioral;