library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Floating_point_utility_functions_pack.all;
use work.FPU_unit_common_pack.all;

package Floating_point_unit_interface_pack is

	constant INPUT_SIZE           : integer := 32;
	constant INPUT_MANTISSA_SIZE  : integer := 23;
	constant OUTPUT_SIZE          : integer := 34;
	constant OUTPUT_MANTISSA_SIZE : integer := 14;
	
	constant AUX_SIZE          : integer := OUTPUT_SIZE;

	type BUS_to_floating_point_unit is record
		opa            : std_logic_vector(INPUT_SIZE - 1 downto 0);
		opb            : std_logic_vector(INPUT_SIZE - 1 downto 0);
		operation      : FPU_operation;
		rmode          : FPU_rounding_mode;
		--operation negotiation
		new_request    : std_logic;
		aux            : std_logic_vector(AUX_SIZE - 1 downto 0);
	end record;

	constant BUS_to_floating_point_unit_initial_state : BUS_to_floating_point_unit := (opa            => to_floating_point(0, INPUT_SIZE, INPUT_MANTISSA_SIZE),
		                                                                               opb            => to_floating_point(0, INPUT_SIZE, INPUT_MANTISSA_SIZE),
		                                                                               operation      => ADD,
		                                                                               rmode          => nearest_even,
		                                                                               new_request    => '0',
		                                                                               aux            => std_logic_vector(to_unsigned(0, AUX_SIZE)));

	type BUS_from_floating_point_unit is record
		request_ready    : std_logic;
		aux              : std_logic_vector(AUX_SIZE - 1 downto 0);
		exception        : FPU_exception;
		output           : std_logic_vector(OUTPUT_SIZE - 1 downto 0);
	end record;

	constant BUS_from_floating_point_unit_initial_state : BUS_from_floating_point_unit := (request_ready    => '0',
		                                                                                   aux              => std_logic_vector(to_unsigned(0, AUX_SIZE)),
		                                                                                   exception        => FPU_exceptions_initial_state,
		                                                                                   output           => to_floating_point(0, OUTPUT_SIZE, OUTPUT_MANTISSA_SIZE));

end Floating_point_unit_interface_pack;

package body Floating_point_unit_interface_pack is
end Floating_point_unit_interface_pack;
