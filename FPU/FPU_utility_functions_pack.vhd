library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.Fixed_point_utility_functions_pack.all;
use work.Floating_point_utility_functions_pack.all;

package FPU_utility_functions_pack is

	function to_scalar(int : integer; size : integer; frac_size : integer) return std_logic_vector;
	function to_scalar(float : real; size : integer; frac_size : integer) return std_logic_vector;

end package;

package body FPU_utility_functions_pack is

	function to_scalar(int : integer; size : integer; frac_size : integer) return std_logic_vector is
		variable fp : std_logic_vector(size - 1 downto 0);
	begin
		--fp := to_fixed_point(int, size, frac_size);
		fp := to_floating_point(int, size, frac_size);
		return fp;
	end function;

	function to_scalar(float : real; size : integer; frac_size : integer) return std_logic_vector is
		variable fp : std_logic_vector(size - 1 downto 0);
	begin
		--fp := to_fixed_point(float, size, frac_size);
		fp := to_floating_point(float, size, frac_size);
		return fp;
	end function;
	
end package body;
