----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Erik J. Reynolds
-- 
-- Create Date:    14:09:51 09/13/2010 
-- Design Name: 
-- Module Name:    hex2led - Behavioral 
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

entity hex2led is
	Port	(	hex : in std_logic_vector(3 downto 0);		-- Hex Counter Input (4-bit).
				led : out std_logic_vector(6 downto 0)		-- LED Cathode output (7-bit).
			);
end hex2led;

architecture Behavioral of hex2led is
-- Begin Behavioral
begin

	-- Main process to update the output of the common LED pins
	updateLED : process (hex)
	begin
		case hex is
			when "0001" => led <= "1111001"; -- 1
			when "0010" => led <= "0100100"; -- 2
			when "0011" => led <= "0110000"; -- 3
			when "0100" => led <= "0011001"; -- 4
			when "0101" => led <= "0010010"; -- 5
			when "0110" => led <= "0000010"; -- 6
			when "0111" => led <= "1111000"; -- 7
			when "1000" => led <= "0000000"; -- 8
			when "1001" => led <= "0011000"; -- 9
			when "1010" => led <= "0001000"; -- A
			when "1011" => led <= "0000011"; -- B
			when "1100" => led <= "1000110"; -- C
			when "1101" => led <= "0100001"; -- D
			when "1110" => led <= "0000110"; -- E
			when "1111" => led <= "0001110"; -- F
			when others => led <= "1000000"; -- 0
		end case;
	end process;
end Behavioral;

