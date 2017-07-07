library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity led_bright is
        PORT(
        clk           	: IN  STD_LOGIC;                                    
        masterReset   	: IN  STD_LOGIC;                                    
        ready           : IN  STD_LOGIC;                                    
        accel_val       : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); 
        pwm_out       	: OUT STD_LOGIC); 
end led_bright;

architecture Behavioral of led_bright is
    COMPONENT pwm
    PORT(
         clk : IN  std_logic;
         masterReset : IN  std_logic;
         en : IN  std_logic;
         duty : IN  std_logic_vector(7 downto 0);
         pwm_out : OUT  std_logic
        );
    END COMPONENT;

   signal en : std_logic := '0';
   signal duty : std_logic_vector(7 downto 0) := (others => '0');
	signal clkEdge : std_logic := '0';
	
	type DETECT_FSM is (WAITING, DELAY1);
	signal DETECT_STATE : DETECT_FSM := WAITING;
	
begin

   M1: pwm PORT MAP (clk, masterReset, en, duty, pwm_out);

	duty <= accel_val;
	
	--Control Ready and enable latching
	process (masterReset, clk) begin
		 if (masterReset = '1') then
			  en <= '0';
			  clkEdge <= '0';
			  DETECT_STATE <= WAITING;
		 elsif ( clk'event and clk = '0') then
			if(clkEdge = '0' and ready = '1') then
				DETECT_STATE <= DELAY1;
				en <= '1';
			else 
				case DETECT_STATE is 
					when DELAY1 => 
						DETECT_STATE <= WAITING;
					when WAITING => 
						en <= '0';
				end case;
			end if;
			clkEdge <= ready;
		 end if;
	end process;

end Behavioral;

