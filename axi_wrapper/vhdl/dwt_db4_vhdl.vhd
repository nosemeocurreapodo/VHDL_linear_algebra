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
		data_out_ok   : out std_logic;
		data_out      : out std_logic_vector(scalar_size-1 downto 0);
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

	signal control_register  : std_logic_vector(7 downto 0) := "00000001";
	signal data_in_len_register : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(32, 32));
	signal data_out_len_register : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned((32 + 8 - 1)/2, 32));

	signal slave_data      : std_logic_vector(scalar_size - 1 downto 0);
	signal slave_data_ok   : std_logic;
	signal slave_data_last : std_logic;

	signal master_data    : scalar;
	signal master_data_ok : std_logic;

	signal shift_reg        : scalar_array(SHIFT_REG_LEN - 1 downto 0);
	signal filter_input     : Vector8;
	--signal lo_filter_coeff  : Vector8;
	--signal hi_filter_coeff  : Vector8;

	--constant hi_filter_coeff : Vector8 := (to_scalar(-2.303778133088965008632911830440708500016152482483092977910968e-01),
	--									   to_scalar(7.148465705529156470899219552739926037076084010993081758450110e-01),
	--									   to_scalar(-6.308807679298589078817163383006152202032229226771951174057473e-01),
	--									   to_scalar(-2.798376941685985421141374718007538541198732022449175284003358e-02),
	--									   to_scalar(1.870348117190930840795706727890814195845441743745800912057770e-01),
	--									   to_scalar(3.084138183556076362721936253495905017031482172003403341821219e-02),
	--									   to_scalar(-3.288301166688519973540751354924438866454194113754971259727278e-02),
	--									   to_scalar(-1.059740178506903210488320852402722918109996490637641983484974e-02));
	
	--constant hi_filter_coeff : Vector8 := (to_scalar(-1.059740178506903210488320852402722918109996490637641983484974e-02),
	--									   to_scalar(-3.288301166688519973540751354924438866454194113754971259727278e-02),
	--									   to_scalar(3.084138183556076362721936253495905017031482172003403341821219e-02),
	--									   to_scalar(1.870348117190930840795706727890814195845441743745800912057770e-01),
	--									   to_scalar(-2.798376941685985421141374718007538541198732022449175284003358e-02),
	--									   to_scalar(-6.308807679298589078817163383006152202032229226771951174057473e-01),
	--									   to_scalar(7.148465705529156470899219552739926037076084010993081758450110e-01),
	--									   to_scalar(-2.303778133088965008632911830440708500016152482483092977910968e-01));

	constant hi_filter_coeff : Vector8 := (to_scalar(-0.01059740178506903210488),
										   to_scalar(-0.03288301166688519973540),
										   to_scalar( 0.03084138183556076362721),
										   to_scalar( 0.18703481171909308407957),
										   to_scalar(-0.02798376941685985421141),
										   to_scalar(-0.63088076792985890788171),
										   to_scalar( 0.71484657055291564708992),
										   to_scalar(-0.23037781330889650086329));

	--constant hi_filter_coeff : Vector8 := (to_scalar(0.0),
	--									   to_scalar(0.0),
	--									   to_scalar(0.0),
	--									   to_scalar(0.0),
	--									   to_scalar(1.0),
	--									   to_scalar(0.0),
	--									   to_scalar(0.0),
	--									   to_scalar(0.0));

	--constant lo_filter_coeff : Vector8 := (to_scalar(-1.059740178506903210488320852402722918109996490637641983484974e-02),
	--									   to_scalar(3.288301166688519973540751354924438866454194113754971259727278e-02),
	--									   to_scalar(3.084138183556076362721936253495905017031482172003403341821219e-02),
	--									   to_scalar(-1.870348117190930840795706727890814195845441743745800912057770e-01),
	--									   to_scalar(-2.798376941685985421141374718007538541198732022449175284003358e-02),
	--									   to_scalar(6.308807679298589078817163383006152202032229226771951174057473e-01),
	--									   to_scalar(7.148465705529156470899219552739926037076084010993081758450110e-01),
	--									   to_scalar(2.303778133088965008632911830440708500016152482483092977910968e-01));

	--constant lo_filter_coeff : Vector8 := (to_scalar(2.303778133088965008632911830440708500016152482483092977910968e-01),
	--									   to_scalar(7.148465705529156470899219552739926037076084010993081758450110e-01),
	--									   to_scalar(6.308807679298589078817163383006152202032229226771951174057473e-01),
	--									   to_scalar(-2.798376941685985421141374718007538541198732022449175284003358e-02),
	--									   to_scalar(-1.870348117190930840795706727890814195845441743745800912057770e-01),
	--									   to_scalar(3.084138183556076362721936253495905017031482172003403341821219e-02),
	--									   to_scalar(3.288301166688519973540751354924438866454194113754971259727278e-02),
	--									   to_scalar(-1.059740178506903210488320852402722918109996490637641983484974e-02));

	constant lo_filter_coeff : Vector8 := (to_scalar( 0.23037781330889650086329),
										   to_scalar( 0.71484657055291564708992),
										   to_scalar( 0.63088076792985890788171),
										   to_scalar(-0.02798376941685985421141),
										   to_scalar(-0.18703481171909308407957),
										   to_scalar( 0.03084138183556076362721),
										   to_scalar( 0.03288301166688519973540),
										   to_scalar(-0.01059740178506903210488));

	signal lo_data     : scalar;
	signal lo_data_ok  : std_logic;

	signal hi_data     : scalar;
	signal hi_data_ok  : std_logic;

	signal data_in_count : unsigned(31 downto 0)  := to_unsigned(0, 32);
	signal data_out_count : unsigned(31 downto 0) := to_unsigned(0, 32);

	signal do_padding       : std_logic  := '0';
	signal do_padding_count : unsigned(31 downto 0) := to_unsigned(0, 32);

	signal do_convolution : std_logic              := '0';
	signal do_convolution_count : unsigned(31 downto 0) := to_unsigned(0, 32);

	type state_type is (IDLE, LESS_THAN_8, ADD_START_PADDING, SEND_ALL_DATA, ADD_END_PADDING, FINISH_PROCESSING);
	signal state : state_type := IDLE;


begin

SCALAR_S_AXIS_inst : SCALAR_S_AXIS
	generic map (
		C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH
	)
	port map (
		data_out_ok     => slave_data_ok,
		data_out        => slave_data,
		data_out_last   => slave_data_last,
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
		new_operation_request    => do_convolution,
		new_operation_request_id => request_id_zero,
		new_operation_done       => hi_data_ok,
		Vector1_input            => filter_input,
		Vector2_input            => hi_filter_coeff,
		output                   => hi_data
	);

	lo_filter : Vector8_dot_fast 
	port map(
		clk                      => s_axis_aclk,
		new_operation_request    => do_convolution,
		new_operation_request_id => request_id_zero,
		new_operation_done       => lo_data_ok,
		Vector1_input            => filter_input,
		Vector2_input            => lo_filter_coeff,
		output                   => lo_data
	);

	filter_input_gen: for i in 7 downto 0 generate
		filter_input(i) <= shift_reg(i+6);
	end generate;
    
	data_in_count_process : process(s_axis_aclk)
	begin
		if (rising_edge(s_axis_aclk)) then		
			if(state = FINISH_PROCESSING) then
				data_in_count <= to_unsigned(0, 32);
			else
				if(slave_data_ok = '1') then
					data_in_count <= data_in_count + 1;
					data_out_len_register <= std_logic_vector(to_unsigned((to_integer(data_in_count) + 8 - 1)/2, 32));
				end if;
			end if;
		end if;
	end process;

  	data_out_count_process : process(s_axis_aclk)
	begin
		if (rising_edge(s_axis_aclk)) then		
			if(state = IDLE) then
				data_out_count <= to_unsigned(0, 32);
			else
				if(lo_data_ok = '1') then
					data_out_count <= data_out_count + 1;
				end if;
			end if;
		end if;
	end process;

	do_convolution_count_process : process(s_axis_aclk)
	begin
		if (rising_edge(s_axis_aclk)) then		
			if(state = IDLE) then
				do_convolution_count <= to_unsigned(0, 32);
			else
				if(do_convolution = '1') then
					do_convolution_count <= do_convolution_count + 1;
				end if;
			end if;
		end if;
	end process;

	do_padding_count_process : process(s_axis_aclk)
	begin
		if (rising_edge(s_axis_aclk)) then		
			if(state = IDLE) then
				do_padding_count <= to_unsigned(0, 32);
			else
				if(do_padding = '1') then
					do_padding_count <= do_padding_count + 1;
				end if;
			end if;
		end if;
	end process;

	shift_reg_process : process(s_axis_aclk)
		variable index_1 : integer;
		variable index_2 : integer;
	begin
		if (rising_edge(s_axis_aclk)) then		
			if(slave_data_ok = '1' or do_padding = '1') then
				if(state = IDLE or state = LESS_THAN_8) then
					index_1 := 7 - to_integer(data_in_count);
					index_2 := 8 + to_integer(data_in_count);
					shift_reg(index_1) <= to_scalar(slave_data);
					shift_reg(index_2) <= to_scalar(slave_data);
				else
					for I in SHIFT_REG_LEN - 1 downto 1 loop
						shift_reg(I) <= shift_reg(I-1);
					end loop;
					if(slave_data_ok = '1') then
						shift_reg(0) <= to_scalar(slave_data);
					else
						index_1 := to_integer(do_padding_count)*2;
						if(index_1 > 15) then
							index_1 := 15;
						end if;
						shift_reg(0) <= shift_reg(index_1);
					end if;
				end if;
			end if;
		end if;
	end process;

	state_machine : process(s_axis_aclk)
	begin
		if (rising_edge(s_axis_aclk)) then		
			case state is
				when IDLE =>
					if(data_in_count > 0) then
						state <= LESS_THAN_8;
					end if;
					do_convolution <= '0';
					do_padding <= '0';

				when LESS_THAN_8 =>
					if(data_in_count = 7) then
						state <= ADD_START_PADDING;
						do_convolution <= '1';
					end if;

				when ADD_START_PADDING =>					
					do_convolution <= '0';

					state <= SEND_ALL_DATA;

				when SEND_ALL_DATA =>
					do_convolution <= not do_convolution;

					if(slave_data_last = '1') then
						state <= ADD_END_PADDING;
						do_padding <= '1';
					end if;
					--if(data_in_count = to_integer(unsigned(data_in_len_register)) - 1) then
					--	state <= ADD_END_PADDING;
					--	do_padding <= '1';
					--end if;

				when ADD_END_PADDING =>
					do_convolution <= not do_convolution;
					if(do_convolution_count = to_integer(unsigned(data_out_len_register)) -1) then
						state <= FINISH_PROCESSING;
						do_padding <= '0';
					end if;
				when FINISH_PROCESSING =>
					do_convolution <= '0';
					do_padding <= '0';
					if(data_out_count = to_integer(unsigned(data_out_len_register)) - 1) then
						state <= IDLE;
					end if;
			end case;
		end if;
	end process;

end arch_imp;
