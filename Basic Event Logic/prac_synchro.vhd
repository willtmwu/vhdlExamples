----------------------------------------------------------------------------------
-- Company: University of Queensland
-- Engineer: MDS
-- 
-- Create Date:    25/07/2014 
-- Design Name: 
-- Module Name:    pracTop - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity prac_synchro is
    Port ( ssegAnode : out  STD_LOGIC_VECTOR (7 downto 0);
           ssegCathode : out  STD_LOGIC_VECTOR (7 downto 0);
           slideSwitches : in  STD_LOGIC_VECTOR (15 downto 0);
           pushButtons : in  STD_LOGIC_VECTOR (4 downto 0);
           LEDs : out  STD_LOGIC_VECTOR (15 downto 0);
			  clk100mhz : in STD_LOGIC;
			  logic_analyzer : out STD_LOGIC_VECTOR (7 downto 0)
			  );
end prac_synchro;

architecture Behavioral of prac_synchro is

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

	component clockedRegister port (
		D : in  STD_LOGIC_VECTOR (15 downto 0);
		E : in  STD_LOGIC;
		clk : in  STD_LOGIC;
		reset : in  STD_LOGIC;
		Q : out  STD_LOGIC_VECTOR (15 downto 0)
		);
	end component;


	signal masterReset : std_logic;

	signal button1 : std_logic;
	signal button2 : std_logic;
	signal submitButton : std_logic;
	
	signal currentState : std_logic_vector(2 downto 0);
	signal openLock : std_logic := '0';
	signal closeLock : std_logic := '0';

	signal correctAttempts : std_logic_vector(7 downto 0) := (others => '0');
	signal incorrectAttempts : std_logic_vector(7 downto 0) := (others => '0');
	
	signal displayKey : std_logic_vector(15 downto 0);
	signal upperKey : std_logic_vector(7 downto 0);
	signal lowerKey : std_logic_vector(7 downto 0);
	signal checkKey : std_logic_vector(15 downto 0);
	signal regEnable : std_logic;
	signal digit5 : std_logic_vector(3 downto 0);
	signal digit6 : std_logic_vector(3 downto 0);
	signal digit7 : std_logic_vector(3 downto 0);
	signal digit8 : std_logic_vector(3 downto 0);
	signal clockScalers : std_logic_vector (26 downto 0);
	
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
	
	u2 : clockedRegister port map (
		D (7 downto 0) => lowerKey,
		D (15 downto 8) => upperKey,
		E => regEnable,
		clk => clockScalers(11),
		reset => masterReset,
		Q => checkKey
	);
	
	masterReset <= pushButtons(3);
	submitButton <= pushButtons(2);
	button1 <= pushButtons(1);
	button2 <= pushButtons(0);
	logic_analyzer <= clockScalers(26 downto 19);

	process (clk100mhz, masterReset) begin
		  if (masterReset = '1') then
					clockScalers <= "000000000000000000000000000";
		  elsif (clk100mhz'event and clk100mhz = '1')then
					clockScalers <= clockScalers + '1';
		  end if;
	end process;
	 
	regEnable <= '1';
	
	process (button1, button2, submitButton, clk100mhz, masterReset) begin
			if (masterReset = '1') then
				openLock <= '0';
				closeLock <= '0';
				lowerKey <= (others => '0');
				upperKey <= (others => '0');
				displayKey <= (others => '0');
			elsif (clk100mhz'event and clk100mhz = '1')then
				if( slideSwitches(7 downto 0) /= "00000110" 
					and slideSwitches(7 downto 0) /= "00110011") then
					openLock <= '0';
				end if;
				
				if (button1 = '1') then
					openLock <= '0';
					closeLock <= '0';
					lowerKey <= displayKey(7 downto 0);
					displayKey(7 downto 0) <= slideSwitches(7 downto 0);
				elsif (button2 = '1') then
					openLock <= '0';
					closeLock <= '0';
					upperKey <= displayKey(15 downto 8);
					displayKey (15 downto 8) <= slideSwitches(7 downto 0);
				elsif (submitButton = '1') then			
					if (lowerKey = "00000110" and upperKey = "00110011") then					
						openLock <= '1';
					else 
						closeLock <= '1';
					end if;
				end if;
			end if;
	end process;
	
	process (openLock , clockScalers) begin
		LEDs (15 downto 2) <= clockScalers(26 downto 13);
		if(openLock = '1') then
			LEDs(0) <= '0';
			LEDs(1) <= '1';
		else
			LEDs(0) <= '1';
			LEDs(1) <= '0';			
		end if;
	end process;
	
	digit6 <= incorrectAttempts(7 downto 4);
	digit5 <= incorrectAttempts(3 downto 0);
	digit8 <= correctAttempts(7 downto 4);
	digit7 <= correctAttempts(3 downto 0);

	process (masterReset, openlock) begin
		if (masterReset = '1') then
			correctAttempts <= (others => '0');
		elsif (openLock'event and openLock = '1' ) then
			correctAttempts <= correctAttempts + '1';
		end if;
	end process;
	
	process (masterReset, closelock) begin
		if (masterReset = '1') then
			incorrectAttempts <= (others => '0');
		elsif (closeLock'event and closeLock = '1' ) then
			incorrectAttempts <= incorrectAttempts + '1';
		end if;
	end process;
	
end Behavioral;

