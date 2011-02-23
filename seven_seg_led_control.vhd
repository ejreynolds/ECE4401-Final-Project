----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Erik J. Reynolds
-- 
-- Create Date:    15:31:38 09/02/2010 
-- Design Name: 
-- Module Name:    seven_seg_led_control - Behavioral 
-- Project Name:   ECE 4401 - Lab 01
-- Target Devices: 
-- Tool versions: 
-- Description: 
--		7-segment LED display controller.
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

entity seven_seg_led_control is
	Port	(	clk		: in std_logic;								-- Clock input.
				--reset		: in std_logic;							-- Reset input.
				input		: in std_logic_vector(15 downto 0);		-- 16-bit LED input (4 per display).
				anode		: out std_logic_vector(3 downto 0);		-- Anode selection output.
				cathode	: out std_logic_vector(6 downto 0)		-- 7-segment cathode output.
			);
end seven_seg_led_control;

architecture Behavioral of seven_seg_led_control is
-- Component Declaration
	component hex2led Port	(	hex : in std_logic_vector(3 downto 0);
										led : out std_logic_vector(6 downto 0)
									);
	end component;
	
-- Internal Signals
	signal led0, led1, led2, led3 : std_logic_vector(6 downto 0);
	signal LEDcontrol : std_logic_vector(1 downto 0);
	
begin
	-- Instantiate the components
	hexLED0 : hex2led port map (	hex(3) => input(3),
											hex(2) => input(2),
											hex(1) => input(1),
											hex(0) => input(0),
											led => led0
										);
	hexLED1 : hex2led port map	(	hex(3) => input(7),
											hex(2) => input(6),
											hex(1) => input(5),
											hex(0) => input(4),
											led => led1
										);
	hexLED2 : hex2led port map	(	hex(3) => input(11),
											hex(2) => input(10),
											hex(1) => input(9),
											hex(0) => input(8),
											led => led2
										);
	hexLED3 : hex2led port map (	hex(3) => input(15),
											hex(2) => input(14),
											hex(1) => input(13),
											hex(0) => input(12),
											led => led3
										);
										
	-- Main Process
	main : process (clk) is
	begin
		if (clk = '1' and clk'event) then
			-- Loop through the LEDs on the 1ms clock
			case LEDcontrol is
				when "01" => LEDcontrol <= "10";
				when "10" => LEDcontrol <= "11";
				when "11" => LEDcontrol <= "00";
				when others => LEDcontrol <= "01";
			end case;
		end If;
	end process;
	
	-- Process to assign LED output based on LEDcontrol signal
	LED : process (LEDcontrol, led0, led1, led2, led3) is
	begin
		if (LEDcontrol = "00") then
			anode <= "1110";
			cathode <= led0;
		elsif (LEDcontrol = "01") then
			anode <= "1101";
			cathode <= led1;
		elsif (LEDcontrol = "10") then
			anode <= "1011";
			cathode <= led2;
		elsif (LEDcontrol = "11") then
			anode <= "0111";
			cathode <= led3;
		end if;
	end process;

end Behavioral;

