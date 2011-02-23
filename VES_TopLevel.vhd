----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Erik J. Reynolds
-- Module Name:    VES_TopLevel - Behavioral 
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

entity VES_TopLevel is
	Port	(	clk50 : in std_logic;								-- 50 MHz clock input.
				clk40 : in std_logic;								-- 40 MHz clock input.
				btn : in std_logic_vector(3 downto 0);			-- Button input (4-bit).
				sw	: in std_logic_vector(7 downto 0);			-- Switch input (8-bit).
				led : out std_logic_vector(7 downto 0);		-- LED output (8-bit).
				an	: out std_logic_vector(3 downto 0);			-- 7-Seg Anode output (4-bit).
				seg : out std_logic_vector(6 downto 0);		-- 7-Seg Cathode output (7-bit).
				vgaRed : out std_logic_vector(3 downto 1);	-- VGA RED output (3-bit).
				vgaGreen : out std_logic_vector(3 downto 1);	-- VGA GREEN output (3-bit).
				vgaBlue : out std_logic_vector(3 downto 2);	-- VGA BLUE output (2-bit).
				Hsync : out std_logic;								-- VGA H-Sync output.
				Vsync : out std_logic								-- VGA H-Sync output.
			);
end VES_TopLevel;

architecture Behavioral of VES_TopLevel is
-- Signals
	signal reset : std_logic;
	signal switches : std_logic_vector(7 downto 0);
	
	-- Wishbone stuff
	signal dwr, drd : std_logic_vector(31 downto 0);
	signal ack_m, ack_s : std_logic_vector(3 downto 0);
	signal dat_o_m0, dat_o_m1, dat_o_m2, dat_o_m3 : std_logic_vector(31 downto 0);
	signal cyc, we_m : std_logic_vector(3 downto 0);
	signal dat_o_s0, dat_o_s1, dat_o_s2, dat_o_s3 : std_logic_vector(31 downto 0);
	signal adr_m0, adr_m1, adr_m2, adr_m3, adr_slave : std_logic_vector(31 downto 0);
	signal irq_s : std_logic_vector(3 downto 0);
	signal irq_m, we_s : std_logic;
	signal irq_v : std_logic_vector(1 downto 0);
	signal stb_s, stb_m : std_logic_vector(3 downto 0);
	
begin
	--led <= sw;
	
	-- Set the reset signal
	reset <= sw(7);
	switches <= '0' & sw(6 downto 0);
	
	-- Instantiate Components
	-- Slave 0 (0x0): VGA
	-- Slave 1 (0x4): Buttons
	-- Slave 2 (0x8): 7-Seg
	-- Slave 3 (0xC): Switches
	U5 : entity work.wb_sw port map ( clk50, reset, adr_slave, dwr, dat_o_s3, ack_s(3), stb_s(3), we_s, irq_s(3), switches );
	U4 : entity work.wb_7seg_slave port map ( clk50, reset, adr_slave, dwr, dat_o_s2, ack_s(2), stb_s(2), we_s, an, seg );
	U3 : entity work.wb_buttons port map ( clk50, reset, adr_slave, dwr, dat_o_s1, ack_s(1), stb_s(1), we_s, irq_s(1), btn);--, led );
	U2 : entity work.SVGA port map ( clk50, clk40, reset, sw, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync, adr_slave, dwr, dat_o_s0, ack_s(0), stb_s(0), we_s, irq_s(0), led );
	U1 : entity work.master port map ( clk50, reset, adr_m0, drd, dat_o_m0, ack_m(0), cyc(0), stb_m(0), we_m(0), irq_m, irq_v);--, led );
	U0 : entity work.wb_intercon port map ( ack_m, ack_s, adr_m0, adr_m1, adr_m2, adr_m3, adr_slave, cyc, dat_o_m0, dat_o_m1, dat_o_m2, dat_o_m3, dwr, dat_o_s0, dat_o_s1, dat_o_s2, dat_o_s3, drd, irq_s, irq_m, irq_v, stb_s, stb_m, we_m, we_s, clk50, reset);

end Behavioral;

