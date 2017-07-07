library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

package project_nrf_subprogV2 is

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--

	-- Char HEX constants, must be 0-9 and/or lower case a-f. For internal subprog use for now
	constant CHAR_0_i		: STD_LOGIC_VECTOR(7 downto 0) := x"30";
	constant CHAR_9_i		: STD_LOGIC_VECTOR(7 downto 0) := x"39";
	constant CHAR_A_i		: STD_LOGIC_VECTOR(7 downto 0) := x"61";
	constant CHAR_F_i		: STD_LOGIC_VECTOR(7 downto 0) := x"66";

	subtype nib is std_logic_vector(3 downto 0); 
	subtype byte is std_logic_vector(7 downto 0);
	subtype half_w is std_logic_vector(15 downto 0);
	
	function Hamming_hByte_encoder ( X : nib 		) return byte;
	function Hamming_Byte_encoder  ( X : byte 	) return half_w;
	function Hamming_hByte_decoder ( X : byte 	) return nib;
	function Hamming_Byte_decoder  ( X : half_w 	) return byte;

	function CHAR_TO_HEX ( X : byte ) return nib;
	function HEX_TO_CHAR ( X : nib  ) return byte;

	-- std_logic_vector(4 downto 0) to bcd std_logic_vector(7 downto 0);
	subtype input_num	is std_logic_vector(4 downto 0); -- 5 bit
	subtype BCD_HEX is std_logic_vector(7 downto 0);	-- hex
	function to_BCD (X: input_num) return BCD_HEX;

end project_nrf_subprogV2;

package body project_nrf_subprogV2 is
	
	-- Lower (a -> f) and 0->9 ASCII char translated to hex. 0xf on err
	function CHAR_TO_HEX (X:byte) return nib is
			variable tmpByte : byte := (others => '0');
			variable retNib : nib := (others => '0');
		begin
			if (X>=CHAR_A_i and X<=CHAR_F_i) then
				tmpByte := X-CHAR_A_i;
			elsif (X>=CHAR_0_i and X<=CHAR_F_i) then
				tmpByte := X-CHAR_0_i;
			else 
				tmpByte := (others => '0');
			end if;
			retNib := tmpByte(3 downto 0);
			return retNib;
	end CHAR_TO_HEX;
	
	-- Hex 0-F translated to ASCII char. 0x00 on err
	function HEX_TO_CHAR (X:nib) return byte is
			variable tmpByte 	: byte := (others => '0');
			variable tmpOffset: byte := (others => '0');
		begin
			tmpOffset(3 downto 0) := X;
			if (X>="0000" and X<="1001") then
				tmpByte := CHAR_0_i+tmpOffset;
			elsif (X>="1010" and X<="1111") then
				tmpByte := CHAR_A_i+tmpOffset-"00001010";
			else
				tmpByte := (others => '0');
			end if;
			return tmpByte;
	end HEX_TO_CHAR;

	-- Byte in, 16-bit out
	function Hamming_Byte_encoder (X : byte ) return half_w is
			variable lowerByte : byte   := (others => '0');
			variable upperByte : byte   := (others => '0');
			variable ret_half_w: half_w := (others => '0');
		begin
			lowerByte := Hamming_hByte_encoder( X(3 downto 0) );
			upperByte := Hamming_hByte_encoder( X(7 downto 4) );
			ret_half_w(7  downto 0) := lowerByte;
			ret_half_w(15 downto 8) := upperByte;
			return ret_half_w;
	end Hamming_Byte_encoder;

	-- 4 bit in, 8 encoded out
	function Hamming_hByte_encoder (X : nib) return byte is
			variable H0 : std_logic := '0';
			variable H1 : std_logic := '0';
			variable H2 : std_logic := '0';
			variable P  : std_logic := '0';
			variable encoded : std_logic_vector(7 downto 0) := (others => '0');
		begin
		  H0 := X(1) XOR X(2) XOR X(3);
		  H1 := X(0) XOR X(2) XOR X(3);
		  H2 := X(0) XOR X(1) XOR X(3);
		  P  := X(0) XOR X(1) XOR X(2); -- CHECK LOGIC
		  encoded := X & H2 & H1 & H0 & P; 
		  return encoded;
	end Hamming_hByte_encoder;

	-- 16 bits in, byte out
	function Hamming_Byte_decoder (X : half_w ) return byte is
			variable lowerNib : nib := (others => '0');
			variable upperNib : nib := (others => '0');
			variable retByte 	: byte := (others => '0');
		begin
			lowerNib := Hamming_hByte_decoder( X(7 downto 0) );
			upperNib := Hamming_hByte_decoder( X(15 downto 8) );
			retByte(3 downto 0) := lowerNib;
			retByte(7 downto 4) := upperNib;
			return retByte;
	end Hamming_Byte_decoder;
	
	-- 8 Bits in, 4 bits decoded out
	function Hamming_hByte_decoder(X : byte) return nib is
			variable S0 : std_logic := '0';
			variable S1 : std_logic := '0';
			variable S2 : std_logic := '0';
			variable P  : std_logic := '0';
			variable D  : std_logic_vector(7 downto 0) := (others => '0');
			variable R	: std_logic_vector(3 downto 0) := (others => '0');
		begin
			D := X;
			S0 := D(1) XOR D(5) XOR D(6) XOR D(7);
			S1 := D(2) XOR D(4) XOR D(6) XOR D(7);
			S2 := D(3) XOR D(4) XOR D(5) XOR D(7);
			
			-- Method 1 
--			if ( (S0 = '1') and (S1 = '1') and (S2 = '1') ) then
--				D(7) := D(7) XOR '1';				-- Rel D3
--			elsif ( (S0 XOR S1 XOR S2) = '1' ) then
--				D(1) := D(1) XOR S0;					-- H0
--				D(2) := D(2) XOR S1;					-- H1
--				D(3) := D(3) XOR S2;					-- H2
--			else 
--				D(4) := D(4) XOR NOT(S0);			-- Rel D0
--				D(5) := D(5) XOR NOT(S1);			-- Rel D1
--				D(6) := D(6) XOR NOT(S2);			-- Rel D2
--			end if;

			-- Method 2
			D(1) := D(1) XOR (S0 AND NOT(S1) AND NOT(S2));
			D(2) := D(2) XOR (NOT(S0) AND S1 AND NOT(S2));
			D(3) := D(3) XOR (NOT(S0) AND NOT(S1) AND S2);
			D(4) := D(4) XOR (NOT(S0) AND S1 AND S2);
			D(5) := D(5) XOR (S0 AND NOT(S1) AND S2);
			D(6) := D(6) XOR (S0 AND S1 AND NOT(S2));
			D(7) := D(7) XOR (S0 AND S1 AND S2);	
			
			R := D(7 downto 4);
		  return R;
	end Hamming_hByte_decoder;
	
 	function to_BCD (X: input_num) return BCD_HEX is
			variable retHEX : BCD_HEX := (others => '0');
		begin
			if ( X = "00000") then
				retHex := x"00";
			elsif (X = "00001") then
				retHex := x"01";
			elsif (X = "00010") then
				retHex := x"02";
			elsif (X = "00011") then
				retHex := x"03";
			elsif (X = "00100") then
				retHex := x"04";
			elsif (X = "00101") then
				retHex := x"05";
			elsif (X = "00110") then
				retHex := x"06";
			elsif (X = "00111") then
				retHex := x"07";
			elsif (X = "01000") then
				retHex := x"08";
			elsif (X = "01001") then
				retHex := x"09";
			elsif (X = "01010") then
				retHex := x"10";
			elsif (X = "01011") then
				retHex := x"11";
			elsif (X = "01100") then
				retHex := x"12";
			elsif (X = "01101") then
				retHex := x"13";
			elsif (X = "01110") then
				retHex := x"14";
			elsif (X = "01111") then
				retHex := x"15";
			elsif (X = "10000") then
				retHex := x"16";
			elsif (X = "10001") then
				retHex := x"17";
			elsif (X = "10010") then
				retHex := x"18";
			elsif (X = "10011") then
				retHex := x"19";
			elsif (X = "10100") then
				retHex := x"20";
			elsif (X = "10101") then
				retHex := x"21";
			elsif (X = "10110") then
				retHex := x"22";
			elsif (X = "10111") then
				retHex := x"23";
			elsif (X = "11000") then
				retHex := x"24";
			elsif (X = "11001") then
				retHex := x"25";
			elsif (X = "11010") then
				retHex := x"26";
			elsif (X = "11011") then
				retHex := x"27";
			elsif (X = "11100") then
				retHex := x"28";
			elsif (X = "11101") then
				retHex := x"29";
			elsif (X = "11110") then
				retHex := x"30";
			elsif (X = "11111") then
				retHex := x"31";
			end if;
			return retHex;
	end to_BCD; 
end project_nrf_subprogV2;
