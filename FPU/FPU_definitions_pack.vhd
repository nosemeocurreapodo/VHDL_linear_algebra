library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.request_id_pack.all;
use work.Fixed_point_definition.all;
use work.Floating_point_definition.all;
use work.Fixed_point_unit_interface_pack.all;
use work.Floating_point_unit_interface_pack.all;
use work.FPU_unit_common_pack.all;

package FPU_definitions_pack is
	-- for fixed point
--	constant scalar_size : integer := fixed_point_size;
--	subtype scalar is fixed_point;
	
--	constant scalar_zero : fixed_point := fixed_point_zero;

--	subtype BUS_to_FPU is BUS_to_fixed_point_unit;
--	subtype BUS_from_FPU is BUS_from_fixed_point_unit;

--	-- for floating point
	constant scalar_size : integer := floating_point_size;
	subtype scalar is floating_point;

	constant scalar_zero : floating_point := floating_point_zero;

	subtype BUS_to_FPU is BUS_to_floating_point_unit;
	subtype BUS_from_FPU is BUS_from_floating_point_unit;

	function to_scalar(slv : std_logic_vector(scalar_size - 1 downto 0)) return scalar;
	function to_scalar(int : integer) return scalar;
	function to_scalar(float : real) return scalar;
	function scalar_to_std_logic_vector(fp : scalar) return std_logic_vector;

end package FPU_definitions_pack;

package body FPU_definitions_pack is

--	function to_scalar(slv : std_logic_vector(scalar_size - 1 downto 0)) return scalar is
--		variable fp : fixed_point;
--	begin
--		fp := to_fixed_point(slv);
--		return fp;
--	end function;

--	function to_scalar(int : integer) return scalar is
--		variable fp : fixed_point;
--	begin
--		fp := to_fixed_point(int);
--		return fp;
--	end function;

--	function to_scalar(float : real) return scalar is
--		variable fp : fixed_point;
--	begin
--		fp := to_fixed_point(float);
--		return fp;
--	end function;

--	function scalar_to_std_logic_vector(fp : scalar) return std_logic_vector is
--		variable slv : std_logic_vector(fixed_point_size-1 downto 0);
--		variable fix_p : fixed_point;
--	begin
--		fix_p := fp;
--		slv := fixed_point_to_std_logic_vector(fix_p);
--		return slv;
--	end function;
	
	
	function to_scalar(slv : std_logic_vector(scalar_size - 1 downto 0)) return scalar is
		variable fp : floating_point;
	begin
		fp := to_floating_point(slv);
		return fp;
	end function;

	function to_scalar(int : integer) return scalar is
		variable fp : floating_point;
	begin
		fp := to_floating_point(int);
		return fp;
	end function;

	function to_scalar(float : real) return scalar is
		variable fp : floating_point;
	begin
		fp := to_floating_point(float);
		return fp;
	end function;

	function scalar_to_std_logic_vector(fp : scalar) return std_logic_vector is
		variable slv : std_logic_vector(floating_point_size-1 downto 0);
		variable fix_p : floating_point;
	begin
		fix_p := fp;
		slv := floating_point_to_std_logic_vector(fix_p);
		return slv;
	end function;
	
end package body FPU_definitions_pack;
