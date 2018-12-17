library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity queue_tb is
	-- Generic declarations of the tested unit
		generic(
		width : INTEGER := 8;
		height : INTEGER := 128 );
end queue_tb;

architecture TB_ARCHITECTURE of queue_tb is
	-- Component declaration of the tested unit
	component queue
		generic(
		width : INTEGER := 8;
		height : INTEGER := 128 );
	port(
		clk : in STD_LOGIC;
		rst : in STD_LOGIC;
		re : in STD_LOGIC;
		we : in STD_LOGIC;
		din : in STD_LOGIC_VECTOR(width-1 downto 0);
		dout : out STD_LOGIC_VECTOR(width-1 downto 0);
		empty : out STD_LOGIC;
		full : out STD_LOGIC );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC;
	signal rst : STD_LOGIC;
	signal re : STD_LOGIC;
	signal we : STD_LOGIC;
	signal din : STD_LOGIC_VECTOR(width-1 downto 0);
	-- Observed signals - signals mapped to the output ports of tested entity
	signal dout : STD_LOGIC_VECTOR(width-1 downto 0);
	signal empty : STD_LOGIC;
	signal full : STD_LOGIC;

	-- Add your code here ...

begin

	-- Unit Under Test port map
	UUT : queue
		generic map (
			width => width,
			height => height
		)

		port map (
			clk => clk,
			rst => rst,
			re => re,
			we => we,
			din => din,
			dout => dout,
			empty => empty,
			full => full
		);

	-- Add your stimulus here ...

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_queue of queue_tb is
	for TB_ARCHITECTURE
		for UUT : queue
			use entity work.queue(queue);
		end for;
	end for;
end TESTBENCH_FOR_queue;

