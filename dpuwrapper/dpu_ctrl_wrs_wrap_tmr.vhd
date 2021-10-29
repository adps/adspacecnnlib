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

-- define feature and weight width and TMR types
library work;
use work.tmr.all;
use work.cnn_defs.all;



entity dpu_ctrl_wrs_wrap_tmr is
  port (
    clk : in std_logic;
    rst : in std_logic;
    -- Start Command
    start_addr : in tmr_logic_vector(63 downto 0);
    start_addr_valid : in tmr_logic;   
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
    -- DPU Data Paths
    -- Input Data Stream
    feature_stream : out std_logic_vector(feature_width-1 downto 0);
    feature_valid  : out tmr_logic;
    feature_ready  : in tmr_logic;
    -- Output Data Stream
    output_stream  : in std_logic_vector(feature_width-1 downto 0);
    output_valid   : in tmr_logic;
    output_ready   : out tmr_logic;
      -- Output Data Stream
    output2_stream  : in std_logic_vector(feature_width-1 downto 0);
    output2_valid   : in tmr_logic;
    output2_ready   : out tmr_logic;
    output2_enable  : out tmr_logic;
    -- Weights Configuration Stream Port
    weight_stream  : out std_logic_vector(weight_width-1 downto 0);
    weight_id      : out tmr_logic_vector(7 downto 0);
    weight_first   : out tmr_logic;
    weight_last    : out tmr_logic;
    -- Dynamic Configuration Parameters
    relu           : out  tmr_logic;
    conv_3x3       : out  tmr_logic;
    use_maxpool    : out  tmr_logic;
    feature_image_width : out tmr_logic_vector(13 downto 0);
    number_of_features : out tmr_logic_vector(11 downto 0);
    stride2        : out tmr_logic;
    mp_feature_image_width : out tmr_logic_vector(13 downto 0);
    mp_number_of_features : out tmr_logic_vector(11 downto 0);
    number_of_active_neurons : out tmr_logic_vector(9 downto 0);
    throttle_rate : out tmr_logic_vector(9 downto 0);
    -- Status
    access_error : out tmr_logic_vector(51 downto 0);
    clear_error  : in  tmr_logic
  );
end entity;

architecture rtl of dpu_ctrl_wrs_wrap_tmr is


  component dpu_ctrl_wrs_wrap is
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
      output2_stream           : in  std_logic_vector(feature_width-1 downto 0);
      output2_valid            : in  std_logic;
      output2_ready            : out std_logic;
      output2_enable           : out std_logic;
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
      access_error             : out std_logic_vector(51 downto 0);
      clear_error              : in  std_logic);
  end component dpu_ctrl_wrs_wrap;


  
      

  signal m0_axi_awid               : STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal m0_axi_awaddr             : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m0_axi_awlen              : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal m0_axi_awsize             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m0_axi_awburst            : STD_LOGIC_VECTOR(1 DOWNTO 0);
  signal m0_axi_awlock             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m0_axi_awcache            : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m0_axi_awprot             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m0_axi_awregion           : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m0_axi_awqos              : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m0_axi_awvalid            : STD_LOGIC_VECTOR(0 DOWNTO 0);
 
  signal m0_axi_wdata              : STD_LOGIC_VECTOR(511 DOWNTO 0);
  signal m0_axi_wstrb              : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m0_axi_wlast              : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m0_axi_wvalid             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  
  signal m0_axi_bready             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m0_axi_arid               : STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal m0_axi_araddr             : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m0_axi_arlen              : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal m0_axi_arsize             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m0_axi_arburst            : STD_LOGIC_VECTOR(1 DOWNTO 0);
  signal m0_axi_arlock             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m0_axi_arcache            : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m0_axi_arprot             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m0_axi_arregion           : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m0_axi_arqos              : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m0_axi_arvalid            : STD_LOGIC_VECTOR(0 DOWNTO 0);

  signal m0_axi_rready             : STD_LOGIC_VECTOR(0 DOWNTO 0);
 
  signal m1_axi_awid               : STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal m1_axi_awaddr             : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m1_axi_awlen              : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal m1_axi_awsize             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m1_axi_awburst            : STD_LOGIC_VECTOR(1 DOWNTO 0);
  signal m1_axi_awlock             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m1_axi_awcache            : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m1_axi_awprot             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m1_axi_awregion           : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m1_axi_awqos              : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m1_axi_awvalid            : STD_LOGIC_VECTOR(0 DOWNTO 0);
 
  signal m1_axi_wdata              : STD_LOGIC_VECTOR(511 DOWNTO 0);
  signal m1_axi_wstrb              : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m1_axi_wlast              : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m1_axi_wvalid             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  
  signal m1_axi_bready             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m1_axi_arid               : STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal m1_axi_araddr             : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m1_axi_arlen              : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal m1_axi_arsize             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m1_axi_arburst            : STD_LOGIC_VECTOR(1 DOWNTO 0);
  signal m1_axi_arlock             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m1_axi_arcache            : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m1_axi_arprot             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m1_axi_arregion           : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m1_axi_arqos              : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m1_axi_arvalid            : STD_LOGIC_VECTOR(0 DOWNTO 0);

  signal m1_axi_rready             : STD_LOGIC_VECTOR(0 DOWNTO 0);

  signal m2_axi_awid               : STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal m2_axi_awaddr             : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m2_axi_awlen              : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal m2_axi_awsize             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m2_axi_awburst            : STD_LOGIC_VECTOR(1 DOWNTO 0);
  signal m2_axi_awlock             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m2_axi_awcache            : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m2_axi_awprot             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m2_axi_awregion           : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m2_axi_awqos              : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m2_axi_awvalid            : STD_LOGIC_VECTOR(0 DOWNTO 0);
 
  signal m2_axi_wdata              : STD_LOGIC_VECTOR(511 DOWNTO 0);
  signal m2_axi_wstrb              : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m2_axi_wlast              : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m2_axi_wvalid             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  
  signal m2_axi_bready             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m2_axi_arid               : STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal m2_axi_araddr             : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal m2_axi_arlen              : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal m2_axi_arsize             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m2_axi_arburst            : STD_LOGIC_VECTOR(1 DOWNTO 0);
  signal m2_axi_arlock             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal m2_axi_arcache            : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m2_axi_arprot             : STD_LOGIC_VECTOR(2 DOWNTO 0);
  signal m2_axi_arregion           : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m2_axi_arqos              : STD_LOGIC_VECTOR(3 DOWNTO 0);
  signal m2_axi_arvalid            : STD_LOGIC_VECTOR(0 DOWNTO 0);

  signal m2_axi_rready             : STD_LOGIC_VECTOR(0 DOWNTO 0);

  signal mt_axi_awid               : TMR_LOGIC_VECTOR(5 DOWNTO 0);
  signal mt_axi_awaddr             : TMR_LOGIC_VECTOR(63 DOWNTO 0);
  signal mt_axi_awlen              : TMR_LOGIC_VECTOR(7 DOWNTO 0);
  signal mt_axi_awsize             : TMR_LOGIC_VECTOR(2 DOWNTO 0);
  signal mt_axi_awburst            : TMR_LOGIC_VECTOR(1 DOWNTO 0);
  signal mt_axi_awlock             : TMR_LOGIC_VECTOR(0 DOWNTO 0);
  signal mt_axi_awcache            : TMR_LOGIC_VECTOR(3 DOWNTO 0);
  signal mt_axi_awprot             : TMR_LOGIC_VECTOR(2 DOWNTO 0);
  signal mt_axi_awregion           : TMR_LOGIC_VECTOR(3 DOWNTO 0);
  signal mt_axi_awqos              : TMR_LOGIC_VECTOR(3 DOWNTO 0);
  signal mt_axi_awvalid            : TMR_LOGIC_VECTOR(0 DOWNTO 0);
 
  signal mt_axi_wdata              : TMR_LOGIC_VECTOR(511 DOWNTO 0);
  signal mt_axi_wstrb              : TMR_LOGIC_VECTOR(63 DOWNTO 0);
  signal mt_axi_wlast              : TMR_LOGIC_VECTOR(0 DOWNTO 0);
  signal mt_axi_wvalid             : TMR_LOGIC_VECTOR(0 DOWNTO 0);
  
  signal mt_axi_bready             : TMR_LOGIC_VECTOR(0 DOWNTO 0);
  signal mt_axi_arid               : TMR_LOGIC_VECTOR(5 DOWNTO 0);
  signal mt_axi_araddr             : TMR_LOGIC_VECTOR(63 DOWNTO 0);
  signal mt_axi_arlen              : TMR_LOGIC_VECTOR(7 DOWNTO 0);
  signal mt_axi_arsize             : TMR_LOGIC_VECTOR(2 DOWNTO 0);
  signal mt_axi_arburst            : TMR_LOGIC_VECTOR(1 DOWNTO 0);
  signal mt_axi_arlock             : TMR_LOGIC_VECTOR(0 DOWNTO 0);
  signal mt_axi_arcache            : TMR_LOGIC_VECTOR(3 DOWNTO 0);
  signal mt_axi_arprot             : TMR_LOGIC_VECTOR(2 DOWNTO 0);
  signal mt_axi_arregion           : TMR_LOGIC_VECTOR(3 DOWNTO 0);
  signal mt_axi_arqos              : TMR_LOGIC_VECTOR(3 DOWNTO 0);
  signal mt_axi_arvalid            : TMR_LOGIC_VECTOR(0 DOWNTO 0);

  signal mt_axi_rready             : TMR_LOGIC_VECTOR(0 DOWNTO 0);


  
  
  signal feature_stream_i           : tmr_logic_vector(feature_width-1 downto 0);
  signal weight_stream_i            : tmr_logic_vector(weight_width-1 downto 0);

  signal feature_stream0           : std_logic_vector(feature_width-1 downto 0);
  signal weight_stream0            : std_logic_vector(weight_width-1 downto 0);  
  signal weight_id0                : std_logic_vector(7 downto 0);
  signal feature_image_width0      : std_logic_vector(13 downto 0);
  signal number_of_features0       : std_logic_vector(11 downto 0);
  signal mp_feature_image_width0   : std_logic_vector(13 downto 0);
  signal mp_number_of_features0    : std_logic_vector(11 downto 0);
  signal number_of_active_neurons0 : std_logic_vector(9 downto 0);
  signal throttle_rate0            : std_logic_vector(9 downto 0);
  signal access_error0             : std_logic_vector(51 downto 0);

  signal feature_stream1           : std_logic_vector(feature_width-1 downto 0);
  signal weight_stream1            : std_logic_vector(weight_width-1 downto 0);  
  signal weight_id1                : std_logic_vector(7 downto 0);
  signal feature_image_width1      : std_logic_vector(13 downto 0);
  signal number_of_features1       : std_logic_vector(11 downto 0);
  signal mp_feature_image_width1   : std_logic_vector(13 downto 0);
  signal mp_number_of_features1    : std_logic_vector(11 downto 0);
  signal number_of_active_neurons1 : std_logic_vector(9 downto 0);
  signal throttle_rate1            : std_logic_vector(9 downto 0);
  signal access_error1             : std_logic_vector(51 downto 0);

  signal feature_stream2           : std_logic_vector(feature_width-1 downto 0);
  signal weight_stream2            : std_logic_vector(weight_width-1 downto 0);  
  signal weight_id2                : std_logic_vector(7 downto 0);
  signal feature_image_width2      : std_logic_vector(13 downto 0);
  signal number_of_features2       : std_logic_vector(11 downto 0);
  signal mp_feature_image_width2   : std_logic_vector(13 downto 0);
  signal mp_number_of_features2    : std_logic_vector(11 downto 0);
  signal number_of_active_neurons2 : std_logic_vector(9 downto 0);
  signal throttle_rate2            : std_logic_vector(9 downto 0);
  signal access_error2             : std_logic_vector(51 downto 0);
  
  signal  start_addr0 : std_logic_vector(63 downto 0);
  signal  start_addr1 : std_logic_vector(63 downto 0);
  signal  start_addr2 : std_logic_vector(63 downto 0);
  
begin

  start_addr0 <= to_std_logic_vector(start_addr,0);
  start_addr1 <= to_std_logic_vector(start_addr,1);
  start_addr2 <= to_std_logic_vector(start_addr,2);
  
  

  -- Create 3 Instances of the DPU_CTRL_WRAP core   

  dpu_ctrl_wrs_wrap_0: dpu_ctrl_wrs_wrap
    port map (
      clk                      => clk,
      rst                      => rst,
      start_addr               => start_addr0,
      start_addr_valid         => start_addr_valid(0),
      m_axi_awid               => m0_axi_awid,
      m_axi_awaddr             => m0_axi_awaddr,
      m_axi_awlen              => m0_axi_awlen,
      m_axi_awsize             => m0_axi_awsize,
      m_axi_awburst            => m0_axi_awburst,
      m_axi_awlock             => m0_axi_awlock,
      m_axi_awcache            => m0_axi_awcache,
      m_axi_awprot             => m0_axi_awprot,
      m_axi_awregion           => m0_axi_awregion,
      m_axi_awqos              => m0_axi_awqos,
      m_axi_awvalid            => m0_axi_awvalid,
      m_axi_awready            => m_axi_awready,
      m_axi_wdata              => m0_axi_wdata,
      m_axi_wstrb              => m0_axi_wstrb,
      m_axi_wlast              => m0_axi_wlast,
      m_axi_wvalid             => m0_axi_wvalid,
      m_axi_wready             => m_axi_wready,
      m_axi_bid                => m_axi_bid,
      m_axi_bresp              => m_axi_bresp,
      m_axi_bvalid             => m_axi_bvalid,
      m_axi_bready             => m0_axi_bready,
      m_axi_arid               => m0_axi_arid,
      m_axi_araddr             => m0_axi_araddr,
      m_axi_arlen              => m0_axi_arlen,
      m_axi_arsize             => m0_axi_arsize,
      m_axi_arburst            => m0_axi_arburst,
      m_axi_arlock             => m0_axi_arlock,
      m_axi_arcache            => m0_axi_arcache,
      m_axi_arprot             => m0_axi_arprot,
      m_axi_arregion           => m0_axi_arregion,
      m_axi_arqos              => m0_axi_arqos,
      m_axi_arvalid            => m0_axi_arvalid,
      m_axi_arready            => m_axi_arready,
      m_axi_rid                => m_axi_rid,
      m_axi_rdata              => m_axi_rdata,
      m_axi_rresp              => m_axi_rresp,
      m_axi_rlast              => m_axi_rlast,
      m_axi_rvalid             => m_axi_rvalid,
      m_axi_rready             => m0_axi_rready,
      feature_stream           => feature_stream0,
      feature_valid            => feature_valid(0),
      feature_ready            => feature_ready(0),
      output_stream            => output_stream,
      output_valid             => output_valid(0),
      output_ready             => output_ready(0),
      output2_stream           => output2_stream,
      output2_valid            => output2_valid(0),
      output2_ready            => output2_ready(0),
      output2_enable           => output2_enable(0),
      weight_stream            => weight_stream0,
      weight_id                => weight_id0,
      weight_first             => weight_first(0),
      weight_last              => weight_last(0),
      relu                     => relu(0),
      conv_3x3                 => conv_3x3(0),
      use_maxpool              => use_maxpool(0),
      feature_image_width      => feature_image_width0,
      number_of_features       => number_of_features0,
      stride2                  => stride2(0),
      mp_feature_image_width   => mp_feature_image_width0,
      mp_number_of_features    => mp_number_of_features0,
      number_of_active_neurons => number_of_active_neurons0,
      throttle_rate            => throttle_rate0,
      access_error             => access_error0,
      clear_error              => clear_error(0));

  dpu_ctrl_wrs_wrap_1: dpu_ctrl_wrs_wrap
    port map (
      clk                      => clk,
      rst                      => rst,
      start_addr               => start_addr1,
      start_addr_valid         => start_addr_valid(1),
      m_axi_awid               => m1_axi_awid,
      m_axi_awaddr             => m1_axi_awaddr,
      m_axi_awlen              => m1_axi_awlen,
      m_axi_awsize             => m1_axi_awsize,
      m_axi_awburst            => m1_axi_awburst,
      m_axi_awlock             => m1_axi_awlock,
      m_axi_awcache            => m1_axi_awcache,
      m_axi_awprot             => m1_axi_awprot,
      m_axi_awregion           => m1_axi_awregion,
      m_axi_awqos              => m1_axi_awqos,
      m_axi_awvalid            => m1_axi_awvalid,
      m_axi_awready            => m_axi_awready,
      m_axi_wdata              => m1_axi_wdata,
      m_axi_wstrb              => m1_axi_wstrb,
      m_axi_wlast              => m1_axi_wlast,
      m_axi_wvalid             => m1_axi_wvalid,
      m_axi_wready             => m_axi_wready,
      m_axi_bid                => m_axi_bid,
      m_axi_bresp              => m_axi_bresp,
      m_axi_bvalid             => m_axi_bvalid,
      m_axi_bready             => m1_axi_bready,
      m_axi_arid               => m1_axi_arid,
      m_axi_araddr             => m1_axi_araddr,
      m_axi_arlen              => m1_axi_arlen,
      m_axi_arsize             => m1_axi_arsize,
      m_axi_arburst            => m1_axi_arburst,
      m_axi_arlock             => m1_axi_arlock,
      m_axi_arcache            => m1_axi_arcache,
      m_axi_arprot             => m1_axi_arprot,
      m_axi_arregion           => m1_axi_arregion,
      m_axi_arqos              => m1_axi_arqos,
      m_axi_arvalid            => m1_axi_arvalid,
      m_axi_arready            => m_axi_arready,
      m_axi_rid                => m_axi_rid,
      m_axi_rdata              => m_axi_rdata,
      m_axi_rresp              => m_axi_rresp,
      m_axi_rlast              => m_axi_rlast,
      m_axi_rvalid             => m_axi_rvalid,
      m_axi_rready             => m1_axi_rready,
      feature_stream           => feature_stream1,
      feature_valid            => feature_valid(1),
      feature_ready            => feature_ready(1),
      output_stream            => output_stream,
      output_valid             => output_valid(1),
      output_ready             => output_ready(1),
      output2_stream           => output2_stream,
      output2_valid            => output2_valid(1),
      output2_ready            => output2_ready(1),
      output2_enable           => output2_enable(1),
      weight_stream            => weight_stream1,
      weight_id                => weight_id1,
      weight_first             => weight_first(1),
      weight_last              => weight_last(1),
      relu                     => relu(1),
      conv_3x3                 => conv_3x3(1),
      use_maxpool              => use_maxpool(1),
      feature_image_width      => feature_image_width1,
      number_of_features       => number_of_features1,
      stride2                  => stride2(1),
      mp_feature_image_width   => mp_feature_image_width1,
      mp_number_of_features    => mp_number_of_features1,
      number_of_active_neurons => number_of_active_neurons1,
      throttle_rate            => throttle_rate1,
      access_error             => access_error1,
      clear_error              => clear_error(1));

  dpu_ctrl_wrs_wrap_2: dpu_ctrl_wrs_wrap
    port map (
      clk                      => clk,
      rst                      => rst,
      start_addr               => start_addr2,
      start_addr_valid         => start_addr_valid(2),
      m_axi_awid               => m2_axi_awid,
      m_axi_awaddr             => m2_axi_awaddr,
      m_axi_awlen              => m2_axi_awlen,
      m_axi_awsize             => m2_axi_awsize,
      m_axi_awburst            => m2_axi_awburst,
      m_axi_awlock             => m2_axi_awlock,
      m_axi_awcache            => m2_axi_awcache,
      m_axi_awprot             => m2_axi_awprot,
      m_axi_awregion           => m2_axi_awregion,
      m_axi_awqos              => m2_axi_awqos,
      m_axi_awvalid            => m2_axi_awvalid,
      m_axi_awready            => m_axi_awready,
      m_axi_wdata              => m2_axi_wdata,
      m_axi_wstrb              => m2_axi_wstrb,
      m_axi_wlast              => m2_axi_wlast,
      m_axi_wvalid             => m2_axi_wvalid,
      m_axi_wready             => m_axi_wready,
      m_axi_bid                => m_axi_bid,
      m_axi_bresp              => m_axi_bresp,
      m_axi_bvalid             => m_axi_bvalid,
      m_axi_bready             => m2_axi_bready,
      m_axi_arid               => m2_axi_arid,
      m_axi_araddr             => m2_axi_araddr,
      m_axi_arlen              => m2_axi_arlen,
      m_axi_arsize             => m2_axi_arsize,
      m_axi_arburst            => m2_axi_arburst,
      m_axi_arlock             => m2_axi_arlock,
      m_axi_arcache            => m2_axi_arcache,
      m_axi_arprot             => m2_axi_arprot,
      m_axi_arregion           => m2_axi_arregion,
      m_axi_arqos              => m2_axi_arqos,
      m_axi_arvalid            => m2_axi_arvalid,
      m_axi_arready            => m_axi_arready,
      m_axi_rid                => m_axi_rid,
      m_axi_rdata              => m_axi_rdata,
      m_axi_rresp              => m_axi_rresp,
      m_axi_rlast              => m_axi_rlast,
      m_axi_rvalid             => m_axi_rvalid,
      m_axi_rready             => m2_axi_rready,
      feature_stream           => feature_stream2,
      feature_valid            => feature_valid(2),
      feature_ready            => feature_ready(2),
      output_stream            => output_stream,
      output_valid             => output_valid(2),
      output_ready             => output_ready(2),
      output2_stream           => output2_stream,
      output2_valid            => output2_valid(2),
      output2_ready            => output2_ready(2),
      output2_enable           => output2_enable(2),
      weight_stream            => weight_stream2,
      weight_id                => weight_id2,
      weight_first             => weight_first(2),
      weight_last              => weight_last(2),
      relu                     => relu(2),
      conv_3x3                 => conv_3x3(2),
      use_maxpool              => use_maxpool(2),
      feature_image_width      => feature_image_width2,
      number_of_features       => number_of_features2,
      stride2                  => stride2(2),
      mp_feature_image_width   => mp_feature_image_width2,
      mp_number_of_features    => mp_number_of_features2,
      number_of_active_neurons => number_of_active_neurons2,
      throttle_rate            => throttle_rate2,
      access_error             => access_error2,
      clear_error              => clear_error(2));



  -- TMR resolve Feature and Weight stream data
  
  feature_stream_i <= to_tmr_logic_vector(feature_stream0,feature_stream1,feature_stream2);
  weight_stream_i <= to_tmr_logic_vector(weight_stream0,weight_stream1,weight_stream2);

  feature_stream <= tmr_resolve(feature_stream_i);
  weight_stream <= tmr_resolve(weight_stream_i);
  
  -- Combine Vector Signals to DPU into TMR Types
  
  weight_id  <= to_tmr_logic_vector(weight_id0,weight_id1,weight_id2);                  
  feature_image_width <= to_tmr_logic_vector(feature_image_width0,feature_image_width1,feature_image_width2);       
  number_of_features <= to_tmr_logic_vector(number_of_features0,number_of_features1,number_of_features2);        
  mp_feature_image_width <= to_tmr_logic_vector(mp_feature_image_width0,mp_feature_image_width1,mp_feature_image_width2);    
  mp_number_of_features <= to_tmr_logic_vector(mp_number_of_features0,mp_number_of_features1,mp_number_of_features2);   
  number_of_active_neurons <= to_tmr_logic_vector(number_of_active_neurons0,number_of_active_neurons1,number_of_active_neurons2);  
  throttle_rate <= to_tmr_logic_vector(throttle_rate0,throttle_rate1,throttle_rate2);             
  access_error <= to_tmr_logic_vector(access_error0,access_error1,access_error2);



  -- TMR resolve AXI4 Output Signals

   
  mt_axi_awid <= to_tmr_logic_vector(m0_axi_awid,m1_axi_awid,m2_axi_awid);       
  mt_axi_awaddr <= to_tmr_logic_vector(m0_axi_awaddr,m1_axi_awaddr,m2_axi_awaddr);    
  mt_axi_awlen <= to_tmr_logic_vector(m0_axi_awlen,m1_axi_awlen,m2_axi_awlen);     
  mt_axi_awsize <= to_tmr_logic_vector(m0_axi_awsize,m1_axi_awsize,m2_axi_awsize);    
  mt_axi_awburst <= to_tmr_logic_vector(m0_axi_awburst,m1_axi_awburst,m2_axi_awburst);   
  mt_axi_awlock <= to_tmr_logic_vector(m0_axi_awlock,m1_axi_awlock,m2_axi_awlock);    
  mt_axi_awcache <= to_tmr_logic_vector(m0_axi_awcache,m1_axi_awcache,m2_axi_awcache);   
  mt_axi_awprot <= to_tmr_logic_vector(m0_axi_awprot,m1_axi_awprot,m2_axi_awprot);    
  mt_axi_awregion <= to_tmr_logic_vector(m0_axi_awregion,m1_axi_awregion,m2_axi_awregion);  
  mt_axi_awqos <= to_tmr_logic_vector(m0_axi_awqos,m1_axi_awqos,m2_axi_awqos);     
  mt_axi_awvalid <= to_tmr_logic_vector(m0_axi_awvalid,m1_axi_awvalid,m2_axi_awvalid);  
                                                                   
  mt_axi_wdata <= to_tmr_logic_vector(m0_axi_wdata,m1_axi_wdata,m2_axi_wdata);     
  mt_axi_wstrb <= to_tmr_logic_vector(m0_axi_wstrb,m1_axi_wstrb,m2_axi_wstrb);     
  mt_axi_wlast <= to_tmr_logic_vector(m0_axi_wlast,m1_axi_wlast,m2_axi_wlast);     
  mt_axi_wvalid <= to_tmr_logic_vector(m0_axi_wvalid,m1_axi_wvalid,m2_axi_wvalid);   
                                                                   
  mt_axi_bready <= to_tmr_logic_vector(m0_axi_bready,m1_axi_bready,m2_axi_bready);    
  mt_axi_arid <= to_tmr_logic_vector(m0_axi_arid,m1_axi_arid,m2_axi_arid);      
  mt_axi_araddr <= to_tmr_logic_vector(m0_axi_araddr,m1_axi_araddr,m2_axi_araddr);    
  mt_axi_arlen <= to_tmr_logic_vector(m0_axi_arlen,m1_axi_arlen,m2_axi_arlen);     
  mt_axi_arsize <= to_tmr_logic_vector(m0_axi_arsize,m1_axi_arsize,m2_axi_arsize);    
  mt_axi_arburst <= to_tmr_logic_vector(m0_axi_arburst,m1_axi_arburst,m2_axi_arburst);   
  mt_axi_arlock <= to_tmr_logic_vector(m0_axi_arlock,m1_axi_arlock,m2_axi_arlock);    
  mt_axi_arcache <= to_tmr_logic_vector(m0_axi_arcache,m1_axi_arcache,m2_axi_arcache);   
  mt_axi_arprot <= to_tmr_logic_vector(m0_axi_arprot,m1_axi_arprot,m2_axi_arprot);    
  mt_axi_arregion <= to_tmr_logic_vector(m0_axi_arregion,m1_axi_arregion,m2_axi_arregion);  
  mt_axi_arqos <= to_tmr_logic_vector(m0_axi_arqos,m1_axi_arqos,m2_axi_arqos);     
  mt_axi_arvalid <= to_tmr_logic_vector(m0_axi_arvalid,m1_axi_arvalid,m2_axi_arvalid);  
                                                                  
  mt_axi_rready <= to_tmr_logic_vector(m0_axi_rready,m1_axi_rready,m2_axi_rready);   


  m_axi_awid     <= tmr_resolve(mt_axi_awid);       
  m_axi_awaddr   <= tmr_resolve(mt_axi_awaddr);    
  m_axi_awlen    <= tmr_resolve(mt_axi_awlen);     
  m_axi_awsize   <= tmr_resolve(mt_axi_awsize);    
  m_axi_awburst  <= tmr_resolve(mt_axi_awburst);   
  m_axi_awlock   <= tmr_resolve(mt_axi_awlock);    
  m_axi_awcache  <= tmr_resolve(mt_axi_awcache);   
  m_axi_awprot   <= tmr_resolve(mt_axi_awprot);    
  m_axi_awregion <= tmr_resolve(mt_axi_awregion);  
  m_axi_awqos    <= tmr_resolve(mt_axi_awqos);     
  m_axi_awvalid  <= tmr_resolve(mt_axi_awvalid);  
                                  
  m_axi_wdata    <= tmr_resolve(mt_axi_wdata);     
  m_axi_wstrb    <= tmr_resolve(mt_axi_wstrb);     
  m_axi_wlast    <= tmr_resolve(mt_axi_wlast);     
  m_axi_wvalid   <= tmr_resolve(mt_axi_wvalid);   
                                  
  m_axi_bready   <= tmr_resolve(mt_axi_bready);    
  m_axi_arid     <= tmr_resolve(mt_axi_arid);      
  m_axi_araddr   <= tmr_resolve(mt_axi_araddr);    
  m_axi_arlen    <= tmr_resolve(mt_axi_arlen);     
  m_axi_arsize   <= tmr_resolve(mt_axi_arsize);    
  m_axi_arburst  <= tmr_resolve(mt_axi_arburst);   
  m_axi_arlock   <= tmr_resolve(mt_axi_arlock);    
  m_axi_arcache  <= tmr_resolve(mt_axi_arcache);   
  m_axi_arprot   <= tmr_resolve(mt_axi_arprot);    
  m_axi_arregion <= tmr_resolve(mt_axi_arregion);  
  m_axi_arqos    <= tmr_resolve(mt_axi_arqos);     
  m_axi_arvalid  <= tmr_resolve(mt_axi_arvalid);  
                                 
  m_axi_rready   <= tmr_resolve(mt_axi_rready);  
  
  
  
end architecture; 
