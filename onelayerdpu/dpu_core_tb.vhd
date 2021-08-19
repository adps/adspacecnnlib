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



-------------------------------------------------------------------------------
-- Title      : Testbench for design "dpu_core"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : dpu_core_tb.vhd
-- Author     : WINDOWS-LK2ORD6  <am@WINDOWS-LK2ORD6>
-- Company    : 
-- Created    : 2021-04-07
-- Last update: 2021-06-01
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2021 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2021-04-07  1.0      am      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.cnn_tools.all;
use work.cnn_defs.all;

use std.textio.all;

-------------------------------------------------------------------------------

entity dpu_core_tb is

end entity dpu_core_tb;

-------------------------------------------------------------------------------

architecture sim_only of dpu_core_tb is

  -- component generics
  --constant feature_width : natural := 8;
  --constant weight_width  : natural := 8;
  -- defined in cnn_tools_pkg

  -- component ports
  signal clk                      : std_logic := '1';
  signal rst                      : std_logic := '0';
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

  signal op_overflow_detect : std_logic;


  -- Enable different parts of the Simulation
  constant sim_simple32x32            : boolean := true;
  constant sim_simple32x32_conv       : boolean := true;
  constant sim_simple25x25_maxpool    : boolean := true;
  constant sim_yolov3_layer0          : boolean := false; -- cannot run in same
                                                          -- sim as xcaffe version
  constant sim_yolov3_layer0_xcaffe   : boolean := true;
  constant sim_yolov3_layer2_xcaffe   : boolean := true;
  constant sim_yolov3_layer4_xcaffe   : boolean := true;
  constant sim_yolov3_layer6_xcaffe   : boolean := true;
  constant sim_yolov3_layer8a_xcaffe  : boolean := true;  -- 1st 128 Neurons
  constant sim_yolov3_layer8b_xcaffe  : boolean := true;  -- 2nd 128 Neurons

  -- Run Layer 8 again without (layer 9) MAXPOOL to get 26x26 output for layer
  -- 19 use
  -- Inefficient solution - DPU should allow both pre and post MAXPOOL results
  -- to be recorded
  constant sim_yolov3_layer8a_nomaxp_xcaffe  : boolean := true;  -- 1st 128 Neurons
  constant sim_yolov3_layer8b_nomaxp_xcaffe  : boolean := true;  -- 2nd 128 Neurons
  
  constant sim_yolov3_layer10a_xcaffe : boolean := true;  -- 1st 128 Neurons
  constant sim_yolov3_layer10b_xcaffe : boolean := true;  -- 2nd 128 Neurons
  constant sim_yolov3_layer10c_xcaffe : boolean := true;  -- 3rd 128 Neurons
  constant sim_yolov3_layer10d_xcaffe : boolean := true;  -- 4th 128 Neurons

  constant sim_yolov3_layer11_xcaffe : boolean := true;  -- 8x128 Neurons

  constant sim_yolov3_layer12_xcaffe : boolean := true;  -- 2x128 Neurons

  constant sim_yolov3_layer13_xcaffe : boolean := true;  -- 4x128 Neurons

  constant sim_yolov3_layer14_xcaffe : boolean := true;  -- 45 Neurons

  constant sim_yolov3_layer17_xcaffe : boolean := true;  -- 128 Neurons

  constant sim_yolov3_layer1819_xcaffe : boolean := true;  -- Upsample/Concat

  constant sim_yolov3_layer20_xcaffe : boolean := true;  -- 2x128 Neurons

  constant sim_yolov3_layer21_xcaffe : boolean := true;  -- 45 Neurons

  signal sim_output           : integer := 0;
  signal merge_output_layer8  : boolean := false;
  signal merge_output_layer8_nomaxp  : boolean := false;
  signal merge_output_layer10 : boolean := false;
  signal merge_output_layer11 : std_logic_vector(7 downto 0):= (others => '0');
  signal merge_output_layer12 : std_logic_vector(1 downto 0):= (others => '0');
  signal merge_output_layer13 : std_logic_vector(3 downto 0):= (others => '0');

  signal merge_output_layer20 : std_logic_vector(1 downto 0):= (others => '0');

  constant DATA_DIR : string := "../../../../../data/";
  
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

  signal output_count : integer := 0;
  signal reset_output_count : boolean := false;
  
begin  -- architecture sim_only

  -- component instantiation
  DUT : dpu_core
--    generic map (
--      feature_width => feature_width,
--      weight_width  => weight_width)
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
      op_overflow_detect       => op_overflow_detect);


  process (clk)
  begin
    if rising_edge(clk) then
      assert op_overflow_detect = '0' report "Output Stage Overflow" severity failure;
      if reset_output_count then
        output_count <= 0;
      elsif output_valid = '1' then
        output_count <= output_count+1;
      end if;
    end if;
  end process;

  -- clock generation
  clk <= not clk after 5 ns;

  -- waveform generation
  WaveGen_Proc : process
    variable feature : unsigned(feature_width-1 downto 0) := (others => '0');
    variable weight  : unsigned(weight_width-1 downto 0)  := (others => '0');
    -- Variables for Upsample and Concat OPeration
    file upsample_input_file : text;
    file concat_input_file : text;
    file concat_output_file : text;
    type line_array is array(natural range <> ) of line;
    variable l : line;
    variable la : line_array(1 to 13*128);
    
  begin
    -- insert signal assignments here
    feature_stream           <= (others => '0');
    feature_valid            <= '0';
    output_ready             <= '1';
    weight_stream            <= (others => '0');
    weight_id                <= (others => '0');
    weight_first             <= '0';
    weight_last              <= '0';
    relu                     <= '0';
    conv_3x3                 <= '0';
    use_maxpool              <= '0';
    feature_image_width      <= (others => '1');
    number_of_features       <= (others => '1');
    stride2                  <= '0';
    mp_feature_image_width   <= (others => '1');
    mp_number_of_features    <= (others => '1');
    number_of_active_neurons <= (others => '0');
    throttle_rate            <= (others => '0');

    wait until clk = '1';

    rst <= '1';
    wait until clk = '0';
    wait for 200 ns;
    wait until clk = '1';
    rst <= '0';
----------------------------------------------------------------------------------------------------   
    wait for 200 ns;
    -- Test simple network, 32x32 image, 3 pixels deep, no conv, no maxpool, no
    -- relu, 10 neurons
----------------------------------------------------------------------------------------------------

    if sim_simple32x32 then

      relu                     <= '0';
      conv_3x3                 <= '0';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(32, 14));
      number_of_features       <= std_logic_vector(to_unsigned(3, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= (others => '1');
      mp_number_of_features    <= (others => '1');
    
      number_of_active_neurons <= std_logic_vector(to_unsigned(10, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(21, 10));

      -- Set up Weights
      wait until clk = '0';
      wait until clk = '1';

      weight := (others => '0');
      for i in 1 to 10 loop
        for j in 0 to 3 loop            -- bias + 3 weights 
          weight_stream <= std_logic_vector(weight);
          weight_id     <= std_logic_vector(to_unsigned(i, 8));
          if j = 0 then
            weight_first <= '1';
          else
            weight_first <= '0';
          end if;
          if j = 3 then
            weight_last <= '1';
          else
            weight_last <= '0';
          end if;

          wait until clk = '0';
          wait until clk = '1';
          weight := weight+1;
        end loop;
      end loop;
      weight_last <= '0';

      wait for 200ns;

      feature := (others => '0');
      for i in 0 to 31 loop
        for j in 0 to 31 loop
          for k in 0 to 2 loop
            if k = 0 then
              feature_stream <= std_logic_vector(to_unsigned(j+1, 8));
            else
              if k = 1 then
                feature_stream <= std_logic_vector(to_unsigned(i+1, 8));
              else
                feature_stream <= std_logic_vector(to_unsigned(i+j+1, 8));
              end if;
            end if;
            feature_valid <= '1';
            wait until clk = '0';
            if feature_ready = '0' then
              wait until feature_ready = '1';
            end if;
            wait until clk = '1';
            feature := feature+1;
          end loop;
        end loop;
      end loop;
      feature_valid <= '0';
      wait for 4000 ns;
      assert output_count = 32*32*10  report "Incorrect number of output data" severity failure;
      reset_output_count <= true;
      wait for 20 ns;
      reset_output_count <= false;
    end if;


    if sim_simple32x32_conv then
----------------------------------------------------------------------------------------------------
      wait for 4000 ns;
      -- Test simple network, 32x32 image, 3 pixels deep, 3x3 conv, no maxpool, no
      -- relu, 20 neurons
----------------------------------------------------------------------------------------------------
      relu                     <= '0';
      conv_3x3                 <= '1';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(32, 14));
      number_of_features       <= std_logic_vector(to_unsigned(3, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= (others => '1');
      mp_number_of_features    <= (others => '1');
  
      number_of_active_neurons <= std_logic_vector(to_unsigned(10, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(21, 10));

      -- Set up Weights
      wait until clk = '0';
      wait until clk = '1';

      weight := (others => '0');
      for i in 1 to 20 loop
        for j in 0 to 27 loop           -- bias + 3 weights 
          weight_stream <= std_logic_vector(weight);
          weight_id     <= std_logic_vector(to_unsigned(i, 8));
          if j = 0 then
            weight_first <= '1';
          else
            weight_first <= '0';
          end if;
          if j = 3 then
            weight_last <= '1';
          else
            weight_last <= '0';
          end if;

          wait until clk = '0';
          wait until clk = '1';
          weight := weight+1;
        end loop;
      end loop;
      weight_last <= '0';

      wait for 200ns;


      feature := (others => '0');
      for i in 0 to 31 loop
        for j in 0 to 31 loop
          for k in 0 to 2 loop
            if k = 0 then
              feature_stream <= std_logic_vector(to_unsigned(j+1, 8));
            else
              if k = 1 then
                feature_stream <= std_logic_vector(to_unsigned(i+1, 8));
              else
                feature_stream <= std_logic_vector(to_unsigned(85, 8));
              end if;
            end if;
            feature_valid <= '1';
            wait until clk = '0';
            if feature_ready = '0' then
              wait until feature_ready = '1';
            end if;
            wait until clk = '1';
            feature := feature+1;
          end loop;
        end loop;
      end loop;
      feature_valid <= '0';



-- Allow time for zero pad data to flush through
      wait for 50us;

      assert output_count = 32*32*20  report "Incorrect number of output data" severity failure;
      reset_output_count <= true;
      wait for 20 ns;
      reset_output_count <= false;
    end if;
    if sim_simple25x25_maxpool then


----------------------------------------------------------------------------------------------------   
      wait for 200 ns;
      -- Test simple network, 25x25 image, 8 pixels deep, no conv, maxpool
      -- enabled ,
      -- relu, 34 neurons
----------------------------------------------------------------------------------------------------
      relu                     <= '1';
      conv_3x3                 <= '0';
      use_maxpool              <= '1';
      feature_image_width      <= std_logic_vector(to_unsigned(26, 14));
      number_of_features       <= std_logic_vector(to_unsigned(8, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(26, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(34, 12));
 
      number_of_active_neurons <= std_logic_vector(to_unsigned(34, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(78, 10));

      -- Set up Weights
      wait until clk = '0';
      wait until clk = '1';

      weight := (others => '0');
      for i in 1 to 34 loop
        for j in 0 to 8 loop            -- bias + 8 weights 
          weight_stream <= std_logic_vector(weight);
          weight_id     <= std_logic_vector(to_unsigned(i, 8));
          if j = 0 then
            weight_first <= '1';
          else
            weight_first <= '0';
          end if;
          if j = 8 then
            weight_last <= '1';
          else
            weight_last <= '0';
          end if;

          wait until clk = '0';
          wait until clk = '1';
          weight := weight+1;
          if weight > 15 then
            weight := weight - i*j;
          end if;
        end loop;
      end loop;
      weight_last <= '0';

      wait for 200ns;

      feature := (others => '0');
      for i in 0 to 25 loop
        for j in 0 to 25 loop
          for k in 0 to 7 loop
            if k = 0 then
              feature_stream <= std_logic_vector(to_unsigned(j+1, 8));
            else
              if k = 1 then
                feature_stream <= std_logic_vector(to_unsigned(i+1, 8));
              else
                feature_stream <= std_logic_vector(to_unsigned(85, 8));
              end if;
            end if;
            feature_valid <= '1';
            wait until clk = '0';
            if feature_ready = '0' then
              wait until feature_ready = '1';
            end if;
            wait until clk = '1';
            feature := feature+1;
          end loop;
        end loop;
      end loop;
      feature_valid <= '0';


      wait for 250 ns;
      assert output_count = 13*13*34  report "Incorrect number of output data" severity failure;
      reset_output_count <= true;
      wait for 20 ns;
      reset_output_count <= false;
    end if;


   
    if sim_yolov3_layer0 then



      -- Read Weights from file   
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '1';
      feature_image_width      <= std_logic_vector(to_unsigned(416, 14));
      number_of_features       <= std_logic_vector(to_unsigned(3, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(416, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(16, 12));
      number_of_active_neurons <= std_logic_vector(to_unsigned(16, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(48, 10));

      -- Using Tiny Yolo V3 Model 

      read_weights_file_nobias(
        weight_filename   => DATA_DIR & "tmp_layer0-conv_filter.txt",
        weight_scaling    => 256,
        layer_size        => 16,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 3,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 5;

      read_feature_file(
        feature_filename  => DATA_DIR & "input_data416x416.txt",
        input_bias        => 128,
        input_height      => 416,
        input_width       => 416,
        input_no_features => 3,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;

    end if;

    if sim_yolov3_layer0_xcaffe then

      -- Read Weights from file  
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '1';
      feature_image_width      <= std_logic_vector(to_unsigned(416, 14));
      number_of_features       <= std_logic_vector(to_unsigned(3, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(416, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(16, 12));
     
      number_of_active_neurons <= std_logic_vector(to_unsigned(16, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(32, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   => DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer0-conv",
        scale_layer_name  => "layer0-scale",
        bn_layer_name     => "layer0-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 16,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 3,
        neuron_skip       => 0,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 5;

      read_feature_file(
        feature_filename  => DATA_DIR & "input_data416x416.txt",
        input_bias        => 128,
        input_height      => 416,
        input_width       => 416,
        input_no_features => 3,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;



    if sim_yolov3_layer2_xcaffe then

      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '1';
      feature_image_width      <= std_logic_vector(to_unsigned(208, 14));
      number_of_features       <= std_logic_vector(to_unsigned(16, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(208, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(32, 12));
   
      number_of_active_neurons <= std_logic_vector(to_unsigned(32, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(64, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   => DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer2-conv",
        scale_layer_name  => "layer2-scale",
        bn_layer_name     => "layer2-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 32,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 16,
        neuron_skip       => 0,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 6;

      read_feature_file(
        feature_filename  => "output_data2.txt",
        input_bias        => 0,
        input_height      => 208,
        input_width       => 208,
        input_no_features => 16,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;

    if sim_yolov3_layer4_xcaffe then

      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '1';
      feature_image_width      <= std_logic_vector(to_unsigned(104, 14));
      number_of_features       <= std_logic_vector(to_unsigned(32, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(104, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(64, 12));
     
      number_of_active_neurons <= std_logic_vector(to_unsigned(64, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(128, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer4-conv",
        scale_layer_name  => "layer4-scale",
        bn_layer_name     => "layer4-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 64,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 32,
        neuron_skip       => 0,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 7;

      read_feature_file(
        feature_filename  => "output_data3.txt",
        input_bias        => 0,
        input_height      => 104,
        input_width       => 104,
        input_no_features => 32,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;



    if sim_yolov3_layer6_xcaffe then

      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '1';
      feature_image_width      <= std_logic_vector(to_unsigned(52, 14));
      number_of_features       <= std_logic_vector(to_unsigned(64, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(52, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(256, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer6-conv",
        scale_layer_name  => "layer6-scale",
        bn_layer_name     => "layer6-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 64,
        neuron_skip       => 0,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 8;

      read_feature_file(
        feature_filename  => "output_data4.txt",
        input_bias        => 0,
        input_height      => 52,
        input_width       => 52,
        input_no_features => 64,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;



    if sim_yolov3_layer8a_xcaffe then
      -- Implement first 128 neurons of layer 8

      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '1';
      feature_image_width      <= std_logic_vector(to_unsigned(26, 14));
      number_of_features       <= std_logic_vector(to_unsigned(128, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(26, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
     
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(256, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer8-conv",
        scale_layer_name  => "layer8-scale",
        bn_layer_name     => "layer8-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 128,
        neuron_skip       => 0,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 9;

      read_feature_file(
        feature_filename  => "output_data5.txt",
        input_bias        => 0,
        input_height      => 26,
        input_width       => 26,
        input_no_features => 128,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;

    if sim_yolov3_layer8b_xcaffe then
      -- Implement second 128 neurons of layer 8



      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '1';
      feature_image_width      <= std_logic_vector(to_unsigned(26, 14));
      number_of_features       <= std_logic_vector(to_unsigned(128, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(26, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
      
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(256, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer8-conv",
        scale_layer_name  => "layer8-scale",
        bn_layer_name     => "layer8-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 128,
        neuron_skip       => 128,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 10;

      read_feature_file(
        feature_filename  => "output_data5.txt",
        input_bias        => 0,
        input_height      => 26,
        input_width       => 26,
        input_no_features => 128,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;


    if sim_yolov3_layer8a_nomaxp_xcaffe then
      -- Implement first 128 neurons of layer 8
      -- Output before MAX POOL

      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(26, 14));
      number_of_features       <= std_logic_vector(to_unsigned(128, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(26, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
    
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(256, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer8-conv",
        scale_layer_name  => "layer8-scale",
        bn_layer_name     => "layer8-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 128,
        neuron_skip       => 0,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 50;

      read_feature_file(
        feature_filename  => "output_data5.txt",
        input_bias        => 0,
        input_height      => 26,
        input_width       => 26,
        input_no_features => 128,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;

    if sim_yolov3_layer8b_nomaxp_xcaffe then
      -- Implement second 128 neurons of layer 8



      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(26, 14));
      number_of_features       <= std_logic_vector(to_unsigned(128, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(26, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
      
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(256, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer8-conv",
        scale_layer_name  => "layer8-scale",
        bn_layer_name     => "layer8-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 128,
        neuron_skip       => 128,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 51;

      read_feature_file(
        feature_filename  => "output_data5.txt",
        input_bias        => 0,
        input_height      => 26,
        input_width       => 26,
        input_no_features => 128,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;
    

    if sim_yolov3_layer10a_xcaffe then
      -- Implement first 128 neurons of layer 10

      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(13, 14));
      number_of_features       <= std_logic_vector(to_unsigned(256, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(13, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
     
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(256, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer10-conv",
        scale_layer_name  => "layer10-scale",
        bn_layer_name     => "layer10-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 128,
        neuron_skip       => 0,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 10;

      read_feature_file(
        feature_filename  => "output_data6.txt",
        input_bias        => 0,
        input_height      => 13,
        input_width       => 13,
        input_no_features => 256,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;

    if sim_yolov3_layer10b_xcaffe then
      -- Implement first 128 neurons of layer 10

      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(13, 14));
      number_of_features       <= std_logic_vector(to_unsigned(256, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(13, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(256, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer10-conv",
        scale_layer_name  => "layer10-scale",
        bn_layer_name     => "layer10-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 128,
        neuron_skip       => 128,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 11;

      read_feature_file(
        feature_filename  => "output_data6.txt",
        input_bias        => 0,
        input_height      => 13,
        input_width       => 13,
        input_no_features => 256,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;


    if sim_yolov3_layer10c_xcaffe then
      -- Implement first 128 neurons of layer 10

      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(13, 14));
      number_of_features       <= std_logic_vector(to_unsigned(256, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(13, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
   
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(256, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer10-conv",
        scale_layer_name  => "layer10-scale",
        bn_layer_name     => "layer10-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 128,
        neuron_skip       => 256,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 12;

      read_feature_file(
        feature_filename  => "output_data6.txt",
        input_bias        => 0,
        input_height      => 13,
        input_width       => 13,
        input_no_features => 256,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;

    if sim_yolov3_layer10d_xcaffe then
      -- Implement first 128 neurons of layer 10

      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(13, 14));
      number_of_features       <= std_logic_vector(to_unsigned(256, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(13, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
      
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(256, 10));

      -- Using Tiny Yolo V3 Model 

      read_xcaffe_file(
        xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer10-conv",
        scale_layer_name  => "layer10-scale",
        bn_layer_name     => "layer10-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 128,
        neuron_skip       => 384,
        clk               => clk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);


      sim_output <= 13;

      read_feature_file(
        feature_filename  => "output_data6.txt",
        input_bias        => 0,
        input_height      => 13,
        input_width       => 13,
        input_no_features => 256,
        clk               => clk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);


      wait for 4000 us;


    end if;




    if sim_yolov3_layer11_xcaffe then




      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(13, 14));
      number_of_features       <= std_logic_vector(to_unsigned(512, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(13, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));

      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(256, 10));

      for i in 0 to 7 loop
        -- Implement block of 128 neurons of layer 11
        -- Using Tiny Yolo V3 Model 

        read_xcaffe_file(
          xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
          layer_name        => "layer11-conv",
          scale_layer_name  => "layer11-scale",
          bn_layer_name     => "layer11-bn",
          has_bias          => false,
          weight_scaling    => 32767.0,
          layer_size        => 128,
          input_mask_height => 3,
          input_mask_width  => 3,
          input_no_features => 128,
          neuron_skip       => 128*i,
          clk               => clk,
          weight_stream     => weight_stream,
          weight_id         => weight_id,
          weight_first      => weight_first,
          weight_last       => weight_last);


        sim_output <= 14+i;

        read_feature_file(
          feature_filename  => "output_data7.txt",
          input_bias        => 0,
          input_height      => 13,
          input_width       => 13,
          input_no_features => 512,
          clk               => clk,
          feature_stream    => feature_stream,
          feature_valid     => feature_valid,
          feature_ready     => feature_ready);


        wait for 4000 us;
      end loop;

    end if;




    if sim_yolov3_layer12_xcaffe then




      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '0';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(13, 14));
      number_of_features       <= std_logic_vector(to_unsigned(1024, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(13, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));

      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(384, 10));

      for i in 0 to 1 loop
        -- Implement block of 128 neurons of layer 11
        -- Using Tiny Yolo V3 Model 

        read_xcaffe_file(
          xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
          layer_name        => "layer12-conv",
          scale_layer_name  => "layer12-scale",
          bn_layer_name     => "layer12-bn",
          has_bias          => false,
          weight_scaling    => 32767.0,
          layer_size        => 128,
          input_mask_height => 1,
          input_mask_width  => 1,
          input_no_features => 128,
          neuron_skip       => 128*i,
          clk               => clk,
          weight_stream     => weight_stream,
          weight_id         => weight_id,
          weight_first      => weight_first,
          weight_last       => weight_last);


        sim_output <= 22+i;

        read_feature_file(
          feature_filename  => "output_data8.txt",
          input_bias        => 0,
          input_height      => 13,
          input_width       => 13,
          input_no_features => 1024,
          clk               => clk,
          feature_stream    => feature_stream,
          feature_valid     => feature_valid,
          feature_ready     => feature_ready);


        wait for 4000 us;
      end loop;
      
    end if;





   if sim_yolov3_layer13_xcaffe then




      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '1';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(13, 14));
      number_of_features       <= std_logic_vector(to_unsigned(256, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(13, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
      
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(256, 10));

      for i in 0 to 3 loop
        -- Implement block of 128 neurons of layer 11
        -- Using Tiny Yolo V3 Model 

        read_xcaffe_file(
          xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
          layer_name        => "layer13-conv",
          scale_layer_name  => "layer13-scale",
          bn_layer_name     => "layer13-bn",
          has_bias          => false,
          weight_scaling    => 32767.0,
          layer_size        => 128,
          input_mask_height => 3,
          input_mask_width  => 3,
          input_no_features => 128,
          neuron_skip       => 128*i,
          clk               => clk,
          weight_stream     => weight_stream,
          weight_id         => weight_id,
          weight_first      => weight_first,
          weight_last       => weight_last);


        sim_output <= 24+i;

        read_feature_file(
          feature_filename  => "output_data9.txt",
          input_bias        => 0,
          input_height      => 13,
          input_width       => 13,
          input_no_features => 256,
          clk               => clk,
          feature_stream    => feature_stream,
          feature_valid     => feature_valid,
          feature_ready     => feature_ready);


        wait for 4000 us;
      end loop;

   end if;




    if sim_yolov3_layer14_xcaffe then



      -- Read Weights from file 
      relu                     <= '0';
      conv_3x3                 <= '0';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(13, 14));
      number_of_features       <= std_logic_vector(to_unsigned(512, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(13, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
     
      number_of_active_neurons <= std_logic_vector(to_unsigned(45, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(90, 10));

   
        -- Using Tiny Yolo V3 Model 

        read_xcaffe_file(
          xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
          layer_name        => "layer14-conv",
          scale_layer_name  => "",
          bn_layer_name     => "",
          has_bias          => true,
          weight_scaling    => 32767.0,
          layer_size        => 45,
          input_mask_height => 1,
          input_mask_width  => 1,
          input_no_features => 512,
          neuron_skip       => 0,
          clk               => clk,
          weight_stream     => weight_stream,
          weight_id         => weight_id,
          weight_first      => weight_first,
          weight_last       => weight_last);


      sim_output <= 28;
      
      read_feature_file(
          feature_filename  => "output_data10.txt",
          input_bias        => 0,
          input_height      => 13,
          input_width       => 13,
          input_no_features => 512,
          clk               => clk,
          feature_stream    => feature_stream,
          feature_valid     => feature_valid,
          feature_ready     => feature_ready);


        wait for 4000 us;
      
    end if;

    if sim_yolov3_layer17_xcaffe then



      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '0';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(13, 14));
      number_of_features       <= std_logic_vector(to_unsigned(256, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(13, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
     
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(384, 10));

   
        -- Using Tiny Yolo V3 Model 

        read_xcaffe_file(
          xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
          layer_name        => "layer17-conv",
          scale_layer_name  => "layer17-scale",
          bn_layer_name     => "layer17-bn",
          has_bias          => false,
          weight_scaling    => 32767.0,
          layer_size        => 128,
          input_mask_height => 1,
          input_mask_width  => 1,
          input_no_features => 256,
          neuron_skip       => 0,
          clk               => clk,
          weight_stream     => weight_stream,
          weight_id         => weight_id,
          weight_first      => weight_first,
          weight_last       => weight_last);


        sim_output <= 29;

        -- Note also reads in layer12 output
        read_feature_file(
          feature_filename  => "output_data9.txt",
          input_bias        => 0,
          input_height      => 13,
          input_width       => 13,
          input_no_features => 256,
          clk               => clk,
          feature_stream    => feature_stream,
          feature_valid     => feature_valid,
          feature_ready     => feature_ready);


        wait for 4000 us;
      
    end if;

    if sim_yolov3_layer1819_xcaffe then
      -- Layer 18, Upsample Layer 17 output to 26x26 (x128)
      -- Layer 19, Concatenate Layer 18 Output with Layer 8 26x26 (x256)
      file_open(upsample_input_file,"output_data12.txt",read_mode);
      file_open(concat_input_file,"output_data6_nomaxp.txt",read_mode);
      file_open(concat_output_file,"output_data13.txt",write_mode);
      for i in 1 to 13 loop
        for ii in 0 to 1 loop
          for j in 1 to 13 loop
            for k in 1 to 128 loop
              if ii = 0 then
                readline(upsample_input_file,la((j-1)*128+k));
              end if;
            end loop;
            for jj in 0 to 1 loop
              for k in 1 to 128 loop
                l:=la((j-1)*128+k);
                writeline(concat_output_file,l);          
              end loop;
              for k in 1 to 256 loop
                readline(concat_input_file,l);
                writeline(concat_output_file,l);
              end loop;           
            end loop;
          end loop;
        end loop;
      end loop;
      file_close(upsample_input_file);
      file_close(concat_input_file);
      file_close(concat_output_file);
      
    end if;


    if sim_yolov3_layer20_xcaffe then




      -- Read Weights from file 
      relu                     <= '1';
      conv_3x3                 <= '0';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(26, 14));
      number_of_features       <= std_logic_vector(to_unsigned(384, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(13, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
      
      number_of_active_neurons <= std_logic_vector(to_unsigned(128, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(384, 10));

      for i in 0 to 1 loop
        -- Implement block of 128 neurons of layer 20
        -- Using Tiny Yolo V3 Model 

        read_xcaffe_file(
          xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
          layer_name        => "layer20-conv",
          scale_layer_name  => "layer20-scale",
          bn_layer_name     => "layer20-bn",
          has_bias          => false,
          weight_scaling    => 32767.0,
          layer_size        => 128,
          input_mask_height => 1,
          input_mask_width  => 1,
          input_no_features => 384,
          neuron_skip       => 128*i,
          clk               => clk,
          weight_stream     => weight_stream,
          weight_id         => weight_id,
          weight_first      => weight_first,
          weight_last       => weight_last);


        sim_output <= 30+i;

        read_feature_file(
          feature_filename  => "output_data13.txt",
          input_bias        => 0,
          input_height      => 26,
          input_width       => 26,
          input_no_features => 384,
          clk               => clk,
          feature_stream    => feature_stream,
          feature_valid     => feature_valid,
          feature_ready     => feature_ready);


        wait for 4000 us;
      end loop;
      
    end if;


    if sim_yolov3_layer21_xcaffe then



      -- Read Weights from file 
      relu                     <= '0';
      conv_3x3                 <= '0';
      use_maxpool              <= '0';
      feature_image_width      <= std_logic_vector(to_unsigned(26, 14));
      number_of_features       <= std_logic_vector(to_unsigned(256, 12));
      stride2                  <= '0';
      mp_feature_image_width   <= std_logic_vector(to_unsigned(13, 14));
      mp_number_of_features    <= std_logic_vector(to_unsigned(128, 12));
     
      number_of_active_neurons <= std_logic_vector(to_unsigned(45, 10));
      throttle_rate            <= std_logic_vector(to_unsigned(90, 10));

   
        -- Using Tiny Yolo V3 Model 

        read_xcaffe_file(
          xcaffe_filename   =>  DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
          layer_name        => "layer21-conv",
          scale_layer_name  => "",
          bn_layer_name     => "",
          has_bias          => true,
          weight_scaling    => 32767.0,
          layer_size        => 45,
          input_mask_height => 1,
          input_mask_width  => 1,
          input_no_features => 256,
          neuron_skip       => 0,
          clk               => clk,
          weight_stream     => weight_stream,
          weight_id         => weight_id,
          weight_first      => weight_first,
          weight_last       => weight_last);


        sim_output <= 32;

        read_feature_file(
          feature_filename  => "output_data14.txt",
          input_bias        => 0,
          input_height      => 26,
          input_width       => 26,
          input_no_features => 256,
          clk               => clk,
          feature_stream    => feature_stream,
          feature_valid     => feature_valid,
          feature_ready     => feature_ready);


        wait for 4000 us;
      
    end if;
    
    wait;


  end process WaveGen_Proc;






  gen_yolo_op : if sim_yolov3_layer0 or sim_yolov3_layer0_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount  : integer := 0;
      variable incount_f : integer := 0;
      variable incount_c : integer := 0;
      variable incount_r : integer := 0;
      variable ocount_f  : integer := 0;
      variable ocount_c  : integer := 0;
      variable ocount_r  : integer := 0;
      file output_file   : text is out "output_data2.txt";
      variable ol        : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 5 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;


          if fcount = unsigned(number_of_active_neurons) -1 then
            fcount := 0;
            pcount := pcount +1;
            write (l, string'("T= "));
            write (l, cycle);
            write (l, string'(" Output feature: "));
            write (l, pcount);
            write (l, string'(": "));
            write (l, outcount);
            write (l, string'(" O:"));
            write (l, ocount_r);
            write (l, string'(","));
            write (l, ocount_c);
            write (l, string'(","));
            write (l, ocount_f);
            write (l, string'(" I:"));
            write (l, incount_r);
            write (l, string'(","));
            write (l, incount_c);
            write (l, string'(","));
            write (l, incount_f);
            writeline (output, l);
          else
            fcount := fcount+1;
          end if;
          if outcount = 208*208*16 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;
          if ocount_f < 15 then
            ocount_f := ocount_f+1;
          else
            ocount_f := 0;
            if ocount_c < 207 then
              ocount_c := ocount_c+1;
            else
              ocount_c := 0;
              if ocount_r < 207 then
                ocount_r := ocount_r+1;
              else
                ocount_r := 0;
              end if;
            end if;
          end if;


        end if;

        if feature_valid = '1' and feature_ready = '1' then
          if incount_f < 3 then
            incount_f := incount_f+1;
          else
            incount_f := 0;
            if ocount_c < 415 then
              incount_c := incount_c+1;
            else
              incount_c := 0;
              if incount_r < 415 then
                incount_r := incount_r+1;
              else
                incount_r := 0;
              end if;
            end if;
          end if;
        end if;

      end if;
    end process;

  end generate;


  gen_yolo_op2 : if sim_yolov3_layer2_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount  : integer := 0;
      variable incount_f : integer := 0;
      variable incount_c : integer := 0;
      variable incount_r : integer := 0;
      variable ocount_f  : integer := 0;
      variable ocount_c  : integer := 0;
      variable ocount_r  : integer := 0;
      file output_file   : text is out "output_data3.txt";
      variable ol        : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 6 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;


          if fcount = unsigned(number_of_active_neurons) -1 then
            fcount := 0;
            pcount := pcount +1;
            write (l, string'("T= "));
            write (l, cycle);
            write (l, string'(" Output feature: "));
            write (l, pcount);
            write (l, string'(": "));
            write (l, outcount);
            write (l, string'(" O:"));
            write (l, ocount_r);
            write (l, string'(","));
            write (l, ocount_c);
            write (l, string'(","));
            write (l, ocount_f);
            write (l, string'(" I:"));
            write (l, incount_r);
            write (l, string'(","));
            write (l, incount_c);
            write (l, string'(","));
            write (l, incount_f);
            writeline (output, l);
          else
            fcount := fcount+1;
          end if;
          if outcount = 104*104*32 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;
          if ocount_f < 31 then
            ocount_f := ocount_f+1;
          else
            ocount_f := 0;
            if ocount_c < 103 then
              ocount_c := ocount_c+1;
            else
              ocount_c := 0;
              if ocount_r < 103 then
                ocount_r := ocount_r+1;
              else
                ocount_r := 0;
              end if;
            end if;
          end if;


        end if;

        if feature_valid = '1' and feature_ready = '1' then
          if incount_f < 15 then
            incount_f := incount_f+1;
          else
            incount_f := 0;
            if ocount_c < 104 then
              incount_c := incount_c+1;
            else
              incount_c := 0;
              if incount_r < 104 then
                incount_r := incount_r+1;
              else
                incount_r := 0;
              end if;
            end if;
          end if;
        end if;

      end if;
    end process;

  end generate;


  gen_yolo_op3 : if sim_yolov3_layer4_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount  : integer := 0;
      variable incount_f : integer := 0;
      variable incount_c : integer := 0;
      variable incount_r : integer := 0;
      variable ocount_f  : integer := 0;
      variable ocount_c  : integer := 0;
      variable ocount_r  : integer := 0;
      file output_file   : text is out "output_data4.txt";
      variable ol        : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 7 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 52*52*64 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;

        end if;

      end if;
    end process;

  end generate;


  gen_yolo_op4 : if sim_yolov3_layer6_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount  : integer := 0;
      variable incount_f : integer := 0;
      variable incount_c : integer := 0;
      variable incount_r : integer := 0;
      variable ocount_f  : integer := 0;
      variable ocount_c  : integer := 0;
      variable ocount_r  : integer := 0;
      file output_file   : text is out "output_data5.txt";
      variable ol        : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 8 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 26*26*128 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;

        end if;

      end if;
    end process;

  end generate;


  gen_yolo_op8a : if sim_yolov3_layer8a_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount  : integer := 0;
      variable incount_f : integer := 0;
      variable incount_c : integer := 0;
      variable incount_r : integer := 0;
      variable ocount_f  : integer := 0;
      variable ocount_c  : integer := 0;
      variable ocount_r  : integer := 0;
      file output_file   : text is out "output_data6a.txt";
      variable ol        : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 9 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 13*13*128 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;

        end if;

      end if;
    end process;

  end generate;

  gen_yolo_op8b : if sim_yolov3_layer8b_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount  : integer := 0;
      variable incount_f : integer := 0;
      variable incount_c : integer := 0;
      variable incount_r : integer := 0;
      variable ocount_f  : integer := 0;
      variable ocount_c  : integer := 0;
      variable ocount_r  : integer := 0;
      file output_file   : text is out "output_data6b.txt";
      variable ol        : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 10 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 13*13*128 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
            merge_output_layer8 <= true;
          end if;


        end if;

      end if;
    end process;

    process
      file merge_file0    : text;
      file merge_file1    : text;
      file merge_file_out : text is out "output_data6.txt";
      variable l          : line;
    begin
      wait until merge_output_layer8;
      file_open(merge_file0,"output_data6a.txt",read_mode);
      file_open(merge_file1,"output_data6b.txt",read_mode);
      for i in 1 to 13 loop       
        for j in 1 to 13 loop
          for k in 1 to 128 loop
            readline(merge_file0, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file1, l);
            writeline(merge_file_out, l);
          end loop;
        end loop;
      end loop;
    end process;



  end generate;


   gen_yolo_op8a_nomaxp : if sim_yolov3_layer8a_nomaxp_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount  : integer := 0;
      variable incount_f : integer := 0;
      variable incount_c : integer := 0;
      variable incount_r : integer := 0;
      variable ocount_f  : integer := 0;
      variable ocount_c  : integer := 0;
      variable ocount_r  : integer := 0;
      file output_file   : text is out "output_data6a_nomaxp.txt";
      variable ol        : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 50 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 26*26*128 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;

        end if;

      end if;
    end process;

  end generate;

  gen_yolo_op8b_nomaxp : if sim_yolov3_layer8b_nomaxp_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount  : integer := 0;
      variable incount_f : integer := 0;
      variable incount_c : integer := 0;
      variable incount_r : integer := 0;
      variable ocount_f  : integer := 0;
      variable ocount_c  : integer := 0;
      variable ocount_r  : integer := 0;
      file output_file   : text is out "output_data6b_nomaxp.txt";
      variable ol        : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 51 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 26*26*128 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
            merge_output_layer8_nomaxp <= true;
          end if;


        end if;

      end if;
    end process;

    process
      file merge_file0    : text;
      file merge_file1    : text;
      file merge_file_out : text is out "output_data6_nomaxp.txt";
      variable l          : line;
    begin
      wait until merge_output_layer8_nomaxp;
      file_open(merge_file0,"output_data6a_nomaxp.txt",read_mode);
      file_open(merge_file1,"output_data6b_nomaxp.txt",read_mode);
      for i in 1 to 26 loop
        for j in 1 to 26 loop
          for k in 1 to 128 loop
            readline(merge_file0, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file1, l);
            writeline(merge_file_out, l);
          end loop;
        end loop;
      end loop;
    end process;



  end generate;





  

  gen_yolo_op10a : if sim_yolov3_layer10a_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount : integer := 0;

      file output_file : text is out "output_data7a.txt";
      variable ol      : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 10 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 13*13*128 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;

        end if;

      end if;
    end process;

  end generate;



  gen_yolo_op10b : if sim_yolov3_layer10b_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount : integer := 0;

      file output_file : text is out "output_data7b.txt";
      variable ol      : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 11 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 13*13*128 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;

        end if;

      end if;
    end process;

  end generate;

  gen_yolo_op10c : if sim_yolov3_layer10c_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount : integer := 0;

      file output_file : text is out "output_data7c.txt";
      variable ol      : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 12 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 13*13*128 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;

        end if;

      end if;
    end process;

  end generate;


  gen_yolo_op10d : if sim_yolov3_layer10d_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount : integer := 0;

      file output_file : text is out "output_data7d.txt";
      variable ol      : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 13 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 13*13*128 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
            merge_output_layer10 <= true;
          end if;

        end if;

      end if;
    end process;


    process
      file merge_file0    : text;
      file merge_file1    : text;
      file merge_file2    : text;
      file merge_file3    : text;
      file merge_file_out : text is out "output_data7.txt";
      variable l          : line;
    begin
      wait until merge_output_layer10;
      file_open(merge_file0,"output_data7a.txt",read_mode);
      file_open(merge_file1,"output_data7b.txt",read_mode);
      file_open(merge_file2,"output_data7c.txt",read_mode);
      file_open(merge_file3,"output_data7d.txt",read_mode);
      for i in 1 to 13 loop
        for j in 1 to 13 loop
          for k in 1 to 128 loop
            readline(merge_file0, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file1, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file2, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file3, l);
            writeline(merge_file_out, l);
          end loop;
        end loop;
      end loop;
    end process;

  end generate;



  gen_yolo_op11 : if sim_yolov3_layer11_xcaffe generate


    gen_yolo_op11_loop : for i in 0 to 7 generate

      -- Print out neuron outputs
      process(clk)
        variable l          : line;
        variable int_output : integer;
        variable cycle      : integer := 0;
        variable fcount     : integer := 0;
        variable pcount     : integer := 0;

        variable outcount : integer := 0;
        constant filename : string  := "output_data8" & integer'image(i) &".txt";
        file output_file  : text is out filename;
        variable ol       : line;
      begin
        if rising_edge(clk) then
          cycle := cycle+1;
          if output_valid = '1' and sim_output = 14+i then
            -- Output is unsigned if ReLU used

            if ReLU = '1' then
              int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
            else
              int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
            end if;

            write(ol, int_output);
            writeline(output_file, ol);
            outcount := outcount+1;

            if outcount = 13*13*128 then
              write (l, string'("Closing file: "));
              write (l, outcount);
              writeline (output, l);
              file_close(output_file);
              
              merge_output_layer11(i) <= '1';
             
            end if;

          end if;

        end if;
      end process;

    end generate;


    process
      file merge_file0    : text;
      file merge_file1    : text;
      file merge_file2    : text; 
      file merge_file3    : text;
      file merge_file4    : text;
      file merge_file5    : text;
      file merge_file6    : text; 
      file merge_file7    : text;
      file merge_file_out : text;
      variable l          : line;
    begin
      wait until merge_output_layer11 = "11111111";
      file_open(merge_file0,"output_data80.txt",read_mode);
      file_open(merge_file1,"output_data81.txt",read_mode);
      file_open(merge_file2,"output_data82.txt",read_mode);
      file_open(merge_file3,"output_data83.txt",read_mode);
      file_open(merge_file4,"output_data84.txt",read_mode);
      file_open(merge_file5,"output_data85.txt",read_mode);
      file_open(merge_file6,"output_data86.txt",read_mode);
      file_open(merge_file7,"output_data87.txt",read_mode);
      file_open(merge_file_out,"output_data8.txt",write_mode);
      for i in 1 to 13 loop
        for j in 1 to 13 loop
          for k in 1 to 128 loop
            readline(merge_file0, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file1, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file2, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file3, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file4, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file5, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file6, l);
            writeline(merge_file_out, l);
          end loop;
          for k in 1 to 128 loop
            readline(merge_file7, l);
            writeline(merge_file_out, l);
          end loop;
        end loop;
      end loop;
    end process;

  end generate;


  gen_yolo_op12 : if sim_yolov3_layer12_xcaffe generate


    gen_yolo_op12_loop : for i in 0 to 1 generate

      -- Print out neuron outputs
      process(clk)
        variable l          : line;
        variable int_output : integer;
        variable cycle      : integer := 0;
        variable fcount     : integer := 0;
        variable pcount     : integer := 0;

        variable outcount : integer := 0;
        constant filename : string  := "output_data9" & integer'image(i) &".txt";
        file output_file  : text is out filename;
        variable ol       : line;
      begin
        if rising_edge(clk) then
          cycle := cycle+1;
          if output_valid = '1' and sim_output = 22+i then
            -- Output is unsigned if ReLU used

            if ReLU = '1' then
              int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
            else
              int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
            end if;

            write(ol, int_output);
            writeline(output_file, ol);
            outcount := outcount+1;

            if outcount = 13*13*128 then
              write (l, string'("Closing file: "));
              write (l, outcount);
              writeline (output, l);
              file_close(output_file);
              
              merge_output_layer12(i) <= '1';
            
            end if;

          end if;

        end if;
      end process;

    end generate;
  process
    file merge_file0    : text; 
    file merge_file1    : text; 
    file merge_file_out : text;
    variable l          : line;
  begin
    wait until merge_output_layer12 = "11";
    file_open(merge_file0,"output_data90.txt",read_mode);
    file_open(merge_file1,"output_data91.txt",read_mode);
    file_open(merge_file_out,"output_data9.txt",write_mode);
    for i in 1 to 13 loop
      for j in 1 to 13 loop
        for k in 1 to 128 loop
          readline(merge_file0, l);
          writeline(merge_file_out, l);
        end loop;
        for k in 1 to 128 loop
          readline(merge_file1, l);
          writeline(merge_file_out, l);
        end loop;
      end loop;
    end loop;
  end process;

end generate;



  gen_yolo_op13 : if sim_yolov3_layer13_xcaffe generate


    gen_yolo_op13_loop : for i in 0 to 3 generate

      -- Print out neuron outputs
      process(clk)
        variable l          : line;
        variable int_output : integer;
        variable cycle      : integer := 0;
        variable fcount     : integer := 0;
        variable pcount     : integer := 0;

        variable outcount : integer := 0;
        constant filename : string  := "output_data10_" & integer'image(i) &".txt";
        file output_file  : text is out filename;
        variable ol       : line;
      begin
        if rising_edge(clk) then
          cycle := cycle+1;
          
          if output_valid = '1' and sim_output = 24+i then
            -- Output is unsigned if ReLU used
            if ReLU = '1' then
              int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
            else
              int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
            end if;

            write(ol, int_output);
            writeline(output_file, ol);
            outcount := outcount+1;

            if outcount = 13*13*128 then
              write (l, string'("Closing file: "));
              write (l, outcount);
              writeline (output, l);
              file_close(output_file);
             
              merge_output_layer13(i) <= '1';
              
            end if;

          end if;

        end if;
      end process;

    end generate;
  process
    file merge_file0    : text; 
    file merge_file1    : text;
    file merge_file2    : text; 
    file merge_file3    : text; 
    file merge_file_out : text;
    variable l          : line;
  begin
    wait until merge_output_layer13 = "1111";
    file_open(merge_file0,"output_data10_0.txt",read_mode);
    file_open(merge_file1,"output_data10_1.txt",read_mode);
    file_open(merge_file2,"output_data10_2.txt",read_mode);
    file_open(merge_file3,"output_data10_3.txt",read_mode);
    file_open(merge_file_out,"output_data10.txt",write_mode);
    for i in 1 to 13 loop
      for j in 1 to 13 loop
        for k in 1 to 128 loop
          readline(merge_file0, l);
          writeline(merge_file_out, l);
        end loop;
        for k in 1 to 128 loop
          readline(merge_file1, l);
          writeline(merge_file_out, l);
        end loop;
        for k in 1 to 128 loop
          readline(merge_file2, l);
          writeline(merge_file_out, l);
        end loop;
        for k in 1 to 128 loop
          readline(merge_file3, l);
          writeline(merge_file_out, l);
        end loop;
      end loop;
    end loop;
    file_close(merge_file_out);
    file_close(merge_file0);
    file_close(merge_file1);
    file_close(merge_file2);
    file_close(merge_file3);    
  end process;

end generate;


 gen_yolo_op14 : if sim_yolov3_layer14_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount  : integer := 0;
      file output_file   : text is out "output_data11.txt";
      variable ol        : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 28 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 13*13*45 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;

        end if;

      end if;
    end process;

 end generate;
                 
 gen_yolo_op17 : if sim_yolov3_layer17_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount  : integer := 0;
      file output_file   : text is out "output_data12.txt";
      variable ol        : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 29 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 13*13*128 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;

        end if;

      end if;
    end process;

  end generate;


  gen_yolo_op120 : if sim_yolov3_layer20_xcaffe generate


    gen_yolo_op20_loop : for i in 0 to 1 generate

      -- Print out neuron outputs
      process(clk)
        variable l          : line;
        variable int_output : integer;
        variable cycle      : integer := 0;
        variable fcount     : integer := 0;
        variable pcount     : integer := 0;

        variable outcount : integer := 0;
        constant filename : string  := "output_data14_" & integer'image(i) &".txt";
        file output_file  : text is out filename;
        variable ol       : line;
      begin
        if rising_edge(clk) then
          cycle := cycle+1;
          if output_valid = '1' and sim_output = 30+i then
            -- Output is unsigned if ReLU used

            if ReLU = '1' then
              int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
            else
              int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
            end if;

            write(ol, int_output);
            writeline(output_file, ol);
            outcount := outcount+1;

            if outcount = 26*26*128 then
              write (l, string'("Closing file: "));
              write (l, outcount);
              writeline (output, l);
              file_close(output_file);
              
              merge_output_layer20(i) <= '1';
            
            end if;

          end if;

        end if;
      end process;

    end generate;
  process
    file merge_file0    : text; 
    file merge_file1    : text; 
    file merge_file_out : text;
    variable l          : line;
  begin
    wait until merge_output_layer20 = "11";
    file_open(merge_file0,"output_data14_0.txt",read_mode);
    file_open(merge_file1,"output_data14_1.txt",read_mode);
    file_open(merge_file_out,"output_data14.txt",write_mode);
    for i in 1 to 26 loop
      for j in 1 to 26 loop
        for k in 1 to 128 loop
          readline(merge_file0, l);
          writeline(merge_file_out, l);
        end loop;
        for k in 1 to 128 loop
          readline(merge_file1, l);
          writeline(merge_file_out, l);
        end loop;
      end loop;
    end loop;
  end process;

end generate;


gen_yolo_op21 : if sim_yolov3_layer21_xcaffe generate

    -- Print out neuron outputs
    process(clk)
      variable l          : line;
      variable int_output : integer;
      variable cycle      : integer := 0;
      variable fcount     : integer := 0;
      variable pcount     : integer := 0;

      variable outcount  : integer := 0;
      file output_file   : text is out "output_data15.txt";
      variable ol        : line;
    begin
      if rising_edge(clk) then
        cycle := cycle+1;
        if output_valid = '1' and sim_output = 32 then
          -- Output is unsigned if ReLU used

          if ReLU = '1' then
            int_output := to_integer(unsigned(output_stream(feature_width-1 downto 0)));
          else
            int_output := to_integer(signed(output_stream(feature_width-1 downto 0)));
          end if;

          write(ol, int_output);
          writeline(output_file, ol);
          outcount := outcount+1;

          if outcount = 26*26*45 then
            write (l, string'("Closing file: "));
            write (l, outcount);
            writeline (output, l);
            file_close(output_file);
          end if;

        end if;

      end if;
    end process;

 end generate;
                  
end architecture sim_only;
