library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package FPU_utility_functions is
	-- count the  zeros starting from left
	function count_l_zeros(signal s_vector : std_logic_vector) return integer;
	function count_l_zeros(signal s_vector : unsigned) return integer;
	function count_l_zeros(signal s_vector : signed) return integer;
	function count_l_zeros_var(s_vector : unsigned) return integer;

end package FPU_utility_functions;

package body FPU_utility_functions is
	function count_l_zeros(signal s_vector : std_logic_vector) return integer is
		variable v_count : integer := 0;
	begin
		for i in s_vector'range loop
			if s_vector(i) = '1' then
				v_count := s_vector'length - i - 1;
				exit;
			end if;
		end loop;
		return v_count;
	end count_l_zeros;

	function count_l_zeros(signal s_vector : unsigned) return integer is
		variable v_count : integer := 0;
	begin
		for i in s_vector'range loop
			if s_vector(i) = '1' then
				v_count := s_vector'length - i - 1;
				exit;
			end if;
		end loop;
		return v_count;
	end count_l_zeros;
	
	function count_l_zeros(signal s_vector : signed) return integer is
		variable v_count : integer := 0;
	begin
		for i in s_vector'range loop
			if s_vector(i) = '1' then
				v_count := s_vector'length - i - 1;
				exit;
			end if;
		end loop;
		return v_count;
	end count_l_zeros;

	function count_l_zeros_var(s_vector : unsigned) return integer is
		variable v_count : integer := 0;
	begin
		for i in s_vector'range loop
			if s_vector(i) = '1' then
				v_count := s_vector'length - i - 1;
				exit;
			end if;
		end loop;
		return v_count;
	end count_l_zeros_var;
end package body FPU_utility_functions;
