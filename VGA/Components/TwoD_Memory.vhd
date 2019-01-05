												   -------------------------------------------------------------------------------
--
-- Title       : tw_port_memory
-- Design      : two_port_memory
-- Author      : 
-- Company     : 
--
-------------------------------------------------------------------------------
--
-- File        : tw_port_memory.vhd
-- Generated   : Fri Dec 14 03:44:00 2018
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
--{entity {tw_port_memory} architecture {tw_port_memory_arch}}

library IEEE;
use IEEE.STD_LOGIC_1164.all;
USE ieee.numeric_std.ALL;

entity twoD_memory is
	generic(
		row_length: integer := 10;
		column_length: integer := 10;
		data_length: integer := 12
		);
	 port(
		 clk, cs_wr, cs_rd : in STD_LOGIC;
		 addr_rd_i, addr_rd_j, addr_wr_i, addr_wr_j : in integer;
		 data_wr : in std_logic_vector(data_length-1 downto 0);
		 data_rd : out std_logic_vector(data_length-1 downto 0)
	     );
end twoD_memory;

--}} End of automatically maintained section

architecture twoD_memory_arch of twoD_memory is
type mem_type is array (0 to row_length-1, 0 to column_length-1) of std_logic_vector(data_length-1 downto 0);
signal mem: mem_type;
begin

in1_logic: process(clk)
begin
	if (clk'event and clk='1') then	
		if (cs_wr = '1') then
			mem(addr_wr_i, addr_wr_j) <= data_wr;
		end if;
	end if;
end process;


data_rd <= mem(addr_rd_i, addr_rd_j) when (cs_rd = '1') else (others => '0');

end twoD_memory_arch;
