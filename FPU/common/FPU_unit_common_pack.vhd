library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package FPU_unit_common_pack is
	type FPU_operation is (ADD, SUB, MUL, DIV, SQRT);
	type FPU_rounding_mode is (nearest_even, zero, up, down);

	type FPU_exception is record
		ine       : std_logic;
		overflow  : std_logic;
		underflow : std_logic;
		div_zero  : std_logic;
		inf       : std_logic;
		zero      : std_logic;
		qnan      : std_logic;
		snan      : std_logic;
	end record;

	constant FPU_exceptions_initial_state : FPU_exception := (ine       => '0',
		                                                      overflow  => '0',
		                                                      underflow => '0',
		                                                      div_zero  => '0',
		                                                      inf       => '0',
		                                                      zero      => '0',
		                                                      qnan      => '0',
		                                                      snan      => '0');

	function to_fpu_operation(fpu_op_slv : std_logic_vector(2 downto 0)) return FPU_operation;
	function to_std_logic_vector(fp_op : FPU_operation) return std_logic_vector;
	function to_fpu_rounding_mode(fpu_rmode_slv : std_logic_vector(1 downto 0)) return FPU_rounding_mode;
	function to_std_logic_vector(fp_rmode : FPU_rounding_mode) return std_logic_vector;

end package FPU_unit_common_pack;

package body FPU_unit_common_pack is
	function to_fpu_operation(fpu_op_slv : std_logic_vector(2 downto 0)) return FPU_operation is
		variable fpu_op : FPU_operation;
	begin
		if (fpu_op_slv = "000") then
			fpu_op := ADD;
		elsif (fpu_op_slv = "001") then
			fpu_op := SUB;
		elsif (fpu_op_slv = "010") then
			fpu_op := MUL;
		elsif (fpu_op_slv = "011") then
			fpu_op := DIV;
		end if;
		return fpu_op;
	end function;

	function to_std_logic_vector(fp_op : FPU_operation) return std_logic_vector is
		variable fp_op_slv : std_logic_vector(2 downto 0);
	begin
		if fp_op = ADD then
			fp_op_slv := "000";
		elsif fp_op = SUB then
			fp_op_slv := "001";
		elsif fp_op = MUL then
			fp_op_slv := "010";
		elsif fp_op = DIV then
			fp_op_slv := "011";
		end if;
		return fp_op_slv;
	end function;

	function to_fpu_rounding_mode(fpu_rmode_slv : std_logic_vector(1 downto 0)) return FPU_rounding_mode is
		variable fpu_rmode : FPU_rounding_mode;
	begin
		if (fpu_rmode_slv = "00") then
			fpu_rmode := nearest_even;
		elsif (fpu_rmode_slv = "01") then
			fpu_rmode := zero;
		elsif (fpu_rmode_slv = "10") then
			fpu_rmode := up;
		elsif (fpu_rmode_slv = "11") then
			fpu_rmode := down;
		end if;
		return fpu_rmode;
	end function;

	function to_std_logic_vector(fp_rmode : FPU_rounding_mode) return std_logic_vector is
		variable fp_rmode_slv : std_logic_vector(1 downto 0);
	begin
		--nearest_even, zero, up, down
		if (fp_rmode = nearest_even) then
			fp_rmode_slv := "00";
		elsif (fp_rmode = zero) then
			fp_rmode_slv := "01";
		elsif (fp_rmode = up) then
			fp_rmode_slv := "10";
		elsif (fp_rmode = down) then
			fp_rmode_slv := "11";
		end if;
		return fp_rmode_slv;
	end function;
end package body FPU_unit_common_pack;
