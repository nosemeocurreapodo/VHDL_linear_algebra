library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Floating_point_definition.all;
use work.FPU_unit_common_pack.all;

package Floating_point_unit_interface_pack is

	constant SIZE       : integer := 32;
	constant FRAC_SIZE  : integer := 20;

	type BUS_to_floating_point_unit is record
		opa            : std_logic_vector(SIZE - 1 downto 0);
		opb            : std_logic_vector(SIZE - 1 downto 0);
		operation      : FPU_operation;
		rmode          : FPU_rounding_mode;
		--operation negotiation
		new_request    : std_logic;
		new_request_id : request_id;
	end record;

	constant BUS_to_floating_point_unit_initial_state : BUS_to_floating_point_unit := (opa            => to_floating_point(0, EXPONENT_SIZE, MANTISSA_SIZE),
		                                                                               opb            => to_floating_point(0, EXPONENT_SIZE, MANTISSA_SIZE),
		                                                                               operation      => ADD,
		                                                                               rmode          => nearest_even,
		                                                                               new_request    => '0',
		                                                                               new_request_id => request_id_zero);

	type BUS_from_floating_point_unit is record
		request_ready    : std_logic;
		request_ready_id : request_id;
		exception        : FPU_exception;
		output           : std_logic_vector(SIZE - 1 downto 0);
	end record;

	constant BUS_from_floating_point_unit_initial_state : BUS_from_floating_point_unit := (request_ready    => '0',
		                                                                                   request_ready_id => request_id_zero,
		                                                                                   exception        => FPU_exceptions_initial_state,
		                                                                                   output           => to_floating_point(0, EXPONENT_SIZE, MANTISSA_SIZE));

end Floating_point_unit_interface_pack;

package body Floating_point_unit_interface_pack is
end Floating_point_unit_interface_pack;
