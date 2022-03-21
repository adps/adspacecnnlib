--Copyright (c) 2021, Alpha Data Parallel Systems Ltd.
--All rights reserved.
--
--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:
--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of the Alpha Data Parallel Systems Ltd. nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.
--
--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL Alpha Data Parallel Systems Ltd. BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


--
-- dpu_core.vhd
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


-- define feature and weight width
library work;
use work.tmr.all;
use work.cnn_defs.all;

entity dpu_top is
    port (
  --  clk : in std_logic;
  --  rst : in std_logic;
    m_axi_aclk : in std_logic;
    m_axi_aresetn : in std_logic;
    reg_axi_aclk : in std_logic;  -- Duplicate clock to keen IPI happy
    reg_axi_aresetn : in std_logic;
    -- AXI-Lite Control Interface
    reg_axi_awaddr       : in  std_logic_vector(11 downto 0);
      reg_axi_awvalid      : in  std_logic;
      reg_axi_wdata        : in  std_logic_vector(31 downto 0);
      reg_axi_wstrb        : in  std_logic_vector(3 downto 0);
      reg_axi_wvalid       : in  std_logic;
      reg_axi_bready       : in  std_logic;
      reg_axi_araddr       : in  std_logic_vector(11 downto 0);
      reg_axi_arvalid      : in  std_logic;
      reg_axi_rready       : in  std_logic;
      reg_axi_awready      : out std_logic;
      reg_axi_wready       : out std_logic;
      reg_axi_bresp        : out std_logic_vector(1 downto 0);
      reg_axi_bvalid       : out std_logic;
      reg_axi_arready      : out std_logic;
      reg_axi_rdata        : out std_logic_vector(31 downto 0);
      reg_axi_rresp        : out std_logic_vector(1 downto 0);
      reg_axi_rvalid       : out std_logic;
     
    -- Memory Interface AXI
    m_axi_awid : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    m_axi_awaddr : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axi_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axi_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_awlock : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_awregion : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_awqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_awvalid : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_awready : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_wdata : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    m_axi_wstrb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axi_wlast : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_wvalid : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_wready : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_bid : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    m_axi_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_bvalid : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_bready : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_arid : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    m_axi_araddr : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axi_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axi_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_arlock : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_arregion : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_arqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_arvalid : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_arready : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_rid : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    m_axi_rdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    m_axi_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_rlast : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_rvalid : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axi_rready : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    led0 : out std_logic;
    led1 : out std_logic;
    led2 : out std_logic;
    led3 : out std_logic

    );
end entity;

architecture rtl of dpu_top is
  component dpu_ctrl_wrs_wrap_tmr is
    port (
      clk                      : in  std_logic;
      rst                      : in  std_logic;
      start_addr               : in  tmr_logic_vector(63 downto 0);
      start_addr_valid         : in  tmr_logic;
      m_axi_awid               : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
      m_axi_awaddr             : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      m_axi_awlen              : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_awsize             : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_awburst            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_awlock             : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_awcache            : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_awprot             : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_awregion           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_awqos              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_awvalid            : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_awready            : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_wdata              : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
      m_axi_wstrb              : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      m_axi_wlast              : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_wvalid             : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_wready             : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_bid                : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
      m_axi_bresp              : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_bvalid             : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_bready             : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_arid               : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
      m_axi_araddr             : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      m_axi_arlen              : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_arsize             : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_arburst            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_arlock             : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_arcache            : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_arprot             : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_arregion           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_arqos              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_arvalid            : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_arready            : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_rid                : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
      m_axi_rdata              : IN  STD_LOGIC_VECTOR(511 DOWNTO 0);
      m_axi_rresp              : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_rlast              : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_rvalid             : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axi_rready             : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      feature_stream           : out std_logic_vector(feature_width-1 downto 0);
      feature_valid            : out tmr_logic;
      feature_ready            : in  tmr_logic;
      output_stream            : in  std_logic_vector(feature_width-1 downto 0);
      output_valid             : in  tmr_logic;
      output_ready             : out tmr_logic;
      output2_stream           : in  std_logic_vector(feature_width-1 downto 0);
      output2_valid            : in  tmr_logic;
      output2_ready            : out tmr_logic;
      output2_enable           : out tmr_logic;
      weight_stream            : out std_logic_vector(weight_width-1 downto 0);
      weight_id                : out tmr_logic_vector(7 downto 0);
      weight_first             : out tmr_logic;
      weight_last              : out tmr_logic;
      relu                     : out tmr_logic;
      conv_3x3                 : out tmr_logic;
      use_maxpool              : out tmr_logic;
      feature_image_width      : out tmr_logic_vector(13 downto 0);
      number_of_features       : out tmr_logic_vector(11 downto 0);
      stride2                  : out tmr_logic;
      mp_feature_image_width   : out tmr_logic_vector(13 downto 0);
      mp_number_of_features    : out tmr_logic_vector(11 downto 0);
      number_of_active_neurons : out tmr_logic_vector(9 downto 0);
      throttle_rate            : out tmr_logic_vector(9 downto 0);
      access_error             : out tmr_logic_vector(51 downto 0);
      clear_error              : in  tmr_logic);
  end component dpu_ctrl_wrs_wrap_tmr;
  

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal start_addr               : tmr_logic_vector(63 downto 0);
  signal start_addr_valid         : tmr_logic;

  signal feature_stream           : std_logic_vector(feature_width-1 downto 0);
  signal feature_valid            : tmr_logic;
  signal feature_ready            : tmr_logic;
  signal output_stream            : std_logic_vector(feature_width-1 downto 0);
  signal output_valid             : tmr_logic;
  signal output_ready             : tmr_logic;
  signal output2_stream           : std_logic_vector(feature_width-1 downto 0);
  signal output2_valid            : tmr_logic;
  signal output2_ready            : tmr_logic;
  signal output2_enable           : tmr_logic;
  signal weight_stream            : std_logic_vector(weight_width-1 downto 0);
  signal weight_id                : tmr_logic_vector(7 downto 0);
  signal weight_first             : tmr_logic;
  signal weight_last              : tmr_logic;
  signal relu                     : tmr_logic;
  signal conv_3x3                 : tmr_logic;
  signal use_maxpool              : tmr_logic;
  signal feature_image_width      : tmr_logic_vector(13 downto 0);
  signal number_of_features       : tmr_logic_vector(11 downto 0);
  signal stride2                  : tmr_logic;
  signal mp_feature_image_width   : tmr_logic_vector(13 downto 0);
  signal mp_number_of_features    : tmr_logic_vector(11 downto 0);
  signal number_of_active_neurons : tmr_logic_vector(9 downto 0);
  signal throttle_rate            : tmr_logic_vector(9 downto 0);
  signal access_error             : tmr_logic_vector(51 downto 0);
  signal clear_error              : tmr_logic;
  
 
  component dpu_core_2op_tmr is
    port (
      clk                      : in  std_logic;
      rst                      : in  std_logic;
      feature_stream           : in  std_logic_vector(feature_width-1 downto 0);
      feature_valid            : in  tmr_logic;
      feature_ready            : out tmr_logic;
      output_stream            : out std_logic_vector(feature_width-1 downto 0);
      output_valid             : out tmr_logic;
      output_ready             : in  tmr_logic;
      output2_stream           : out std_logic_vector(feature_width-1 downto 0);
      output2_valid            : out tmr_logic;
      output2_ready            : in  tmr_logic;
      output2_enable           : in  tmr_logic;
      weight_stream            : in  std_logic_vector(weight_width-1 downto 0);
      weight_id                : in  tmr_logic_vector(7 downto 0);
      weight_first             : in  tmr_logic;
      weight_last              : in  tmr_logic;
      relu                     : in  tmr_logic;
      conv_3x3                 : in  tmr_logic;
      use_maxpool              : in  tmr_logic;
      feature_image_width      : in  tmr_logic_vector(13 downto 0);
      number_of_features       : in  tmr_logic_vector(11 downto 0);
      stride2                  : in  tmr_logic;
      mp_feature_image_width   : in  tmr_logic_vector(13 downto 0);
      mp_number_of_features    : in  tmr_logic_vector(11 downto 0);
      number_of_active_neurons : in  tmr_logic_vector(9 downto 0);
      throttle_rate            : in  tmr_logic_vector(9 downto 0);
      op_overflow_detect       : out tmr_logic);
  end component dpu_core_2op_tmr;
 
  component reg_bank_axi4l is
    generic (
      number_of_axil_regs : natural);
    port (
      aclk                 : in  std_logic;
      aresetn              : in  std_logic;
      reg_axi_awaddr       : in  std_logic_vector(11 downto 0);
      reg_axi_awvalid      : in  std_logic;
      reg_axi_wdata        : in  std_logic_vector(31 downto 0);
      reg_axi_wstrb        : in  std_logic_vector(3 downto 0);
      reg_axi_wvalid       : in  std_logic;
      reg_axi_bready       : in  std_logic;
      reg_axi_araddr       : in  std_logic_vector(11 downto 0);
      reg_axi_arvalid      : in  std_logic;
      reg_axi_rready       : in  std_logic;
      reg_axi_awready      : out std_logic                                        := '0';
      reg_axi_wready       : out std_logic                                        := '0';
      reg_axi_bresp        : out std_logic_vector(1 downto 0)                     := (others => '0');
      reg_axi_bvalid       : out std_logic                                        := '0';
      reg_axi_arready      : out std_logic                                        := '0';
      reg_axi_rdata        : out std_logic_vector(31 downto 0)                    := (others => '0');
      reg_axi_rresp        : out std_logic_vector(1 downto 0)                     := (others => '0');
      reg_axi_rvalid       : out std_logic                                        := '0';
      status_regs_in       : in  std_Logic_vector(32*number_of_axil_regs-1 downto 0);
      control_regs_out     : out std_Logic_vector(32*number_of_axil_regs-1 downto 0);
      control_regs_written : out std_Logic_vector(number_of_axil_regs-1 downto 0) := (others => '0'));
  end component reg_bank_axi4l;

  constant number_of_axil_regs : natural := 8;
  
  signal status_regs_in       : std_Logic_vector(32*number_of_axil_regs-1 downto 0);
  signal control_regs_out     : std_Logic_vector(32*number_of_axil_regs-1 downto 0);
  signal control_regs_written : std_Logic_vector(number_of_axil_regs-1 downto 0) := (others => '0');
 
  signal dpu_state : std_logic_vector(3 downto 0);
  signal run_counter : unsigned(31 downto 0) := (others => '0');
  signal dpu_counter : unsigned(31 downto 0) := (others => '0');
  
  
begin

  clk <= m_axi_aclk;
  rst <= not m_axi_aresetn;
 

  dpu_ctrl_wrs_wrap_1: dpu_ctrl_wrs_wrap_tmr
    port map (
      clk                      => reg_axi_aclk,
      rst                      => rst,
      start_addr               => start_addr,
      start_addr_valid         => start_addr_valid,
      m_axi_awid               => m_axi_awid,
      m_axi_awaddr             => m_axi_awaddr,
      m_axi_awlen              => m_axi_awlen,
      m_axi_awsize             => m_axi_awsize,
      m_axi_awburst            => m_axi_awburst,
      m_axi_awlock            => m_axi_awlock,
      m_axi_awcache            => m_axi_awcache,
      m_axi_awprot             => m_axi_awprot,
      m_axi_awregion           => m_axi_awregion,
      m_axi_awqos              => m_axi_awqos,
      m_axi_awvalid            => m_axi_awvalid,
      m_axi_awready            => m_axi_awready,
      m_axi_wdata              => m_axi_wdata,
      m_axi_wstrb              => m_axi_wstrb,
      m_axi_wlast              => m_axi_wlast,
      m_axi_wvalid             => m_axi_wvalid,
      m_axi_wready             => m_axi_wready,
      m_axi_bid                => m_axi_bid,
      m_axi_bresp              => m_axi_bresp,
      m_axi_bvalid             => m_axi_bvalid,
      m_axi_bready             => m_axi_bready,
      m_axi_arid               => m_axi_arid,
      m_axi_araddr             => m_axi_araddr,
      m_axi_arlen              => m_axi_arlen,
      m_axi_arsize             => m_axi_arsize,
      m_axi_arburst            => m_axi_arburst,
      m_axi_arlock             => m_axi_arlock,
      m_axi_arcache            => m_axi_arcache,
      m_axi_arprot             => m_axi_arprot,
      m_axi_arregion           => m_axi_arregion,
      m_axi_arqos              => m_axi_arqos,
      m_axi_arvalid            => m_axi_arvalid,
      m_axi_arready            => m_axi_arready,
      m_axi_rid                => m_axi_rid,
      m_axi_rdata              => m_axi_rdata,
      m_axi_rresp              => m_axi_rresp,
      m_axi_rlast              => m_axi_rlast,
      m_axi_rvalid             => m_axi_rvalid,
      m_axi_rready             => m_axi_rready,
      feature_stream           => feature_stream,
      feature_valid            => feature_valid,
      feature_ready            => feature_ready,
      output_stream            => output_stream,
      output_valid             => output_valid,
      output_ready             => output_ready,
      output2_stream            => output2_stream,
      output2_valid             => output2_valid,
      output2_ready             => output2_ready,
      output2_enable           => output2_enable,
      weight_stream            => weight_stream,
      weight_id                => weight_id,
      weight_first             => weight_first,
      weight_last              => weight_last,
      relu                     => relu,
      conv_3x3                 => conv_3x3,
      use_maxpool              => use_maxpool,
      feature_image_width      => feature_image_width,
      number_of_features       => number_of_features,
      stride2                  => stride2,
      mp_feature_image_width   => mp_feature_image_width,
      mp_number_of_features    => mp_number_of_features,
      number_of_active_neurons => number_of_active_neurons,
      throttle_rate            => throttle_rate,
      access_error             => access_error,
      clear_error              => clear_error);




  dpu_core_2op_1: dpu_core_2op_tmr
    port map (
      clk                      => clk,
      rst                      => rst,
      feature_stream           => feature_stream,
      feature_valid            => feature_valid,
      feature_ready            => feature_ready,
      output_stream            => output_stream,
      output_valid             => output_valid,
      output_ready             => output_ready,
      output2_stream            => output2_stream,
      output2_valid             => output2_valid,
      output2_ready             => output2_ready,
      output2_enable           => output2_enable,
      weight_stream            => weight_stream,
      weight_id                => weight_id,
      weight_first             => weight_first,
      weight_last              => weight_last,
      relu                     => relu,
      conv_3x3                 => conv_3x3,
      use_maxpool              => use_maxpool,
      feature_image_width      => feature_image_width,
      number_of_features       => number_of_features,
      stride2                  => stride2,
      mp_feature_image_width   => mp_feature_image_width,
      mp_number_of_features    => mp_number_of_features,
      number_of_active_neurons => number_of_active_neurons,
      throttle_rate            => throttle_rate,
      op_overflow_detect       => open);


  reg_bank_axi4l_1: reg_bank_axi4l
    generic map (
      number_of_axil_regs => number_of_axil_regs)
    port map (
      aclk                 => clk,
      aresetn              => m_axi_aresetn,
      reg_axi_awaddr       => reg_axi_awaddr,
      reg_axi_awvalid      => reg_axi_awvalid,
      reg_axi_wdata        => reg_axi_wdata,
      reg_axi_wstrb        => reg_axi_wstrb,
      reg_axi_wvalid       => reg_axi_wvalid,
      reg_axi_bready       => reg_axi_bready,
      reg_axi_araddr       => reg_axi_araddr,
      reg_axi_arvalid      => reg_axi_arvalid,
      reg_axi_rready       => reg_axi_rready,
      reg_axi_awready      => reg_axi_awready,
      reg_axi_wready       => reg_axi_wready,
      reg_axi_bresp        => reg_axi_bresp,
      reg_axi_bvalid       => reg_axi_bvalid,
      reg_axi_arready      => reg_axi_arready,
      reg_axi_rdata        => reg_axi_rdata,
      reg_axi_rresp        => reg_axi_rresp,
      reg_axi_rvalid       => reg_axi_rvalid,
      status_regs_in       => status_regs_in,
      control_regs_out     => control_regs_out,
      control_regs_written => control_regs_written);



  start_addr <= to_tmr_logic_vector(control_regs_out(63 downto 0));
  start_addr_valid <= to_tmr_logic(control_regs_written(0));

  status_regs_in(63 downto 0) <= control_regs_out(63 downto 0);
  status_regs_in(64+51 downto 64) <= tmr_resolve(access_error);
  clear_error <= to_tmr_logic(control_regs_written(2));

  process (clk)
  begin
    if rising_edge(clk) then
      led0 <= not status_regs_in(64+48);
      led1 <= not status_regs_in(64+49);
      led2 <= not status_regs_in(64+50);
      led3 <= not status_regs_in(64+51);

      -- Run and DPU Status Counters
      dpu_state <= status_regs_in(64+51 downto 64+48);
      if start_addr_valid = '1' then
        run_counter <= (others => '0');
        dpu_counter <= (others => '0');
      else
        if dpu_state /= "0000" and dpu_state /= "1111" and dpu_state /= "1110" then
          run_counter <= run_counter +1;
        end if;
        if dpu_state = "0111" then
          dpu_counter <= dpu_counter+1;
        end if;
      end if;
      status_regs_in(159 downto 128) <= std_logic_vector(run_counter);
      status_regs_in(191 downto 160) <= std_logic_vector(dpu_counter);
    end if;
  end process;
  
  
end architecture;
