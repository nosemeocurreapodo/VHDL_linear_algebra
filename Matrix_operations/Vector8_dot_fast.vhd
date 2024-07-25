library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;

use work.FPU_wrapper_component_pack.all;
use work.FPU_wrapper_definitions_pack.all;
use work.Matrix_definition_pack.all;

entity Vector8_dot_fast is
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
end entity Vector8_dot_fast;

architecture RTL of Vector8_dot_fast is

	-- 1 stage
	signal Vector1_input_reg       : Vector8;
	signal Vector2_input_reg       : Vector8;
	signal First_stage_request_id  : request_id;
	signal First_stage_enable      : std_logic := '0';
	-- 2 stage
	signal Vector_aux1_stage2      : Vector8;
	signal Second_stage_request_id : request_id;
	signal Second_stage_enable     : std_logic := '0';
	--3 stage
	signal Vector_aux1_stage3      : Vector4;
	signal Third_stage_request_id  : request_id;
	signal Third_stage_enable      : std_logic;
	--4 stage
	signal Vector_aux1_stage4      : Vector2;
	signal Forth_stage_request_id  : request_id;
	signal Forth_stage_enable      : std_logic;

begin

	--first stage
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (new_operation_request = '1') then
				Vector1_input_reg       <= Vector1_input;
				Vector2_input_reg       <= Vector2_input;
				First_stage_request_id <= new_operation_request_id;
				First_stage_enable     <= '1';
			else
				First_stage_enable <= '0';
			end if;
		end if;
	end process;
	-- second stage
	-- 8 multiplicadores
	--X
	Multiplier_stage1 : FPU_multiplier port map(clk       => clk,
			                              opa       => Vector1_input_reg(0),
			                              opb       => Vector2_input_reg(0),
			                              new_op    => First_stage_enable,
			                              output    => Vector_aux1_stage2(0),
			                              op_id_in  => First_stage_request_id,
			                              op_ready  => Second_stage_enable,
			                              op_id_out => Second_stage_request_id);

	generate_multiplires : for I in 1 to 7 generate
		Multipliers_stage1 : FPU_multiplier port map(clk      => clk,
				                              opa      => Matrix_input_reg(I),
				                              opb      => Vector_input_reg(I),
				                              new_op   => First_stage_enable,
				                              output   => Vector_aux1_stage2(I),
				                              op_id_in => First_stage_request_id);
	end generate;

	-- 3 stage
	-- 4 sumadores
	Adder_stage3 : FPU_adder port map(clk       => clk,
			                          opa       => Vector_aux1_stage2(0),
			                          opb       => Vector_aux1_stage2(1),
			                          output    => Vector_aux1_stage3(0),
			                          new_op    => Second_stage_enable,
			                          op_id_in  => Second_stage_request_id,
			                          op_ready  => Third_stage_enable,
			                          op_id_out => Third_stage_request_id);

	generate_adders_stage3 : for I in 1 to 3 generate
	Adders_stage3 : FPU_adder port map(clk      => clk,
				                       opa      => Vector_aux1_stage2(I*2),
				                       opb      => Vector_aux2_stage2(I*2+1),
				                       output   => Vector_aux1_stage3(I),
				                       new_op   => Second_stage_enable,
				                       op_id_in => Second_stage_request_id);
	end generate;

	-- 4 stage
	-- 2 sumadores
	Adder_1_stage4 : FPU_adder port map(clk       => clk,
			                            opa       => Vector_aux1_stage3(0),
			                            opb       => Vector_aux1_stage3(1),
			                            output    => Vector_aux1_stage4(0),
			                            new_op    => Third_stage_enable,
			                            op_id_in  => Third_stage_request_id,
			                            op_ready  => Forth_stage_enable,
			                            op_id_out => Forth_stage_request_id);

	Adder_2_stage4 : FPU_adder port map(clk       => clk,
			                            opa       => Vector_aux1_stage3(2),
			                            opb       => Vector_aux1_stage3(3),
			                            output    => Vector_aux1_stage4(1),
			                            new_op    => Third_stage_enable,
			                            op_id_in  => Third_stage_request_id);

	-- 5 stage (output)
	-- 1 sumadores
	Adder_stage5 : FPU_adder port map(clk       => clk,
			                          opa       => Vector_aux3_stage4(0),
			                          opb       => Vector_aux1_stage4(1),
			                          output    => output,
			                          new_op    => Forth_stage_enable,
			                          op_id_in  => Forth_stage_request_id,
			                          op_ready  => new_operation_done,
			                          op_id_out => new_operation_done_id);

end architecture RTL;

