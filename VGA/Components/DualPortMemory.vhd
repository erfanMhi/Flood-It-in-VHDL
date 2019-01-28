-------------------------------------------------------------------------------
--
-- Title       : DualPortMemory
-- Design      : Q2
-- Author      : mohadese golpour
-- Company     : 
--
-------------------------------------------------------------------------------
--
-- File        : DualPortMemory.vhd
-- Generated   : Fri Dec 22 21:09:41 2017
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {DualPortMemory} architecture {DualPortMemory}}

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_STD.all;

entity DualPortMemory is
	 generic(
	        Data_Width : integer := 8;
	 	    Addr_Width : integer := 7
		    );
	 port(
		 clk : in STD_LOGIC;
		 CS1 : in STD_LOGIC;
		 CS2 : in STD_LOGIC;
		 Addr1 : in STD_LOGIC_VECTOR(Addr_Width-1 downto 0);
		 Addr2 : in STD_LOGIC_VECTOR(Addr_Width-1 downto 0);
		 Data1 : in STD_LOGIC_VECTOR(Data_Width-1 downto 0);
		 Data2 : out STD_LOGIC_VECTOR(Data_Width-1 downto 0)
	     );
end DualPortMemory;

--}} End of automatically maintained section

architecture DualPortMemory of DualPortMemory is
							 
type MyRam is array(2**Addr_Width-1 downto 0) of std_logic_vector(Data_Width-1 downto 0);
signal Ram : MyRam;			

begin
	
	Data2 <= Ram(to_integer(unsigned(Addr2))) when (CS2 = '1') else (others => '0');
			
	process(clk)
	begin	
		if rising_edge(clk) then
			if (CS1 = '1') then 
				Ram(to_integer(unsigned(Addr1))) <= Data1;
			end if;
		end if;
	end process;
	

end DualPortMemory;
