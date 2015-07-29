library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity bcd_display is
    Port ( 	clk : in std_logic;
				masterReset : in std_logic;
				byte_in : in  STD_LOGIC_VECTOR(7 downto 0);
				bcd_val : out  STD_LOGIC_VECTOR(11 downto 0)
			  );
end bcd_display;

architecture Behavioral of bcd_display is begin

	process ( masterReset, clk, byte_in )
		 variable byte_src 	: std_logic_vector (4 downto 0) ;
		 variable bcd_out     : std_logic_vector (11 downto 0) ;
	begin
		 if(masterReset = '1') then
			  byte_src := (others => '0');
			  bcd_out := (others => '0');
			  bcd_val <= (others => '0');
		 elsif(clk'event and clk='1') then
			  bcd_out             	:= (others => '0');
			  bcd_out(2 downto 0) 	:= byte_in(7 downto 5);
			  byte_src         		:= byte_in(4 downto 0);
			  
			  for i in byte_src'range loop
					if bcd_out(3 downto 0) > "0100" then
						 bcd_out(3 downto 0) := bcd_out(3 downto 0) + "0011";
					end if ;
					if bcd_out(7 downto 4) > "0100" then
						 bcd_out(7 downto 4) := bcd_out(7 downto 4) + "0011";
					end if ;
					-- No roll over for hundred digit

					bcd_out := bcd_out(10 downto 0) & byte_src(byte_src'left) ;
					byte_src := byte_src(byte_src'left - 1 downto byte_src'right) & '0' ;
			  end loop ;
			  bcd_val <= bcd_out + '1';
		 end if;
	end process ;
	
end Behavioral;




























--Reference: http://stackoverflow.com/questions/23871792/convert-8bit-binary-number-to-bcd-in-vhdl