LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY test_fsm_controller IS
END test_fsm_controller;
 
ARCHITECTURE behavior OF test_fsm_controller IS 
    COMPONENT fsm_controller
    PORT(
         masterReset : IN  std_logic;
         buttonDown : IN  std_logic;
         en1 : OUT  std_logic;
         en2 : OUT  std_logic
        );
    END COMPONENT;
    
   --Inputs
   signal masterReset : std_logic := '0';
   signal buttonDown : std_logic := '0';

 	--Outputs
   signal en1 : std_logic;
   signal en2 : std_logic;
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
   constant buttonDown_period : time := 10 ns;
 
	TYPE timer_state_fsm IS (start, stop1, stop2);
	signal timer_state : timer_state_fsm := start;
 
	signal counter_state : std_logic_vector(3 downto 0) := (others => '0');
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: fsm_controller PORT MAP (
          masterReset => masterReset,
          buttonDown => buttonDown,
          en1 => en1,
          en2 => en2
        );
		  
   -- Clock process definitions
   buttonDown_process :process
   begin
		buttonDown <= '0';
		wait for buttonDown_period/2;
		buttonDown <= '1';
		wait for buttonDown_period/2;
   end process;
 

   -- Stimulus process
	process (buttonDown) begin				
	
	if (buttonDown'event and buttonDown = '1') then
		counter_state <= counter_state + '1';
		case timer_state is
				when start => 
					if counter_state = 1 then
						if masterReset = '1' then
							counter_state <= (others => '0');
							timer_state <= stop1;
							masterReset <= '0'
						end if;
						masterReset <= 1;
						counter_staet <= counter_state - '1';
					end if;
					
				when stop1 => 
					if counter_state = 2 then
						if masterReset = '1' then
							counter_state <= (others => '0');
							timer_state <= stop2;
							masterReset <= '0'
						end if;
						masterReset <= 1;
						counter_staet <= counter_state - '1';
					end if;
				when stop2 => 
					if counter_state = 3 then
						if masterReset = '1' then
							counter_state <= (others => '0');
							timer_state <= stop1;
							masterReset <= '0'
						end if;
						masterReset <= 1;
						counter_staet <= counter_state - '1';
					end if;
			end case;
	end if;

   end process;

END;
