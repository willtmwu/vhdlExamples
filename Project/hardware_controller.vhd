----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:55:30 09/26/2014 
-- Design Name: 
-- Module Name:    hardware_controller - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Display Lower is send buffer, upper is receive buffer
--

--Not sure if this module is required, still in integration phase
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hardware_controller is
	Port ( 
				masterReset : out  STD_LOGIC;
				displayLower : in  STD_LOGIC;
				displayUpper : in  STD_LOGIC;
				addr : out  STD_LOGIC
			);
end hardware_controller;

architecture Behavioral of hardware_controller is
	
begin


end Behavioral;

