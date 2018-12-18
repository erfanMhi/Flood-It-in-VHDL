----------------------------------------------------------------------------------
-- Moving Square Demonstration 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.fpga_graphic.all;
entity Board is
  port ( CLK_50MHz		: in std_logic;
			RESET				: in std_logic;
			ColorOut			: out std_logic_vector(11 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in std_logic_vector(7 downto 0);
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0)
  );
end Board;

architecture Behavioral of Board is
  
  shared variable ColorOutput: std_logic_vector(11 downto 0);
  
  signal column_width: std_logic_vector(9 downto 0) := "0000000001";
  signal row_width: std_logic_vector(9 downto 0) := "0000000001";
  
  signal food_size: std_logic_vector(10 downto 0) := "00000010110";
  signal food_inc: boolean:= false;
  
  signal SquareX: std_logic_vector(9 downto 0) := "0000001110";  
  signal SquareY: std_logic_vector(9 downto 0) := "0000010111";  
  signal SquareXMoveDir, SquareYMoveDir: std_logic := '0';
  --constant SquareWidth: std_logic_vector(4 downto 0) := "11001";
  constant SquareXmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareXmax: std_logic_vector(9 downto 0); -- := "1010000000"-SquareWidth;
  constant SquareYmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareYmax: std_logic_vector(9 downto 0); -- := "0111100000"-SquareWidth;
  signal ColorSelect: std_logic_vector(2 downto 0) := "001";
  signal Prescaler: std_logic_vector(40 downto 0) := (others => '0');
  
   function multiply(a,b: std_logic_vector(10 downto 0)) return std_logic_vector is
		variable ans:std_logic_vector(10 downto 0);
  begin
		ans := std_logic_vector(unsigned(a) * unsigned(b))(10 downto 0);
		return ans;
  
  end function multiply;
  
	procedure to_grid(variable   x,y   : in std_logic_vector;
                            variable row, column    : out    std_logic_vector) is
		constant row_width: std_logic_vector(10 downto 0) := "00000000100";
		constant column_width: std_logic_vector(10 downto 0) := "00000000100"; 
    begin
		row := multiply(x, row_width);
		column := multiply(y, column_width);
    end procedure;

  

  
  
  function colorize_cell(row, column, ScanlineX, ScanlineY: std_logic_vector(10 downto 0)) return std_logic_vector is
		variable color_cell:std_logic_vector(11 downto 0);
		constant row_width: std_logic_vector(10 downto 0) := "00000000100";
		constant column_width: std_logic_vector(10 downto 0) := "00000000100";
		variable r, c: std_logic_vector(10 downto 0);
	begin
		r := row;
		c := column;
		to_grid(r, c, r, c);
		if (ScanlineX >= c AND ScanlineY >= r AND ScanlineX < (c+row_width) AND ScanlineY < (r+column_width)) then
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
	
	function draw_circle(x1, y1, r, ScanlineX, ScanlineY: std_logic_vector(10 downto 0)) return std_logic_vector is
		variable color_line:std_logic_vector(11 downto 0);
		variable x: integer;
		constant row_width: std_logic_vector(10 downto 0) := "00000000100";
		constant column_width: std_logic_vector(10 downto 0) := "00000000100";
		variable row, column: std_logic_vector(10 downto 0);
	begin
		row := x1;
		column := y1;
		to_grid(row, column, row, column);
		x := ((to_integer(unsigned(row))-to_integer(unsigned(ScanlineX))) * (to_integer(unsigned(row))-to_integer(unsigned(ScanlineX)))) + ((to_integer(unsigned(column))-to_integer(unsigned(ScanlineY))) * (to_integer(unsigned(column))-to_integer(unsigned(ScanlineY))));
		
		if x <= to_integer(unsigned(r)) then
			color_line := "000000001001";
			
		else
			color_line := "111111111111";
		end if;
		return color_line;
	end function draw_circle;

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
			if Prescaler = "0000000000000000000100000000000000000000" then  -- Activated every 0,002 sec (2 msec)
				Prescaler <= (others => '0');
				if food_size = "00000010110" then
					food_inc <= false;
				elsif food_size = "00000000001" then
					food_inc <= true;
				end if;
				if food_inc = true then
					food_size <= food_size +1;
				else
					food_size <= food_size -1;
				end if;
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
		Coloroutput := draw_line(std_logic_vector(to_unsigned(300, 11)), std_logic_vector(to_unsigned(455, 11)), std_logic_vector(to_unsigned(330, 11)), std_logic_vector(to_unsigned(455, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(300, 11)), std_logic_vector(to_unsigned(455, 11)), std_logic_vector(to_unsigned(310, 11)), std_logic_vector(to_unsigned(445, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(300, 11)), std_logic_vector(to_unsigned(455, 11)), std_logic_vector(to_unsigned(310, 11)), std_logic_vector(to_unsigned(465, 11)), ScanlineX, ScanlineY);
		
		-- up arrow
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(335, 11)), std_logic_vector(to_unsigned(440, 11)), std_logic_vector(to_unsigned(335, 11)), std_logic_vector(to_unsigned(470, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(335, 11)), std_logic_vector(to_unsigned(440, 11)), std_logic_vector(to_unsigned(345, 11)), std_logic_vector(to_unsigned(450, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(335, 11)), std_logic_vector(to_unsigned(440, 11)), std_logic_vector(to_unsigned(325, 11)), std_logic_vector(to_unsigned(450, 11)), ScanlineX, ScanlineY);
		
		-- down arrow
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(355, 11)), std_logic_vector(to_unsigned(460, 11)), std_logic_vector(to_unsigned(345, 11)), std_logic_vector(to_unsigned(470, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(335, 11)), std_logic_vector(to_unsigned(460, 11)), std_logic_vector(to_unsigned(345, 11)), std_logic_vector(to_unsigned(470, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(345, 11)), std_logic_vector(to_unsigned(440, 11)), std_logic_vector(to_unsigned(345, 11)), std_logic_vector(to_unsigned(470, 11)), ScanlineX, ScanlineY);
		
		-- right arrow
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(380, 11)), std_logic_vector(to_unsigned(455, 11)), std_logic_vector(to_unsigned(350, 11)), std_logic_vector(to_unsigned(455, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(380, 11)), std_logic_vector(to_unsigned(455, 11)), std_logic_vector(to_unsigned(370, 11)), std_logic_vector(to_unsigned(465, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(380, 11)), std_logic_vector(to_unsigned(455, 11)), std_logic_vector(to_unsigned(370, 11)), std_logic_vector(to_unsigned(445, 11)), ScanlineX, ScanlineY);
		
		-- rectangle
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(80, 11)), std_logic_vector(to_unsigned(50, 11)), std_logic_vector(to_unsigned(600, 11)), std_logic_vector(to_unsigned(50, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(80, 11)), std_logic_vector(to_unsigned(50, 11)), std_logic_vector(to_unsigned(80, 11)), std_logic_vector(to_unsigned(430, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(600, 11)), std_logic_vector(to_unsigned(430, 11)), std_logic_vector(to_unsigned(80, 11)), std_logic_vector(to_unsigned(430, 11)), ScanlineX, ScanlineY);
		Coloroutput := Coloroutput and draw_line(std_logic_vector(to_unsigned(600, 11)), std_logic_vector(to_unsigned(430, 11)), std_logic_vector(to_unsigned(600, 11)), std_logic_vector(to_unsigned(50, 11)), ScanlineX, ScanlineY);
	
		-- colored cells
		ColorOutput :=	Coloroutput and colorize_cell("00000101111", "00000100110", ScanlineX, ScanlineY);
		ColorOutput :=	Coloroutput and colorize_cell("00000101110", "00000100110", ScanlineX, ScanlineY);
		ColorOutput :=	Coloroutput and colorize_cell("00000101110", "00000100111", ScanlineX, ScanlineY);
		ColorOutput :=	Coloroutput and colorize_cell("00000101110", "00000101000", ScanlineX, ScanlineY);
		--ColorOutput :=	Coloroutput and colorize_cell("00000100110", "00000010110", ScanlineX, ScanlineY);
		ColorOutput :=	Coloroutput and draw_circle("00000100110", "00000010110", food_size, ScanlineX, ScanlineY);
	end process;
	ColorOut <= ColorOutput;
	
	SquareXmax <= "1010000000"-SquareWidth; -- (640 - SquareWidth)
	SquareYmax <= "0111100000"-SquareWidth;	-- (480 - SquareWidth)
	
end Behavioral;

