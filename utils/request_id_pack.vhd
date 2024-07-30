library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package request_id_pack is
		
		constant request_id_size : integer:= 32;
		
		type request_id is record
			id : std_logic_vector(request_id_size-1 downto 0);
		end record;

		constant request_id_zero : request_id := (id => std_logic_vector(to_signed(0, request_id_size)));

end package request_id_pack;

package body request_id_pack is
end package body request_id_pack;
