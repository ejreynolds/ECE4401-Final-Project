----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:44:21 12/18/2010 
-- Design Name: 
-- Module Name:    sprite_mover - Behavioral 
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

entity sprite_mover is
	Port	(	clk40	: in std_logic;									-- 40 MHz (SVGA) clock input.
				bounce_clk : in std_logic;								-- 'Bounce' clock input.
				reset : in std_logic;									-- Reset input.
				hCount : in std_logic_vector(9 downto 0);			-- SVGA H-Count input (10-bit).
				vCount : in std_logic_vector(9 downto 0);			-- SVGA V-Count input (10-bit).
				spriteData : out std_logic_vector(7 downto 0);	-- BRAM Sprite Data output (8-bit).
				spriteActive : out std_logic;							-- Sprite 'Active' output.
				sprite_manual : in std_logic;
				sprite_position : in std_logic_vector(1 downto 0)
			);
end sprite_mover;

architecture Behavioral of sprite_mover is
-- Constants
	constant spriteWidth : integer := 175;
	constant spriteHeight : integer := 175;
	constant frameWidth : integer := 800;
	constant frameHeight : integer := 600;
-- Signals
	signal spriteAddress : std_logic_vector(15 downto 0);
	signal xAddr, yAddr : std_logic_vector(16 downto 0);
	signal startX, startY : std_logic_vector(9 downto 0);
	signal xPixels, yPixels : std_logic_vector(9 downto 0);
	
begin

	-- Calculate the sprite active region
	spriteActive <= '1' when ((hCount >= startX) and (hCount < startX + spriteWidth)) and ((vCount >= startY) and (vCount < startY + spriteHeight)) else '0';
	
	-- Calculate the current pixel within the sprite
	xPixels <= hCount - startX;
	yPixels <= vCount - startY;
	
	-- yAddr := yPixels * 200
	-- xAddr := yAddr + xPixels
	-- 200 = 11001000
	-- 175 = 10101111
	--yAddr <= (yPixels & "0000000") + ('0' & yPixels & "000000") + ("0000" & yPixels & "000"); -- 200
	yAddr <= (yPixels & "0000000") + ("00" & yPixels & "00000") + ("0000" & yPixels & "000") + ("00000" & yPixels & "00") + ("000000" & yPixels & "0") + ("0000000" & yPixels); -- 175
	xAddr <= yAddr + ("00000000" & xPixels);
	spriteAddress <= xAddr(15 downto 0);
	
	-- Bounce the picture around
	bounce : process ( bounce_clk, reset, sprite_manual, sprite_position)
		constant yMax : integer := frameHeight - spriteHeight;
		constant xMax : integer := frameWidth - spriteWidth;
		variable X, Y : std_logic_vector(9 downto 0);
		variable dX : std_logic_vector(9 downto 0) := "0000000001";
		variable dY : std_logic_vector(9 downto 0) := "1111111111";
	begin
		if (reset = '1') then
			X := (others => '0'); -- 0
			Y := (others => '0'); -- 0
			dX := "0000000001"; -- +1
			dY := "1111111111"; -- -1
		elsif (rising_edge(bounce_clk)) then
			if (sprite_manual = '0') then
				X := X + dX;
				Y := Y + dY;
			
			else -- manual move
				case sprite_position is
					when "00" => Y := Y + dY;
					when "01" => Y := Y - dY;
					when "10" => X := X - dX;
					when "11" => X := X + dX;
					when others => null;
				end case;
			end if;
			
			-- If hit the left or right, reverse direction.
			if (X < 0 or X >= xMax) then
				dX := 0 - dX;
			end if;
				
			-- If hit the bottom or top, reverse direction.
			if (Y < 0 or Y >= yMax) then
				dY := 0 - dY;
			end if;
		end if;
			
		startX <= X;
		startY <= Y;
	end process;

	-- Instantiate the sprite
	uSprite : entity work.smile_sprite port map ( ADDRA => spriteAddress(14 downto 0), CLKA => clk40, DOUTA => spriteData );
	
end Behavioral;

