----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:00:22 12/13/2010 
-- Design Name: 
-- Module Name:    svga_sync - Behavioral 
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
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity svga_sync is
	Port (	clk : in std_logic;
				reset : in std_logic;
				HSync : out std_logic;
				VSync : out std_logic;
				HCount : out std_logic_vector(9 downto 0);
				VCount : out std_logic_vector(9 downto 0);
				vidActive : out std_logic
			);
end svga_sync;

architecture Behavioral of svga_sync is
-- Constants (SVGA)
	constant HPW : natural := 128;		-- Horizontal Sync Pulse Width (pixels)
	constant HFP : natural := 40;		-- Horizontal Sync Front Porch (pixels)
	constant HBP : natural := 88;	-- Horizontal Sync Back Porch (pixels)
	constant VPW : natural := 4;		-- Vertical Sync Pulse Width (lines)
	constant VFP : natural := 1;		-- Vertical Sync Front Porch (lines)
	constant VBP : natural := 21;		-- Vertical Sync Back Porch (lines)
	constant PAL : natural := 800;	-- Pixels "active" in Line (pixels)
	constant LAF : natural := 600;	-- Lines "active" in Frame (lines)
	constant PLD : natural := 1056;	-- Pixels per Line
	constant LFD : natural := 628;	-- Lines per Frame

-- Signals
	signal hCounter : natural range 0 to PLD - 1; -- horizontal counter
	signal vCounter : natural range 0 to LFD - 1; -- verical counter

begin

	-- Main synchronization process
	sync_proc : process (clk, reset)
	begin
		if (reset = '1') then
			hCounter <= 0;
			vCounter <= 0;
		elsif (rising_edge(clk)) then
			if (hCounter = PLD - 1) then -- if hCounter == maxsize
				hCounter <= 0; -- roll over
				
				if (vCounter = LFD - 1) then -- if vcounter == maxsize
					vCounter <= 0; -- roll over
				else
					vCounter <= vCounter + 1; -- increment
				end if;
			else
				hCounter <= hCounter + 1; -- increment
			end if;
	
			-- Generates horizontal sync (active low)
			if (hCounter = PAL - 1 + HFP) then 
				HSync <= '0'; -- active
			elsif (hCounter = PAL - 1 + HFP + HPW) then 
				HSync <= '1'; -- inactive
			end if;
	
			-- Generates vertical sync (active low)
			if (vCounter = LAF - 1 + VFP) then 
				VSync <= '0'; -- active
			elsif (vCounter = LAF - 1 + VFP + VPW)  then
				VSync <= '1'; -- inactive
			end if;
		end if;
	end process;
	
	-- Output the counter
	HCount <= conv_std_logic_vector(hCounter, 10);
	VCount <= conv_std_logic_vector(vCounter, 10);
	
	-- Video Active Region
	vidActive <= '1' when (hCounter < PAL) else '0';
	
end Behavioral;
