library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Fixed_point_Adder is
	-- OUT_SIZE can be either IN_SIZE or IN_SIZE+1
	generic (
		IN_SIZE	 : integer := 32;
		OUT_SIZE : integer := 32;
		AUX_SIZE : integer := 32
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
end entity Fixed_point_Adder;

architecture RTL of Fixed_point_Adder is
	signal opa_1    : std_logic_vector(IN_SIZE - 1 downto 0);
	signal opb_1    : std_logic_vector(IN_SIZE - 1 downto 0);
	signal aux_1    : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_op_1 : std_logic;

	signal out_2    : std_logic_vector(IN_SIZE downto 0);
	signal aux_2    : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_op_2 : std_logic;

begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			-- stage 1 -- latch input
			opa_1    <= opa;
			opb_1    <= opb;
			aux_1    <= aux_in;
			-- seems to be important, otherwise we propagate undifined states during simulation
			if(new_op = '1') then
				new_op_1 <= '1';
			else
				new_op_1 <= '0';
			end if;

			-- stage 2 -- do adition
			out_2    <= std_logic_vector(signed(opa_1(IN_SIZE -1) & opa_1) + signed(opb_1));
			aux_2    <= aux_1;
			new_op_2 <= new_op_1;

			-- stage 3 output
			output   <= out_2(OUT_SIZE - 1 downto 0);
			aux_out  <= aux_2;
			op_ready <= new_op_2;
		end if;
	end process;
end architecture RTL;
