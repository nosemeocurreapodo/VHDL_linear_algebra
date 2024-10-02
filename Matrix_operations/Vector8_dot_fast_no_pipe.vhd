library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;

use work.FPU_definitions_pack.all;
use work.FPU_component_pack.all;
use work.Matrix_definition_pack.all;

entity Vector8_dot_fast_no_pipe is
	port(
		clk                      : in  std_logic;
		new_operation_request    : in  std_logic;
		new_operation_request_id : in  request_id;
		new_operation_done       : out std_logic;
		new_operation_done_id    : out request_id;
		Vector1_input            : in  Vector8;
		Vector2_input            : in  Vector8;
		output                   : out scalar
	);
end entity Vector8_dot_fast_no_pipe;

architecture RTL of Vector8_dot_fast_no_pipe is
	-- 1 stage
	signal output_1       : signed(scalar_size*2 - 1 downto 0);
	signal request_id_1   : request_id;
	signal op_done_1      : std_logic := '0';
begin

	process(clk)
	begin
		if (rising_edge(clk)) then
			op_done_1    <= new_operation_request;
			request_id_1 <= new_operation_request_id;
			output_1 <= Vector1_input(0)*Vector2_input(0) + 
					  Vector1_input(1)*Vector2_input(1) + 
					  Vector1_input(2)*Vector2_input(2) +
					  Vector1_input(3)*Vector2_input(3) +
					  Vector1_input(4)*Vector2_input(4) +
					  Vector1_input(5)*Vector2_input(5) +
					  Vector1_input(6)*Vector2_input(6) +
					  Vector1_input(7)*Vector2_input(7);
			
			output <= output_1(scalar_size + 20 - 1 downto 20);
			new_operation_done <= op_done_1;
			new_operation_done_id <= request_id_1;

		end if;
	end process;


end architecture RTL;

