----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:27:09 09/04/2014 
-- Design Name: 
-- Module Name:    fsm_controller - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fsm_controller is
    Port ( masterReset : in  STD_LOGIC;
           buttonDown : in  STD_LOGIC;
           en1 : out  STD_LOGIC;
           en2 : out  STD_LOGIC);
end fsm_controller;

architecture Behavioral of fsm_controller is
	 TYPE timer_state_fsm IS (start, stop1, stop2);
	 signal timer_state : timer_state_fsm := stop2;
begin

process (masterReset, buttonDown) begin
		if (masterReset = '1') then
			timer_state <= stop2;
			en1 <= '0';
			en2 <= '0';
		elsif (buttonDown'event and buttonDown = '1') then
			case timer_state is
				when stop2 => 
					en1 <= '1';
					en2 <= '1';
					timer_state <= start;
				when start => 
					en1 <= '0';
					timer_state <= stop1;
				when stop1 => 
					en2 <= '0';
					timer_state <= stop2;
			end case;
		end if;
	end process;
end Behavioral;

