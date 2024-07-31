library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Fixed_point_definition.all;
use work.Synthesis_definitions_pack.all;

entity Fixed_point_Multiplier is
	port(
		clk       : in  std_logic;
		opa       : in  fixed_point;
		opb       : in  fixed_point;
		output    : out fixed_point;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
		op_ready  : out std_logic
	);
end entity Fixed_point_Multiplier;

architecture RTL of Fixed_point_Multiplier is

	-- stage 1
	signal request_1 : std_logic;
	signal request_id_1 : request_id;

	signal opa_1 : signed(fixed_point_size - 1 downto 0);
	signal opb_1 : signed(fixed_point_size - 1 downto 0);

	-- multiplication pipeline stages (this is required for infering pipeline in the dsps)
	-- 4 stages are required for 32 bit (20 bit fraction) fixed point
	constant num_pipe_stages : integer := 4;
	type signed_array is array (num_pipe_stages - 1 downto 0) of signed(fixed_point_size*2 - 1 downto 0);

	signal pipe_request    : std_logic_vector(num_pipe_stages - 1 downto 0);
	signal pipe_request_id : request_id_array(num_pipe_stages - 1 downto 0);
	signal pipe_output     : signed_array;
	
	-- output stage
	signal request_o : std_logic;
	signal request_id_o : request_id;
	
	signal output_o : signed(fixed_point_size * 2 - 1 downto 0);

begin
	process(clk)

	begin
		if (rising_edge(clk)) then
			
			-- stage 1
			opa_1 <= opa;
			opb_1 <= opb;

			if (new_op = '1') then
				request_id_1 <= op_id_in;
				request_1    <= '1';
			else
				request_id_1 <= request_id_zero;
				request_1    <= '0';
			end if;

			-- mult pipeline stages
			pipe_request(0)    <= request_1;
			pipe_request_id(0) <= request_id_1;
			pipe_output(0)     <= opa_1 * opb_1;

			for I in num_pipe_stages - 1 downto 1 loop
				pipe_request(I)    <= pipe_request(I - 1);
				pipe_request_id(I) <= pipe_request_id(I - 1);
				pipe_output(I)     <= pipe_output(I - 1);
			end loop;

			-- output stage 
			op_ready <= pipe_request(num_pipe_stages - 1);
			op_id_out <= pipe_request_id(num_pipe_stages - 1);

			output <= pipe_output(num_pipe_stages - 1)(fixed_point_size + fraction_size - 1 downto fraction_size);

		end if;
	end process;
end architecture RTL;

--architecture RTL of Fixed_point_Multiplier is

--	-- stage 1
--	signal new_request_1     : std_logic;
--	signal request_id_1      : request_id;

--	signal output_sign_1     : std_logic;
--	signal operator_a_up_1   : unsigned(maximum_multiplier_width - 1 downto 0);
--	signal operator_a_down_1 : unsigned(maximum_multiplier_width - 1 downto 0);
--	signal operator_b_up_1   : unsigned(maximum_multiplier_width - 1 downto 0);
--	signal operator_b_down_1 : unsigned(maximum_multiplier_width - 1 downto 0);

--	-- stage 2
--	signal new_request_2   : std_logic;
--	signal request_id_2    : request_id;

--	signal output_sign_2   : std_logic;
--	signal a_downXb_down_2 : unsigned(maximum_multiplier_width * 2 - 1 downto 0);
--	signal a_upXb_down_2   : unsigned(maximum_multiplier_width * 2 - 1 downto 0);
--	signal a_downXb_up_2   : unsigned(maximum_multiplier_width * 2 - 1 downto 0);
--	signal a_upXb_up_2     : unsigned(maximum_multiplier_width * 2 - 1 downto 0);

--	-- multiplication pipeline stages (this is required for infering pipeline in the dsps)
--	constant num_pipe_stages : integer := 15;
--	type unsigned_array is array (num_pipe_stages - 1 downto 0) of unsigned(maximum_multiplier_width * 2 - 1 downto 0);

--	signal pipe_new_request    : std_logic_vector(num_pipe_stages - 1 downto 0);
--	signal pipe_new_request_id : request_id_array(num_pipe_stages - 1 downto 0);
--	signal pipe_a_downXb_down  : unsigned_array;
--	signal pipe_a_upXb_down    : unsigned_array;
--	signal pipe_a_downXb_up    : unsigned_array;
--	signal pipe_a_upXb_up      : unsigned_array;

--	-- stage 3
--	signal new_request_3 : std_logic;
--	signal request_id_3  : request_id;

--	signal output_sign_3 : std_logic;
--	signal sum1_3 : unsigned(maximum_multiplier_width * 4 - 1 downto 0);
--	signal sum2_3 : unsigned(maximum_multiplier_width * 4 - 1 downto 0);

--	-- stage 4
--	signal new_request_4 : std_logic;
--	signal request_id_4  : request_id;

--	signal output_sign_4 : std_logic;
--	signal sum_4 : unsigned(maximum_multiplier_width * 4 - 1 downto 0);

--begin
--	process(clk)
--		variable opa_abs : unsigned(fixed_point_size - 1 downto 0);
--		variable opb_abs : unsigned(fixed_point_size - 1 downto 0);
--	begin
--		if (rising_edge(clk)) then
--			-- 1 stage
--			if (new_op = '1') then
--				if (opa >= 0 and opb >= 0) then
--					output_sign_1 <= '0';
--				elsif (opa >= 0 and opb < 0) then
--					output_sign_1 <= '1';
--				elsif (opa < 0 and opb >= 0) then
--					output_sign_1 <= '1';
--				else
--					output_sign_1 <= '0';
--				end if;

--				opa_abs := unsigned(abs (opa));
--				opb_abs := unsigned(abs (opb));

--				operator_a_up_1   <= unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width - fixed_point_size + maximum_multiplier_width)) & std_logic_vector(opa_abs(fixed_point_size - 1 downto maximum_multiplier_width)));
--				operator_a_down_1 <= opa_abs(maximum_multiplier_width - 1 downto 0);
--				operator_b_up_1   <= unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width - fixed_point_size + maximum_multiplier_width)) & std_logic_vector(opb_abs(fixed_point_size - 1 downto maximum_multiplier_width)));
--				operator_b_down_1 <= opb_abs(maximum_multiplier_width - 1 downto 0);

--				request_id_1 <= op_id_in;
--				new_request_1 <= '1';
--			else
--				request_id_1 <= request_id_zero;
--				new_request_1 <= '0';
--			end if;

--			-- 2 stage
--			new_request_2 <= new_request_1;
--			request_id_2  <= request_id_1;

--			output_sign_2 <= output_sign_1;

--			a_downXb_down_2 <= operator_a_down_1 * operator_b_down_1;
--			a_upXb_down_2   <= operator_a_up_1 * operator_b_down_1;
--			a_downXb_up_2   <= operator_a_down_1 * operator_b_up_1;
--			a_upXb_up_2     <= operator_a_up_1 * operator_b_up_1;

--			-- multiplication pipeline stages
--			pipe_new_request(0)    <= new_request_2;
--			pipe_new_request_id(0) <= request_id_2;
--			pipe_a_downXb_down(0)  <= a_downXb_down_2;
--			pipe_a_upXb_down(0)    <= a_upXb_down_2;
--			pipe_a_downXb_up(0)    <= a_downXb_up_2;
--			pipe_a_upXb_up(0)      <= a_upXb_up_2;

--			for I in num_pipe_stages - 1 downto 1 loop
--				pipe_new_request(I)    <= pipe_new_request(I - 1);
--				pipe_new_request_id(I) <= pipe_new_request_id(I - 1);
--				pipe_a_downXb_down(I)  <= pipe_a_downXb_down(I - 1);
--				pipe_a_upXb_down(I)    <= pipe_a_upXb_down(I - 1);
--				pipe_a_downXb_up(I)    <= pipe_a_downXb_up(I - 1);
--				pipe_a_upXb_up(I)      <= pipe_a_upXb_up(I - 1);
--			end loop;

--			-- 3 stage
--			new_request_3 <= pipe_new_request(num_pipe_stages - 1);
--			request_id_3  <= pipe_new_request_id(num_pipe_stages - 1);

--			output_sign_3 <= output_sign_2;
--			sum1_3        <= unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width)) & std_logic_vector(pipe_a_upXb_down(num_pipe_stages - 1)) & std_logic_vector(to_unsigned(0, maximum_multiplier_width))) + unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width * 2)) & std_logic_vector(pipe_a_downXb_down(num_pipe_stages - 1)));
--			sum2_3        <= unsigned(std_logic_vector(pipe_a_upXb_up(num_pipe_stages - 1)) & std_logic_vector(to_unsigned(0, maximum_multiplier_width * 2))) + unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width)) & std_logic_vector(pipe_a_downXb_up(num_pipe_stages - 1)) & std_logic_vector(to_unsigned(0, maximum_multiplier_width)));

--			-- 4 stage
--			new_request_4 <= new_request_3;
--			request_id_4  <= request_id_3;

--			output_sign_4 <= output_sign_3;
--			sum_4         <= sum1_3 + sum2_3;

--			-- output
--			if (output_sign_4 = '0') then
--				output <= signed(sum_4(fixed_point_size + fraction_size - 1 downto fraction_size));
--			else
--				output <= -signed(sum_4(fixed_point_size + fraction_size - 1 downto fraction_size));
--			end if;

--			op_id_out <= request_id_4;
--			op_ready  <= new_request_4;

--		end if;
--	end process;
--end architecture RTL;
