----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Erik J. Reynolds
-- 
-- Create Date:    23:44:26 10/01/2010 
-- Design Name: 
-- Module Name:    wb_7seg_slave - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--		Wishbone Slave Module for the 7 Segment LED Controller
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

entity wb_7seg_slave is
	Port (	clk_i : in std_logic;								-- Clock input.
				rst_i : in std_logic;								-- Reset input.
				adr_i : in std_logic_vector(31 downto 0);		-- Address input.
				dat_i : in std_logic_vector(31 downto 0);		-- Data input (32-bit).
				dat_o : out std_logic_vector(31 downto 0);	-- Data output (32-bit).
				ack_o : out std_logic;								-- Acknowledgement output (indicates we're finished).
				stb_i : in std_logic;								-- Strobe input (indicates slave is selected).
				we_i	: in std_logic;								-- Write Enable input ('0' := read; '1' := write).
				an : out std_logic_vector(3 downto 0);			-- 7 seg LED anode output.
				seg : out std_logic_vector(6 downto 0)			-- 7 seg LED common cathode output.
			);
end wb_7seg_slave;
	
architecture Behavioral of wb_7seg_slave is
--Signals
	signal led_clk : std_logic;
	signal seven_seg_output : std_logic_vector(15 downto 0) := x"0000";
	
begin
	-- Instantiate components
	seven_seg : entity work.seven_seg_led_control port map ( led_clk, seven_seg_output, an, seg );
	led_clk_div : entity work.clock_divider generic map (divisor => 2**16) port map ( clk_i, rst_i, led_clk );
	
	-- Main Process
	slave_proc : process (clk_i, rst_i) is
	begin
		if (rst_i = '1') then
			seven_seg_output  <= x"0000"; -- reset the 7seg output
		elsif (rising_edge(clk_i)) then
			if (stb_i = '1' and we_i = '1') then -- if our strobe was asserted and write enable is asserted...
				seven_seg_output <= dat_i(15 downto 0); -- grab the lower 16 bits from data input
			end if;

		end if;
	end process slave_proc;
	
	ack_o <= '1';
	
end Behavioral;

