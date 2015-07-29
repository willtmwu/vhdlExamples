LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY fsm_prac4 IS
    PORT ( X 					: IN  STD_LOGIC;
           RESET 				: IN  STD_LOGIC;
           clk100mhz 		: IN  STD_LOGIC;
           Z 					: OUT STD_LOGIC;
			  DEBUG_CHECK		: OUT STD_LOGIC_VECTOR (3 downto 0);
			  DEBUG_OUT			: OUT STD_LOGIC_VECTOR (3 downto 0));
END fsm_prac4;

ARCHITECTURE Behavioral OF fsm_prac4 IS
	TYPE State_check_type IS (B,C,D,E,F);
	--ATTRIBUTE ENUM_ENCODING of State_check_type: type is "000 010 100 110"
	attribute enum_encoding : string;
	attribute enum_encoding of State_check_type : type is "gray";
	
	TYPE State_out_type IS (L,M,N);
	Signal state_check : State_check_type := B;
	Signal state_out : State_out_type := L;
	Signal S : std_logic;
BEGIN
	PROCESS(RESET, clk100mhz) 
	BEGIN
		IF (RESET = '0') THEN
			state_check <= B;
		ELSIF (clk100mhz'EVENT AND clk100mhz = '1') THEN
			CASE state_check IS
				WHEN B =>
					IF X = '1' THEN
						state_check <= C;
					ELSE
						state_check <= B;
					END IF;
					DEBUG_CHECK <= "0000";
					
				WHEN C =>
					IF X = '1' THEN
						state_check <= D;
					ELSE
						state_check <= B;
					END IF;
					DEBUG_CHECK <= "0001";
					
				WHEN D =>
					IF X = '0' THEN
						state_check <= E;
					ELSE
						state_check <= B;
					END IF;
					DEBUG_CHECK <= "0010";
					
				WHEN E =>
					IF X = '1' THEN
						state_check <= F;
					ELSE
						state_check <= B;
					END IF;
					DEBUG_CHECK <= "0011";
					
				WHEN F =>
					IF X = '1' THEN
						state_check <= D;
					ELSE
						state_check <= B;
					END IF;
					DEBUG_CHECK <= "0100";
					
			END CASE;
		END IF;
	END PROCESS;
	
	S <= '1' WHEN (state_check = E AND X = '1') ELSE '0';
	
	PROCESS (RESET, clk100mhz)
	BEGIN
		IF RESET = '0' THEN
			state_out <= L;
		ELSIF (clk100mhz'EVENT AND clk100mhz = '1') THEN
			CASE state_out IS
				WHEN L =>
					IF S = '1' THEN
						state_out <= M;
					ELSE
						state_out <= L;
					END IF;
					DEBUG_OUT <= "0000";
					
				WHEN M =>
					state_out <= N;
					DEBUG_OUT <= "0001";
					
				WHEN N =>
					state_out <= L;
					DEBUG_OUT <= "0010";
					
			END CASE;
		END IF;
	END PROCESS;
	
	Z <= '1' WHEN (state_out = M OR state_out = N) ELSE '0';
	
END Behavioral;

