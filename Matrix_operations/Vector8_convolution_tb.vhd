library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.request_id_pack.all;
use work.FPU_definitions_pack.all;
use work.Matrix_definition_pack.all;
use work.Matrix_component_pack.all;

entity Vector8_convolution_tb is
end entity Vector8_convolution_tb;

architecture rtl of Vector8_convolution_tb is

	component Vector8_convolution_fast is
		port(
			clk                      : in  std_logic;
			new_operation_request    : in  std_logic;
			new_operation_done       : out std_logic;
			input                    : in  scalar;
			output                   : out scalar
		);
	end component Vector8_convolution_fast;

	signal clk : std_logic := '1';

	signal new_operation_request    : std_logic := '0';
	signal new_operation_done       : std_logic;
	signal scalar_input             : scalar := scalar_zero;
	signal scalar_output            : scalar;
	signal slv_input               : std_logic_vector(scalar_size - 1 downto 0);
	signal slv_output               : std_logic_vector(scalar_size - 1 downto 0);

	type state_type is (IDLE, FEEDING, BUSY, WAITING, READY);
	signal state : state_type := IDLE;

	signal counter : integer := 0;

begin
	Vector8_convolution_fast_instantiation : Vector8_convolution_fast port map(
			clk                      => clk,
			new_operation_request    => new_operation_request,
			new_operation_done       => new_operation_done,
			input                    => scalar_input,
			output                   => scalar_output);

	clk <= not (clk) after 5 ns;

	verify : process(clk)
		--random number generator
		variable seed1, seed2  : positive; -- seed values for random generator
		variable rand          : real;  -- random real-number value in range 0 to 1.0  
		variable range_of_rand : real := 10.0; -- the range of random values created will be 0 to +1000.
	begin
		if (rising_edge(clk)) then
		
			counter <= counter + 1;
		
			case state is
				when IDLE =>
					if (counter > 10) then
						state <= FEEDING;
						new_operation_request <= '1';
					end if;
				when FEEDING =>
					uniform(seed1, seed2, rand); -- generate random number
					scalar_input <= to_scalar(rand);
					
					if(counter > 30) then
					    state <= BUSY;
						new_operation_request <= '0';
					end if;
					
                when BUSY =>
                    if(new_operation_done = '1') then
						state <= WAITING;
					end if;
                
                when WAITING =>
                    if(new_operation_done = '0') then
						state <= READY;
					end if;
                
				when READY =>
					assert false
						report "processing done!!"
						severity failure;
			end case;

			slv_input <= scalar_to_std_logic_vector(scalar_input);	
			slv_output <= scalar_to_std_logic_vector(scalar_output);			

		end if;
	end process verify;
end rtl;