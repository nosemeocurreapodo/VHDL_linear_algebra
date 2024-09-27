library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.request_id_pack.all;
use work.FPU_definitions_pack.all;
use work.Matrix_definition_pack.all;
use work.Matrix_component_pack.all;

entity dwt_db4_vhdl_tb is
end entity dwt_db4_vhdl_tb;

architecture rtl of dwt_db4_vhdl_tb is

	component SCALAR_M_AXIS is
		generic (
			C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
			SCALAR_FIFO_DEPTH	: integer	:= 32
		);
		port (
			data_in_ok  : in std_logic;
			data_in     : in std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);

			M_AXIS_ACLK	: in std_logic;
			M_AXIS_ARESETN	: in std_logic;
			M_AXIS_TVALID	: out std_logic;
			M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
			M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
			M_AXIS_TKEEP	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
			M_AXIS_TLAST	: out std_logic;
			M_AXIS_TREADY	: in std_logic
		);
	end component SCALAR_M_AXIS;

	component SCALAR_S_AXIS is
		generic (
			C_S_AXIS_TDATA_WIDTH	: integer	:= 32
		);
		port (
			data_out_ok   : out std_logic;
			data_out      : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
			data_out_last : out std_logic;

			S_AXIS_ACLK	: in std_logic;
			S_AXIS_ARESETN	: in std_logic;
			S_AXIS_TREADY	: out std_logic;
			S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
			S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
			S_AXIS_TLAST	: in std_logic;
			S_AXIS_TVALID	: in std_logic
		);
	end component SCALAR_S_AXIS;

	component dwt_db4_vhdl is
		generic (
			SHIFT_REG_LEN	: integer	:= 16;
			C_S00_AXIS_TDATA_WIDTH	: integer	:= 32;
			C_M00_AXIS_TDATA_WIDTH	: integer	:= 32
		);
		port (
	
			-- Ports of Axi Slave Bus Interface S00_AXIS
			s_axis_aclk  	: in std_logic;
			s_axis_aresetn	: in std_logic;
			s_axis_tready	: out std_logic;
			s_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
			s_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
			s_axis_tlast	: in std_logic;
			s_axis_tvalid	: in std_logic;
	
			-- Ports of Axi Master Bus Interface M00_AXIS
			hi_m_axis_aclk	    : in std_logic;
			hi_m_axis_aresetn	: in std_logic;
			hi_m_axis_tvalid	: out std_logic;
			hi_m_axis_tdata  	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
			hi_m_axis_tstrb 	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
			hi_m_axis_tkeep 	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
			hi_m_axis_tlast	    : out std_logic;
			hi_m_axis_tready	: in std_logic;
	
			-- Ports of Axi Master Bus Interface M00_AXIS
			lo_m_axis_aclk  	: in std_logic;
			lo_m_axis_aresetn	: in std_logic;
			lo_m_axis_tvalid	: out std_logic;
			lo_m_axis_tdata	    : out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
			lo_m_axis_tstrb 	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
			lo_m_axis_tkeep 	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
			lo_m_axis_tlast 	: out std_logic;
			lo_m_axis_tready	: in std_logic
	
		);
	end component dwt_db4_vhdl;

	signal clk : std_logic := '1';
	signal rst : std_logic := '0';

	signal scalar_input        : std_logic_vector(scalar_size - 1 downto 0) := std_logic_vector(to_unsigned(0, scalar_size));
	signal scalar_input_ok     : std_logic := '0';

	signal hi_data             : std_logic_vector(scalar_size - 1 downto 0) := std_logic_vector(to_unsigned(0, scalar_size));
	signal hi_data_ok          : std_logic := '0';
	signal hi_data_last        : std_logic := '0';
	signal lo_data             : std_logic_vector(scalar_size - 1 downto 0) := std_logic_vector(to_unsigned(0, scalar_size));
	signal lo_data_ok          : std_logic := '0';
	signal lo_data_last        : std_logic := '0';
	  
	type state_type is (IDLE, FEEDING, BUSY, WAITING, READY);
	signal state : state_type := IDLE;

	signal counter : integer := 0;
	
	constant scalar_vector_len : integer := 5121;
	constant reset_len         : integer := 32;  
	constant AXIS_TDATA_WIDTH : integer := 32;

	signal S_AXIS_TVALID  : std_logic;
	signal S_AXIS_TDATA   : std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
	signal S_AXIS_TSTRB   : std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal S_AXIS_TKEEP   : std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0) := "1111";
	signal S_AXIS_TLAST   : std_logic;
	signal S_AXIS_TREADY  : std_logic;

	signal lo_AXIS_TVALID  : std_logic;
	signal lo_AXIS_TDATA   : std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
	signal lo_AXIS_TSTRB   : std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal lo_AXIS_TKEEP   : std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal lo_AXIS_TLAST   : std_logic;
	signal lo_AXIS_TREADY  : std_logic;

	signal hi_AXIS_TVALID  : std_logic;
	signal hi_AXIS_TDATA   : std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
	signal hi_AXIS_TSTRB   : std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal hi_AXIS_TKEEP   : std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal hi_AXIS_TLAST   : std_logic;
	signal hi_AXIS_TREADY  : std_logic;

begin

	SCALAR_M_AXIS_tb_instantiation : SCALAR_M_AXIS 
	    generic map(
	       C_M_AXIS_TDATA_WIDTH => AXIS_TDATA_WIDTH,
	       SCALAR_FIFO_DEPTH => 32)
		port map (
			data_in_ok  => scalar_input_ok,
			data_in     => scalar_input,
	
			M_AXIS_ACLK	    => clk,
			M_AXIS_ARESETN	=> rst,
			M_AXIS_TVALID	=> S_AXIS_TVALID,
			M_AXIS_TDATA	=> S_AXIS_TDATA,
			M_AXIS_TSTRB	=> S_AXIS_TSTRB,
			M_AXIS_TKEEP	=> S_AXIS_TKEEP,
			M_AXIS_TLAST	=> S_AXIS_TLAST,
			M_AXIS_TREADY	=> S_AXIS_TREADY
		);
		
	SCALAR_hi_S_AXIS_tb_instantiation : SCALAR_S_AXIS 
	generic map(
	   C_S_AXIS_TDATA_WIDTH => AXIS_TDATA_WIDTH)
	port map (
		data_out_ok   => hi_data_ok,
		data_out      => hi_data,
		data_out_last => hi_data_last, 

		S_AXIS_ACLK    	=> clk,
		S_AXIS_ARESETN	=> rst,
		S_AXIS_TREADY	=> hi_AXIS_TREADY,
		S_AXIS_TDATA	=> hi_AXIS_TDATA,
		S_AXIS_TSTRB	=> hi_AXIS_TSTRB,
		S_AXIS_TLAST	=> hi_AXIS_TLAST,
		S_AXIS_TVALID	=> hi_AXIS_TVALID
	);

	SCALAR_lo_S_AXIS_tb_instantiation : SCALAR_S_AXIS 
	generic map(
	   C_S_AXIS_TDATA_WIDTH => AXIS_TDATA_WIDTH)
	port map (
		data_out_ok   => lo_data_ok,
		data_out      => lo_data,
		data_out_last => lo_data_last,

		S_AXIS_ACLK    	=> clk,
		S_AXIS_ARESETN	=> rst,
		S_AXIS_TREADY	=> lo_AXIS_TREADY,
		S_AXIS_TDATA	=> lo_AXIS_TDATA,
		S_AXIS_TSTRB	=> lo_AXIS_TSTRB,
		S_AXIS_TLAST	=> lo_AXIS_TLAST,
		S_AXIS_TVALID	=> lo_AXIS_TVALID
	);

	dwt_db4_vhdl_instantiation : dwt_db4_vhdl
		generic map(
			SHIFT_REG_LEN          => 16,
			C_S00_AXIS_TDATA_WIDTH => AXIS_TDATA_WIDTH,
			C_M00_AXIS_TDATA_WIDTH => AXIS_TDATA_WIDTH
		)
		port map (
			-- Ports of Axi Slave Bus Interface S00_AXIS
			s_axis_aclk  	=> clk,
			s_axis_aresetn	=> rst,
			s_axis_tready	=> S_AXIS_TREADY,
			s_axis_tdata	=> S_AXIS_TDATA,
			s_axis_tstrb	=> S_AXIS_TSTRB,
			s_axis_tlast	=> S_AXIS_TLAST,
			s_axis_tvalid	=> S_AXIS_TVALID,
	
			-- Ports of Axi Master Bus Interface M00_AXIS
			hi_m_axis_aclk	    => clk,
			hi_m_axis_aresetn	=> rst,
			hi_m_axis_tvalid	=> hi_AXIS_TVALID,
			hi_m_axis_tdata  	=> hi_AXIS_TDATA,
			hi_m_axis_tstrb 	=> hi_AXIS_TSTRB,
			hi_m_axis_tkeep     => hi_AXIS_TKEEP,
			hi_m_axis_tlast	    => hi_AXIS_TLAST,
			hi_m_axis_tready	=> hi_AXIS_TREADY,
	
			-- Ports of Axi Master Bus Interface M00_AXIS
			lo_m_axis_aclk  	=> clk,
			lo_m_axis_aresetn	=> rst,
			lo_m_axis_tvalid	=> lo_AXIS_TVALID,
			lo_m_axis_tdata	    => lo_AXIS_TDATA,
			lo_m_axis_tstrb 	=> lo_AXIS_TSTRB,
			lo_m_axis_tkeep 	=> lo_AXIS_TKEEP,
			lo_m_axis_tlast 	=> lo_AXIS_TLAST,
			lo_m_axis_tready	=> lo_AXIS_TREADY
		);


	clk <= not (clk) after 5 ns;
    rst <= '0', '1' after 15 ns;


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
					if (counter = reset_len-1) then
						state <= FEEDING;
						scalar_input_ok <= '0';
						scalar_input <= scalar_to_std_logic_vector(to_scalar(0));
					end if;
				when FEEDING =>
					--uniform(seed1, seed2, rand); -- generate random number
					rand := real(counter - reset_len);
					scalar_input <= scalar_to_std_logic_vector(to_scalar(rand));
					scalar_input_ok <= '1';
					if(counter = scalar_vector_len + reset_len - 1) then
					    state <= BUSY;
					end if;
					
                when BUSY =>
					scalar_input_ok <= '0';
					scalar_input <= scalar_to_std_logic_vector(to_scalar(0));
                    if(counter = scalar_vector_len*2) then
						state <= WAITING;
					end if;
                
                when WAITING =>
					scalar_input_ok <= '0';
					scalar_input <= scalar_to_std_logic_vector(to_scalar(0));
					state <= READY;

				when READY =>
					assert false
						report "processing done!!"
						severity failure;
			end case;
		end if;
	end process verify;
end rtl;