library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Floating_point_definition.all;
use work.FPU_unit_common_pack.all;

package Floating_point_unit_interface_pack is
	type BUS_to_floating_point_unit is record
		opa            : floating_point;
		opb            : floating_point;
		fpu_op         : FPU_operation;
		rmode          : FPU_rounding_mode;
		--operation negotiation
		new_request    : std_logic;
		new_request_id : request_id;
	end record;

	constant FPU_BUS_to_fpu_initial_state : BUS_to_floating_point_unit := (opa            => to_floating_point(std_logic_vector(to_unsigned(0, floating_point_size))),
		                                                                   opb            => to_floating_point(std_logic_vector(to_unsigned(0, floating_point_size))),
		                                                                   fpu_op         => ADD,
		                                                                   rmode          => nearest_even,
		                                                                   new_request    => '0',
		                                                                   new_request_id => to_signed(0, request_id_size));

	type BUS_from_floating_point_unit is record
		request_ready    : std_logic;
		request_ready_id : request_id;
		FPU_exc          : FPU_exception;
		output           : floating_point;
	end record;

	constant FPU_BUS_from_fpu_initial_state : BUS_from_floating_point_unit := (request_ready    => '0',
		                                                                       request_ready_id => to_signed(0, request_id_size),
		                                                                       FPU_exc          => FPU_exceptions_initial_state,
		                                                                       output           => to_floating_point(std_logic_vector(to_unsigned(0, floating_point_size))));

end Floating_point_unit_interface_pack;

package body Floating_point_unit_interface_pack is
end Floating_point_unit_interface_pack;
