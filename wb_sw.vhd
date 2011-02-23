--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Engineer: John A. Chandy
--
-- Create Date:    10:35:40 09/19/06
-- Design Name:    
-- Module Name:    wb_swts - Behavioral
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description: wb_swts is a read-only slave module that returns the switch 
--              status on the lower 8 bits of the data bus
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wb_sw is
	Port ( clk_i : in std_logic;
          rst_i : in std_logic;
		    adr_i : in std_logic_vector(31 downto 0);
          dat_i : in std_logic_vector(31 downto 0);
          dat_o : out std_logic_vector(31 downto 0);
          ack_o : out std_logic;
          stb_i : in std_logic;
          we_i  : in std_logic;
			 irq_o : out std_logic;
			 sw : in std_logic_vector(7 downto 0)
		);
end wb_sw;

architecture Behavioral of wb_sw is
	type state_type is (WAIT4CHANGE, WAIT4IRQACK);
	signal state : state_type;
	signal last_sw : std_logic_vector(7 downto 0);
begin

--	process(clk_i,rst_i)
--	begin
--		if ( rst_i = '1' ) then
		--	state <= WAIT4CHANGE;
--			state <= WAIT4IRQACK;
--			last_sw <= sw;
--		elsif ( clk_i'event and clk_i='0' ) then

--			case state is
--			when WAIT4CHANGE =>
--				if ( last_sw /= sw ) then
--					state <= WAIT4IRQACK;
--				end if;

--			when WAIT4IRQACK =>
--				if ( stb_i <= '1' ) then
--					state <= WAIT4CHANGE;
--					last_sw <= sw;
--				end if;
			
--			when others => state <= WAIT4CHANGE;
--
--			end case;
--		end if;
--	end process;

	-- since this module is read-only, just always set
	-- the outgoing data bus to the current switch status
	-- always acknowledge bus requests, since there are
	-- no wait states inserted.
	dat_o(7 downto 0) <= sw;
	dat_o(31 downto 8) <= X"000000";
	ack_o <= '1';
--	irq_o <= '1' when state = WAIT4IRQACK else '0';

end Behavioral;
