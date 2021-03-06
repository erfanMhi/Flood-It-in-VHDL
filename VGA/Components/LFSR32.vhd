-------------------------------------------------------------------------------
--
-- Title       : LFSR32
-- Design      : LFSR32
-- Author      : Mahdi
-- Company     : M
--
-------------------------------------------------------------------------------
--
-- File        : LFSR32.vhd
-- Generated   : Sat Dec 29 19:00:46 2018
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.20
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {LFSR32} architecture {LFSR32}}

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity LFSR32 is
	Port(
		Resetn: in std_logic;
		Clk: in std_logic;
		LFSR32Out: out std_logic_vector(31 downto 0)
	);
end LFSR32;

--}} End of automatically maintained section

architecture LFSR32 of LFSR32 is

signal pseudo_rand : std_logic_vector(31 downto 0) := "10010010010110101000101001001001";

begin

	-- enter your statements here --
	process(clk)
		-- maximal length 32-bit xnor LFSR
		function lfsr32func(x : std_logic_vector(31 downto 0)) return std_logic_vector is
		begin
			return x(30 downto 0) & (x(0) xnor x(1) xnor x(21) xnor x(31));
			--return x(30 downto 0) & not(x(0) xor x(2) xor x(6) xor x(7));  -- This works too
		end function;
	begin
		if rising_edge(clk) then
			if resetn='0' then
				pseudo_rand <= (others => '0');
			else
				pseudo_rand <= lfsr32func(pseudo_rand);
			end if;
		end if;
	end process;
	
	LFSR32Out <= pseudo_rand;

end LFSR32;
