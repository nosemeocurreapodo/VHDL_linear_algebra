library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Fixed_point_utility_functions.all;
use work.FPU_unit_common_pack.all;

package Fixed_point_unit_interface_pack is

	constant SIZE       : integer := 32;
	constant FRAC_SIZE  : integer := 20;
	constant AUX_SIZE   : integer := 32;

	type BUS_to_fixed_point_unit is record
		opa          : std_logic_vector(SIZE - 1 downto 0);
		opb          : std_logic_vector(SIZE - 1 downto 0);
		operation    : FPU_operation;
		rmode        : FPU_rounding_mode;
		new_request  : std_logic;
		aux          : std_logic_vector(AUX_SIZE - 1 downto 0);
	end record;

	constant BUS_to_fixed_point_unit_initial_state : BUS_to_fixed_point_unit := (opa            => to_fixed_point(0.0, SIZE, FRAC_SIZE),
		                                                                         opb            => to_fixed_point(0.0, SIZE, FRAC_SIZE),
		                                                                         operation      => ADD,
		                                                                         rmode          => nearest_even,
		                                                                         new_request    => '0',
		                                                                         aux            => std_logic_vector(to_signed(0, AUX_SIZE)));

	type BUS_from_fixed_point_unit is record
		request_ready  : std_logic;
		aux            : std_logic_vector(AUX_SIZE - 1 downto 0);
		exception      : FPU_exception;
		output         : std_logic_vector(SIZE - 1 downto 0);
	end record;

	constant BUS_from_fixed_point_initial_state : BUS_from_fixed_point_unit := (request_ready  => '0',
	                                                                            aux            => std_logic_vector(to_signed(0, AUX_SIZE)),
                                                                            	exception      => FPU_exceptions_initial_state,
	                                                                            output         => to_fixed_point(0.0, SIZE, FRAC_SIZE));

end package Fixed_point_unit_interface_pack;

package body Fixed_point_unit_interface_pack is

end package body Fixed_point_unit_interface_pack;
