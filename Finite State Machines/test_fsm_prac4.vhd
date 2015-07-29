LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY test_fsm_prac4 IS
END test_fsm_prac4;
 
ARCHITECTURE behavior OF test_fsm_prac4 IS 
    COMPONENT fsm_prac4
    PORT(
         X : IN  std_logic;
         RESET : IN  std_logic;
         clk100mhz : IN  std_logic;
         Z : OUT  std_logic
        );
    END COMPONENT;
	 
   signal X : std_logic := '0';
   signal RESET : std_logic := '0';
   signal clk100mhz : std_logic := '0';
   signal Z : std_logic;
	
	signal check_data_line : std_logic_vector (15 downto 0) 	:= "0110110100011100";
	signal check_data_match : std_logic_vector (15 downto 0) := "0000011011000000";
	signal check_state_trans : std_logic_vector (19 downto 0) := "11010011101100011010";
   constant clk100mhz_period : time := 10 ns;
	signal full_check_state : std_logic_vector(31 downto 0) := (others => '0');
	subtype counter_bit_int is integer range 0 to 31;
BEGIN

	full_check_state(31 downto 16) <= check_data_line;
	full_check_state(15 downto 0) <= check_data_match;

   uut: fsm_prac4 PORT MAP (
          X => X,
          RESET => RESET,
          clk100mhz => clk100mhz,
          Z => Z
        );

   -- Clock process definitions
   clk100mhz_process :process
   begin	
		clk100mhz <= '0';
		wait for clk100mhz_period/2;
		clk100mhz <= '1';
		wait for clk100mhz_period/2;
   end process;
 
	RESET <= '1';

   -- Stimulus process
   stim_proc: process 
	begin
		RESET <= '0' ;
		wait for clk100mhz_period*10;
		RESET <= '1' ;
		wait for clk100mhz_period*10;
	
		FOR I in 19 downto 0 loop
			wait until clk100mhz'event;
			if clk100mhz = '1' then
				X <= check_state_trans(I);
			end if;
			--assert ( Z = check_data_match(I) ) report "MATCH ERROR" severity error;
		END loop;
		wait until clk100mhz'event and clk100mhz = '1';
		
		wait for clk100mhz_period*10;
		wait;
   end process;

--	tester : process (clk100mHz)
--	variable counter : counter_bit_int := 0;
--	begin
--		--wait until submitButton'event and submitButton = '1' ;
--		if (clk100mhz'event and clk100mhz = '1') then
--			if (counter >= 0) then
--				X <= full_check_state(counter);
--				counter := counter - 1;
--			else 
--				counter := 31;
--			end if;
--		end if;
--	end process;

END;


