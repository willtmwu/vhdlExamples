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
            logic_analyzer : out STD_LOGIC_VECTOR (7 downto 0)
            );
end hardware_interface;

architecture Behavioral of hardware_interface is
	component ssegDriver port (
		clk 		: in std_logic;
		rst 		: in std_logic;
		cathode_p: out std_logic_vector(7 downto 0);
		anode_p 	: out std_logic_vector(7 downto 0);
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

	component bcd_counter port (
			rst 		: in std_logic;
			en 		: in std_logic;
			bcd_out 	: out std_logic_vector(7 downto 0);
			clk 		: in std_logic
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
    signal clk2Hz : std_logic := '0';
    
	 --Component Signals
	 signal en1 : std_logic := '0';
	 signal en2 : std_logic := '0';
	 
	 --System Signals
	 TYPE timer_state_fsm IS (start, stop1, stop2);
	 signal timer_state : timer_state_fsm := stop2;
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

	k1 : bcd_counter port map (masterReset, en1, displayUpper(7 downto 0), clk2Hz);
	k2 : bcd_counter port map (masterReset, en2, displayLower(7 downto 0), clk2Hz);

   --Central Button
	masterReset <= pushButtons(4);
	buttonLeft  <= pushButtons(3);
	buttonRight <= pushButtons(0);
	buttonUp    <= pushButtons(2);
	buttonDown  <= pushButtons(1);
    
	LEDs (15 downto 0) <= clockScalers(26 downto 11);
	logic_analyzer (7 downto 0) <= clockScalers(26 downto 19);

	--clk2Hz <= clockScalers(26); 
	-- 3 of 24
	process (clockScalers(23), masterReset ) 
		variable count_scaler : std_logic_vector(2 downto 0) := (others => '0');
		begin
		if (masterReset = '1') then
			count_scaler := (others => '0');
		elsif (clockScalers(23)'event and clockScalers(23) = '1') then
			count_scaler := count_scaler + '1';
			if (count_scaler = 3) then
				clk2Hz <= not(clk2Hz);
				count_scaler := (others => '0');
			end if;
		end if;
	end process;
    
	process (clk100mhz, masterReset) begin
		  if (masterReset = '1') then
					clockScalers <= "000000000000000000000000000";
		  elsif (clk100mhz'event and clk100mhz = '1')then
					clockScalers <= clockScalers + '1';
		  end if;
	end process;

	--en1 <= '1' when (timer_state = start) else '0'
	
	process (masterReset, buttonDown) begin
		if (masterReset = '1') then
			timer_state <= stop2;
			en1 <= '0';
			en2 <= '0';
		elsif (buttonDown'event and buttonDown = '1') then
			case timer_state is
				when stop2 => 
					en1 <= '1';
					en2 <= '1';
					timer_state <= start;
				when start => 
					en1 <= '0';
					timer_state <= stop1;
				when stop1 => 
					en2 <= '0';
					timer_state <= stop2;
			end case;
		end if;
	end process;

end Behavioral;