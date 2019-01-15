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
	 	    Addr_Width : integer := 10
		    );
	 port(
		 clk : in STD_LOGIC;
		 CS1 : in STD_LOGIC;
		 CS2 : in STD_LOGIC;
		 WE1 : in STD_LOGIC;
		 WE2 : in STD_LOGIC;
		 Addr1 : in STD_LOGIC_VECTOR(Addr_Width-1 downto 0);
		 Addr2 : in STD_LOGIC_VECTOR(Addr_Width-1 downto 0);
		 Data1 : inout STD_LOGIC_VECTOR(Data_Width-1 downto 0);
		 Data2 : inout STD_LOGIC_VECTOR(Data_Width-1 downto 0)
	     );
end DualPortMemory;

--}} End of automatically maintained section

architecture DualPortMemory of DualPortMemory is
							 
type MyRam is array(2**Addr_Width-1 downto 0) of std_logic_vector(Data_Width-1 downto 0);
signal Ram : MyRam;			

begin
	
	Data1 <= Ram(to_integer(unsigned(Addr1))) when (CS1 = '1' and WE1 = '0') else (others => 'Z');
	Data2 <= Ram(to_integer(unsigned(Addr2))) when (CS2 = '1' and WE2 = '0') else (others => 'Z');
			
	process(clk)
	begin	
		if rising_edge(clk) then
			if (CS1 = '1' and WE1 = '1') then 
				Ram(to_integer(unsigned(Addr1))) <= Data1;
			end if;
			if (CS2 = '1' and WE2 = '1') then 
				Ram(to_integer(unsigned(Addr2))) <= Data2;
			end if;
		end if;
	end process;
	

end DualPortMemory;
