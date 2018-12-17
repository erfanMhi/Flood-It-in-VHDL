-------------------------------------------------------------------------------
--
-- Title       : queue
-- Design      : queue
-- Author      : TheMn
-- Company     : GU
--
-------------------------------------------------------------------------------
--
-- File        : queue.vhd
-- Generated   : Mon Dec 17 12:11:21 2018
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description : implementation of FIFO in vhdl
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {queue} architecture {queue}}

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity queue is
	generic(width : INTEGER := 8;
			height : INTEGER := 128);
	 port(
		 clk : in STD_LOGIC;
		 rst : in STD_LOGIC;
		 re : in STD_LOGIC;
		 we : in STD_LOGIC;
		 din : in STD_LOGIC_VECTOR((width - 1) downto 0);
		 dout : out STD_LOGIC_VECTOR((width - 1) downto 0);
		 empty : out STD_LOGIC;
		 full : out STD_LOGIC
	     );
end queue;																	  

architecture queue of queue is
	type MEMORY is array (0 to (height-1)) of STD_LOGIC_VECTOR((width-1) downto 0);
	signal mem : MEMORY := (others => (others => '0'));
	signal rp, wp : INTEGER := 0; -- pointers
	signal qe, qf : STD_LOGIC := '0';
begin

	 -- enter your statements here --
	process(clk, rst)
		variable size : INTEGER := 0;
	begin
		if(rst = '1') then
			dout <= (others => '0');
			qe <= '0';
			qf <= '0';
			rp <= 0;
			wp <= 0;
			size := 0;
		elsif(rising_edge(clk)) then
			if(re = '1' and qe = '0') then
				dout <= mem(rp);
				rp <= rp + 1;
				size := size - 1;
			end if;
			if(we = '1' and qf = '0') then
				mem(wp) <= din;
				wp <= wp + 1;
				size := size + 1;
			end if;
			if(rp = (height-1)) then
				rp <= 0;
			end if;
			if(wp = (height-1)) then
				wp <= 0;
			end if;
			if(size = 0) then
				qe <= '1';
			else
				qe <= '0';
			end if;
			if(size = height) then
				qf <= '1';
			else
				qf <= '0';
			end if;
		end if;
	end process; 
	
	empty <= qe;
	full <= qf;
	 
end queue;
