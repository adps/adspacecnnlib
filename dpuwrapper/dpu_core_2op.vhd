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



-- Dynamic ReLU selection

entity dpu_core_2op is
--  generic (
--    feature_width : natural := 8;
--    weight_width : natural := 8);   
  port (
    clk : in std_logic;
    rst : in std_logic;
    -- Input Data Stream
    feature_stream : in std_logic_vector(feature_width-1 downto 0);
    feature_valid  : in std_logic;
    feature_ready  : out std_logic;
    -- Output Data Stream
    output_stream  : out std_logic_vector(feature_width-1 downto 0);
    output_valid   : out std_logic;
    output_ready   : in  std_logic;
       -- Output Data Stream
    output2_stream  : out std_logic_vector(feature_width-1 downto 0);
    output2_valid   : out std_logic;
    output2_ready   : in  std_logic;
    output2_enable  : in  std_logic;
    -- Weights Configuration Stream Port
    weight_stream  : in std_logic_vector(weight_width-1 downto 0);
    weight_id      : in std_logic_vector(7 downto 0);
    weight_first   : in std_logic;
    weight_last    : in std_logic;
    -- Dynamic Configuration Parameters
    relu           : in  std_logic;
    conv_3x3       : in  std_logic;
    use_maxpool    : in  std_logic;
    feature_image_width : in std_logic_vector(13 downto 0);
    number_of_features : in std_logic_vector(11 downto 0);
    stride2        : in std_logic;
    mp_feature_image_width : in std_logic_vector(13 downto 0);
    mp_number_of_features : in std_logic_vector(11 downto 0);
    number_of_active_neurons : in std_logic_vector(9 downto 0);
    throttle_rate : in std_logic_vector(9 downto 0);
    -- Error detection
    op_overflow_detect : out std_logic
    
  );
end entity;

architecture rtl of dpu_core_2op is

  component zero_pad_dynamic is
    generic (
      stream_width : natural);
    port (
      clk              : in  std_logic;
      rst              : in  std_logic;
      image_width      : in  std_logic_vector(13 downto 0);
      number_of_features : in std_logic_vector(11 downto 0);
      stream_in        : in  std_logic_vector(stream_width-1 downto 0);
      stream_in_valid  : in  std_logic;
      stream_in_ready  : out std_logic;
      stream_out       : out std_logic_vector(stream_width-1 downto 0);
      stream_out_valid : out std_logic;
      stream_out_ready : in  std_logic);
  end component zero_pad_dynamic;

  signal feature_stream_valid_3x3, feature_stream_ready_3x3 : std_logic;
  --signal feature_stream_valid_1x1 : std_logic;
  --signal feature_stream_ready_1x1 : std_logic;
  
  signal  zp_feature_stream : std_logic_vector(feature_width-1 downto 0);
  signal  zp_feature_valid  : std_logic;
  signal  zp_feature_ready  : std_logic;


  component feature_buffer_dynamic_3x3 is
    generic (
      feature_width : natural);
    port (
      clk                 : in  std_logic;
      rst                 : in  std_logic;
      feature_image_width : in    std_logic_vector(13 downto 0);
      number_of_features  : in    std_logic_vector(11 downto 0);
      stride              : in    std_logic;
      feature_stream      : in  std_logic_vector(feature_width-1 downto 0);
      feature_valid       : in  std_logic;
      feature_ready       : out std_logic;
      mask_feature_stream : out std_logic_vector(feature_width-1 downto 0);
      mask_feature_valid  : out std_logic;
      mask_feature_ready  : in  std_logic;
      mask_feature_first  : out std_logic;
      mask_feature_last   : out std_logic);
  end component feature_buffer_dynamic_3x3;

  signal mask_feature_stream : std_logic_vector(feature_width-1 downto 0);
  signal mask_feature_valid  : std_logic;
  signal mask_feature_ready  : std_logic;
  signal mask_feature_first  : std_logic;
  signal mask_feature_last   : std_logic;


  signal feature_stream_1x1 : std_logic_vector(feature_width-1 downto 0);
  signal feature_valid_1x1  : std_logic;
  signal feature_ready_1x1  : std_logic;
  signal feature_first_1x1  : std_logic;
  signal feature_last_1x1   : std_logic;
  signal feature_count_1x1  : unsigned(11 downto 0);

  signal cnn_feature_stream : std_logic_vector(feature_width-1 downto 0);
  signal cnn_feature_valid  : std_logic;
  signal cnn_feature_ready  : std_logic;
  signal cnn_feature_first  : std_logic;
  signal cnn_feature_last   : std_logic;

  signal throttle_count : unsigned(9 downto 0);

  constant layer_size   : natural := 128;
  constant layer_size_order : natural := 8;
  constant weight_mem_order : natural := 10;
  constant output_width : natural := feature_width;
  constant output_shift : natural := 8;
  constant bias_shift : natural := 0; 

  
  component conv_neuron_layer_drl is
    generic (
      layer_size       : natural;
      layer_size_order : natural;
      feature_width    : natural;
      weight_width     : natural;
      weight_mem_order : natural;
      output_width     : natural;
      output_shift     : natural;
      bias_shift       : natural);
    port (
      clk            : in  std_logic;
      relu           : in  std_logic;
      number_of_active_neurons : in std_logic_vector(9 downto 0);
      feature_stream : in  std_logic_vector(feature_width-1 downto 0);
      feature_first  : in  std_logic;
      feature_last   : in  std_logic;
      weight_stream  : in  std_logic_vector(weight_width-1 downto 0);
      weight_id      : in  std_logic_vector(layer_size_order-1 downto 0);
      weight_first   : in  std_logic;
      weight_last    : in  std_logic;
      output_stream  : out std_logic_vector(output_width-1 downto 0);
      output_id      : out std_logic_vector(layer_size_order-1 downto 0);
      output_valid   : out std_logic);
  end component conv_neuron_layer_drl;

 
  signal cnn_output_stream  : std_logic_vector(output_width-1 downto 0);
  signal cnn_output_id      : std_logic_vector(layer_size_order-1 downto 0);
  signal cnn_output_valid   : std_logic;


  signal mpzp_stream_in        : std_logic_vector(feature_width-1 downto 0);
  signal mpzp_stream_in_valid  : std_logic;

  signal mpzp_stream_out       : std_logic_vector(feature_width-1 downto 0);

  component maxpool22_dynamic is
    generic (
      feature_width : natural);
    port (
      clk                 : in  std_logic;
      rst                 : in  std_logic;
      number_of_features  : in  std_logic_vector(11 downto 0);
      feature_image_width : in  std_logic_vector(13 downto 0);
      feature_stream      : in  std_logic_vector(feature_width-1 downto 0);
      feature_valid       : in  std_logic;
      max_feature_stream  : out std_logic_vector(feature_width-1 downto 0);
      max_feature_valid   : out std_logic);
  end component maxpool22_dynamic;
  

  signal max_feature_stream : std_logic_vector(feature_width-1 downto 0);
  signal max_feature_valid  : std_logic;

  
  signal output_valid_i : std_logic;

  signal feature_image_width_plus2 : std_logic_vector(13 downto 0);
  signal mp_feature_image_width_plus1 : std_logic_vector(13 downto 0);


  signal feature_in_count : integer := 0;
  signal zp_in_count : integer := 0;
  signal fb0_in_count : integer := 0;
  signal cnn_in_count : integer := 0;
  signal cnn_out_count : integer := 0;
  signal out_count : integer := 0;
  signal cycle : integer := 0;
  
  
begin

  process (clk)
  begin
    if rising_edge(clk) then
      feature_image_width_plus2 <= std_logic_vector((unsigned(feature_image_width) + 2));
      mp_feature_image_width_plus1 <= std_logic_vector((unsigned(mp_feature_image_width) + 1));      
    end if;
  end process;
  


  -- Select either a 3x3 conv path or a 1x1 direct connection
  
  feature_stream_valid_3x3 <= feature_valid and conv_3x3;
  feature_valid_1x1 <= feature_valid and not conv_3x3;

  feature_ready <= feature_stream_ready_3x3 when conv_3x3 = '1' else feature_ready_1x1;
  

  zero_pad_dynamic_1: zero_pad_dynamic
    generic map (
      stream_width => feature_width)
    port map (
      clk              => clk,
      rst              => rst,
      image_width      => feature_image_width,
      number_of_features  => number_of_features,
      stream_in        => feature_stream,
      stream_in_valid  => feature_stream_valid_3x3,
      stream_in_ready  => feature_stream_ready_3x3,
      stream_out       => zp_feature_stream,
      stream_out_valid => zp_feature_valid,
      stream_out_ready => zp_feature_ready);



  feature_buffer_dynamic_3x3_1: feature_buffer_dynamic_3x3
    generic map (
      feature_width => feature_width)
    port map (
      clk                 => clk,
      rst                 => rst,
      feature_image_width => feature_image_width_plus2,
      number_of_features  => number_of_features,
      stride              => stride2,
      feature_stream      => zp_feature_stream,
      feature_valid       => zp_feature_valid,
      feature_ready       => zp_feature_ready,
      mask_feature_stream => mask_feature_stream,
      mask_feature_valid  => mask_feature_valid,
      mask_feature_ready  => mask_feature_ready,
      mask_feature_first  => mask_feature_first,
      mask_feature_last   => mask_feature_last);


  -- need to add module/code for 1x1 stream setting of 1st and last
  process(clk)
  begin
    if rising_edge(clk) then
      if feature_valid_1x1 = '1' and feature_ready_1x1 = '1' then
        if feature_count_1x1 = unsigned(number_of_features)-1 then
          feature_count_1x1 <= (others => '0');
          feature_first_1x1 <= '1';
          feature_last_1x1 <= '0';
        else
          feature_first_1x1 <= '0';
          feature_count_1x1 <= feature_count_1x1+1;
          if feature_count_1x1 = unsigned(number_of_features)-2 then
            feature_last_1x1 <= '1';
          else
            feature_last_1x1 <= '0';
          end if;
        end if;
      end if;
      if rst = '1' then
        feature_first_1x1 <= '1';
        feature_last_1x1 <= '0';
        feature_count_1x1 <= (others => '0');
      end if;
    end if;
  end process;

  feature_stream_1x1 <=  feature_stream;

  -- Select  3x3 conv path or a 1x1 direct connection for CNN Layer
  cnn_feature_stream <= mask_feature_stream when conv_3x3 = '1' else feature_stream_1x1;
  cnn_feature_valid <= mask_feature_valid when conv_3x3 = '1' else feature_valid_1x1;
  cnn_feature_first <= mask_feature_first when conv_3x3 = '1' else feature_first_1x1 and feature_valid_1x1;
  cnn_feature_last <= mask_feature_last when conv_3x3 = '1' else feature_last_1x1 and feature_valid_1x1;
  mask_feature_ready <= cnn_feature_ready and conv_3x3;
  feature_ready_1x1 <= cnn_feature_ready and not conv_3x3;
  
  -- Need to throttle input to Layer if Number of Weights is low, but number of
  -- neurons is high
  -- e.g. layer 1 : 27 weights vs 32 neurons.
  -- But throttle can be set higher to compensate for MaxPool delays
  process(clk)
  begin
    if rising_edge(clk) then
      if throttle_count /= "0000000000" then
        throttle_count <= throttle_count -1;
        if cnn_feature_last = '1' then
          cnn_feature_ready <= '0';
        end if;
      else
        cnn_feature_ready <= '1';
        if cnn_feature_first = '1' and cnn_feature_valid = '1' and cnn_feature_ready = '1' then
          throttle_count <= unsigned(throttle_rate);
        end if;
      end if;
        
      
      if rst ='1' then
        throttle_count <= (others => '0');
        cnn_feature_ready <= '1';
      end if;
    end if;
  end process;  
  
  
  

  conv_neuron_layer_drl_1: conv_neuron_layer_drl
    generic map (
      layer_size       => layer_size,
      layer_size_order => layer_size_order,
      feature_width    => feature_width,
      weight_width     => weight_width,
      weight_mem_order => weight_mem_order,
      output_width     => output_width,
      output_shift     => output_shift,
      bias_shift       => bias_shift)
    port map (
      clk            => clk,
      relu           => relu,
      number_of_active_neurons => number_of_active_neurons,
      feature_stream => cnn_feature_stream,
      feature_first  => cnn_feature_first,
      feature_last   => cnn_feature_last,
      weight_stream  => weight_stream,
      weight_id      => weight_id,
      weight_first   => weight_first,
      weight_last    => weight_last,
      output_stream  => cnn_output_stream,
      output_id      => cnn_output_id,
      output_valid   => cnn_output_valid);


  mpzp_stream_in <= cnn_output_stream;
  mpzp_stream_in_valid <= cnn_output_valid and use_maxpool;


  maxpool22_dynamic_1: maxpool22_dynamic
    generic map (
      feature_width => feature_width)
    port map (
      clk                 => clk,
      rst                 => rst,
      number_of_features  => mp_number_of_features,
      feature_image_width => mp_feature_image_width,
      feature_stream      => mpzp_stream_in,
      feature_valid       => mpzp_stream_in_valid,
      max_feature_stream  => max_feature_stream,
      max_feature_valid   => max_feature_valid);
  

  output_stream <= max_feature_stream when use_maxpool = '1' else cnn_output_stream;
  output_valid_i <= max_feature_valid when use_maxpool = '1' else cnn_output_valid;

  output_valid <= output_valid_i;
  op_overflow_detect <= (output_valid_i and not output_ready) or (output2_enable and cnn_output_valid and output2_ready);
  
  output2_stream <= cnn_output_stream;
  output2_valid <= cnn_output_valid and output2_enable;
  

  -- Some Simulation Integer Signals for Debug
  process (clk)
  begin
    if rising_edge(clk) then
      cycle <= cycle+1;
      if feature_valid = '1' and ((feature_stream_ready_3x3 = '1' and conv_3x3 = '1') or (feature_ready_1x1 = '1' and not conv_3x3 = '1')) then
        feature_in_count <= feature_in_count+1;
      end if;
      if feature_stream_valid_3x3 = '1' and feature_stream_ready_3x3 = '1' then
        zp_in_count <= zp_in_count+1;
      end if;
      if zp_feature_valid = '1' and zp_feature_ready = '1' then
        fb0_in_count <= fb0_in_count+1;
      end if;
      if cnn_feature_valid = '1' and cnn_feature_ready = '1' then
        cnn_in_count <= cnn_in_count+1;
      end if;
      if use_maxpool = '1' then
        if mpzp_stream_in_valid = '1' then
          cnn_out_count <= cnn_out_count+1;
        end if;
      else
        if cnn_output_valid = '1' and output_ready = '1' then
          cnn_out_count <= cnn_out_count+1;
        end if;
      end if;
      if output_valid_i = '1' and output_ready = '1' then
        out_count <= out_count+1;
      end if;     
    end if;
  end process;

  
  
end architecture;
