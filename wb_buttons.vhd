----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Erik J. Reynolds
-- Module Name:    wb_buttons - Behavioral 
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
--		Adapted from Dr. Chandy's wb_swts.vhd (wishbone slide switch slave module).
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wb_buttons is
	Port ( clk_i : in std_logic;
          rst_i : in std_logic;
		    adr_i : in std_logic_vector(31 downto 0);
          dat_i : in std_logic_vector(31 downto 0);
          dat_o : out std_logic_vector(31 downto 0);
          ack_o : out std_logic;
          stb_i : in std_logic;
          we_i  : in std_logic;
			 irq_o : out std_logic;
			 btn : in std_logic_vector(3 downto 0)
			 --led : out std_logic_vector(7 downto 0)
		);
end wb_buttons;

architecture Behavioral of wb_buttons is
	type state_type is (WAIT4CHANGE, WAIT4IRQACK);
	signal state : state_type;
	signal last_buttons : std_logic_vector(3 downto 0);
--	signal up, down, left, right : std_logic;
--	signal debounce_clk : std_logic;
--	signal position_modifier, debouncedButtons : std_logic_vector(3 downto 0);
begin

	process(clk_i, rst_i)
	begin
		if (rst_i = '1') then
			state <= WAIT4CHANGE;
			last_buttons <= btn;
		elsif (rising_edge(clk_i)) then

			case state is
				when WAIT4CHANGE =>
					if ( last_buttons /= btn) then
						state <= WAIT4IRQACK;
						last_buttons <= btn;
					end if;

				when WAIT4IRQACK =>
					if ( stb_i <= '1' ) then
						state <= WAIT4CHANGE;
					end if;
			
				when others => state <= WAIT4CHANGE;
			end case;
		end if;
	end process;

	-- since this module is read-only, just always set
	-- the outgoing data bus to the current debounced one-shot'd button status
	-- always acknowledge bus requests, since there are
	-- no wait states inserted.
	dat_o(3 downto 0) <= last_buttons;
	dat_o(31 downto 4) <= X"0000000";
	ack_o <= '1';
	irq_o <= '1' when state = WAIT4IRQACK else '0';

	-- Create the 'position_modifier vector'
--	position_modifier <= up & down & left & right;
	
--	led(7 downto 4) <= btn;
--	led(3 downto 0) <= last_buttons;
--	led(3 downto 0) <= position_modifier or debouncedButtons;
--	uClockDiv : entity work.clock_divider generic map ( divisor => 25000000) port map (clk_i, rst_i, debounce_clk);
--	uDebouncer : entity work.button_debouncer generic map ( NUM_SWITCHES => 4)	port map ( 	clk => debounce_clk, btnIn => btn, btnOut => debouncedButtons);
--	uOneShot_Up : entity work.one_shot port map (debouncedButtons(3), clk_i, up);
--	uOneShot_Down : entity work.one_shot port map (debouncedButtons(2), clk_i, down);
--	uOneShot_Left : entity work.one_shot port map (debouncedButtons(1), clk_i, left);
--	uOneShot_Right : entity work.one_shot port map (debouncedButtons(0), clk_i, right);
end Behavioral;


