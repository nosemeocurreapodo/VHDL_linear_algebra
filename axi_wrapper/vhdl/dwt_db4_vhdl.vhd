library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;

use work.FPU_definitions_pack.all;
use work.Matrix_definition_pack.all;
use work.Matrix_component_pack.all;

entity dwt_db4_vhdl is
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
		hi_m_axis_tlast	    : out std_logic;
		hi_m_axis_tready	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
		lo_m_axis_aclk  	: in std_logic;
		lo_m_axis_aresetn	: in std_logic;
		lo_m_axis_tvalid	: out std_logic;
		lo_m_axis_tdata	    : out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		lo_m_axis_tstrb 	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		lo_m_axis_tlast 	: out std_logic;
		lo_m_axis_tready	: in std_logic

	);
end dwt_db4_vhdl;

architecture arch_imp of dwt_db4_vhdl is

	-- component declaration
	component SCALAR_S_AXIS is
		generic (
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
		);
		port (
		data_out_ok : out std_logic;
		data_out    : out std_logic_vector(scalar_size-1 downto 0);
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TLAST	: in std_logic;
		S_AXIS_TVALID	: in std_logic
		);
	end component SCALAR_S_AXIS;

	component SCALAR_M_AXIS is
		generic (
		C_M_AXIS_TDATA_WIDTH  : integer	:= 32;
		SCALAR_FIFO_DEPTH	  : integer	:= 32
		);
		port (
		data_in_ok  : in std_logic;
		data_in     : in std_logic_vector(scalar_size-1 downto 0);
		M_AXIS_ACLK	: in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_TVALID	: out std_logic;
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TLAST	: out std_logic;
		M_AXIS_TREADY	: in std_logic
		);
	end component SCALAR_M_AXIS;

	signal slave_data     : std_logic_vector(scalar_size - 1 downto 0);
	signal slave_data_ok  : std_logic;

	signal master_data    : scalar;
	signal master_data_ok : std_logic;

	signal shift_reg        : scalar_array(SHIFT_REG_LEN - 1 downto 0);
	signal filter_input     : Vector8;
	signal lo_filter_coeff  : Vector8;
	signal hi_filter_coeff  : Vector8;

	constant lo_filter_coeff : Vector8 := to_floating_point(0.0);

	signal lo_data     : scalar;
	signal lo_data_ok  : std_logic;

	signal hi_data     : scalar;
	signal hi_data_ok  : std_logic;

	signal data_in_count : unsigned(31 downto 0)  := to_unsigned(0, 32);
	signal data_in_new   : std_logic              := '0';
begin

SCALAR_S_AXIS_inst : SCALAR_S_AXIS
	generic map (
		C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH
	)
	port map (
		data_out_ok     => slave_data_ok,
		data_out        => slave_data,
		S_AXIS_ACLK	    => s_axis_aclk,
		S_AXIS_ARESETN	=> s_axis_aresetn,
		S_AXIS_TREADY	=> s_axis_tready,
		S_AXIS_TDATA	=> s_axis_tdata,
		S_AXIS_TSTRB	=> s_axis_tstrb,
		S_AXIS_TLAST	=> s_axis_tlast,
		S_AXIS_TVALID	=> s_axis_tvalid
	);

SCALAR_hi_M_AXIS_inst : SCALAR_M_AXIS
	generic map (
		C_M_AXIS_TDATA_WIDTH  => C_M00_AXIS_TDATA_WIDTH,
		SCALAR_FIFO_DEPTH     => 32
	)
	port map (
		data_in_ok      => hi_data_ok,
		data_in         => scalar_to_std_logic_vector(hi_data),
		M_AXIS_ACLK	    => hi_m_axis_aclk,
		M_AXIS_ARESETN	=> hi_m_axis_aresetn,
		M_AXIS_TVALID	=> hi_m_axis_tvalid,
		M_AXIS_TDATA	=> hi_m_axis_tdata,
		M_AXIS_TSTRB	=> hi_m_axis_tstrb,
		M_AXIS_TLAST	=> hi_m_axis_tlast,
		M_AXIS_TREADY	=> hi_m_axis_tready
	);

SCALAR_lo_M_AXIS_inst : SCALAR_M_AXIS
	generic map (
		C_M_AXIS_TDATA_WIDTH  => C_M00_AXIS_TDATA_WIDTH,
		SCALAR_FIFO_DEPTH     => 32
	)
	port map (
		data_in_ok      => lo_data_ok,
		data_in         => scalar_to_std_logic_vector(lo_data),
		M_AXIS_ACLK	    => lo_m_axis_aclk,
		M_AXIS_ARESETN	=> lo_m_axis_aresetn,
		M_AXIS_TVALID	=> lo_m_axis_tvalid,
		M_AXIS_TDATA	=> lo_m_axis_tdata,
		M_AXIS_TSTRB	=> lo_m_axis_tstrb,
		M_AXIS_TLAST	=> lo_m_axis_tlast,
		M_AXIS_TREADY	=> lo_m_axis_tready
	);

	hi_filter : Vector8_dot_fast 
	port map(
		clk                      => s_axis_aclk,
		new_operation_request    => data_in_new,
		new_operation_request_id => request_id_zero,
		new_operation_done       => hi_data_ok,
		Vector1_input            => filter_input,
		Vector2_input            => hi_filter_coeff,
		output                   => hi_data
	);

	lo_filter : Vector8_dot_fast 
	port map(
		clk                      => s_axis_aclk,
		new_operation_request    => data_in_new,
		new_operation_request_id => request_id_zero,
		new_operation_done       => lo_data_ok,
		Vector1_input            => filter_input,
		Vector2_input            => lo_filter_coeff,
		output                   => lo_data
	);

  filter_input_gen: for i in 7 downto 0 generate
    filter_input(i) <= shift_reg(i);
  end generate;
    
	shift_reg_process : process(s_axis_aclk)
	begin
		if (rising_edge(s_axis_aclk)) then
			if(slave_data_ok = '1') then
				for I in SHIFT_REG_LEN - 1 downto 1 loop
					shift_reg(I) <= shift_reg(I-1);
				end loop;
				shift_reg(0) <= to_scalar(slave_data);
				data_in_count <= data_in_count + 1;
				if(data_in_count >= 8) then
					data_in_new <= '1';
				else
					data_in_new <= '0';
				end if;
			else
				data_in_new <= '0';
			end if;
		end if;
	end process;
end arch_imp;
