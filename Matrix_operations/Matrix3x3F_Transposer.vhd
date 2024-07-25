library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DTAM_FPGA_definitions_pack.all;

entity Matrix3x3F_Transposer is
	port(
		clk              : in  std_logic;
		enable           : in  std_logic;
		Matrix_input     : in  Matrix3x3F;
		Matrix_transpose : out Matrix3x3F
	);
end entity Matrix3x3F_Transposer;

architecture RTL of Matrix3x3F_Transposer is
begin
	process(clk, enable)
	begin
		if (rising_edge(clk) and enable = '1') then
			Matrix_transpose(0) <= Matrix_input(0);
			Matrix_transpose(4) <= Matrix_input(4);
			Matrix_transpose(8) <= Matrix_input(8);

			Matrix_transpose(1) <= Matrix_input(3);
			Matrix_transpose(2) <= Matrix_input(6);

			Matrix_transpose(3) <= Matrix_input(1);
			Matrix_transpose(5) <= Matrix_input(7);

			Matrix_transpose(6) <= Matrix_input(2);
			Matrix_transpose(7) <= Matrix_input(5);
		end if;
	end process;
end architecture RTL;

