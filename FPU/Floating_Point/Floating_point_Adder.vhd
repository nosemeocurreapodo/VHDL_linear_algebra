library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Floating_point_definition.all;
use work.FPU_utility_functions.all;

entity Floating_point_Adder is
	port(
		clk       : in  std_logic;
		opa       : in  floating_point;
		opb       : in  floating_point;
		output    : out floating_point;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
		op_ready  : out std_logic
	);
end entity Floating_point_Adder;

architecture RTL of Floating_point_Adder is

	-- 1 stage
	signal opa_sign_1      : std_logic;
	signal opb_sign_1      : std_logic;
	signal opa_exponent_1  : unsigned(exponent_size - 1 downto 0);
	signal opb_exponent_1  : unsigned(exponent_size - 1 downto 0);
	signal opa_mantissa_1  : unsigned(mantissa_size + 2 downto 0);
	signal opb_mantissa_1  : unsigned(mantissa_size + 2 downto 0);
	signal exponent_diff_1 : signed(exponent_size downto 0);

	signal request_id_1      : request_id;
	signal new_operation_1   : std_logic;
	-- 2 stage
	signal opa_sign_2        : std_logic;
	signal opb_sign_2        : std_logic;
	signal opa_mantissa_2    : unsigned(mantissa_size + 2 downto 0);
	signal opb_mantissa_2    : unsigned(mantissa_size + 2 downto 0);
	signal output_exponent_2 : unsigned(exponent_size - 1 downto 0);

	signal request_id_2      : request_id;
	signal new_operation_2   : std_logic;
	-- 3 stage
	signal opa_sign_3        : std_logic;
	signal opb_sign_3        : std_logic;
	signal output_mantissa_3 : signed(mantissa_size + 2 downto 0);
	signal output_exponent_3 : unsigned(exponent_size - 1 downto 0);

	signal request_id_3      : request_id;
	signal new_operation_3   : std_logic;
	-- 4 stage
	signal output_sign_4     : std_logic;
	signal output_exponent_4 : unsigned(exponent_size - 1 downto 0);
	signal output_mantissa_4 : unsigned(mantissa_size + 2 downto 0);

	signal request_id_4    : request_id;
	signal new_operation_4 : std_logic;

	-- 5 stage
	signal output_sign_5     : std_logic;
	signal output_exponent_5 : unsigned(exponent_size - 1 downto 0);
	signal output_mantissa_5 : unsigned(mantissa_size + 2 downto 0);

	signal request_id_5    : request_id;
	signal new_operation_5 : std_logic;

begin
	process(clk)
		variable output_mantissa_4_lz : integer;
	begin
		if (rising_edge(clk)) then
			-- 1 stage
			if (new_op = '1') then
				-- dependiendo de los signos la operacion que se realiza (suma, resta)
				opa_sign_1 <= opa.sign;
				opb_sign_1 <= opb.sign;

				opa_exponent_1 <= opa.exponent;
				opb_exponent_1 <= opb.exponent;

				-- de normalizo
				if (opa.exponent = 0) then -- de normalized number
					opa_mantissa_1 <= unsigned("000" & std_logic_vector(opa.mantissa));
				else
					opa_mantissa_1 <= unsigned("001" & std_logic_vector(opa.mantissa));
				end if;
				if (opb.exponent = 0) then
					opb_mantissa_1 <= unsigned("000" & std_logic_vector(opb.mantissa));
				else
					opb_mantissa_1 <= unsigned("001" & std_logic_vector(opb.mantissa));
				end if;

				-- la differencia me da cual tengo que shift_right
				exponent_diff_1 <= signed('0' & std_logic_vector(opa.exponent)) - signed('0' & std_logic_vector(opb.exponent));

				request_id_1    <= op_id_in;
				new_operation_1 <= '1';
			else
				new_operation_1 <= '0';
			end if;

			-- 2 stage shift_right
			if (exponent_diff_1 >= 0) then
				opb_mantissa_2    <= shift_right(opb_mantissa_1, to_integer(abs (exponent_diff_1)));
				opa_mantissa_2    <= opa_mantissa_1;
				output_exponent_2 <= opa_exponent_1;
			else
				opa_mantissa_2    <= shift_right(opa_mantissa_1, to_integer(abs (exponent_diff_1)));
				opb_mantissa_2    <= opb_mantissa_1;
				output_exponent_2 <= opb_exponent_1;
			end if;

			opa_sign_2 <= opa_sign_1;
			opb_sign_2 <= opb_sign_1;

			request_id_2    <= request_id_1;
			new_operation_2 <= new_operation_1;

			-- 3 stage suma
			if (opa_sign_2 = '0' and opb_sign_2 = '0') then
				output_mantissa_3 <= signed(opa_mantissa_2) + signed(opb_mantissa_2);
			elsif (opa_sign_2 = '0' and opb_sign_2 = '1') then
				output_mantissa_3 <= signed(opa_mantissa_2) - signed(opb_mantissa_2);
			elsif (opa_sign_2 = '1' and opb_sign_2 = '0') then
				output_mantissa_3 <= signed(opb_mantissa_2) - signed(opa_mantissa_2);
			elsif (opa_sign_2 = '1' and opb_sign_2 = '1') then
				output_mantissa_3 <= -(signed(opb_mantissa_2) + signed(opa_mantissa_2));
			else                        --should not happen
				output_mantissa_3 <= signed(opa_mantissa_2) + signed(opb_mantissa_2);
			end if;
			opa_sign_3 <= opa_sign_2;
			opb_sign_3 <= opb_sign_2;

			output_exponent_3 <= output_exponent_2;

			request_id_3    <= request_id_2;
			new_operation_3 <= new_operation_2;

			-- 4 stage normalizo
			-- calculo el signo
			if (output_mantissa_3 = 0) then
				if (opa_sign_3 = '1' and opb_sign_3 = '1') then
					output_sign_4 <= '1';
				else
					output_sign_4 <= '0';
				end if;
			elsif (output_mantissa_3 > 0) then
				output_sign_4 <= '0';
			else
				output_sign_4 <= '1';
			end if;

			output_mantissa_4 <= unsigned(abs (output_mantissa_3));
			output_exponent_4 <= output_exponent_3;

			request_id_4    <= request_id_3;
			new_operation_4 <= new_operation_3;

			-- 5 sigo normalizando
			output_sign_5        <= output_sign_4;
			output_mantissa_4_lz := count_l_zeros(output_mantissa_4);
			output_mantissa_5    <= shift_left(output_mantissa_4, output_mantissa_4_lz + 1);
			if (output_exponent_4 = 0) then
				output_exponent_5 <= output_exponent_4 - output_mantissa_4_lz;
			else
				output_exponent_5 <= output_exponent_4 - output_mantissa_4_lz + 2;
			end if;

			request_id_5    <= request_id_4;
			new_operation_5 <= new_operation_4;

			-- stage 6 salida!
			output.sign     <= output_sign_5;
			output.exponent <= output_exponent_5;
			output.mantissa <= output_mantissa_5(mantissa_size + 2 downto 3);

			op_id_out <= request_id_5;
			op_ready  <= new_operation_5;
		end if;
	end process;
end architecture RTL;