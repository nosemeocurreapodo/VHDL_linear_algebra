library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


package Fixed_point_utility_functions is

	function to_fixed_point(int : integer; size : integer; frac_size : integer) return std_logic_vector;
	function to_fixed_point(float : real; size : integer; frac_size : integer) return std_logic_vector;
	--function fixed_point_to_std_logic_vector(fp : std_logic_vector) return std_logic_vector;

	--constant fixed_point_zero : fixed_point := to_fixed_point(0.0);

end package;

package body Fixed_point_utility_functions is

	function to_fixed_point(int : integer; size : integer; frac_size : integer) return std_logic_vector is
		variable fp : signed(size - 1 downto 0);
		variable i  : signed(size - 1 downto 0);
	begin
		i  := to_signed(int, size);
		fp := shift_left(i, frac_size);
		return std_logic_vector(fp);
	end function;

	function to_fixed_point(float : real; size : integer; frac_size : integer) return std_logic_vector is
		variable fp                : signed(size - 1 downto 0);
		variable float_shift       : real;
		variable float_shift_abs   : real;
		variable integer_shift_abs : integer;
	begin
		float_shift       := float * real(2 ** frac_size);
		float_shift_abs   := abs (float_shift);
		integer_shift_abs := integer(floor(float_shift_abs));
		fp                := signed(to_unsigned(integer_shift_abs, size));
		if (integer(float_shift) < 0) then
			fp := -fp;
		end if;
		return std_logic_vector(fp);
	end function;

end package body;