library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity hardware_interface is
    Port ( ssegAnode : out  STD_LOGIC_VECTOR (7 downto 0);
           ssegCathode : out  STD_LOGIC_VECTOR (7 downto 0);
           slideSwitches : in  STD_LOGIC_VECTOR (15 downto 0);
           pushButtons : in  STD_LOGIC_VECTOR (4 downto 0);
           LEDs : out  STD_LOGIC_VECTOR (15 downto 0);
			  clk100mhz : in STD_LOGIC;
			  logic_analyzer : out STD_LOGIC_VECTOR (7 downto 0)
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
	
	component bcd_2_adder port (
			Carry_in : in std_logic;			
			Carry_out : out std_logic;
			Adig0: in STD_LOGIC_VECTOR (3 downto 0);
			Adig1: in STD_LOGIC_VECTOR (3 downto 0);
			Bdig0: in STD_LOGIC_VECTOR (3 downto 0);
			Bdig1: in STD_LOGIC_VECTOR (3 downto 0);
			Sdig0: out STD_LOGIC_VECTOR (3 downto 0);
			Sdig1: out STD_LOGIC_VECTOR (3 downto 0)
		);
	end component;

	signal clockScalers : std_logic_vector (26 downto 0);
	signal masterReset : std_logic;
	signal displayKey : std_logic_vector(15 downto 0);
	signal digit5 : std_logic_vector(3 downto 0);
	signal digit6 : std_logic_vector(3 downto 0);
	signal digit7 : std_logic_vector(3 downto 0);
	signal digit8 : std_logic_vector(3 downto 0);
	
	signal buttonA : std_logic;
	signal buttonB : std_logic;
	signal inA0 : std_logic_vector(3 downto 0);
	signal inA1 : std_logic_vector(3 downto 0);
	signal inB0 : std_logic_vector(3 downto 0);
	signal inB1 : std_logic_vector(3 downto 0);
	signal carry_bit : std_logic;
	
	signal mode_selector : std_logic_vector(1 downto 0);
	
BEGIN
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
	
	u2 : bcd_2_adder port map (carry_bit, digit7(0), inA0, inA1, inB0, inB1, digit5, digit6);

	LEDs (15 downto 0) <= clockScalers(26 downto 11);
	process (clk100mhz, masterReset) begin
		if (masterReset = '1') then
				clockScalers <= "000000000000000000000000000";
		elsif (clk100mhz'event and clk100mhz = '1')then
				clockScalers <= clockScalers + '1';
		end if;
	end process;

	buttonA <= pushButtons(0);
	buttonB <= pushButtons(1);
	masterReset <= pushButtons(2);
	mode_selector <= slideSwitches(15 downto 14);
	carry_bit <= slideSwitches(13);
	
	inA0 <= slideSwitches (3 downto 0) when (buttonA'event and buttonA = '1');
	inA1 <= slideSwitches (7 downto 4) when (buttonA'event and buttonA = '1');
	inB0 <= slideSwitches (3 downto 0) when (buttonB'event and buttonB = '1');
	inB1 <= slideSwitches (7 downto 4) when (buttonB'event and buttonB = '1');
	
	displayKey(3 downto 0) <= inA0;
	displayKey(7 downto 4) <= inA1;
	displayKey(11 downto 8) <= inB0;
	displayKey(15 downto 12) <= inB1;
	
	with mode_selector select
	logic_analyzer(3 downto 0) <= inA0 when "01",
											inB0 when "10",
											digit5 when "11";
	
	with mode_selector select
	logic_analyzer(7 downto 4) <= inA1 when "01",
											inB1 when "10",
											digit6 when "11";
	
end Behavioral;

