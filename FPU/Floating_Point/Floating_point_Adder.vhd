library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Floating_point_definition.all;
use work.FPU_utility_functions.all;

entity Floating_point_Adder is
	generic(
		IN_SIZE           : integer := 32;
		IN_EXPONENT_SIZE  : integer := 8;
		IN_MANTISSA_SIZE  : integer := 23;
		OUT_SIZE          : integer := 32;
		OUT_EXPONENT_SIZE : integer := 8;
		OUT_MANTISSA_SIZE : integer := 23;
		AUX_SIZE          : integer := 32
	);
	port(
		clk       : in  std_logic;
		opa       : in  std_logic_vector(IN_SIZE - 1 downto 0);
		opb       : in  std_logic_vector(IN_SIZE - 1 downto 0);
		output    : out std_logic_vector(OUT_SIZE - 1 downto 0);
		new_op    : in  std_logic;
		op_ready  : out std_logic;
		aux_in  : in  std_logic_vector(AUX_SIZE - 1 downto 0);
		aux_out : out std_logic_vector(AUX_SIZE - 1 downto 0)
	);
end entity Floating_point_Adder;

architecture RTL of Floating_point_Adder is

	-- stage 1
	signal opa_sign_1      : std_logic;
	signal opb_sign_1      : std_logic;
	signal opa_exponent_1  : std_logic_vector(IN_EXPONENT_SIZE - 1 downto 0);
	signal opb_exponent_1  : std_logic_vector(IN_EXPONENT_SIZE - 1 downto 0);
	signal opa_mantissa_1  : std_logic_vector(IN_MANTISSA_SIZE - 1 downto 0);
	signal opb_mantissa_1  : std_logic_vector(IN_MANTISSA_SIZE - 1 downto 0);

	signal aux_1      : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_1   : std_logic;

	-- stage 2
	signal opa_sign_2      : std_logic;
	signal opb_sign_2      : std_logic;
	signal opa_exponent_2  : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal opb_exponent_2  : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal opa_mantissa_2  : unsigned(IN_MANTISSA_SIZE - 1 downto 0);
	signal opb_mantissa_2  : unsigned(IN_MANTISSA_SIZE - 1 downto 0);

	signal aux_2      : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_2   : std_logic;

	-- stage 3
	signal opa_mantissa_3    : signed(IN_MANTISSA_SIZE + 2 downto 0);
	signal opb_mantissa_3    : signed(IN_MANTISSA_SIZE + 2 downto 0);
	signal exponent_3 : unsigned(IN_EXPONENT_SIZE - 1 downto 0);

	signal exponent_diff_3 : unsigned(IN_EXPONENT_SIZE - 1 downto 0);

	signal aux_3      : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_3   : std_logic;

	-- stage 4
	signal opa_mantissa_4    : signed(IN_MANTISSA_SIZE + 2 downto 0);
	signal opb_mantissa_4    : signed(IN_MANTISSA_SIZE + 2 downto 0);
	signal exponent_4        : unsigned(IN_EXPONENT_SIZE - 1 downto 0);

	signal aux_4      : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_4   : std_logic;

	-- stage 5
	signal mantissa_5 : signed(IN_MANTISSA_SIZE + 2 downto 0);
	signal exponent_5 : unsigned(IN_EXPONENT_SIZE - 1 downto 0);

	signal aux_5      : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_5   : std_logic;

	-- stage 6
	signal sign_6     : std_logic;
	signal exponent_6 : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal mantissa_6 : unsigned(IN_MANTISSA_SIZE + 2 downto 0);

	signal aux_6    : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_6 : std_logic;

	-- stage 7
	signal sign_7     : std_logic;
	signal exponent_7 : unsigned(OUT_EXPONENT_SIZE - 1 downto 0);
	signal mantissa_7 : unsigned(OUT_MANTISSA_SIZE - 1 downto 0);

	signal aux_7    : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_7 : std_logic;

begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			
			-- stage 1 input registers
			opa_sign_1 <= get_sign(opa);
			opb_sign_1 <= get_sign(opb);
			opa_exponent_1 <= get_exponent(opa, IN_EXPONENT_SIZE);
			opb_exponent_1 <= get_exponent(opb, IN_EXPONENT_SIZE);
			opa_mantissa_1 <= get_mantissa(opa, IN_MANTISSA_SIZE);
			opb_mantissa_1 <= get_mantissa(opb, IN_MANTISSA_SIZE);
			aux_1    <= aux_in;
			new_operation_1 <= new_op;

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

			aux_2           <= aux_1;
			new_operation_2 <= new_operation_1;

			-- stage 3
			-- de normalizo
			exponent_diff_3 <= unsigned(opa_exponent_2) - unsigned(opb_exponent_2);

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

			aux_3           <= aux_2;
			new_operation_3 <= new_operation_2;

			-- stage 4 shift_right
			opb_mantissa_4  <= shift_right(opb_mantissa_3, to_integer(exponent_diff_3));
			opa_mantissa_4  <= opa_mantissa_3;
			exponent_4      <= exponent_3;

			aux_4           <= aux_3;
			new_operation_4 <= new_operation_3;

			-- stage 5 suma
			mantissa_5 <= opa_mantissa_4 + opb_mantissa_4;
			exponent_5 <= exponent_4;

			aux_5           <= aux_4;
			new_operation_5 <= new_operation_4;

			-- stage 6 calculo el signo
			if (mantissa_5 >= 0) then
				sign_6 <= '0';
			else
				sign_6 <= '1';
			end if;

			mantissa_6 <= unsigned( abs (mantissa_5));
			exponent_6 <= exponent_5;

			aux_6           <= aux_5;
			new_operation_6 <= new_operation_5;

			-- stage 7
			sign_7          <= sign_6;
			aux_7           <= aux_6;
			new_operation_7 <= new_operation_6;

			-- the last bit length - 1 bit should be always 0, the length - 3 should be always 1 
			if(mantissa_6 = to_unsigned(0, IN_MANTISSA_SIZE + 2)) then
				exponent_7 <= to_unsigned(0, OUT_EXPONENT_SIZE);
				mantissa_7 <= to_unsigned(0, OUT_MANTISSA_SIZE);
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
			output(OUT_SIZE - 1)     <= sign_7;
			output(OUT_SIZE - 2 downto OUT_SIZE - 2 - OUT_EXPONENT_SIZE) <= exponent_7;
			output(OUT_MANTISSA_SIZE - 1 downto 0) <= mantissa_7;

			aux_out  <= aux_7;
			op_ready <= new_operation_7;
		end if;
	end process;
end architecture RTL;