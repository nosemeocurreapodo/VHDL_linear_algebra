library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;

use work.FPU_wrapper_component_pack.all;
use work.FPU_wrapper_definitions_pack.all;
use work.Matrix_definition_pack.all;

entity Matrix3x3_VMultiplier_fast is
	port(
		clk                      : in  std_logic;
		new_operation_request    : in  std_logic;
		new_operation_request_id : in  request_id;
		new_operation_done       : out std_logic;
		new_operation_done_id    : out request_id;
		Matrix_input             : in  Matrix3x3;
		Vector_input             : in  Vector3;
		Vector_output            : out Vector3
	);
end entity Matrix3x3_VMultiplier_fast;

architecture RTL of Matrix3x3_VMultiplier_fast is

	-- 1 stage
	signal Matrix_input_reg        : Matrix3x3;
	signal Vector_input_reg        : Vector3;
	signal First_stage_request_id  : request_id;
	signal First_stage_enable      : std_logic := '0';
	-- 2 stage
	signal Vector_aux1_stage2      : Vector3;
	signal Vector_aux2_stage2      : Vector3;
	signal Vector_aux3_stage2      : Vector3;
	signal Second_stage_request_id : request_id;
	signal Second_stage_enable     : std_logic := '0';
	--3 stage
	signal Vector_aux1_stage3      : Vector3;
	signal Third_stage_request_id  : request_id;
	signal Third_stage_enable      : std_logic;

begin

	--first stage
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (new_operation_request = '1') then
				Matrix_input_reg       <= Matrix_input;
				Vector_input_reg       <= Vector_input;
				First_stage_request_id <= new_operation_request_id;
				First_stage_enable     <= '1';
			else
				First_stage_enable <= '0';
			end if;
		end if;
	end process;
	-- second stage
	-- 9 multiplicadores
	--X
	Multipliers : FPU_wrapper_multiplier port map(clk       => clk,
			                                      opa       => Matrix_input_reg(0),
			                                      opb       => Vector_input_reg(0),
			                                      new_op    => First_stage_enable,
			                                      output    => Vector_aux1_stage2(0),
			                                      op_id_in  => First_stage_request_id,
			                                      op_ready  => Second_stage_enable,
			                                      op_id_out => Second_stage_request_id);

	generate_multiplires : for I in 1 to 2 generate
		Multipliers : FPU_wrapper_multiplier port map(clk      => clk,
				                                      opa      => Matrix_input_reg(I * 3),
				                                      opb      => Vector_input_reg(0),
				                                      new_op   => First_stage_enable,
				                                      output   => Vector_aux1_stage2(I),
				                                      op_id_in => First_stage_request_id);
	end generate;
	--Y
	generate_y_multiplires : for I in 0 to 2 generate
		Multipliers : FPU_wrapper_multiplier port map(clk      => clk,
				                                      opa      => Matrix_input_reg(((I) * 3) + 1),
				                                      opb      => Vector_input_reg(1),
				                                      output   => Vector_aux2_stage2(I),
				                                      new_op   => First_stage_enable,
				                                      op_id_in => First_stage_request_id);
	end generate;
	--Z
	generate_z_multiplires : for I in 0 to 2 generate
		Multipliers : FPU_wrapper_multiplier port map(clk      => clk,
				                                      opa      => Matrix_input_reg(((I) * 3) + 2),
				                                      opb      => Vector_input_reg(2),
				                                      output   => Vector_aux3_stage2(I),
				                                      new_op   => First_stage_enable,
				                                      op_id_in => First_stage_request_id);
	end generate;

	-- 3 stage
	-- 3 sumadores
	Adder_stage3 : FPU_wrapper_adder port map(clk       => clk,
			                                  opa       => Vector_aux1_stage2(0),
			                                  opb       => Vector_aux2_stage2(0),
			                                  output    => Vector_aux1_stage3(0),
			                                  new_op    => Second_stage_enable,
			                                  op_id_in  => Second_stage_request_id,
			                                  op_ready  => Third_stage_enable,
			                                  op_id_out => Third_stage_request_id);
	generate_adders_stage3 : for I in 1 to 2 generate
		Adders : FPU_wrapper_adder port map(clk      => clk,
				                            opa      => Vector_aux1_stage2(I),
				                            opb      => Vector_aux2_stage2(I),
				                            output   => Vector_aux1_stage3(I),
				                            new_op   => Second_stage_enable,
				                            op_id_in => Second_stage_request_id);
	end generate;

	-- 4 stage (output)
	-- 3 sumadores
	Adder_stage4 : FPU_wrapper_adder port map(clk       => clk,
			                                  opa       => Vector_aux3_stage2(0),
			                                  opb       => Vector_aux1_stage3(0),
			                                  output    => Vector_output(0),
			                                  new_op    => Third_stage_enable,
			                                  op_id_in  => Third_stage_request_id,
			                                  op_ready  => new_operation_done,
			                                  op_id_out => new_operation_done_id);
	generate_adders_stage_4 : for I in 1 to 2 generate
		Adders_stage4 : FPU_wrapper_adder port map(clk      => clk,
				                                   opa      => Vector_aux3_stage2(I),
				                                   opb      => Vector_aux1_stage3(I),
				                                   output   => Vector_output(I),
				                                   new_op   => Third_stage_enable,
				                                   op_id_in => Third_stage_request_id);
	end generate;

end architecture RTL;

