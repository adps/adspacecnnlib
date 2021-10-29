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



entity dpu_ctrl_wrs_wrap is
  port (
    clk : in std_logic;
    rst : in std_logic;
    -- Start Command
    start_addr : in std_logic_vector(63 downto 0);
    start_addr_valid : in std_logic;   
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
    feature_valid  : out std_logic;
    feature_ready  : in std_logic;
    -- Output Data Stream
    output_stream  : in std_logic_vector(feature_width-1 downto 0);
    output_valid   : in std_logic;
    output_ready   : out std_logic;
      -- Output Data Stream
    output2_stream  : in std_logic_vector(feature_width-1 downto 0);
    output2_valid   : in std_logic;
    output2_ready   : out std_logic;
    output2_enable  : out std_logic;
    -- Weights Configuration Stream Port
    weight_stream  : out std_logic_vector(weight_width-1 downto 0);
    weight_id      : out std_logic_vector(7 downto 0);
    weight_first   : out std_logic;
    weight_last    : out std_logic;
    -- Dynamic Configuration Parameters
    relu           : out  std_logic;
    conv_3x3       : out  std_logic;
    use_maxpool    : out  std_logic;
    feature_image_width : out std_logic_vector(13 downto 0);
    number_of_features : out std_logic_vector(11 downto 0);
    stride2        : out std_logic;
    mp_feature_image_width : out std_logic_vector(13 downto 0);
    mp_number_of_features : out std_logic_vector(11 downto 0);
    number_of_active_neurons : out std_logic_vector(9 downto 0);
    throttle_rate : out std_logic_vector(9 downto 0);
    -- Status
    access_error : out std_logic_vector(51 downto 0);
    clear_error  : in  std_logic
  );
end entity;

architecture rtl of dpu_ctrl_wrs_wrap is


  component dpu_ctrl_wrs is
    port (
      clk                      : in  std_logic;
      rst                      : in  std_logic;
      start_addr               : in  std_logic_vector(63 downto 0);
      start_addr_valid         : in  std_logic;
      iudm_command             : out std_logic_vector(103 downto 0);
      iudm_valid               : out std_logic;
      iudm_ready               : in  std_logic;
      iudm_status              : in  std_logic_vector(7 downto 0);
      iudm_status_valid        : in  std_logic;
      iudm_status_ready        : out std_logic;
      iudm_data                : in  std_logic_vector(31 downto 0);
      iudm_data_valid          : in  std_logic;
      iudm_data_ready          : out std_logic;
      iudm_data_last           : in  std_logic;
      wdm_command              : out std_logic_vector(103 downto 0);
      wdm_valid                : out std_logic;
      wdm_ready                : in  std_logic;
      wdm_status               : in  std_logic_vector(7 downto 0);
      wdm_status_valid         : in  std_logic;
      wdm_status_ready         : out std_logic;
      wdm_data_last            : in  std_logic;
      idm_command              : out std_logic_vector(103 downto 0);
      idm_valid                : out std_logic;
      idm_ready                : in  std_logic;
      idm_status               : in  std_logic_vector(7 downto 0);
      idm_status_valid         : in  std_logic;
      idm_status_ready         : out std_logic;
      idm2_command : out std_logic_vector(103 downto 0);
      idm2_valid   : out std_logic;
      idm2_ready   : in  std_logic;
      idm2_status  : in std_logic_vector(7 downto 0);
      idm2_status_valid : in std_logic;
      idm2_status_ready : out std_logic;
      odm_command              : out std_logic_vector(103 downto 0);
      odm_valid                : out std_logic;
      odm_ready                : in  std_logic;
      odm_status               : in  std_logic_vector(7 downto 0);
      odm_status_valid         : in  std_logic;
      odm_status_ready         : out std_logic;
      odm2_command              : out std_logic_vector(103 downto 0);
      odm2_valid                : out std_logic;
      odm2_ready                : in  std_logic;
      odm2_status               : in  std_logic_vector(7 downto 0);
      odm2_status_valid         : in  std_logic;
      odm2_status_ready         : out std_logic;
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
      rescale_enable : out std_logic;
      rescale_fcount1 : out std_logic_vector(15 downto 0);
      rescale_fcount2 : out std_logic_vector(15 downto 0);
      output2_enable           : out std_logic;
      access_error             : out std_logic_vector(51 downto 0);
      clear_error              : in  std_logic);
  end component dpu_ctrl_wrs;

  signal iudm_command             : std_logic_vector(103 downto 0);
  signal iudm_valid               : std_logic;
  signal iudm_ready               : std_logic;
  signal iudm_status              : std_logic_vector(7 downto 0);
  signal iudm_status_valid        : std_logic;
  signal iudm_status_ready        : std_logic;
  signal iudm_data                : std_logic_vector(31 downto 0);
  signal iudm_data_valid          : std_logic;
  signal iudm_data_ready          : std_logic;
  signal iudm_data_last           : std_logic;
  signal wdm_command              : std_logic_vector(103 downto 0);
  signal wdm_valid                : std_logic;
  signal wdm_ready                : std_logic;
  signal wdm_status               : std_logic_vector(7 downto 0);
  signal wdm_status_valid         : std_logic;
  signal wdm_status_ready         : std_logic;
  signal wdm_data_last            : std_logic;
  signal idm_command              : std_logic_vector(103 downto 0);
  signal idm_valid                : std_logic;
  signal idm_ready                : std_logic;
  signal idm_status               : std_logic_vector(7 downto 0);
  signal idm_status_valid         : std_logic;
  signal idm_status_ready         : std_logic;
  signal idm2_command              : std_logic_vector(103 downto 0);
  signal idm2_valid                : std_logic;
  signal idm2_ready                : std_logic;
  signal idm2_status               : std_logic_vector(7 downto 0);
  signal idm2_status_valid         : std_logic;
  signal idm2_status_ready         : std_logic;
  signal odm_command              : std_logic_vector(103 downto 0);
  signal odm_valid                : std_logic;
  signal odm_ready                : std_logic;
  signal odm_status               : std_logic_vector(7 downto 0);
  signal odm_status_valid         : std_logic;
  signal odm_status_ready         : std_logic;
  signal odm2_command              : std_logic_vector(103 downto 0);
  signal odm2_valid                : std_logic;
  signal odm2_ready                : std_logic;
  signal odm2_status               : std_logic_vector(7 downto 0);
  signal odm2_status_valid         : std_logic;
  signal odm2_status_ready         : std_logic;

  signal rstn : std_logic;
  signal s2mm_tkeep : std_logic_vector(0 downto 0);
  signal s2mm_tlast : std_logic;

  signal weight_data : std_logic_vector(weight_width-1 downto 0);
  signal weight_valid,weight_ready : std_logic;
  signal number_of_features_i : std_logic_vector(11 downto 0);
  signal weight_id_i : unsigned(7 downto 0);
  signal weight_count : unsigned(11 downto 0);


  signal rescale_enable : std_logic;
  signal rescale_fcount1 : std_logic_vector(15 downto 0);
  signal rescale_fcount2 : std_logic_vector(15 downto 0);

  signal feature1_stream : std_logic_vector(feature_width-1 downto 0);
  signal feature1_valid : std_logic;
  signal feature1_ready : std_logic;
  signal feature2_stream : std_logic_vector(feature_width-1 downto 0);
  signal feature2_valid : std_logic;
  signal feature2_ready : std_logic;
  signal feature2rs_stream : std_logic_vector(feature_width-1 downto 0);
  signal feature2rs_valid : std_logic;
  signal feature2rs_ready : std_logic;


  signal f1count,f2count : unsigned(15 downto 0):=(others => '0');
  signal fstream_select : std_logic := '0';
  
 COMPONENT axi_datamover_wdm
  PORT (
    m_axi_mm2s_aclk : IN STD_LOGIC;
    m_axi_mm2s_aresetn : IN STD_LOGIC;
    mm2s_err : OUT STD_LOGIC;
    m_axis_mm2s_cmdsts_aclk : IN STD_LOGIC;
    m_axis_mm2s_cmdsts_aresetn : IN STD_LOGIC;
    s_axis_mm2s_cmd_tvalid : IN STD_LOGIC;
    s_axis_mm2s_cmd_tready : OUT STD_LOGIC;
    s_axis_mm2s_cmd_tdata : IN STD_LOGIC_VECTOR(103 DOWNTO 0);
    m_axis_mm2s_sts_tvalid : OUT STD_LOGIC;
    m_axis_mm2s_sts_tready : IN STD_LOGIC;
    m_axis_mm2s_sts_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_mm2s_sts_tkeep : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axis_mm2s_sts_tlast : OUT STD_LOGIC;
    m_axi_mm2s_arid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_mm2s_araddr : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axi_mm2s_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axi_mm2s_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_mm2s_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_mm2s_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_mm2s_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_mm2s_aruser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_mm2s_arvalid : OUT STD_LOGIC;
    m_axi_mm2s_arready : IN STD_LOGIC;
    m_axi_mm2s_rdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    m_axi_mm2s_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_mm2s_rlast : IN STD_LOGIC;
    m_axi_mm2s_rvalid : IN STD_LOGIC;
    m_axi_mm2s_rready : OUT STD_LOGIC;
    m_axis_mm2s_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    m_axis_mm2s_tkeep : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axis_mm2s_tlast : OUT STD_LOGIC;
    m_axis_mm2s_tvalid : OUT STD_LOGIC;
    m_axis_mm2s_tready : IN STD_LOGIC
  );
END COMPONENT;

COMPONENT axi_datamover_iudm
  PORT (
    m_axi_mm2s_aclk : IN STD_LOGIC;
    m_axi_mm2s_aresetn : IN STD_LOGIC;
    mm2s_err : OUT STD_LOGIC;
    m_axis_mm2s_cmdsts_aclk : IN STD_LOGIC;
    m_axis_mm2s_cmdsts_aresetn : IN STD_LOGIC;
    s_axis_mm2s_cmd_tvalid : IN STD_LOGIC;
    s_axis_mm2s_cmd_tready : OUT STD_LOGIC;
    s_axis_mm2s_cmd_tdata : IN STD_LOGIC_VECTOR(103 DOWNTO 0);
    m_axis_mm2s_sts_tvalid : OUT STD_LOGIC;
    m_axis_mm2s_sts_tready : IN STD_LOGIC;
    m_axis_mm2s_sts_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_mm2s_sts_tkeep : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axis_mm2s_sts_tlast : OUT STD_LOGIC;
    m_axi_mm2s_arid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_mm2s_araddr : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axi_mm2s_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axi_mm2s_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_mm2s_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_mm2s_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_mm2s_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_mm2s_aruser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_mm2s_arvalid : OUT STD_LOGIC;
    m_axi_mm2s_arready : IN STD_LOGIC;
    m_axi_mm2s_rdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    m_axi_mm2s_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_mm2s_rlast : IN STD_LOGIC;
    m_axi_mm2s_rvalid : IN STD_LOGIC;
    m_axi_mm2s_rready : OUT STD_LOGIC;
    m_axis_mm2s_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_mm2s_tkeep : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axis_mm2s_tlast : OUT STD_LOGIC;
    m_axis_mm2s_tvalid : OUT STD_LOGIC;
    m_axis_mm2s_tready : IN STD_LOGIC
  );
END COMPONENT;
  COMPONENT axi_datamover_idm
  PORT (
    m_axi_mm2s_aclk : IN STD_LOGIC;
    m_axi_mm2s_aresetn : IN STD_LOGIC;
    mm2s_err : OUT STD_LOGIC;
    m_axis_mm2s_cmdsts_aclk : IN STD_LOGIC;
    m_axis_mm2s_cmdsts_aresetn : IN STD_LOGIC;
    s_axis_mm2s_cmd_tvalid : IN STD_LOGIC;
    s_axis_mm2s_cmd_tready : OUT STD_LOGIC;
    s_axis_mm2s_cmd_tdata : IN STD_LOGIC_VECTOR(103 DOWNTO 0);
    m_axis_mm2s_sts_tvalid : OUT STD_LOGIC;
    m_axis_mm2s_sts_tready : IN STD_LOGIC;
    m_axis_mm2s_sts_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_mm2s_sts_tkeep : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axis_mm2s_sts_tlast : OUT STD_LOGIC;
    m_axi_mm2s_arid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_mm2s_araddr : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axi_mm2s_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axi_mm2s_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_mm2s_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_mm2s_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_mm2s_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_mm2s_aruser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_mm2s_arvalid : OUT STD_LOGIC;
    m_axi_mm2s_arready : IN STD_LOGIC;
    m_axi_mm2s_rdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    m_axi_mm2s_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_mm2s_rlast : IN STD_LOGIC;
    m_axi_mm2s_rvalid : IN STD_LOGIC;
    m_axi_mm2s_rready : OUT STD_LOGIC;
    m_axis_mm2s_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_mm2s_tkeep : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axis_mm2s_tlast : OUT STD_LOGIC;
    m_axis_mm2s_tvalid : OUT STD_LOGIC;
    m_axis_mm2s_tready : IN STD_LOGIC
  );
END COMPONENT;

COMPONENT axi_datamover_odm
  PORT (
    m_axi_s2mm_aclk : IN STD_LOGIC;
    m_axi_s2mm_aresetn : IN STD_LOGIC;
    s2mm_err : OUT STD_LOGIC;
    m_axis_s2mm_cmdsts_awclk : IN STD_LOGIC;
    m_axis_s2mm_cmdsts_aresetn : IN STD_LOGIC;
    s_axis_s2mm_cmd_tvalid : IN STD_LOGIC;
    s_axis_s2mm_cmd_tready : OUT STD_LOGIC;
    s_axis_s2mm_cmd_tdata : IN STD_LOGIC_VECTOR(103 DOWNTO 0);
    m_axis_s2mm_sts_tvalid : OUT STD_LOGIC;
    m_axis_s2mm_sts_tready : IN STD_LOGIC;
    m_axis_s2mm_sts_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_s2mm_sts_tkeep : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axis_s2mm_sts_tlast : OUT STD_LOGIC;
    m_axi_s2mm_awid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_s2mm_awaddr : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axi_s2mm_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axi_s2mm_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_s2mm_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_s2mm_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_s2mm_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_s2mm_awuser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_s2mm_awvalid : OUT STD_LOGIC;
    m_axi_s2mm_awready : IN STD_LOGIC;
    m_axi_s2mm_wdata : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    m_axi_s2mm_wstrb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axi_s2mm_wlast : OUT STD_LOGIC;
    m_axi_s2mm_wvalid : OUT STD_LOGIC;
    m_axi_s2mm_wready : IN STD_LOGIC;
    m_axi_s2mm_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_s2mm_bvalid : IN STD_LOGIC;
    m_axi_s2mm_bready : OUT STD_LOGIC;
    s_axis_s2mm_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axis_s2mm_tkeep : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    s_axis_s2mm_tlast : IN STD_LOGIC;
    s_axis_s2mm_tvalid : IN STD_LOGIC;
    s_axis_s2mm_tready : OUT STD_LOGIC
  );
END COMPONENT;


COMPONENT axi_crossbar_1
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axi_awid : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    s_axi_awaddr : IN STD_LOGIC_VECTOR(383 DOWNTO 0);
    s_axi_awlen : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    s_axi_awsize : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    s_axi_awburst : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    s_axi_awlock : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_awcache : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    s_axi_awprot : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    s_axi_awqos : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    s_axi_awvalid : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_awready : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_wdata : IN STD_LOGIC_VECTOR(3071 DOWNTO 0);
    s_axi_wstrb : IN STD_LOGIC_VECTOR(383 DOWNTO 0);
    s_axi_wlast : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_wvalid : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_wready : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_bid : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    s_axi_bresp : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
    s_axi_bvalid : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_bready : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_arid : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    s_axi_araddr : IN STD_LOGIC_VECTOR(383 DOWNTO 0);
    s_axi_arlen : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    s_axi_arsize : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    s_axi_arburst : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    s_axi_arlock : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_arcache : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    s_axi_arprot : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    s_axi_arqos : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    s_axi_arvalid : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_arready : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_rid : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    s_axi_rdata : OUT STD_LOGIC_VECTOR(3071 DOWNTO 0);
    s_axi_rresp : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
    s_axi_rlast : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_rvalid : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    s_axi_rready : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
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
    m_axi_rready : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END COMPONENT;

COMPONENT fifo_generator_0
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
    full : OUT STD_LOGIC;
     almost_full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    data_count : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
    wr_rst_busy : OUT STD_LOGIC;
    rd_rst_busy : OUT STD_LOGIC
  );
END COMPONENT;

signal s_axi_awid     : STD_LOGIC_VECTOR(35 DOWNTO 0) := (others => '0');
signal s_axi_awaddr   : STD_LOGIC_VECTOR(383 DOWNTO 0) := (others => '0');
signal s_axi_awlen    : STD_LOGIC_VECTOR(47 DOWNTO 0) := (others => '0');
signal s_axi_awsize   : STD_LOGIC_VECTOR(17 DOWNTO 0) := (others => '0');
signal s_axi_awburst  : STD_LOGIC_VECTOR(11 DOWNTO 0) := (others => '0');
signal s_axi_awlock   : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_awcache  : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');
signal s_axi_awprot   : STD_LOGIC_VECTOR(17 DOWNTO 0) := (others => '0');
signal s_axi_awqos    : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');
signal s_axi_awvalid  : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_awready  : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_wdata    : STD_LOGIC_VECTOR(3071 DOWNTO 0) := (others => '0');
signal s_axi_wstrb    : STD_LOGIC_VECTOR(383 DOWNTO 0) := (others => '0');
signal s_axi_wlast    : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_wvalid   : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_wready   : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_bid      : STD_LOGIC_VECTOR(35 DOWNTO 0) := (others => '0');
signal s_axi_bresp    : STD_LOGIC_VECTOR(11 DOWNTO 0) := (others => '0');
signal s_axi_bvalid   : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_bready   : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_arid     : STD_LOGIC_VECTOR(35 DOWNTO 0) := (others => '0');
signal s_axi_araddr   : STD_LOGIC_VECTOR(383 DOWNTO 0) := (others => '0');
signal s_axi_arlen    : STD_LOGIC_VECTOR(47 DOWNTO 0) := (others => '0');
signal s_axi_arsize   : STD_LOGIC_VECTOR(17 DOWNTO 0) := (others => '0');
signal s_axi_arburst  : STD_LOGIC_VECTOR(11 DOWNTO 0) := (others => '0');
signal s_axi_arlock   : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_arcache  : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');
signal s_axi_arprot   : STD_LOGIC_VECTOR(17 DOWNTO 0) := (others => '0');
signal s_axi_arqos    : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');
signal s_axi_arvalid  : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_arready  : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_rid      : STD_LOGIC_VECTOR(35 DOWNTO 0) := (others => '0');
signal s_axi_rdata    : STD_LOGIC_VECTOR(3071 DOWNTO 0) := (others => '0');
signal s_axi_rresp    : STD_LOGIC_VECTOR(11 DOWNTO 0) := (others => '0');
signal s_axi_rlast    : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_rvalid   : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
signal s_axi_rready   : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');



signal din         : STD_LOGIC_VECTOR(17 DOWNTO 0);
signal wr_en       : STD_LOGIC;
signal rd_en       : STD_LOGIC;
signal dout        : STD_LOGIC_VECTOR(17 DOWNTO 0);
signal full        : STD_LOGIC;
signal almost_full     : STD_LOGIC;
signal empty       : STD_LOGIC;
signal data_count  : STD_LOGIC_VECTOR(10 DOWNTO 0);
signal wr_rst_busy : STD_LOGIC;
signal rd_rst_busy : STD_LOGIC;

signal rd_weights       : STD_LOGIC;


component rescale_2x2x256x13 is
  port (
    clk            : in  std_logic;
    rst            : in  std_logic;
    feature_stream : in  std_logic_vector(feature_width-1 downto 0);
    feature_valid  : in  std_logic;
    feature_ready  : out std_logic;
    rs_stream      : out std_logic_vector(feature_width-1 downto 0);
    rs_valid       : out std_logic;
    rs_ready       : in  std_logic);
end component rescale_2x2x256x13;

begin

  dpu_ctrl_1: dpu_ctrl_wrs
    port map (
      clk                      => clk,
      rst                      => rst,
      start_addr               => start_addr,
      start_addr_valid         => start_addr_valid,
      iudm_command             => iudm_command,
      iudm_valid               => iudm_valid,
      iudm_ready               => iudm_ready,
      iudm_status              => iudm_status,
      iudm_status_valid        => iudm_status_valid,
      iudm_status_ready        => iudm_status_ready,
      iudm_data                => iudm_data,
      iudm_data_valid          => iudm_data_valid,
      iudm_data_ready          => iudm_data_ready,
      iudm_data_last           => iudm_data_last,
      wdm_command              => wdm_command,
      wdm_valid                => wdm_valid,
      wdm_ready                => wdm_ready,
      wdm_status               => wdm_status,
      wdm_status_valid         => wdm_status_valid,
      wdm_status_ready         => wdm_status_ready,
      wdm_data_last            => wdm_data_last,
      idm_command              => idm_command,
      idm_valid                => idm_valid,
      idm_ready                => idm_ready,
      idm_status               => idm_status,
      idm_status_valid         => idm_status_valid,
      idm_status_ready         => idm_status_ready,
      idm2_command              => idm2_command,
      idm2_valid                => idm2_valid,
      idm2_ready                => idm2_ready,
      idm2_status               => idm2_status,
      idm2_status_valid         => idm2_status_valid,
      idm2_status_ready         => idm2_status_ready,
      odm_command              => odm_command,
      odm_valid                => odm_valid,
      odm_ready                => odm_ready,
      odm_status               => odm_status,
      odm_status_valid         => odm_status_valid,
      odm_status_ready         => odm_status_ready,
      odm2_command              => odm2_command,
      odm2_valid                => odm2_valid,
      odm2_ready                => odm2_ready,
      odm2_status               => odm2_status,
      odm2_status_valid         => odm2_status_valid,
      odm2_status_ready         => odm2_status_ready,
      relu                     => relu,
      conv_3x3                 => conv_3x3,
      use_maxpool              => use_maxpool,
      feature_image_width      => feature_image_width,
      number_of_features       => number_of_features_i,
      stride2                  => stride2,
      mp_feature_image_width   => mp_feature_image_width,
      mp_number_of_features    => mp_number_of_features,
      number_of_active_neurons => number_of_active_neurons,
      throttle_rate            => throttle_rate,
      rescale_enable           => rescale_enable,
      rescale_fcount1          => rescale_fcount1,
      rescale_fcount2          => rescale_fcount2,
      output2_enable           => output2_enable,
      access_error             => access_error,
      clear_error              => clear_error);

  rstn <= not rst;
  number_of_features <= number_of_features_i;

  iudm0 : axi_datamover_iudm
  PORT MAP (
    m_axi_mm2s_aclk => clk,
    m_axi_mm2s_aresetn => rstn,
    mm2s_err => open,
    m_axis_mm2s_cmdsts_aclk => clk,
    m_axis_mm2s_cmdsts_aresetn => rstn,
    s_axis_mm2s_cmd_tvalid => iudm_valid,
    s_axis_mm2s_cmd_tready => iudm_ready,
    s_axis_mm2s_cmd_tdata => iudm_command,
    m_axis_mm2s_sts_tvalid => iudm_status_valid,
    m_axis_mm2s_sts_tready => iudm_status_ready,
    m_axis_mm2s_sts_tdata => iudm_status,
    m_axis_mm2s_sts_tkeep => open,
    m_axis_mm2s_sts_tlast => open,
    m_axi_mm2s_arid => s_axi_arid(3 downto 0),
    m_axi_mm2s_araddr => s_axi_araddr(63 downto 0),
    m_axi_mm2s_arlen => s_axi_arlen(7 downto 0),
    m_axi_mm2s_arsize => s_axi_arsize(2 downto 0),
    m_axi_mm2s_arburst => s_axi_arburst(1 downto 0),
    m_axi_mm2s_arprot => s_axi_arprot(2 downto 0),
    m_axi_mm2s_arcache => s_axi_arcache(3 downto 0),
    m_axi_mm2s_aruser => open,
    m_axi_mm2s_arvalid => s_axi_arvalid(0),
    m_axi_mm2s_arready => s_axi_arready(0),
    m_axi_mm2s_rdata => s_axi_rdata(511 downto 0),
    m_axi_mm2s_rresp => s_axi_rresp(1 downto 0),
    m_axi_mm2s_rlast => s_axi_rlast(0),
    m_axi_mm2s_rvalid => s_axi_rvalid(0),
    m_axi_mm2s_rready => s_axi_rready(0),
    m_axis_mm2s_tdata => iudm_data,
    m_axis_mm2s_tkeep => open,
    m_axis_mm2s_tlast => iudm_data_last,
    m_axis_mm2s_tvalid => iudm_data_valid,
    m_axis_mm2s_tready => iudm_data_ready
  );



  wdm0 : axi_datamover_wdm
  PORT MAP (
    m_axi_mm2s_aclk => clk,
    m_axi_mm2s_aresetn => rstn,
    mm2s_err => open,
    m_axis_mm2s_cmdsts_aclk => clk,
    m_axis_mm2s_cmdsts_aresetn => rstn,
    s_axis_mm2s_cmd_tvalid => wdm_valid,
    s_axis_mm2s_cmd_tready => wdm_ready,
    s_axis_mm2s_cmd_tdata => wdm_command,
    m_axis_mm2s_sts_tvalid => wdm_status_valid,
    m_axis_mm2s_sts_tready => wdm_status_ready,
    m_axis_mm2s_sts_tdata => wdm_status,
    m_axis_mm2s_sts_tkeep => open,
    m_axis_mm2s_sts_tlast => open,
    m_axi_mm2s_arid => s_axi_arid(6+3 downto 6+0),
    m_axi_mm2s_araddr => s_axi_araddr(64+63 downto 64+0),
    m_axi_mm2s_arlen => s_axi_arlen(8+7 downto 8+0),
    m_axi_mm2s_arsize => s_axi_arsize(3+2 downto 3+0),
    m_axi_mm2s_arburst => s_axi_arburst(2+1 downto 2+0),
    m_axi_mm2s_arprot => s_axi_arprot(3+2 downto 3+0),
    m_axi_mm2s_arcache => s_axi_arcache(4+3 downto 4+0),
    m_axi_mm2s_aruser => open,
    m_axi_mm2s_arvalid => s_axi_arvalid(1),
    m_axi_mm2s_arready => s_axi_arready(1),
    m_axi_mm2s_rdata => s_axi_rdata(512+511 downto 512+0),
    m_axi_mm2s_rresp => s_axi_rresp(2+1 downto 2+0),
    m_axi_mm2s_rlast => s_axi_rlast(1),
    m_axi_mm2s_rvalid => s_axi_rvalid(1),
    m_axi_mm2s_rready => s_axi_rready(1),
    m_axis_mm2s_tdata => weight_data,
    m_axis_mm2s_tkeep => open,
    m_axis_mm2s_tlast => wdm_data_last,
    m_axis_mm2s_tvalid => weight_valid,
    m_axis_mm2s_tready => weight_ready
  );


  din(weight_width-1 downto 0) <= weight_data(weight_width-1 downto 0);
  wr_en <= weight_valid and weight_ready;
  weight_ready <= not (almost_full or full);

  
    
  fifo_generator_0_1: fifo_generator_0
    port map (
      clk         => clk,
      srst        => rst,
      din         => din,
      wr_en       => wr_en,
      rd_en       => rd_en,
      dout        => dout,
      full        => full,
      almost_full => almost_full,
      empty       => empty,
      data_count  => data_count,
      wr_rst_busy => wr_rst_busy,
      rd_rst_busy => rd_rst_busy);


  weight_stream <= dout(weight_width-1 downto 0);
  weight_id <= std_logic_vector(weight_id_i);
  rd_en <= rd_weights;
  
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rd_weights <= '0';
        weight_id_i <= (others => '0');
        weight_count <= (others => '0');
        weight_first <= '0';
        weight_last <= '0';
      else
        weight_last <= '0';
        if wdm_valid = '1' then
          weight_id_i <= (others => '0');
          weight_count <= (others => '0');
        end if;
          
        if rd_weights = '0' then
          if empty = '0' and to_integer(unsigned(data_count)) > to_integer(unsigned(number_of_features_i)) then
            rd_weights <= '1';
            weight_first <= '1';
          end if;
        else
          weight_first <= '0';
          if to_integer(weight_count) = to_integer(unsigned(number_of_features_i)) then
            rd_weights <= '0';
            weight_count <= (others => '0');
            weight_id_i <= weight_id_i+1;
          else
            weight_count <= weight_count+1;
          end if;
          if to_integer(weight_count) = to_integer(unsigned(number_of_features_i))-1 then
            weight_last <= '1';
          end if;
        end if;
      end if;    
            
          
        
    end if;
  end process;

  

  idm0: axi_datamover_idm
  PORT MAP (
    m_axi_mm2s_aclk => clk,
    m_axi_mm2s_aresetn => rstn,
    mm2s_err => open,
    m_axis_mm2s_cmdsts_aclk => clk,
    m_axis_mm2s_cmdsts_aresetn => rstn,
    s_axis_mm2s_cmd_tvalid => idm_valid,
    s_axis_mm2s_cmd_tready => idm_ready,
    s_axis_mm2s_cmd_tdata => idm_command,
    m_axis_mm2s_sts_tvalid => idm_status_valid,
    m_axis_mm2s_sts_tready => idm_status_ready,
    m_axis_mm2s_sts_tdata => idm_status,
    m_axis_mm2s_sts_tkeep => open,
    m_axis_mm2s_sts_tlast => open,
    m_axi_mm2s_arid => s_axi_arid(12+3 downto 12+0),
    m_axi_mm2s_araddr => s_axi_araddr(128+63 downto 128+0),
    m_axi_mm2s_arlen => s_axi_arlen(16+7 downto 16+0),
    m_axi_mm2s_arsize => s_axi_arsize(6+2 downto 6+0),
    m_axi_mm2s_arburst => s_axi_arburst(4+1 downto 4+0),
    m_axi_mm2s_arprot => s_axi_arprot(6+2 downto 6+0),
    m_axi_mm2s_arcache => s_axi_arcache(8+3 downto 8+0),
    m_axi_mm2s_aruser => open,
    m_axi_mm2s_arvalid => s_axi_arvalid(2),
    m_axi_mm2s_arready => s_axi_arready(2),
    m_axi_mm2s_rdata => s_axi_rdata(1024+511 downto 1024+0),
    m_axi_mm2s_rresp => s_axi_rresp(4+1 downto 4+0),
    m_axi_mm2s_rlast => s_axi_rlast(2),
    m_axi_mm2s_rvalid => s_axi_rvalid(2),
    m_axi_mm2s_rready => s_axi_rready(2),
    m_axis_mm2s_tdata => feature1_stream,
    m_axis_mm2s_tkeep => open,
    m_axis_mm2s_tlast => open,
    m_axis_mm2s_tvalid => feature1_valid,
    m_axis_mm2s_tready => feature1_ready
  );

  odm0 : axi_datamover_odm
  PORT MAP (
    m_axi_s2mm_aclk => clk,
    m_axi_s2mm_aresetn => rstn,
    s2mm_err => open,
    m_axis_s2mm_cmdsts_awclk => clk,
    m_axis_s2mm_cmdsts_aresetn => rstn,
    s_axis_s2mm_cmd_tvalid => odm_valid,
    s_axis_s2mm_cmd_tready => odm_ready,
    s_axis_s2mm_cmd_tdata => odm_command,
    m_axis_s2mm_sts_tvalid => odm_status_valid,
    m_axis_s2mm_sts_tready => odm_status_ready,
    m_axis_s2mm_sts_tdata => odm_status,
    m_axis_s2mm_sts_tkeep => open,
    m_axis_s2mm_sts_tlast => open,
    m_axi_s2mm_awid => s_axi_awid(18+3 downto 18),
    m_axi_s2mm_awaddr => s_axi_awaddr(192+63 downto 192+0),
    m_axi_s2mm_awlen => s_axi_awlen(24+7 downto 24),
    m_axi_s2mm_awsize => s_axi_awsize(9+2 downto 9),
    m_axi_s2mm_awburst => s_axi_awburst(6+1 downto 6),
    m_axi_s2mm_awprot => s_axi_awprot(9+2 downto 9),
    m_axi_s2mm_awcache => s_axi_awcache(12+3 downto 12),
    m_axi_s2mm_awuser => open,
    m_axi_s2mm_awvalid => s_axi_awvalid(3),
    m_axi_s2mm_awready => s_axi_awready(3),
    m_axi_s2mm_wdata => s_axi_wdata(3*512+511 downto 3*512),
    m_axi_s2mm_wstrb => s_axi_wstrb(3*64+63 downto 3*64),
    m_axi_s2mm_wlast => s_axi_wlast(3),
    m_axi_s2mm_wvalid => s_axi_wvalid(3),
    m_axi_s2mm_wready => s_axi_wready(3),
    m_axi_s2mm_bresp => s_axi_bresp(6+1 downto 6),
    m_axi_s2mm_bvalid => s_axi_bvalid(3),
    m_axi_s2mm_bready => s_axi_bready(3),
    s_axis_s2mm_tdata => output_stream,
    s_axis_s2mm_tkeep => s2mm_tkeep,
    s_axis_s2mm_tlast => s2mm_tlast,
    s_axis_s2mm_tvalid => output_valid,
    s_axis_s2mm_tready => output_ready
  );

  s2mm_tkeep <= "1";
  s2mm_tlast <= '0';



  odm1 : axi_datamover_odm
  PORT MAP (
    m_axi_s2mm_aclk => clk,
    m_axi_s2mm_aresetn => rstn,
    s2mm_err => open,
    m_axis_s2mm_cmdsts_awclk => clk,
    m_axis_s2mm_cmdsts_aresetn => rstn,
    s_axis_s2mm_cmd_tvalid => odm2_valid,
    s_axis_s2mm_cmd_tready => odm2_ready,
    s_axis_s2mm_cmd_tdata => odm2_command,
    m_axis_s2mm_sts_tvalid => odm2_status_valid,
    m_axis_s2mm_sts_tready => odm2_status_ready,
    m_axis_s2mm_sts_tdata => odm2_status,
    m_axis_s2mm_sts_tkeep => open,
    m_axis_s2mm_sts_tlast => open,
    m_axi_s2mm_awid => s_axi_awid(30+3 downto 30),
    m_axi_s2mm_awaddr => s_axi_awaddr(5*64+63 downto 5*64+0),
    m_axi_s2mm_awlen => s_axi_awlen(40+7 downto 40),
    m_axi_s2mm_awsize => s_axi_awsize(15+2 downto 15),
    m_axi_s2mm_awburst => s_axi_awburst(10+1 downto 10),
    m_axi_s2mm_awprot => s_axi_awprot(15+2 downto 15),
    m_axi_s2mm_awcache => s_axi_awcache(20+3 downto 20),
    m_axi_s2mm_awuser => open,
    m_axi_s2mm_awvalid => s_axi_awvalid(5),
    m_axi_s2mm_awready => s_axi_awready(5),
    m_axi_s2mm_wdata => s_axi_wdata(5*512+511 downto 5*512),
    m_axi_s2mm_wstrb => s_axi_wstrb(5*64+63 downto 5*64),
    m_axi_s2mm_wlast => s_axi_wlast(5),
    m_axi_s2mm_wvalid => s_axi_wvalid(5),
    m_axi_s2mm_wready => s_axi_wready(5),
    m_axi_s2mm_bresp => s_axi_bresp(10+1 downto 10),
    m_axi_s2mm_bvalid => s_axi_bvalid(5),
    m_axi_s2mm_bready => s_axi_bready(5),
    s_axis_s2mm_tdata => output2_stream,
    s_axis_s2mm_tkeep => s2mm_tkeep,
    s_axis_s2mm_tlast => s2mm_tlast,
    s_axis_s2mm_tvalid => output2_valid,
    s_axis_s2mm_tready => output2_ready
  );

  s2mm_tkeep <= "1";
  s2mm_tlast <= '0';

  
  xbar0 : axi_crossbar_1
  PORT MAP (
    aclk => clk,
    aresetn => rstn,
    s_axi_awid => s_axi_awid,
    s_axi_awaddr => s_axi_awaddr,
    s_axi_awlen => s_axi_awlen,
    s_axi_awsize => s_axi_awsize,
    s_axi_awburst => s_axi_awburst,
    s_axi_awlock => s_axi_awlock,
    s_axi_awcache => s_axi_awcache,
    s_axi_awprot => s_axi_awprot,
    s_axi_awqos => s_axi_awqos,
    s_axi_awvalid => s_axi_awvalid,
    s_axi_awready => s_axi_awready,
    s_axi_wdata => s_axi_wdata,
    s_axi_wstrb => s_axi_wstrb,
    s_axi_wlast => s_axi_wlast,
    s_axi_wvalid => s_axi_wvalid,
    s_axi_wready => s_axi_wready,
    s_axi_bid => s_axi_bid,
    s_axi_bresp => s_axi_bresp,
    s_axi_bvalid => s_axi_bvalid,
    s_axi_bready => s_axi_bready,
    s_axi_arid => s_axi_arid,
    s_axi_araddr => s_axi_araddr,
    s_axi_arlen => s_axi_arlen,
    s_axi_arsize => s_axi_arsize,
    s_axi_arburst => s_axi_arburst,
    s_axi_arlock => s_axi_arlock,
    s_axi_arcache => s_axi_arcache,
    s_axi_arprot => s_axi_arprot,
    s_axi_arqos => s_axi_arqos,
    s_axi_arvalid => s_axi_arvalid,
    s_axi_arready => s_axi_arready,
    s_axi_rid => s_axi_rid,
    s_axi_rdata => s_axi_rdata,
    s_axi_rresp => s_axi_rresp,
    s_axi_rlast => s_axi_rlast,
    s_axi_rvalid => s_axi_rvalid,
    s_axi_rready => s_axi_rready,
    m_axi_awid => m_axi_awid,
    m_axi_awaddr => m_axi_awaddr,
    m_axi_awlen => m_axi_awlen,
    m_axi_awsize => m_axi_awsize,
    m_axi_awburst => m_axi_awburst,
    m_axi_awlock => m_axi_awlock,
    m_axi_awcache => m_axi_awcache,
    m_axi_awprot => m_axi_awprot,
    m_axi_awregion => m_axi_awregion,
    m_axi_awqos => m_axi_awqos,
    m_axi_awvalid => m_axi_awvalid,
    m_axi_awready => m_axi_awready,
    m_axi_wdata => m_axi_wdata,
    m_axi_wstrb => m_axi_wstrb,
    m_axi_wlast => m_axi_wlast,
    m_axi_wvalid => m_axi_wvalid,
    m_axi_wready => m_axi_wready,
    m_axi_bid => m_axi_bid,
    m_axi_bresp => m_axi_bresp,
    m_axi_bvalid => m_axi_bvalid,
    m_axi_bready => m_axi_bready,
    m_axi_arid => m_axi_arid,
    m_axi_araddr => m_axi_araddr,
    m_axi_arlen => m_axi_arlen,
    m_axi_arsize => m_axi_arsize,
    m_axi_arburst => m_axi_arburst,
    m_axi_arlock => m_axi_arlock,
    m_axi_arcache => m_axi_arcache,
    m_axi_arprot => m_axi_arprot,
    m_axi_arregion => m_axi_arregion,
    m_axi_arqos => m_axi_arqos,
    m_axi_arvalid => m_axi_arvalid,
    m_axi_arready => m_axi_arready,
    m_axi_rid => m_axi_rid,
    m_axi_rdata => m_axi_rdata,
    m_axi_rresp => m_axi_rresp,
    m_axi_rlast => m_axi_rlast,
    m_axi_rvalid => m_axi_rvalid,
    m_axi_rready => m_axi_rready
  );
  


   idm2: axi_datamover_idm
  PORT MAP (
    m_axi_mm2s_aclk => clk,
    m_axi_mm2s_aresetn => rstn,
    mm2s_err => open,
    m_axis_mm2s_cmdsts_aclk => clk,
    m_axis_mm2s_cmdsts_aresetn => rstn,
    s_axis_mm2s_cmd_tvalid => idm2_valid,
    s_axis_mm2s_cmd_tready => idm2_ready,
    s_axis_mm2s_cmd_tdata => idm2_command,
    m_axis_mm2s_sts_tvalid => idm2_status_valid,
    m_axis_mm2s_sts_tready => idm2_status_ready,
    m_axis_mm2s_sts_tdata => idm2_status,
    m_axis_mm2s_sts_tkeep => open,
    m_axis_mm2s_sts_tlast => open,
    m_axi_mm2s_arid => s_axi_arid(24+3 downto 24+0),
    m_axi_mm2s_araddr => s_axi_araddr(256+63 downto 256+0),
    m_axi_mm2s_arlen => s_axi_arlen(32+7 downto 32+0),
    m_axi_mm2s_arsize => s_axi_arsize(12+2 downto 12+0),
    m_axi_mm2s_arburst => s_axi_arburst(8+1 downto 8+0),
    m_axi_mm2s_arprot => s_axi_arprot(12+2 downto 12+0),
    m_axi_mm2s_arcache => s_axi_arcache(16+3 downto 16+0),
    m_axi_mm2s_aruser => open,
    m_axi_mm2s_arvalid => s_axi_arvalid(4),
    m_axi_mm2s_arready => s_axi_arready(4),
    m_axi_mm2s_rdata => s_axi_rdata(2048+511 downto 2048+0),
    m_axi_mm2s_rresp => s_axi_rresp(8+1 downto 8+0),
    m_axi_mm2s_rlast => s_axi_rlast(4),
    m_axi_mm2s_rvalid => s_axi_rvalid(4),
    m_axi_mm2s_rready => s_axi_rready(4),
    m_axis_mm2s_tdata => feature2_stream,
    m_axis_mm2s_tkeep => open,
    m_axis_mm2s_tlast => open,
    m_axis_mm2s_tvalid => feature2_valid,
    m_axis_mm2s_tready => feature2_ready
  );


  -- Counter for Tensor Concatenation

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        fstream_select <= '0';
        f1count <= (others => '0');
        f2count <= (others => '0');
      else
        if rescale_enable = '0' then
          fstream_select <= '0';
          f1count <= (others => '0');
          f2count <= (others => '0');
        else
          if fstream_select = '0' then
            if feature_ready = '1' and feature1_valid = '1' then
              if f1count = unsigned(rescale_fcount1) then
                fstream_select <= '1';
                f1count <= (others => '0');
              else
                f1count <= f1count+1;
              end if;
            end if;
          else
            if feature_ready = '1' and feature2rs_valid = '1' then
              if f2count = unsigned(rescale_fcount2) then
                fstream_select <= '0';
                f2count <= (others => '0');
              else
                f2count <= f2count+1;
              end if;
            end if;
          end if;            
        end if;
      end if;
    end if;
  end process;


  -- Tensor concatenation.
  feature_stream <= feature1_stream when fstream_select = '0' else feature2rs_stream;
  feature_valid <= feature1_valid when fstream_select = '0' else feature2rs_valid;
  feature1_ready <= feature_ready and not fstream_select;
  feature2rs_ready <= feature_ready and fstream_select;
  
  rescale_2x2x256x13_1: rescale_2x2x256x13
    port map (
      clk            => clk,
      rst            => rst,
      feature_stream => feature2_stream,
      feature_valid  => feature2_valid,
      feature_ready  => feature2_ready,
      rs_stream      => feature2rs_stream,
      rs_valid       => feature2rs_valid,
      rs_ready       => feature2rs_ready);
  
end architecture;
