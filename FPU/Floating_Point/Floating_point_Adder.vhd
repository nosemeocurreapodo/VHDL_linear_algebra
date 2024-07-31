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

	-- stage 1
	signal opa_sign_1      : std_logic;
	signal opb_sign_1      : std_logic;
	signal opa_exponent_1  : unsigned(exponent_size - 1 downto 0);
	signal opb_exponent_1  : unsigned(exponent_size - 1 downto 0);
	signal opa_mantissa_1  : unsigned(mantissa_size - 1 downto 0);
	signal opb_mantissa_1  : unsigned(mantissa_size - 1 downto 0);

	signal request_id_1      : request_id;
	signal new_operation_1   : std_logic;

	-- stage 2
	signal opa_sign_2      : std_logic;
	signal opb_sign_2      : std_logic;
	signal opa_exponent_2  : unsigned(exponent_size - 1 downto 0);
	signal opb_exponent_2  : unsigned(exponent_size - 1 downto 0);
	signal opa_mantissa_2  : unsigned(mantissa_size - 1 downto 0);
	signal opb_mantissa_2  : unsigned(mantissa_size - 1 downto 0);

	signal request_id_2      : request_id;
	signal new_operation_2   : std_logic;

	-- stage 3
	signal opa_mantissa_3    : signed(mantissa_size + 2 downto 0);
	signal opb_mantissa_3    : signed(mantissa_size + 2 downto 0);
	signal exponent_3 : unsigned(exponent_size - 1 downto 0);

	signal exponent_diff_3 : unsigned(exponent_size - 1 downto 0);

	signal request_id_3      : request_id;
	signal new_operation_3   : std_logic;

	-- stage 4
	signal opa_mantissa_4    : signed(mantissa_size + 2 downto 0);
	signal opb_mantissa_4    : signed(mantissa_size + 2 downto 0);
	signal exponent_4 : unsigned(exponent_size - 1 downto 0);

	signal request_id_4      : request_id;
	signal new_operation_4   : std_logic;

	-- stage 5
	signal mantissa_5 : signed(mantissa_size + 2 downto 0);
	signal exponent_5 : unsigned(exponent_size - 1 downto 0);

	signal request_id_5      : request_id;
	signal new_operation_5   : std_logic;

	-- stage 6
	signal sign_6     : std_logic;
	signal exponent_6 : unsigned(exponent_size - 1 downto 0);
	signal mantissa_6 : unsigned(mantissa_size + 2 downto 0);

	signal request_id_6    : request_id;
	signal new_operation_6 : std_logic;

	-- stage 7
	signal sign_7     : std_logic;
	signal exponent_7 : unsigned(exponent_size - 1 downto 0);
	signal mantissa_7 : unsigned(mantissa_size - 1 downto 0);

	signal request_id_7    : request_id;
	signal new_operation_7 : std_logic;

begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			
			-- stage 1 input registers
			opa_sign_1 <= opa.sign;
			opb_sign_1 <= opb.sign;
			opa_exponent_1 <= opa.exponent;
			opb_exponent_1 <= opb.exponent;
			opa_mantissa_1 <= opa.mantissa;
			opb_mantissa_1 <= opb.mantissa;

			if (new_op = '1') then
				request_id_1    <= op_id_in;
				new_operation_1 <= '1';
			else
				request_id_1    <= request_id_zero;
				new_operation_1 <= '0';
			end if;

			-- stage 2 check bigger
			if (opa_exponent_1 >= opb_exponent_1) then
				opa_sign_2 <= opa_sign_1;
				opb_sign_2 <= opb_sign_1;
				opa_exponent_2 <= opa_exponent_1;
				opb_exponent_2 <= opb_exponent_1;
				opa_mantissa_2 <= opa_mantissa_1;
				opb_mantissa_2 <= opb_mantissa_1;
			else
				opa_sign_2 <= opb_sign_1;
				opb_sign_2 <= opa_sign_1;
				opa_exponent_2 <= opb_exponent_1;
				opb_exponent_2 <= opa_exponent_1;
				opa_mantissa_2 <= opb_mantissa_1;
				opb_mantissa_2 <= opa_mantissa_1;
			end if;

			request_id_2    <= request_id_1;
			new_operation_2 <= new_operation_1;

			-- stage 3
			-- de normalizo
			exponent_diff_3 <= opa_exponent_2 - opb_exponent_2;

			if (opa_sign_2 = '0') then -- de normalized number
				opa_mantissa_3 <= signed("001" & std_logic_vector(opa_mantissa_2));
			else
				opa_mantissa_3 <= -signed("001" & std_logic_vector(opa_mantissa_2));
			end if;

			if (opb_sign_2 = '0') then
				opb_mantissa_3 <= signed("001" & std_logic_vector(opb_mantissa_2));
			else
				opb_mantissa_3 <= -signed("001" & std_logic_vector(opb_mantissa_2));
			end if;

			exponent_3 <= opa_exponent_2;

			request_id_3    <= request_id_2;
			new_operation_3 <= new_operation_2;

			-- stage 4 shift_right
			opb_mantissa_4  <= shift_right(opb_mantissa_3, to_integer(exponent_diff_3));
			opa_mantissa_4  <= opa_mantissa_3;
			exponent_4      <= exponent_3;

			request_id_4    <= request_id_3;
			new_operation_4 <= new_operation_3;

			-- stage 5 suma
			mantissa_5 <= opa_mantissa_4 + opb_mantissa_4;
			exponent_5 <= exponent_4;

			request_id_5    <= request_id_4;
			new_operation_5 <= new_operation_4;

			-- stage 6 calculo el signo
			if (mantissa_5 >= 0) then
				sign_6 <= '0';
			else
				sign_6 <= '1';
			end if;

			mantissa_6 <= unsigned( abs (mantissa_5));
			exponent_6 <= exponent_5;

			request_id_6    <= request_id_5;
			new_operation_6 <= new_operation_5;

			-- stage 7
			sign_7          <= sign_6;
			request_id_7    <= request_id_6;
			new_operation_7 <= new_operation_6;

			-- the last bit length - 1 bit should be always 0, the length - 3 should be always 1 
			if(mantissa_6 = to_unsigned(0, mantissa_size + 2)) then
				exponent_7 <= to_unsigned(0, exponent_size);
				mantissa_7 <= to_unsigned(0, mantissa_size);
			elsif(mantissa_6(mantissa_6'length - 2 downto mantissa_6'length - 3) = "00") then
				exponent_7 <= exponent_6 - 1;
				mantissa_7 <= mantissa_6(mantissa_6'length - 5 downto 0) & '0';
			elsif(mantissa_6(mantissa_6'length - 2 downto mantissa_6'length - 3) = "01") then
				exponent_7 <= exponent_6;
				mantissa_7 <= mantissa_6(mantissa_6'length - 4 downto 0);
			--elsif(mantissa_6(mantissa_6'length - 2 downto mantissa_6'length - 3) = "11") then
			else
				exponent_7 <= exponent_6 + 1;
				mantissa_7 <= mantissa_6(mantissa_6'length - 3 downto 1);
			end if;

			-- stage output
			output.sign     <= sign_7;
			output.exponent <= exponent_7;
			output.mantissa <= mantissa_7;

			op_id_out <= request_id_7;
			op_ready  <= new_operation_7;
		end if;
	end process;
end architecture RTL;