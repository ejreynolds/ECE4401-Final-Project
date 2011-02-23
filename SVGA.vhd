----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Erik J. Reynolds
-- Module Name:    svga - Behavioral 
-- Project Name:   ECE 4401 - Final Project - Video Effects Simulator
-- Target Devices: Digilent Nexys2 (Spartan 3E 500k)
-- Tool versions:  Xilinx ISE 12.3
-- Description: 
--		SVGA Wishbone slave.  Includes SVGA_Sync to generate 800x600@60 timings using a 40MHz clock.
--		Allows multiple sprite position modes as well as multiple background color options.
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

entity svga is
	Port	(	clk50	: in std_logic;								-- 50 MHz clock input.
				clk40 : in std_logic;								-- 40 MHz clock input.
				reset : in std_logic;								-- Reset input.
				swColor : in std_logic_vector(7 downto 0);	-- Switch Color (8-bit) input.
				vgaRed : out std_logic_vector(3 downto 1);	-- VGA RED 3-bit output.
				vgaGreen : out std_logic_vector(3 downto 1);	-- VGA GREEN 3-bit output.
				vgaBlue : out std_logic_vector(3 downto 2);	-- VGA BLUE 2-bit output.
				Hsync : out std_logic;								-- VGA H-Sync output.
				Vsync : out std_logic;								-- VGA V-Sync output.

				-- Wishbone specific stuff
				adr_i : in std_logic_vector(31 downto 0);		-- Address input.
				dat_i : in std_logic_vector(31 downto 0);		-- Data input (32-bit).
				dat_o : out std_logic_vector(31 downto 0);	-- Data output (32-bit).
				ack_o : out std_logic;								-- Acknowledgement output (indicates we're finished).
				stb_i : in std_logic;								-- Strobe input (indicates slave is selected).
				we_i	: in std_logic;								-- Write Enable input ('0' := read; '1' := write).
				irq_o : out std_logic;								-- Interrupt Request output.
				led : out std_logic_vector(7 downto 0)
			);
end svga;

architecture Behavioral of svga is
-- Components
	-- SVGA Synchro Core
	component svga_sync port (	clk : in std_logic;
										reset : in std_logic;
										HSync : out std_logic;
										VSync : out std_logic;
										HCount : out std_logic_vector(9 downto 0);
										VCount : out std_logic_vector(9 downto 0);
										vidActive : out std_logic
									);
	end component;
	
-- Signals
	signal bounce_clk, vga_clk : std_logic;
	signal hCount, vCount : std_logic_vector(9 downto 0);
	signal doVideo, doSprite, back_sw_en, sprite_manual : std_logic;
	signal spriteData, background, background1, background2, back_temp : std_logic_vector(7 downto 0);
	signal background_function, sprite_position_mode, sprite_position : std_logic_vector(1 downto 0);
	signal red, green : std_logic_vector(2 downto 0);
	signal blue : std_logic_vector(1 downto 0);
begin
	-- Instantiate the synchronization core
	uSVGA_Synchro : svga_sync port map ( vga_clk, reset, Hsync, Vsync, hCount, vCount, doVideo );
	uBounceClock : entity work.clock_divider generic map ( divisor => 200000 ) port map ( vga_clk, reset, bounce_clk );
	uSpriteMover : entity work.sprite_mover port map ( vga_clk, bounce_clk, reset, hCount, vCount, spriteData, doSprite, sprite_manual, sprite_position );

	vga_clk <= clk40;
	
	sprite_manual <= '1' when sprite_position_mode = "01" else '0';
	led(7 downto 6) <= background_function;
	led(5 downto 4) <= sprite_position_mode;
	led(3 downto 2) <= "00";
	led(1 downto 0) <= sprite_position;
	
	-- Set video color outputs	
	background <= swColor when (back_sw_en = '1') else back_temp;
	back_sw_en <= '1' when background_function = "01" else '0';
	
	red <= spriteData(7 downto 5) when doSprite = '1' else background(7 downto 5);
	green <= spriteData(4 downto 2) when doSprite = '1' else background(4 downto 2);
	blue <= spriteData(1 downto 0) when doSprite = '1' else background(1 downto 0);

	vgaRed <= red when doVideo = '1' else "000";
	vgaGreen <= green when doVideo = '1' else "000";
	vgaBlue <= blue when doVideo = '1' else "00";

--	-- Background Handler Process
	background_proc : process (clk40, reset, hCount, vCount)
		variable stripe_counter : natural range 0 to 39;
		variable stripe_color_selector : std_logic;
	begin
		if (reset = '1') then
			stripe_counter := 0;
			stripe_color_selector := '0';
		elsif (rising_edge(clk40)) then
			case background_function is
				-- Solid color / chosen by sliding switches
				--when "01" => back_sw_en <= '1';
				
				-- Solid color / chosen by RNG (uses background1)
				when "10" => back_temp <= background1;
				
				-- Stripes (20 stripes / 40 pixels wide) / two colors chosen by RNG
				when "11" =>
					if (hCount = 0) then
						stripe_counter := 0;
						stripe_color_selector := '0';
						back_temp <= background2;
					else
						if (stripe_counter = 39) then
							if (stripe_color_selector = '0') then
								back_temp <= background1;
							else
								back_temp <= background2;
							end if;
							
							stripe_color_selector := not stripe_color_selector;
							stripe_counter := 0;
						else
							stripe_counter := stripe_counter + 1;
						end if;
					end if;
					
				when others => null;
			end case;
		end if;
	end process;
	
--	-- Main Process (Handle Wishbone Slave Comm)
	slave_proc : process (clk50, reset) is
		variable background_func, sprite_pos_mode, sprite_pos : std_logic_vector(1 downto 0);
		variable color1, color2 : std_logic_vector(7 downto 0);
	begin
		if (reset = '1') then
			background_func := "00";
			sprite_pos_mode := "00";
			sprite_pos := "00";
		elsif (rising_edge(clk50)) then
			if (stb_i = '1' and we_i = '1') then
				-- Grab the packed data from the bus
				color1 := dat_i(21 downto 14);
				color2 := dat_i(13 downto 6);
				background_func := dat_i(5 downto 4);
				sprite_pos_mode := dat_i(3 downto 2);
				sprite_pos := dat_i(1 downto 0);
			end if;
			
			-- Send the variables to signals IF the modes are not N/C (no change)
			if (background_func /= "00") then
				background_function <= background_func;
				background1 <= color1;
				background2 <= color2;
			end if;
			
			if (sprite_pos_mode /= "00") then
				sprite_position_mode <= sprite_pos_mode;
				sprite_position <= sprite_pos;
			end if;
		end if;
	end process slave_proc;
	
	ack_o <= '1';
	
end Behavioral;
