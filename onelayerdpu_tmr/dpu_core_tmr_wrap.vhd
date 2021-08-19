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

library work;
use work.tmr.all;
use work.cnn_defs.all;

-- Dynamic ReLU selection

entity dpu_core_tmr_wrap is  
  port (
    clk : in std_logic;
    rst : in std_logic;
    -- Input Data Stream
    feature_stream : in std_logic_vector(feature_width-1 downto 0);
    feature_valid  : in tmr_logic;
    feature_ready  : out tmr_logic;
    -- Output Data Stream
    output_stream  : out std_logic_vector(feature_width-1 downto 0);
    output_valid   : out tmr_logic;
    output_ready   : in  tmr_logic;
    -- Weights Configuration Stream Port
    weight_stream  : in std_logic_vector(weight_width-1 downto 0);
    weight_id      : in tmr_logic_vector(7 downto 0);
    weight_first   : in tmr_logic;
    weight_last    : in tmr_logic;
    -- Dynamic Configuration Parameters
    relu           : in  tmr_logic;
    conv_3x3       : in  tmr_logic;
    use_maxpool    : in  tmr_logic;
    feature_image_width : in tmr_logic_vector(13 downto 0);
    number_of_features : in tmr_logic_vector(11 downto 0);
    stride2        : in tmr_logic;
    mp_feature_image_width : in tmr_logic_vector(13 downto 0);
    mp_number_of_features : in tmr_logic_vector(11 downto 0);
    number_of_active_neurons : in tmr_logic_vector(9 downto 0);
    throttle_rate : in tmr_logic_vector(9 downto 0);
    -- Error detection
    op_overflow_detect : out tmr_logic
    
  );
end entity;

architecture rtl of dpu_core_tmr_wrap is

  component dpu_core_tmr_flat is
    port (
      clk                      : in  std_logic;
      rst                      : in  std_logic;
      feature_stream           : in  std_logic_vector(feature_width-1 downto 0);
      feature_valid            : in  tmr_logic;
      feature_ready            : out tmr_logic;
      output_stream            : out std_logic_vector(feature_width-1 downto 0);
      output_valid             : out tmr_logic;
      output_ready             : in  tmr_logic;
      weight_stream            : in  std_logic_vector(weight_width-1 downto 0);
      weight_id                : in  std_logic_vector(3*8-1 downto 0);
      weight_first             : in  tmr_logic;
      weight_last              : in  tmr_logic;
      relu                     : in  tmr_logic;
      conv_3x3                 : in  tmr_logic;
      use_maxpool              : in  tmr_logic;
      feature_image_width      : in  std_logic_vector(3*14-1 downto 0);
      number_of_features       : in  std_logic_vector(3*12-1 downto 0);
      stride2                  : in  tmr_logic;
      mp_feature_image_width   : in  std_logic_vector(3*14-1 downto 0);
      mp_number_of_features    : in  std_logic_vector(3*12-1 downto 0);
      number_of_active_neurons : in  std_logic_vector(3*10-1 downto 0);
      throttle_rate            : in  std_logic_vector(3*10-1 downto 0);
      op_overflow_detect       : out tmr_logic);
  end component dpu_core_tmr_flat;

 
  signal weight_id_i                : std_logic_vector(23 downto 0);
  signal feature_image_width_i      : std_logic_vector(3*14-1 downto 0);
  signal number_of_features_i       : std_logic_vector(3*12-1 downto 0);
 
  signal mp_feature_image_width_i   : std_logic_vector(3*14-1 downto 0);
  signal mp_number_of_features_i    : std_logic_vector(3*12-1 downto 0);
  signal number_of_active_neurons_i : std_logic_vector(29 downto 0);
  signal throttle_rate_i            : std_logic_vector(29 downto 0);
 
  
begin



  weight_id_i <= tmr_flatten(weight_id);
  feature_image_width_i <= tmr_flatten(feature_image_width);
  number_of_features_i <= tmr_flatten(number_of_features);
  mp_feature_image_width_i <= tmr_flatten(mp_feature_image_width);
  mp_number_of_features_i <= tmr_flatten(mp_number_of_features);
  number_of_active_neurons_i <= tmr_flatten(number_of_active_neurons);
  throttle_rate_i <= tmr_flatten(throttle_rate);
  

  dpu_core_tmr_1: dpu_core_tmr_flat
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
      weight_id                => weight_id_i,
      weight_first             => weight_first,
      weight_last              => weight_last,
      relu                     => relu,
      conv_3x3                 => conv_3x3,
      use_maxpool              => use_maxpool,
      feature_image_width      => feature_image_width_i,
      number_of_features       => number_of_features_i,
      stride2                  => stride2,
      mp_feature_image_width   => mp_feature_image_width_i,
      mp_number_of_features    => mp_number_of_features_i,
      number_of_active_neurons => number_of_active_neurons_i,
      throttle_rate            => throttle_rate_i,
      op_overflow_detect       => op_overflow_detect);
  
 
 
  
end architecture;
