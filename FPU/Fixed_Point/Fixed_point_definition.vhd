library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.FPU_utility_functions.all;

package Fixed_point_definition is
	constant fixed_point_size : integer := 32;
	constant fraction_size    : integer := 20;

	subtype fixed_point is signed(fixed_point_size - 1 downto 0);
	
	function to_fixed_point(slv : std_logic_vector(fixed_point_size - 1 downto 0)) return fixed_point;
	function to_fixed_point(int : integer) return fixed_point;
	function to_fixed_point(float : real) return fixed_point;
	function fixed_point_to_std_logic_vector(fp : fixed_point) return std_logic_vector;

	constant fixed_point_zero : fixed_point := to_fixed_point(0.0);

end package;

package body Fixed_point_definition is

	function to_fixed_point(slv : std_logic_vector(fixed_point_size - 1 downto 0)) return fixed_point is
		variable fp  : fixed_point;
	begin
		fp := signed(slv);
		return fp;
	end function;

	function to_fixed_point(int : integer) return fixed_point is
		variable fp : fixed_point;
		variable i  : signed(fixed_point_size - 1 downto 0);
	begin
		i  := to_signed(int, fixed_point_size);
		fp := shift_left(i, fraction_size);
		return fp;
	end function;

	function to_fixed_point(float : real) return fixed_point is
		variable fp                : fixed_point;
		variable float_shift       : real;
		variable float_shift_abs   : real;
		variable integer_shift_abs : integer;
	begin
		float_shift       := float * real(2 ** fraction_size);
		float_shift_abs   := abs (float_shift);
		integer_shift_abs := integer(floor(float_shift_abs));
		fp                := signed(to_unsigned(integer_shift_abs, fixed_point_size));
		if (integer(float_shift) < 0) then
			fp := -fp;
		end if;
		return fp;
	end function;

	function fixed_point_to_std_logic_vector(fp : fixed_point) return std_logic_vector is
		variable slv : std_logic_vector(fixed_point_size - 1 downto 0);
	begin
		slv := std_logic_vector(fp);
		return slv;
	end function;
	
end package body;