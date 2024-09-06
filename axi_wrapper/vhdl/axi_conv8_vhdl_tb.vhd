library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.request_id_pack.all;
use work.FPU_definitions_pack.all;
use work.Matrix_definition_pack.all;
use work.Matrix_component_pack.all;

entity axi_conv8_vhdl_tb is
end entity axi_conv8_vhdl_tb;

architecture rtl of axi_conv8_vhdl_tb is

	component Vector8_convolution_fast is
		port(
			clk                      : in  std_logic;
			new_operation_request    : in  std_logic;
			new_operation_done       : out std_logic;
			input                    : in  std_logic_vector(scalar_size - 1 downto 0);
			output                   : out std_logic_vector(scalar_size - 1 downto 0)
		);
	end component Vector8_convolution_fast;

	component axi_conv8_vhdl_wrapper is
		generic (
			-- Users to add parameters here
	
			DISP_FILTER_WIDTH	: integer	:= 16;
	
			-- User parameters ends
			-- Do not modify the parameters beyond this line
	
	
			-- Parameters of Axi Slave Bus Interface S00_AXI
			C_S00_AXI_DATA_WIDTH	: integer	:= 32;
			C_S00_AXI_ADDR_WIDTH	: integer	:= 4;
	
			-- Parameters of Axi Slave Bus Interface S00_AXIS
			C_S00_AXIS_TDATA_WIDTH	: integer	:= 32;
	
			-- Parameters of Axi Master Bus Interface M00_AXIS
			C_M00_AXIS_TDATA_WIDTH	: integer	:= 32;
			C_M00_AXIS_START_COUNT	: integer	:= 32
		);
		port (
			-- Users to add ports here
	
			-- User ports ends
			-- Do not modify the ports beyond this line
	
	
			-- Ports of Axi Slave Bus Interface S00_AXI
			s00_axi_aclk	: in std_logic;
			s00_axi_aresetn	: in std_logic;
			s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
			s00_axi_awprot	: in std_logic_vector(2 downto 0);
			s00_axi_awvalid	: in std_logic;
			s00_axi_awready	: out std_logic;
			s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
			s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
			s00_axi_wvalid	: in std_logic;
			s00_axi_wready	: out std_logic;
			s00_axi_bresp	: out std_logic_vector(1 downto 0);
			s00_axi_bvalid	: out std_logic;
			s00_axi_bready	: in std_logic;
			s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
			s00_axi_arprot	: in std_logic_vector(2 downto 0);
			s00_axi_arvalid	: in std_logic;
			s00_axi_arready	: out std_logic;
			s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
			s00_axi_rresp	: out std_logic_vector(1 downto 0);
			s00_axi_rvalid	: out std_logic;
			s00_axi_rready	: in std_logic;
	
			-- Ports of Axi Slave Bus Interface S00_AXIS
			s00_axis_aclk	: in std_logic;
			s00_axis_aresetn	: in std_logic;
			s00_axis_tready	: out std_logic;
			s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
			s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
			s00_axis_tlast	: in std_logic;
			s00_axis_tvalid	: in std_logic;
	
			-- Ports of Axi Master Bus Interface M00_AXIS
			m00_axis_aclk	: in std_logic;
			m00_axis_aresetn	: in std_logic;
			m00_axis_tvalid	: out std_logic;
			m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
			m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
			m00_axis_tlast	: out std_logic;
			m00_axis_tready	: in std_logic
		);
	end component axi_conv8_vhdl_wrapper;

	signal clk : std_logic := '1';
	signal rst : std_logic := '0';

	signal new_operation_request    : std_logic := '0';
	signal new_operation_done       : std_logic;
	signal scalar_input             : std_logic_vector(scalar_size - 1 downto 0) := std_logic_vector(to_unsigned(0, scalar_size));
	signal scalar_output            : std_logic_vector(scalar_size - 1 downto 0);

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

	axi_conv8_vhdl_wrapper_instantiation: axi_conv8_vhdl_wrapper port map(

			-- Users to add ports here
	
			-- User ports ends
			-- Do not modify the ports beyond this line
	
	
			-- Ports of Axi Slave Bus Interface S00_AXI
			s00_axi_aclk	=> clk,
			s00_axi_aresetn	=> rst,
			s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
			s00_axi_awprot	: in std_logic_vector(2 downto 0);
			s00_axi_awvalid	: in std_logic;
			s00_axi_awready	: out std_logic;
			s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
			s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
			s00_axi_wvalid	: in std_logic;
			s00_axi_wready	: out std_logic;
			s00_axi_bresp	: out std_logic_vector(1 downto 0);
			s00_axi_bvalid	: out std_logic;
			s00_axi_bready	: in std_logic;
			s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
			s00_axi_arprot	: in std_logic_vector(2 downto 0);
			s00_axi_arvalid	: in std_logic;
			s00_axi_arready	: out std_logic;
			s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
			s00_axi_rresp	: out std_logic_vector(1 downto 0);
			s00_axi_rvalid	: out std_logic;
			s00_axi_rready	: in std_logic;
	
			-- Ports of Axi Slave Bus Interface S00_AXIS
			s00_axis_aclk	: in std_logic;
			s00_axis_aresetn	: in std_logic;
			s00_axis_tready	: out std_logic;
			s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
			s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
			s00_axis_tlast	: in std_logic;
			s00_axis_tvalid	: in std_logic;
	
			-- Ports of Axi Master Bus Interface M00_AXIS
			m00_axis_aclk	: in std_logic;
			m00_axis_aresetn	: in std_logic;
			m00_axis_tvalid	: out std_logic;
			m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
			m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
			m00_axis_tlast	: out std_logic;
			m00_axis_tready	: in std_logic
		);
	end component axi_conv8_vhdl_wrapper;

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
					scalar_input <= scalar_to_std_logic_vector(to_scalar(rand));
					
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
		end if;
	end process verify;
end rtl;