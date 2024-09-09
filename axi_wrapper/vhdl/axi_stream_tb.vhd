library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.request_id_pack.all;
use work.FPU_definitions_pack.all;
use work.Matrix_definition_pack.all;
use work.Matrix_component_pack.all;

entity axi_stream_tb is
end entity axi_stream_tb;

architecture rtl of axi_stream_tb is

	component SCALAR_M_AXIS is
		generic (
			-- Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
			C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
			-- Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
			SCALAR_FIFO_DEPTH	: integer	:= 32
		);
		port (
			data_in_ok  : in std_logic;
			data_in     : in std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
			-- Global ports
			M_AXIS_ACLK	: in std_logic;
			-- 
			M_AXIS_ARESETN	: in std_logic;
			-- Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
			M_AXIS_TVALID	: out std_logic;
			-- TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
			M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
			-- TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
			M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
			-- TLAST indicates the boundary of a packet.
			M_AXIS_TLAST	: out std_logic;
			-- TREADY indicates that the slave can accept a transfer in the current cycle.
			M_AXIS_TREADY	: in std_logic
		);
	end component SCALAR_M_AXIS;

	component SCALAR_S_AXIS is
		generic (
			-- Users to add parameters here
	
			-- User parameters ends
			-- Do not modify the parameters beyond this line
	
			-- AXI4Stream sink: Data Width
			C_S_AXIS_TDATA_WIDTH	: integer	:= 32
		);
		port (
			-- Users to add ports here
	
			data_out_ok : out std_logic;
			data_out    : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	
			-- User ports ends
			-- Do not modify the ports beyond this line
	
			-- AXI4Stream sink: Clock
			S_AXIS_ACLK	: in std_logic;
			-- AXI4Stream sink: Reset
			S_AXIS_ARESETN	: in std_logic;
			-- Ready to accept data in
			S_AXIS_TREADY	: out std_logic;
			-- Data in
			S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
			-- Byte qualifier
			S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
			-- Indicates boundary of last packet
			S_AXIS_TLAST	: in std_logic;
			-- Data is in valid
			S_AXIS_TVALID	: in std_logic
		);
	end component SCALAR_S_AXIS;

--	component axi_conv8_vhdl_wrapper is
--		generic (
--			-- Users to add parameters here
	
--			DISP_FILTER_WIDTH	: integer	:= 16;
	
--			-- User parameters ends
--			-- Do not modify the parameters beyond this line
	
	
--			-- Parameters of Axi Slave Bus Interface S00_AXI
--			C_S00_AXI_DATA_WIDTH	: integer	:= 32;
--			C_S00_AXI_ADDR_WIDTH	: integer	:= 4;
	
--			-- Parameters of Axi Slave Bus Interface S00_AXIS
--			C_S00_AXIS_TDATA_WIDTH	: integer	:= 32;
	
--			-- Parameters of Axi Master Bus Interface M00_AXIS
--			C_M00_AXIS_TDATA_WIDTH	: integer	:= 32;
--			C_M00_AXIS_START_COUNT	: integer	:= 32
--		);
--		port (
--			-- Users to add ports here
	
--			-- User ports ends
--			-- Do not modify the ports beyond this line
		
--			-- Ports of Axi Slave Bus Interface S00_AXIS
--			s00_axis_aclk	: in std_logic;
--			s00_axis_aresetn	: in std_logic;
--			s00_axis_tready	: out std_logic;
--			s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
--			s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
--			s00_axis_tlast	: in std_logic;
--			s00_axis_tvalid	: in std_logic;
	
--			-- Ports of Axi Master Bus Interface M00_AXIS
--			m00_axis_aclk	: in std_logic;
--			m00_axis_aresetn	: in std_logic;
--			m00_axis_tvalid	: out std_logic;
--			m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
--			m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
--			m00_axis_tlast	: out std_logic;
--			m00_axis_tready	: in std_logic
--		);
--	end component axi_conv8_vhdl_wrapper;

	signal clk : std_logic := '1';
	signal rst : std_logic := '0';

	signal new_operation_request    : std_logic := '0';
	signal new_operation_done       : std_logic := '0';
	signal scalar_input             : std_logic_vector(scalar_size - 1 downto 0) := std_logic_vector(to_unsigned(0, scalar_size));
	signal scalar_output            : std_logic_vector(scalar_size - 1 downto 0);
	signal scalar_vector_len        : unsigned(31 downto 0) := to_unsigned(64, 32);

	type state_type is (IDLE, FEEDING, BUSY, WAITING, READY);
	signal state : state_type := IDLE;

	signal counter : integer := 0;
	
	constant AXIS_TDATA_WIDTH : integer := 32;

	signal AXIS_TVALID  : std_logic;
	signal AXIS_TDATA   : std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
	signal AXIS_TSTRB   : std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal AXIS_TLAST   : std_logic;
	signal AXIS_TREADY  : std_logic;


begin

	SCALAR_M_AXIS_tb_instantiation : SCALAR_M_AXIS 
	    generic map(
	       C_M_AXIS_TDATA_WIDTH => AXIS_TDATA_WIDTH,
	       SCALAR_FIFO_DEPTH => 32)
		port map (
			data_in_ok  => new_operation_request,
			data_in     => scalar_input,
	
			M_AXIS_ACLK	    => clk,
			M_AXIS_ARESETN	=> rst,
			M_AXIS_TVALID	=> AXIS_TVALID,
			M_AXIS_TDATA	=> AXIS_TDATA,
			M_AXIS_TSTRB	=> AXIS_TSTRB,
			M_AXIS_TLAST	=> AXIS_TLAST,
			M_AXIS_TREADY	=> AXIS_TREADY
		);
		
	SCALAR_S_AXIS_tb_instantiation : SCALAR_S_AXIS 
	generic map(
	   C_S_AXIS_TDATA_WIDTH => AXIS_TDATA_WIDTH)
	port map (
		data_out_ok => new_operation_done,
		data_out    => scalar_output,

		S_AXIS_ACLK    	=> clk,
		S_AXIS_ARESETN	=> rst,
		S_AXIS_TREADY	=> AXIS_TREADY,
		S_AXIS_TDATA	=> AXIS_TDATA,
		S_AXIS_TSTRB	=> AXIS_TSTRB,
		S_AXIS_TLAST	=> AXIS_TLAST,
		S_AXIS_TVALID	=> AXIS_TVALID
	);

    --	axi_conv8_vhdl_wrapper_instantiation: axi_conv8_vhdl_wrapper port map(
    --
	--		s00_axis_aclk	: in std_logic;
	--		s00_axis_aresetn	: in std_logic;
	--		s00_axis_tready	: out std_logic;
	--		s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
	--		s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
	--		s00_axis_tlast	: in std_logic;
	--		s00_axis_tvalid	: in std_logic;
	--
	--		m00_axis_aclk	: in std_logic;
	--		m00_axis_aresetn	: in std_logic;
	--		m00_axis_tvalid	: out std_logic;
	--		m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
	--		m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
	--		m00_axis_tlast	: out std_logic;
	--		m00_axis_tready	: in std_logic
	--	);

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
					if (counter > 10) then
						state <= FEEDING;
						new_operation_request <= '0';
						scalar_input <= scalar_to_std_logic_vector(to_scalar(0));
					end if;
				when FEEDING =>
					uniform(seed1, seed2, rand); -- generate random number
					scalar_input <= scalar_to_std_logic_vector(to_scalar(rand));
					new_operation_request <= '1';
					if(counter > scalar_vector_len) then
					    state <= BUSY;
					end if;
					
                when BUSY =>
					new_operation_request <= '0';
					scalar_input <= scalar_to_std_logic_vector(to_scalar(0));
                    if(new_operation_done = '1') then
						state <= WAITING;
					end if;
                
                when WAITING =>
					new_operation_request <= '0';
					scalar_input <= scalar_to_std_logic_vector(to_scalar(0));
					if(new_operation_done = '0') then
						state <= READY;
					end if;
                
				when READY =>
					assert false
						report "processing done!!"
						severity failure;
			end case;
		end if;
	end process verify;
end rtl;