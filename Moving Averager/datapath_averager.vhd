library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity datapath_averager is
    Port ( mem_addr 			: in  STD_LOGIC_VECTOR(5 downto 0);
           window_val 		: in  STD_LOGIC_VECTOR(1 downto 0);
           overflow 			: out  STD_LOGIC;
           clk 				: in  STD_LOGIC;
			  masterReset 		: in STD_LOGIC;
			  input_val 		: out std_logic_vector (7 downto 0);
           average_val 		: out  STD_LOGIC_VECTOR(7 downto 0));
end datapath_averager;

architecture Behavioral of datapath_averager is

	type DATA_MEM is array (0 to 63) of integer range 0 to 255; 
	signal V : DATA_MEM := (	12, 	23, 	222, 	12, 	231,	42, 	56, 	121, 	78,	76,
										23, 	119, 	12, 	45, 	55,	100, 	21, 	3, 	96, 	34,
										67, 	1,		1, 	54, 	133,	55, 	0, 	5, 	88, 	64,
										88, 	123, 	123, 	24, 	133,	99, 	25, 	44, 	98, 	66,
										200, 	255, 	20, 	45, 	255,	255, 	255, 	255, 	255, 	54,
										1, 	251, 	49, 	234, 	77,	23, 	33, 	94, 	66, 	88,
										222,	12, 	73, 	75 );
	
	type DATA_BUFF is array (0 to 15) of integer range 0 to 255; 
	signal window : integer range 0 to 16 := 4;
	signal fetch_addr : integer range 0 to 64 := 0;
	signal layered_division : integer range 0 to 4 := 2;
	signal average_buff 		:  STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
begin
	
	with window_val select
			window <= 	4 	when "01",
							8 	when "10",
							16 when "11",
							4 when others;
	
	with window_val select
		layered_division <= 	2 when "01",
									3 when "10",
									4 when "11",
									2 when others;
	
	fetch_addr <= conv_integer( IEEE.std_logic_arith.unsigned(mem_addr) );
	--average_val <= average_buff;
	
	process (clk, masterReset) 
		variable buffer_counter : integer range 0 to 16 := 0;
		variable sum : integer range 0 to 511 := 0;
		variable window_buffer : DATA_BUFF := (	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
																0, 0, 0, 0, 0, 0);
		variable temp : std_logic_vector( 8 downto 0);
		variable layered_buffer : DATA_BUFF := (	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
																0, 0, 0, 0, 0, 0);
		variable limit : integer range 0 to 4 := 0;
	begin
			if (masterReset = '1') then
				window_buffer := (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
										0, 0, 0, 0, 0, 0);
				layered_buffer := (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
										0, 0, 0, 0, 0, 0);
				buffer_counter := 0;
				sum := 0;
			elsif (clk'event and clk = '1') then
				window_buffer(buffer_counter) := V(fetch_addr);
				input_val <= std_logic_vector(IEEE.numeric_std.to_unsigned(window_buffer(buffer_counter), 8));
				
				--layered_buffer := window_buffer;
				layered_buffer(0) := window_buffer(0);
				layered_buffer(1) := window_buffer(1);
				layered_buffer(2) := window_buffer(2);
				layered_buffer(3) := window_buffer(3);
				layered_buffer(4) := window_buffer(4);
				layered_buffer(5) := window_buffer(5);
				layered_buffer(6) := window_buffer(6);
				layered_buffer(7) := window_buffer(7);
				layered_buffer(8) := window_buffer(8);
				layered_buffer(9) := window_buffer(9);
				layered_buffer(10) := window_buffer(10);
				layered_buffer(11) := window_buffer(11);
				layered_buffer(12) := window_buffer(12);
				layered_buffer(13) := window_buffer(13);
				layered_buffer(14) := window_buffer(14);
				layered_buffer(15) := window_buffer(15);
				
				--Test
--				limit := (layered_division-1);
--				for I in 0 to 4 loop
--					if (limit >= 0) then
--						layered_buffer(0) := ( (layered_buffer(0)  + layered_buffer(1)) /2 );
--						layered_buffer(1) := ( (layered_buffer(2)  + layered_buffer(3)) /2 );
--						layered_buffer(2) := ( (layered_buffer(4)  + layered_buffer(5)) /2 );
--						layered_buffer(3) := ( (layered_buffer(6)  + layered_buffer(7)) /2 );
--						layered_buffer(4) := ( (layered_buffer(8)  + layered_buffer(9)) /2 );
--						layered_buffer(5) := ( (layered_buffer(10) + layered_buffer(11)) /2 );
--						layered_buffer(6) := ( (layered_buffer(12) + layered_buffer(13)) /2 );
--						layered_buffer(7) := ( (layered_buffer(14) + layered_buffer(15)) /2 );
--					end if;
--					limit := limit - 1;
--				end loop;
	
	
				if (window_val = "01") then
						layered_buffer(0) := ( (layered_buffer(0)  + layered_buffer(1)) /2 );
						layered_buffer(1) := ( (layered_buffer(2)  + layered_buffer(3)) /2 );
						layered_buffer(2) := ( (layered_buffer(4)  + layered_buffer(5)) /2 );
						layered_buffer(3) := ( (layered_buffer(6)  + layered_buffer(7)) /2 );
						layered_buffer(4) := ( (layered_buffer(8)  + layered_buffer(9)) /2 );
						layered_buffer(5) := ( (layered_buffer(10) + layered_buffer(11)) /2 );
						layered_buffer(6) := ( (layered_buffer(12) + layered_buffer(13)) /2 );
						layered_buffer(7) := ( (layered_buffer(14) + layered_buffer(15)) /2 );
						
						layered_buffer(0) := ( (layered_buffer(0)  + layered_buffer(1)) /2 );
						layered_buffer(1) := ( (layered_buffer(2)  + layered_buffer(3)) /2 );
						layered_buffer(2) := ( (layered_buffer(4)  + layered_buffer(5)) /2 );
						layered_buffer(3) := ( (layered_buffer(6)  + layered_buffer(7)) /2 );
						layered_buffer(4) := ( (layered_buffer(8)  + layered_buffer(9)) /2 );
						layered_buffer(5) := ( (layered_buffer(10) + layered_buffer(11)) /2 );
						layered_buffer(6) := ( (layered_buffer(12) + layered_buffer(13)) /2 );
						layered_buffer(7) := ( (layered_buffer(14) + layered_buffer(15)) /2 );
				elsif (window_val = "10") then
						layered_buffer(0) := ( (layered_buffer(0)  + layered_buffer(1)) /2 );
						layered_buffer(1) := ( (layered_buffer(2)  + layered_buffer(3)) /2 );
						layered_buffer(2) := ( (layered_buffer(4)  + layered_buffer(5)) /2 );
						layered_buffer(3) := ( (layered_buffer(6)  + layered_buffer(7)) /2 );
						layered_buffer(4) := ( (layered_buffer(8)  + layered_buffer(9)) /2 );
						layered_buffer(5) := ( (layered_buffer(10) + layered_buffer(11)) /2 );
						layered_buffer(6) := ( (layered_buffer(12) + layered_buffer(13)) /2 );
						layered_buffer(7) := ( (layered_buffer(14) + layered_buffer(15)) /2 );
						
						layered_buffer(0) := ( (layered_buffer(0)  + layered_buffer(1)) /2 );
						layered_buffer(1) := ( (layered_buffer(2)  + layered_buffer(3)) /2 );
						layered_buffer(2) := ( (layered_buffer(4)  + layered_buffer(5)) /2 );
						layered_buffer(3) := ( (layered_buffer(6)  + layered_buffer(7)) /2 );
						layered_buffer(4) := ( (layered_buffer(8)  + layered_buffer(9)) /2 );
						layered_buffer(5) := ( (layered_buffer(10) + layered_buffer(11)) /2 );
						layered_buffer(6) := ( (layered_buffer(12) + layered_buffer(13)) /2 );
						layered_buffer(7) := ( (layered_buffer(14) + layered_buffer(15)) /2 );

						layered_buffer(0) := ( (layered_buffer(0)  + layered_buffer(1)) /2 );
						layered_buffer(1) := ( (layered_buffer(2)  + layered_buffer(3)) /2 );
						layered_buffer(2) := ( (layered_buffer(4)  + layered_buffer(5)) /2 );
						layered_buffer(3) := ( (layered_buffer(6)  + layered_buffer(7)) /2 );
						layered_buffer(4) := ( (layered_buffer(8)  + layered_buffer(9)) /2 );
						layered_buffer(5) := ( (layered_buffer(10) + layered_buffer(11)) /2 );
						layered_buffer(6) := ( (layered_buffer(12) + layered_buffer(13)) /2 );
						layered_buffer(7) := ( (layered_buffer(14) + layered_buffer(15)) /2 );						
				elsif (window_val = "11") then
						layered_buffer(0) := ( (layered_buffer(0)  + layered_buffer(1)) /2 );
						layered_buffer(1) := ( (layered_buffer(2)  + layered_buffer(3)) /2 );
						layered_buffer(2) := ( (layered_buffer(4)  + layered_buffer(5)) /2 );
						layered_buffer(3) := ( (layered_buffer(6)  + layered_buffer(7)) /2 );
						layered_buffer(4) := ( (layered_buffer(8)  + layered_buffer(9)) /2 );
						layered_buffer(5) := ( (layered_buffer(10) + layered_buffer(11)) /2 );
						layered_buffer(6) := ( (layered_buffer(12) + layered_buffer(13)) /2 );
						layered_buffer(7) := ( (layered_buffer(14) + layered_buffer(15)) /2 );						
						
						layered_buffer(0) := ( (layered_buffer(0)  + layered_buffer(1)) /2 );
						layered_buffer(1) := ( (layered_buffer(2)  + layered_buffer(3)) /2 );
						layered_buffer(2) := ( (layered_buffer(4)  + layered_buffer(5)) /2 );
						layered_buffer(3) := ( (layered_buffer(6)  + layered_buffer(7)) /2 );
						layered_buffer(4) := ( (layered_buffer(8)  + layered_buffer(9)) /2 );
						layered_buffer(5) := ( (layered_buffer(10) + layered_buffer(11)) /2 );
						layered_buffer(6) := ( (layered_buffer(12) + layered_buffer(13)) /2 );
						layered_buffer(7) := ( (layered_buffer(14) + layered_buffer(15)) /2 );

						layered_buffer(0) := ( (layered_buffer(0)  + layered_buffer(1)) /2 );
						layered_buffer(1) := ( (layered_buffer(2)  + layered_buffer(3)) /2 );
						layered_buffer(2) := ( (layered_buffer(4)  + layered_buffer(5)) /2 );
						layered_buffer(3) := ( (layered_buffer(6)  + layered_buffer(7)) /2 );
						layered_buffer(4) := ( (layered_buffer(8)  + layered_buffer(9)) /2 );
						layered_buffer(5) := ( (layered_buffer(10) + layered_buffer(11)) /2 );
						layered_buffer(6) := ( (layered_buffer(12) + layered_buffer(13)) /2 );
						layered_buffer(7) := ( (layered_buffer(14) + layered_buffer(15)) /2 );						
						
						layered_buffer(0) := ( (layered_buffer(0)  + layered_buffer(1)) /2 );
						layered_buffer(1) := ( (layered_buffer(2)  + layered_buffer(3)) /2 );
						layered_buffer(2) := ( (layered_buffer(4)  + layered_buffer(5)) /2 );
						layered_buffer(3) := ( (layered_buffer(6)  + layered_buffer(7)) /2 );
						layered_buffer(4) := ( (layered_buffer(8)  + layered_buffer(9)) /2 );
						layered_buffer(5) := ( (layered_buffer(10) + layered_buffer(11)) /2 );
						layered_buffer(6) := ( (layered_buffer(12) + layered_buffer(13)) /2 );
						layered_buffer(7) := ( (layered_buffer(14) + layered_buffer(15)) /2 );						
				end if;
				
	
	
				sum := layered_buffer(0);
				
				--buffer_counter := 0;
				buffer_counter := buffer_counter + 1;
				--buffer_counter := buffer_counter mod window;
				
				if (buffer_counter >= window) then
					buffer_counter := buffer_counter - window;
				end if;
				
				temp := std_logic_vector(IEEE.numeric_std.to_unsigned(sum,9));
				average_val <= temp (7 downto 0);
				--overflow <= temp(8);
				
				if ( sum = 255 ) then
					overflow <= '1';
				else 
					overflow <= '0';
				end if;
				
			end if;
	end process;

	--overflow <= '1' when ( average_val = "111111") else '0';

end Behavioral;

