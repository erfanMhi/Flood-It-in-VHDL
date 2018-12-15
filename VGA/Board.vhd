----------------------------------------------------------------------------------
-- Moving Square Demonstration 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Square is
  port ( CLK_50MHz		: in std_logic;
			RESET				: in std_logic;
			ColorOut			: out std_logic_vector(11 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in std_logic_vector(7 downto 0);
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0)
  );
end Square;

architecture Behavioral of Square is
  
  shared variable ColorOutput: std_logic_vector(11 downto 0);
  
  signal column_width: std_logic_vector(9 downto 0) := "0000000001";
  signal row_width: std_logic_vector(9 downto 0) := "0000000001";
  
  signal SquareX: std_logic_vector(9 downto 0) := "0000001110";  
  signal SquareY: std_logic_vector(9 downto 0) := "0000010111";  
  signal SquareXMoveDir, SquareYMoveDir: std_logic := '0';
  --constant SquareWidth: std_logic_vector(4 downto 0) := "11001";
  constant SquareXmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareXmax: std_logic_vector(9 downto 0); -- := "1010000000"-SquareWidth;
  constant SquareYmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareYmax: std_logic_vector(9 downto 0); -- := "0111100000"-SquareWidth;
  signal ColorSelect: std_logic_vector(2 downto 0) := "001";
  signal Prescaler: std_logic_vector(30 downto 0) := (others => '0');
  
  function signed_multiply(a,b: std_logic_vector(10 downto 0)) return std_logic_vector is
		variable ans:std_logic_vector(21 downto 0);
  begin
		ans := std_logic_vector(signed(a) * signed(b));
		return ans;
  
  end function signed_multiply;
  
 function multiply(a,b: std_logic_vector(10 downto 0)) return std_logic_vector is
		variable ans:std_logic_vector(10 downto 0);
  begin
		ans := std_logic_vector(unsigned(a) * unsigned(b))(10 downto 0);
		return ans;
  
  end function multiply;
  
  
  function colorize_cell(row, column, ScanlineX, ScanlineY: std_logic_vector(10 downto 0)) return std_logic_vector is
		variable color_cell:std_logic_vector(11 downto 0);
		constant row_width: std_logic_vector(10 downto 0) := "00000000100";
		constant column_width: std_logic_vector(10 downto 0) := "00000000100";
	begin
		if (ScanlineX >= multiply(column, row_width) AND ScanlineY >= multiply(row, column_width) AND ScanlineX < (multiply(column, row_width)+row_width) AND ScanlineY < (multiply(row, column_width)+column_width)) then
			color_cell := "000000000000";
		else  
			color_cell := "111111111111";
		end if;
		return color_cell;
		
	end function colorize_cell;
	
  function division(a,b: std_logic_vector(10 downto 0)) return std_logic_vector is
		variable ans:std_logic_vector(10 downto 0);
  begin
		ans := std_logic_vector(resize(unsigned(a) / unsigned(b),a'length));
		return ans;
  
  end function division;
	
	function draw_line(x1, y1, x2, y2, ScanlineX, ScanlineY: std_logic_vector(10 downto 0)) return std_logic_vector is
		variable color_line:std_logic_vector(11 downto 0);
		variable x: integer;
		variable x1_t, x2_t, y1_t, y2_t: std_logic_vector(10 downto 0);
	begin
		x := ((to_integer(unsigned(ScanlineY)) - to_integer(unsigned(y1))) * (to_integer(unsigned(x2))-to_integer(unsigned(x1)))) - ((to_integer(unsigned(y2)) - to_integer(unsigned(y1))) * (to_integer(unsigned(ScanlineX))-to_integer(unsigned(x1))));
		if x1 > x2 then
			x1_t := x1;
			x2_t := x2;
		else
			x2_t := x1;
			x1_t := x2;		
		end if;
		
		if y1 > y2 then
			y1_t := y1;
			y2_t := y2;
		else
			y2_t := y1;
			y1_t := y2;		
		end if;
		
		if x <= 40 and x >= -40 and (ScanlineY < y1_t+1 and ScanlineY > y2_t-1 and ScanlineX < x1_t+1 and ScanlineX > x2_t-1)then
			color_line := "000000000000";
			
		else
			color_line := "111111111111";
		end if;
		return color_line;
	end function draw_line;

begin

	PrescalerCounter: process(CLK_50Mhz, RESET)
	begin
		if RESET = '1' then
			Prescaler <= (others => '0');
			SquareX <= "0111000101";
			SquareY <= "0001100010";
			SquareXMoveDir <= '0';
			SquareYMoveDir <= '0';
			ColorSelect <= "001";
		elsif rising_edge(CLK_50Mhz) then
			Prescaler <= Prescaler + 1;	 
			if Prescaler = "11000011010100000" then  -- Activated every 0,002 sec (2 msec)
				Prescaler <= (others => '0');
				
				--ColorOutput <= not ((not ColorOutput) or (not ((ScanlineX < std_logic_vector(to_unsigned(213, 10))) and (ScanlineX > std_logic_vector(to_unsigned(0, 10))) and (ScanlineY > std_logic_vector(to_unsigned(50, 10))) and (ScanlineY < std_logic_vector(to_unsigned(60, 10))))));
			end if;
		end if;
	end process PrescalerCounter;
	
	color_painter: process(ScanlineX, ScanlineY)
	begin
		if (ScanlineX < std_logic_vector(to_unsigned(213, 10))) and
		(ScanlineX > std_logic_vector(to_unsigned(0, 10))) and
		(ScanlineY > std_logic_vector(to_unsigned(50, 10))) and
		(ScanlineY < std_logic_vector(to_unsigned(60, 10))) then
			ColorOutput := "111111000000";
		else  
			ColorOutput := "111111111111";
		end if;
		
		-- left arrow
		Coloroutput := draw_line(std_logic_vector(to_unsigned(80, 11)), std_logic_vector(to_unsigned(440, 11)), std_logic_vector(to_unsigned(180, 11)), std_logic_vector(to_unsigned(440, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(115, 11)), std_logic_vector(to_unsigned(410, 11)), std_logic_vector(to_unsigned(80, 11)), std_logic_vector(to_unsigned(440, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(115, 11)), std_logic_vector(to_unsigned(470, 11)), std_logic_vector(to_unsigned(80, 11)), std_logic_vector(to_unsigned(440, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(115, 11)), std_logic_vector(to_unsigned(470, 11)), std_logic_vector(to_unsigned(115, 11)), std_logic_vector(to_unsigned(410, 11)), ScanlineX, ScanlineY);
		
		-- up arrow
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(260, 11)), std_logic_vector(to_unsigned(430, 11)), std_logic_vector(to_unsigned(300, 11)), std_logic_vector(to_unsigned(430, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(280, 11)), std_logic_vector(to_unsigned(410, 11)), std_logic_vector(to_unsigned(280, 11)), std_logic_vector(to_unsigned(470, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(260, 11)), std_logic_vector(to_unsigned(430, 11)), std_logic_vector(to_unsigned(280, 11)), std_logic_vector(to_unsigned(410, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(300, 11)), std_logic_vector(to_unsigned(430, 11)), std_logic_vector(to_unsigned(280, 11)), std_logic_vector(to_unsigned(410, 11)), ScanlineX, ScanlineY);
		
		-- down arrow
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(380, 11)), std_logic_vector(to_unsigned(450, 11)), std_logic_vector(to_unsigned(420, 11)), std_logic_vector(to_unsigned(450, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(400, 11)), std_logic_vector(to_unsigned(410, 11)), std_logic_vector(to_unsigned(400, 11)), std_logic_vector(to_unsigned(470, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(380, 11)), std_logic_vector(to_unsigned(450, 11)), std_logic_vector(to_unsigned(400, 11)), std_logic_vector(to_unsigned(470, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(420, 11)), std_logic_vector(to_unsigned(450, 11)), std_logic_vector(to_unsigned(400, 11)), std_logic_vector(to_unsigned(470, 11)), ScanlineX, ScanlineY);
		
		-- right arrow
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(500, 11)), std_logic_vector(to_unsigned(440, 11)), std_logic_vector(to_unsigned(600, 11)), std_logic_vector(to_unsigned(440, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(565, 11)), std_logic_vector(to_unsigned(410, 11)), std_logic_vector(to_unsigned(565, 11)), std_logic_vector(to_unsigned(470, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(565, 11)), std_logic_vector(to_unsigned(410, 11)), std_logic_vector(to_unsigned(600, 11)), std_logic_vector(to_unsigned(440, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(565, 11)), std_logic_vector(to_unsigned(470, 11)), std_logic_vector(to_unsigned(600, 11)), std_logic_vector(to_unsigned(440, 11)), ScanlineX, ScanlineY);
		
		
		--ColorOutput :=	colorize_cell("00001100010", "00000111010", ScanlineX, ScanlineY) and (ColorOutput) and draw_line(std_logic_vector(to_unsigned(16, 10)), std_logic_vector(to_unsigned(320, 10)), std_logic_vector(to_unsigned(0, 10)), std_logic_vector(to_unsigned(338, 10)), ScanlineX, ScanlineY);
	end process;
	--ColorOutput <=	not (not colorize_cell("00001100010", "00000111010", ScanlineX, ScanlineY) or (not ((ScanlineX < std_logic_vector(to_unsigned(213, 10))) and (ScanlineX > std_logic_vector(to_unsigned(0, 10))) and (ScanlineY > std_logic_vector(to_unsigned(50, 10))) and (ScanlineY < std_logic_vector(to_unsigned(60, 10))))));

	ColorOut <= ColorOutput;
	
	SquareXmax <= "1010000000"-SquareWidth; -- (640 - SquareWidth)
	SquareYmax <= "0111100000"-SquareWidth;	-- (480 - SquareWidth)
	
end Behavioral;

