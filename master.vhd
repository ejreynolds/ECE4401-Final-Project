----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:16:01 12/18/2010 
-- Design Name: 
-- Module Name:    master - Behavioral 
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
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity master is
	Port (	clk : in std_logic;
				reset : in std_logic;							
				adr_o : out std_logic_vector(31 downto 0);
				dat_i : in std_logic_vector(31 downto 0);	
				dat_o : out std_logic_vector(31 downto 0);
				ack_i : in std_logic;						
				cyc_o : out std_logic;						
				stb_o : out std_logic;						
				we_o	: out std_logic;
				irq_i_m : in std_logic;
				irqv_i_m : in std_logic_vector(1 downto 0)
				--led : out std_logic_vector(7 downto 0)
			);
end master;

architecture Behavioral of master is

-- Signals
	signal setSeed, gotBreak, color_clk : std_logic;
	signal seed, randNum : std_logic_vector(7 downto 0);
	type sType is ( idle, getButtons, getSwitches, setVideo, set7seg );
	signal state : sType := idle;
	signal scanCode, color1, color2 : std_logic_vector(7 downto 0);
	signal idleCounter : natural range 0 to 9 := 0;
begin
	
	-- Main State Machine Process
	main_proc : process (clk, reset)
		variable tempScan, tempColor1, tempColor2 : std_logic_vector(7 downto 0);
		variable tempButtons : std_logic_vector(3 downto 0);
		variable tempSwitches : std_logic_vector(7 downto 0);
		variable background_function_mode, sprite_position_mode, sprite_position_modifier : std_logic_vector(1 downto 0);
	begin
		if (reset = '1') then
			state <= idle;
			background_function_mode := "00";
			sprite_position_mode := "00";
			sprite_position_modifier := "00";
			tempButtons := (others => '0');
			tempSwitches := (others => '0');
		elsif (rising_edge(clk)) then
		
			-- State machine
			case state is
				when idle =>
					tempColor1 := color1;
					tempColor2 := color2;
					
					if (irq_i_m = '1') then-- and irqv_i_m = "01") then -- we received an interrupt from the buttons
						state <= getButtons;
					else -- no interrupt, output our RNG...
						state <= getSwitches;
					end if;
				
				when getButtons =>
					if (ack_i = '0') then
						adr_o <= x"40000000";
						we_o <= '0'; --read
						cyc_o <= '1';
						stb_o <= '1';
					else
						tempButtons := dat_i(3 downto 0);

						case tempButtons is
							when "1000" => sprite_position_modifier := "00";
							when "0100" => sprite_position_modifier := "01";
							when "0010" => sprite_position_modifier := "10";
							when "0001" => sprite_position_modifier := "11";
							when others => null;
						end case;
						
						cyc_o <= '0';
						stb_o <= '0';
						
						state <= getSwitches;
					end if;
				
				when getSwitches =>
					if (ack_i = '0') then
						adr_o <= x"C0000000";
						we_o <= '0';
						cyc_o <= '1';
						stb_o <= '1';
					else
						tempSwitches := dat_i(7 downto 0);
						
						if (tempSwitches(1) = '1' and (sprite_position_mode /= "01")) then
							sprite_position_mode := "01";
						elsif (tempSwitches(1) = '0' and (sprite_position_mode /= "10")) then
							sprite_position_mode := "10";
						else
							sprite_position_mode := "00";
						end if;
						
						if (tempSwitches(2) = '1' and (background_function_mode /= "10")) then
							background_function_mode := "10";
						elsif (tempSwitches(2) = '0' and (background_function_mode /= "11")) then
							background_function_mode := "11";
						else
							background_function_mode := "00";
						end if;
						
						cyc_o <= '0';
						stb_o <= '0';
						
						state <= setVideo;
					end if;
						
				when setVideo =>
					if (ack_i = '0') then -- we haven't gotten a response yet
						-- Pack the data to send to VGA
						dat_o(21 downto 14) <= tempColor1;
						dat_o(13 downto 6) <= tempColor2;
						dat_o(5 downto 4) <= background_function_mode;
						dat_o(3 downto 2) <= sprite_position_mode;
						dat_o(1 downto 0) <= sprite_position_modifier;
						
						adr_o(31 downto 0) <= x"00000000";
						cyc_o <= '1'; -- grab the bus
						stb_o <= '1'; -- strobe the slave
						we_o <= '1'; -- write
					else -- ack_i = '1'
						cyc_o <= '0';
						stb_o <= '0';
						state <= set7seg;
					end if;
					
				when set7seg =>
					if (ack_i = '0') then -- we haven't gotten a response yet
						dat_o(15 downto 0) <= tempColor1 & tempColor2;
						--dat_o(15 downto 0) <= x"1234";
						adr_o(31 downto 0) <= x"8" & x"0000000";
						cyc_o <= '1';
						stb_o <= '1';
						we_o <= '1';
					else
						cyc_o <= '0';
						stb_o <= '0';
						state <= idle;
					end if;
					
				when others => state <= idle;
			end case;
			
		end if;
		
	end process;
	
	-- Color Clock
	color_proc : process (color_clk, reset)
		variable foo : std_logic;
	begin
		if (reset = '1') then
			color1 <= x"00";
			color2 <= x"00";
			foo := '0';
		elsif (rising_edge(color_clk)) then
			--if (setSeed = '0') then
			
			--end if;
			
			--setSeed <= not setSeed;
			
			if (foo = '0') then
				color2 <= randNum;
			else
				color1 <= randNum;
			end if;
			
			foo := not foo;
		end if;
	end process;
	
	-- Constantly update the seed for the RNG
	-- I chose to just XOR the previous generated number with a constant 0xAC.
	seed <= randNum xor x"AC";
	setSeed <= '1';
	
	-- Instantiate the RNG
	uRNG : entity work.lfsr_rng generic map ( width => 8 ) port map ( clk, setSeed, seed, randNum );
	uColorClock : entity work.clock_divider generic map ( divisor => 50000000 ) port map ( clk, reset, color_clk );	
end Behavioral;

