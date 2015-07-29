library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity hardware_tester_fsm is
	Port (  ssegAnode : out  STD_LOGIC_VECTOR (7 downto 0);
           ssegCathode : out  STD_LOGIC_VECTOR (7 downto 0);
           slideSwitches : in  STD_LOGIC_VECTOR (15 downto 0);
           pushButtons : in  STD_LOGIC_VECTOR (4 downto 0);
           LEDs : out  STD_LOGIC_VECTOR (15 downto 0);
			  clk100mhz : in STD_LOGIC;
			  logic_analyzer : out STD_LOGIC_VECTOR (7 downto 0)
			  );
end hardware_tester_fsm;

architecture Behavioral of hardware_tester_fsm is
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
	
	component fsm_prac4 PORT ( 
		X 				: IN  STD_LOGIC;
		RESET 		: IN  STD_LOGIC;
		clk100mhz 	: IN  STD_LOGIC;
		Z 				: OUT  STD_LOGIC;
		DEBUG_CHECK	: OUT STD_LOGIC_VECTOR(3 downto 0);
		DEBUG_OUT 	: OUT STD_LOGIC_VECTOR(3 downto 0));
	end component;
	
	signal masterReset : std_logic;

	signal button1 : std_logic;
	signal button2 : std_logic;
	signal submitButton : std_logic;

	signal displayKey : std_logic_vector(15 downto 0);
	signal digit5 : std_logic_vector(3 downto 0);
	signal digit6 : std_logic_vector(3 downto 0);
	signal digit7 : std_logic_vector(3 downto 0);
	signal digit8 : std_logic_vector(3 downto 0);
	signal clockScalers : std_logic_vector (26 downto 0);
	
	signal X,RESET,Z : std_logic;
	signal DEBUG_CHECK, DEBUG_OUT : std_logic_vector (3 downto 0) := (others => '0');
	
	subtype counter_bit_int is integer range 0 to 31;
	signal shift_pattern : std_logic_vector (15 downto 0) := (others => '0');
	--signal counting_vect : std_logic_vector (3 downto 0) := (others => '0');
begin
	u1 : ssegDriver port map (
		clk => clockScalers(11),
		rst => masterReset,
		cathode_p => ssegCathode,
		anode_p => ssegAnode,
		digit1_p => displayKey (3 downto 0),
		digit2_p => displayKey (7 downto 4),
		digit3_p => displayKey (11 downto 8),
		digit4_p => displayKey (15 downto 12),
		digit5_p => digit5,
		digit6_p => digit6,
		digit7_p => digit7,
		digit8_p => digit8
	); 

	u2 : fsm_prac4 port map (X, RESET, clockScalers(11), Z, DEBUG_CHECK, DEBUG_OUT);

	masterReset <= pushButtons(3);
	submitButton <= pushButtons(2);
	button1 <= pushButtons(1);
	button2 <= pushButtons(0);
	LEDs (15 downto 0) <= clockScalers(26 downto 11);
	
	logic_analyzer(0) <= Z;
	--logic_analyzer(1) <= X;
	logic_analyzer(2) <= clk100mHz;
	logic_analyzer(3) <= clockScalers(11);
	logic_analyzer(7 downto 4) <= DEBUG_CHECK;
	
	--RESET <= NOT(masterReset);
	RESET <= '1';

	process (clk100mhz, masterReset) begin
		  if (masterReset = '1') then
					clockScalers <= "000000000000000000000000000";
		  elsif (clk100mhz'event and clk100mhz = '1')then
					clockScalers <= clockScalers + '1';
		  end if;
	end process;
	
	displayKey <= shift_pattern;
	
	process(masterReset, clockScalers(11), button1) begin
		if (masterReset = '1') then
			shift_pattern <= (others => '0');
		elsif (clockScalers(11)'event and clockScalers(11) = '1') then
			if (button1 = '1') then
				shift_pattern <= slideSwitches;
			end if;
		end if;
		
	end process;
	
	process (clockScalers(11))
	--variable counter : counter_bit_int := 15;
	variable counting_vect : integer := 0;
	begin
		--wait until submitButton'event and submitButton = '1' ;
		if (clockScalers(11)'event and clockScalers(11) = '1') then
			if (counting_vect >= 0) then
				X <= shift_pattern(counting_vect);
				logic_analyzer(1) <= shift_pattern(counting_vect);
				counting_vect := counting_vect - 1;
			else 
				counting_vect := 15;
			end if;
		end if;
	end process;
end Behavioral;