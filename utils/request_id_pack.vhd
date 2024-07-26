library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package request_id_pack is
		constant request_id_size : integer:= 32;
		subtype request_id is signed(request_id_size-1 downto 0);
		constant request_id_zero : request_id := to_signed(0, request_id_size);

end package request_id_pack;

package body request_id_pack is
end package body request_id_pack;
