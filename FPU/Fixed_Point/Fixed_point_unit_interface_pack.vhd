library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Fixed_point_definition.all;
use work.FPU_unit_common_pack.all;

package Fixed_point_unit_interface_pack is

	type BUS_to_fixed_point_unit is record
		opa            : fixed_point;
		opb            : fixed_point;
		operation      : FPU_operation;
		rmode          : FPU_rounding_mode;
		new_request    : std_logic;
		new_request_id : request_id;
	end record;

	constant BUS_to_fixed_point_unit_initial_state : BUS_to_fixed_point_unit := (opa            => to_fixed_point(0.0),
		                                                                         opb            => to_fixed_point(0.0),
		                                                                         operation      => ADD,
		                                                                         rmode          => nearest_even,
		                                                                         new_request    => '0',
		                                                                         new_request_id => request_id_zero);

	type BUS_from_fixed_point_unit is record
		request_ready     : std_logic;
		request_ready_id  : request_id;
		exception         : FPU_exception;
		output            : fixed_point;
	end record;

	constant BUS_from_fixed_point_initial_state : BUS_from_fixed_point_unit := (request_ready    => '0',
	                                                                            request_ready_id => request_id_zero,
                                                                            	exception        => FPU_exceptions_initial_state,
	                                                                            output           => to_fixed_point(0.0));

end package Fixed_point_unit_interface_pack;

package body Fixed_point_unit_interface_pack is

end package body Fixed_point_unit_interface_pack;
