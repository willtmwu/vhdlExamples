library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
 
ENTITY test_spi_accell IS
END test_spi_accell;
 
ARCHITECTURE behavior OF test_spi_accell IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT spi_accel
    PORT(
         clk100MHz : IN  std_logic;
         masterReset : IN  std_logic;
         CS : OUT  std_logic;
         SCLK : OUT  std_logic;
         MOSI : OUT  std_logic;
         MISO : IN  std_logic;
         READY : INOUT  std_logic;
         X_VAL : OUT  std_logic_vector(7 downto 0);
         Y_VAL : OUT  std_logic_vector(7 downto 0);
         Z_VAL : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk100MHz : std_logic := '0';
   signal masterReset : std_logic := '0';
	signal MISO : std_logic := '0';

 	--Outputs
   signal CS : std_logic := '1';
   signal SCLK : std_logic;
   signal MOSI : std_logic;
   signal READY : std_logic := '0';
   signal X_VAL : std_logic_vector(7 downto 0);
   signal Y_VAL : std_logic_vector(7 downto 0);
   signal Z_VAL : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk100MHz_period : time := 10 ps;
	
	--Test Bench Signals
	type TEST_FSM is (WAITING, MISO_LOADING);
	signal TEST_STATE : TEST_FSM := WAITING;
	signal mosi_loader : std_logic_vector (7 downto 0) := (others => '0');
	signal counter : integer range 0 to 23 := 23;
	constant ACCEL_REG : std_logic_vector(23 downto 0) := "111100000000111101010101";
	signal clk1Mhz : std_logic := '0';
	
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: spi_accel PORT MAP (
          clk100MHz => clk100MHz,
          masterReset => masterReset,
          CS => CS,
          SCLK => SCLK,
          MOSI => MOSI,
          MISO => MISO,
          READY => READY,
          X_VAL => X_VAL,
          Y_VAL => Y_VAL,
          Z_VAL => Z_VAL
        );

   -- Clock process definitions
   clk100MHz_process :process
   begin
		clk100MHz <= '0';
		wait for clk100MHz_period/2;
		clk100MHz <= '1';
		wait for clk100MHz_period/2;
   end process;
 
	clk1mhz <= not(SCLK);
 
   -- Stimulus process
   stim_proc: process (masterReset, SCLK) begin		
      -- hold reset state for 100 ns.
		if (masterReset = '1') then
			counter <= 23;
			mosi_loader <= (others => '0');
			test_state <= WAITING;
		elsif (sclk'event and sclk = '0') then
			mosi_loader(0) <= mosi_loader(1);
			mosi_loader(1) <= mosi_loader(2);
			mosi_loader(2) <= mosi_loader(3);
			mosi_loader(3) <= mosi_loader(4);
			mosi_loader(4) <= mosi_loader(5);
			mosi_loader(5) <= mosi_loader(6);
			mosi_loader(6) <= mosi_loader(7);
			mosi_loader(7) <= MOSI;
			
			if (mosi_loader = "00010000") then 
				TEST_STATE <= MISO_LOADING;
				MISO <= ACCEL_REG(counter);
				counter <= counter - 1;
			end if;
			
			if (TEST_STATE = MISO_LOADING) then
				MISO <= ACCEL_REG(counter);
				counter <= counter - 1;
				
				if (counter = 0) then
					counter <= 23;
					MISO <= ACCEL_REG(0);
					TEST_STATE <= WAITING;
				end if;
			end if;
			
		end if;
		
   end process;

END;
