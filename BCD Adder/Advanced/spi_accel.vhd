library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity spi_accel is
    Port ( clk100MHz 	: in  STD_LOGIC;
           masterReset 	: in  STD_LOGIC;
           CS 				: out  STD_LOGIC;
           SCLK 			: out  STD_LOGIC;
           MOSI 			: out  STD_LOGIC;
           MISO 			: in  STD_LOGIC;
           READY 			: inout  STD_LOGIC;
           X_VAL 			: out  STD_LOGIC_VECTOR(7 downto 0);
           Y_VAL 			: out  STD_LOGIC_VECTOR(7 downto 0);
           Z_VAL 			: out  STD_LOGIC_VECTOR(7 downto 0));
end spi_accel;

architecture Behavioral of spi_accel is

constant READ_CMD  : std_logic_vector (7 downto 0) := x"0B";
constant WRITE_CMD : std_logic_vector (7 downto 0) := x"0A";

constant POWER_CTL_REG : std_logic_vector (7 downto 0) := x"2D";
constant POWER_CTL_VAL : std_logic_vector (7 downto 0) := x"02";
--"01000000";
--"01010000"

--Can use burst read
constant X_REG : std_logic_vector (7 downto 0) := x"08";
    signal X_VAL_R: std_logic_vector (7 downto 0) := (others => '0');
constant Y_REG : std_logic_vector (7 downto 0) := x"09";
    signal Y_VAL_R: std_logic_vector (7 downto 0) := (others => '0');
constant Z_REG : std_logic_vector (7 downto 0) := x"0A";
    signal Z_VAL_R: std_logic_vector (7 downto 0) := (others => '0');
	 
--signal CS : std_logic := '1';
--signal MOSI : std_logic := '0';
--signal MISO : std_logic := '0';

--Initialise Finished -> READY
--signal READY : std_logic := '0';
signal byteCounter : integer range 0 to 7 := 7;	 
signal byteCounter_delayed : integer range 0 to 7 := 0;

--Intialiser FSM
type SPI_FSM is (CMD, PWR_REG, VAL, DONE, CMD_R, ACC_REG, VAL_ACC, IDLE);
signal SPI_STATE : SPI_FSM := CMD;
signal SPI_STATE_DEBUG : SPI_FSM := CMD;

--Burst Read Accel FSM
type BURST_FSM is (X_VAL_S, Y_VAL_S, Z_VAL_S);
signal BURST_STATE : BURST_FSM := X_VAL_S;
signal BURST_STATE_DEBUG : BURST_FSM := X_VAL_S;

--Clk Scaled Signals
signal clk3Hz : std_logic := '0';
signal clk1MHz : std_logic := '0';

signal clockScalers : std_logic_vector (26 downto 0) := (others => '0');
	
--Edge Detector	
signal clkEdge : std_logic := '0';	
type DETECT_FSM is (WAITING, DELAY1, DELAY2);
signal DETECT_STATE : DETECT_FSM := WAITING;
	
BEGIN

--1MHz Scalar SPI SCLK
--process (masterReset,clk100Mhz) 
--    variable wdCounter : std_logic_vector (7 downto 0) := (others => '0');
--    begin
--    if (masterReset = '1') then
--        wdCounter := "00000000";
--    elsif (clk100Mhz'event and clk100Mhz = '1') then
--        wdCounter := wdCounter + '1';
--        if (wdCounter = "00000111") then
--            clk1Mhz <= not(clk1Mhz);
--            wdCounter := "00000000";
--        end if;
--    end if;
--end process;  
    
--300ms watchdog timer
process (masterReset, clk1Mhz) 
	--Falling edge detector
	begin
    if (masterReset = '1') then
        clk3Hz <= '0';
		  clkEdge <= '0';
		  DETECT_STATE <= WAITING;
    elsif ( clk1Mhz'event and clk1Mhz = '0') then
		if(clkEdge = '1' and clockScalers(24) = '0') then
			DETECT_STATE <= DELAY1;
			clk3Hz <= '1';
		else 
			case DETECT_STATE is 
				when DELAY1 => DETECT_STATE <= DELAY2;
				when DELAY2 => 
					if (READY = '0') then
						DETECT_STATE <= WAITING;
					end if;
				when WAITING => 
					clk3Hz <= '0';
			end case;
		end if;
		clkEdge <= clockScalers(24);
    end if;
end process;

process (clk100Mhz, masterReset) begin
	  if (masterReset = '1') then
			clockScalers <= "000000000000000000000000000";
	  elsif (clk100mhz'event and clk100mhz = '1')then
			clockScalers <= clockScalers + '1';
	  end if;
end process;

	
clk1Mhz <= clockScalers(5);
--SCLK <= not(clk1Mhz);
SCLK <= (clk1Mhz);

READY <= '1' when ( (SPI_STATE_DEBUG = IDLE) or (SPI_STATE_DEBUG = DONE) ) else '0';
X_VAL <= X_VAL_R;
Y_VAL <= Y_VAL_R;
Z_VAL <= Z_VAL_R;

--SPI FSM LOOP
process (masterReset, clk1Mhz) begin
    if (masterReset = '1') then
        CS <= '1';
        SPI_STATE <= CMD;
        BURST_STATE <= X_VAL_S;
        byteCounter <= 7;
		  X_VAL_R <= (others => '0');
		  Y_VAL_R <= (others => '0');
		  Z_VAL_R <= (others => '0');
    elsif (clk1Mhz'event and clk1Mhz = '0') then
        --FSM Sent Data loop
        case SPI_STATE is 
            when CMD =>
                CS <= '0';
                MOSI <= WRITE_CMD(byteCounter);
            when PWR_REG =>
                CS <= '0';
                MOSI <= POWER_CTL_REG(byteCounter);
            when VAL => 
                CS <= '0';
                MOSI <= POWER_CTL_VAL(byteCounter);
            when CMD_R =>
                CS <= '0';
                MOSI <= READ_CMD(byteCounter);
            when ACC_REG => 
                CS <= '0';
                MOSI <= X_REG(byteCounter);
            when VAL_ACC =>
                CS <= '0';
					 MOSI <= '1';
                --Burst FSM Read/Load
                case BURST_STATE_DEBUG is
                    when X_VAl_S =>
                        --X_VAL_R(byteCounter) <= MISO;
								X_VAL_R(byteCounter_delayed) <= MISO;
                    when Y_VAl_S =>
                        --Y_VAL_R(byteCounter) <= MISO;
								Y_VAL_R(byteCounter_delayed) <= MISO;
                    when Z_VAl_S =>
                        --Z_VAL_R(byteCounter) <= MISO;
								Z_VAL_R(byteCounter_delayed) <= MISO;
                end case;
				when others =>
					if (BURST_STATE_DEBUG = Z_VAL_S) then
						Z_VAL_R(0) <= MISO;
					end if;
				
					CS <= '1';
					MOSI <= '0'; 
        end case;
        
        if (byteCounter = 0) then
            --Secondary FSM Switch/Transition Loop
            case SPI_STATE is
                when CMD => SPI_STATE <= PWR_REG;
                when PWR_REG => SPI_STATE <= VAL;
                when VAL => SPI_STATE <= DONE;
                when DONE => 
                    cs <= '1';
                    if (clk3Hz = '1') then 
                        SPI_STATE <= CMD_R;
                    end if;
                when CMD_R => SPI_STATE <= ACC_REG;
                when ACC_REG => SPI_STATE <= VAL_ACC;
                when VAL_ACC => 
                    --Only Transition on Burst FSM
                    if (BURST_STATE = Z_VAL_S) then
                        SPI_STATE <= IDLE;
                    end if;
                    
                    case BURST_STATE is
                        when X_VAl_S => BURST_STATE <= Y_VAL_S;
                        when Y_VAl_S => BURST_STATE <= Z_VAL_S;
                        when Z_VAl_S => BURST_STATE <= X_VAL_S;
                    end case;
                when IDLE =>                 
                    cs <= '1';
                    if (clk3Hz = '1') then 
                        SPI_STATE <= CMD_R;
                    end if;
            end case;
            
            byteCounter <= 7;
        else 
            byteCounter <= byteCounter - 1;
        end if;
    end if;
end process;

--Delayed Clock
process (masterReset, clk1Mhz) begin
	if (masterReset = '1') then
		byteCounter_delayed <= 0;
		SPI_STATE_DEBUG <= CMD;
		BURST_STATE_DEBUG <= X_VAL_S;
	elsif (clk1Mhz'event and clk1Mhz = '0') then
		byteCounter_delayed <= byteCounter;
		SPI_STATE_DEBUG <= SPI_STATE;
		BURST_STATE_DEBUG <= BURST_STATE;
	end if;
end process;

END Behavioral;

