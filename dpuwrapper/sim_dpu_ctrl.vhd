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
use work.cnn_defs.all;

entity sim_dpu_ctrl is
end entity;

architecture sim_only of sim_dpu_ctrl is


  component dpu_ctrl_wrap is
    port (
      clk                      : in  std_logic;
      rst                      : in  std_logic;
      start_addr               : in  std_logic_vector(63 downto 0);
      start_addr_valid         : in  std_logic;
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
      feature_valid            : out std_logic;
      feature_ready            : in  std_logic;
      output_stream            : in  std_logic_vector(feature_width-1 downto 0);
      output_valid             : in  std_logic;
      output_ready             : out std_logic;
      weight_stream            : out std_logic_vector(weight_width-1 downto 0);
      weight_id                : out std_logic_vector(7 downto 0);
      weight_first             : out std_logic;
      weight_last              : out std_logic;
      relu                     : out std_logic;
      conv_3x3                 : out std_logic;
      use_maxpool              : out std_logic;
      feature_image_width      : out std_logic_vector(13 downto 0);
      number_of_features       : out std_logic_vector(11 downto 0);
      stride2                  : out std_logic;
      mp_feature_image_width   : out std_logic_vector(13 downto 0);
      mp_number_of_features    : out std_logic_vector(11 downto 0);
      number_of_active_neurons : out std_logic_vector(9 downto 0);
      throttle_rate            : out std_logic_vector(9 downto 0);
      access_error             : out std_logic_vector(35 downto 0);
      clear_error              : in  std_logic);
  end component dpu_ctrl_wrap;
  
  signal clk                      : std_logic := '0';
  signal rst                      : std_logic := '0';
  signal start_addr               : std_logic_vector(63 downto 0) := (others => '0');
  signal start_addr_valid         : std_logic := '0';
  signal m_axi_awid               : STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal m_axi_awaddr             : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m_axi_awlen              : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal m_axi_awsize             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m_axi_awburst            : STD_LOGIC_VECTOR(1 DOWNTO 0);
  signal m_axi_awlock             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_awcache            : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m_axi_awprot             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m_axi_awregion           : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m_axi_awqos              : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m_axi_awvalid            : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_awready            : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_wdata              : STD_LOGIC_VECTOR(511 DOWNTO 0);
  signal m_axi_wstrb              : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m_axi_wlast              : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_wvalid             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_wready             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_bid                : STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal m_axi_bresp              : STD_LOGIC_VECTOR(1 DOWNTO 0);
  signal m_axi_bvalid             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_bready             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_arid               : STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal m_axi_araddr             : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m_axi_arlen              : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal m_axi_arsize             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m_axi_arburst            : STD_LOGIC_VECTOR(1 DOWNTO 0);
  signal m_axi_arlock             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_arcache            : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m_axi_arprot             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m_axi_arregion           : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m_axi_arqos              : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m_axi_arvalid            : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_arready            : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_rid                : STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal m_axi_rdata              : STD_LOGIC_VECTOR(511 DOWNTO 0);
  signal m_axi_rresp              : STD_LOGIC_VECTOR(1 DOWNTO 0);
  signal m_axi_rlast              : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_rvalid             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m_axi_rready             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal feature_stream           : std_logic_vector(feature_width-1 downto 0);
  signal feature_valid            : std_logic;
  signal feature_ready            : std_logic;
  signal output_stream            : std_logic_vector(feature_width-1 downto 0);
  signal output_valid             : std_logic;
  signal output_ready             : std_logic;
  signal weight_stream            : std_logic_vector(weight_width-1 downto 0);
  signal weight_id                : std_logic_vector(7 downto 0);
  signal weight_first             : std_logic;
  signal weight_last              : std_logic;
  signal relu                     : std_logic;
  signal conv_3x3                 : std_logic;
  signal use_maxpool              : std_logic;
  signal feature_image_width      : std_logic_vector(13 downto 0);
  signal number_of_features       : std_logic_vector(11 downto 0);
  signal stride2                  : std_logic;
  signal mp_feature_image_width   : std_logic_vector(13 downto 0);
  signal mp_number_of_features    : std_logic_vector(11 downto 0);
  signal number_of_active_neurons : std_logic_vector(9 downto 0);
  signal throttle_rate            : std_logic_vector(9 downto 0);
  signal access_error             : std_logic_vector(35 downto 0);
  signal clear_error              : std_logic := '0';

  component dpu_core is
    port (
      clk                      : in  std_logic;
      rst                      : in  std_logic;
      feature_stream           : in  std_logic_vector(feature_width-1 downto 0);
      feature_valid            : in  std_logic;
      feature_ready            : out std_logic;
      output_stream            : out std_logic_vector(feature_width-1 downto 0);
      output_valid             : out std_logic;
      output_ready             : in  std_logic;
      weight_stream            : in  std_logic_vector(weight_width-1 downto 0);
      weight_id                : in  std_logic_vector(7 downto 0);
      weight_first             : in  std_logic;
      weight_last              : in  std_logic;
      relu                     : in  std_logic;
      conv_3x3                 : in  std_logic;
      use_maxpool              : in  std_logic;
      feature_image_width      : in  std_logic_vector(13 downto 0);
      number_of_features       : in  std_logic_vector(11 downto 0);
      stride2                  : in  std_logic;
      mp_feature_image_width   : in  std_logic_vector(13 downto 0);
      mp_number_of_features    : in  std_logic_vector(11 downto 0);
      number_of_active_neurons : in  std_logic_vector(9 downto 0);
      throttle_rate            : in  std_logic_vector(9 downto 0);
      op_overflow_detect       : out std_logic);
  end component dpu_core;
  
  component sim_memory is
    port (
      s_axi_aclk    : in  std_logic;
      s_axi_aresetn : in  std_logic;
      s_axi_awid    : in  std_logic_vector(5 downto 0);
      s_axi_awaddr  : in  std_logic_vector(18 downto 0);
      s_axi_awlen   : in  std_logic_vector(7 downto 0);
      s_axi_awsize  : in  std_logic_vector(2 downto 0);
      s_axi_awburst : in  std_logic_vector(1 downto 0);
      s_axi_awlock  : in  std_logic;
      s_axi_awcache : in  std_logic_vector(3 downto 0);
      s_axi_awprot  : in  std_logic_vector(2 downto 0);
      s_axi_awvalid : in  std_logic;
      s_axi_awready : out std_logic;
      s_axi_wdata   : in  std_logic_vector(511 downto 0);
      s_axi_wstrb   : in  std_logic_vector(63 downto 0);
      s_axi_wlast   : in  std_logic;
      s_axi_wvalid  : in  std_logic;
      s_axi_wready  : out std_logic;
      s_axi_bid     : out std_logic_vector(5 downto 0);
      s_axi_bresp   : out std_logic_vector(1 downto 0);
      s_axi_bvalid  : out std_logic;
      s_axi_bready  : in  std_logic;
      s_axi_arid    : in  std_logic_vector(5 downto 0);
      s_axi_araddr  : in  std_logic_vector(18 downto 0);
      s_axi_arlen   : in  std_logic_vector(7 downto 0);
      s_axi_arsize  : in  std_logic_vector(2 downto 0);
      s_axi_arburst : in  std_logic_vector(1 downto 0);
      s_axi_arlock  : in  std_logic;
      s_axi_arcache : in  std_logic_vector(3 downto 0);
      s_axi_arprot  : in  std_logic_vector(2 downto 0);
      s_axi_arvalid : in  std_logic;
      s_axi_arready : out std_logic;
      s_axi_rid     : out std_logic_vector(5 downto 0);
      s_axi_rdata   : out std_logic_vector(511 downto 0);
      s_axi_rresp   : out std_logic_vector(1 downto 0);
      s_axi_rlast   : out std_logic;
      s_axi_rvalid  : out std_logic;
      s_axi_rready  : in  std_logic);
  end component sim_memory;

 signal resetn : std_logic := '1';
  
begin

  clk <= not clk after 5 ns;
  
  process
  begin
    rst <= '1';
    clear_error <= '0';
    wait for 20 ns;
    rst <= '0';
    wait for 100 ns;
    start_addr <= (others => '0');
    start_addr_valid <= '1';
    wait for 10 ns;
    start_addr <= (others => '0');
    start_addr_valid <= '0';
    wait;
    
  end process;
  
  resetn <= not rst;

  dpu_ctrl_wrap_1: dpu_ctrl_wrap
    port map (
      clk                      => clk,
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




  dpu_core_1: dpu_core
    port map (
      clk                      => clk,
      rst                      => rst,
      feature_stream           => feature_stream,
      feature_valid            => feature_valid,
      feature_ready            => feature_ready,
      output_stream            => output_stream,
      output_valid             => output_valid,
      output_ready             => output_ready,
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


  sim_memory_1: sim_memory
    port map (
      s_axi_aclk    => clk,
      s_axi_aresetn => resetn,
      s_axi_awid    => m_axi_awid,
      s_axi_awaddr  => m_axi_awaddr(18 downto 0),
      s_axi_awlen   => m_axi_awlen,
      s_axi_awsize  => m_axi_awsize,
      s_axi_awburst => m_axi_awburst,
      s_axi_awlock  => m_axi_awlock(0),
      s_axi_awcache => m_axi_awcache,
      s_axi_awprot  => m_axi_awprot,
      s_axi_awvalid => m_axi_awvalid(0),
      s_axi_awready => m_axi_awready(0),
      s_axi_wdata   => m_axi_wdata,
      s_axi_wstrb   => m_axi_wstrb,
      s_axi_wlast   => m_axi_wlast(0),
      s_axi_wvalid  => m_axi_wvalid(0),
      s_axi_wready  => m_axi_wready(0),
      s_axi_bid     => m_axi_bid,
      s_axi_bresp   => m_axi_bresp,
      s_axi_bvalid  => m_axi_bvalid(0),
      s_axi_bready  => m_axi_bready(0),
      s_axi_arid    => m_axi_arid,
      s_axi_araddr  => m_axi_araddr(18 downto 0),
      s_axi_arlen   => m_axi_arlen,
      s_axi_arsize  => m_axi_arsize,
      s_axi_arburst => m_axi_arburst,
      s_axi_arlock  => m_axi_arlock(0),
      s_axi_arcache => m_axi_arcache,
      s_axi_arprot  => m_axi_arprot,
      s_axi_arvalid => m_axi_arvalid(0),
      s_axi_arready => m_axi_arready(0),
      s_axi_rid     => m_axi_rid,
      s_axi_rdata   => m_axi_rdata,
      s_axi_rresp   => m_axi_rresp,
      s_axi_rlast   => m_axi_rlast(0),
      s_axi_rvalid  => m_axi_rvalid(0),
      s_axi_rready  => m_axi_rready(0));
  
end architecture;
