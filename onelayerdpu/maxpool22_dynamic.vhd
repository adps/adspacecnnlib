--Copyright (c) 2022, Alpha Data Parallel Systems Ltd.
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
-- maxpool.vhd
-- Max Pool operation 
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


--use std.textio.all; --  Imports the standard textio package.

entity maxpool22_dynamic is
  generic (
    feature_width : natural := 8);   
  port (
    clk : in std_logic;
    rst : in std_logic;
    number_of_features : in std_logic_vector(11 downto 0);
    feature_image_width : in std_logic_vector(13 downto 0);
    feature_stream : in std_logic_vector(feature_width-1 downto 0);
    feature_valid  : in  std_logic;
    max_feature_stream : out std_logic_vector(feature_width-1 downto 0);
    max_feature_valid  : out std_logic);
end entity;

architecture rtl of maxpool22_dynamic is

  signal p : unsigned(25 downto 0):= (others => '0');
  signal set_length : std_Logic := '0';
  signal nof_r1 : std_logic_vector(11 downto 0):= (others => '0');
  signal fiw_r1 : std_logic_vector(13 downto 0):= (others => '0');
  signal nof_m1 : unsigned(11 downto 0):= (others => '0');
  signal fiw_m1 : unsigned(13 downto 0):= (others => '0');
  signal sle0,sle1,sle2 : std_logic := '0';
 
  component prog_length_sr is
    generic (
      width        : natural;
      memory_depth : natural);
    port (
      clk            : in  std_logic;
      rst            : in  std_logic;
      length         : in  std_logic_vector(memory_depth-1 downto 0);
      set_length     : in  std_logic;
      data_in        :     std_logic_vector(width-1 downto 0);
      data_in_valid  : in  std_logic;
      data_out       : out std_logic_vector(width-1 downto 0);
      data_out_valid : out std_logic);
  end component prog_length_sr;

  signal data0,data1,data2 : std_logic_vector(feature_width-1 downto 0):= (others => '0');
  signal data0_valid,data1_valid,data2_valid,data2_valid_r1 : std_logic := '0';
  signal fs_r1,fs_r2,max0,max0_r1,max1,max1_r1,max2 : std_logic_vector(feature_width-1 downto 0):= (others => '0');

  signal row_count : std_logic := '0';
  signal col_count : unsigned(13 downto 0) := (others => '0');
  signal f_count : unsigned(11 downto 0) := (others => '0');

  
  
begin

  -- Possibly Sub-optimal
  -- number_of_features*feature_image_width could be pre-calculated
  -- set_length could be set by controller, not detected
  
  process(clk)
  begin
    if rising_edge(clk) then
      p <= unsigned(number_of_features)*fiw_m1;
      nof_r1 <= number_of_features;
      fiw_r1 <= feature_image_width;
      nof_m1 <= unsigned(number_of_features)-1;
      fiw_m1 <= unsigned(feature_image_width)-1;
      
      if nof_r1 /= number_of_features or fiw_r1 /= feature_image_width then
        sle0 <= '1';
      else
        sle0 <= '0';
      end if;
      sle1 <= sle0;
      sle2 <= sle1;
      set_length <= sle2;      
    end if;
  end process;


  prog_length_sr_1: prog_length_sr
    generic map (
      width        => feature_width,
      memory_depth => 8)
    port map (
      clk            => clk,
      rst            => rst,
      length         => number_of_features(7 downto 0),
      set_length     => set_length,
      data_in        => feature_stream,
      data_in_valid  => feature_valid,
      data_out       => data0,
      data_out_valid => data0_valid);

  prog_length_sr_2: prog_length_sr
    generic map (
      width        => feature_width,
      memory_depth => 13)
    port map (
      clk            => clk,
      rst            => rst,
      length         => std_logic_vector(p(12 downto 0)),
      set_length     => set_length,
      data_in        => data0,
      data_in_valid  => data0_valid,
      data_out       => data1,
      data_out_valid => data1_valid);

  prog_length_sr_3: prog_length_sr
    generic map (
      width        => feature_width,
      memory_depth => 8)
    port map (
      clk            => clk,
      rst            => rst,
      length         => number_of_features(7 downto 0),
      set_length     => set_length,
      data_in        => data1,
      data_in_valid  => data1_valid,
      data_out       => data2,
      data_out_valid => data2_valid);


  process(clk)
  begin
    if rising_edge(clk) then
      -- Align data onto same clock cycle.
      -- Each SR adds 2 clock cycle delays.
      fs_r1 <= feature_stream;
      fs_r2 <= fs_r1;

      if unsigned(fs_r2)>unsigned(data0) then
        max0 <= fs_r2;
      else
        max0 <= data0;
      end if;

      max0_r1 <= max0;

      if unsigned(max0_r1)>unsigned(data1) then
        max1 <= max0_r1;
      else
        max1 <= data1;
      end if;
 
      max1_r1 <= max1;
      
      if unsigned(max1_r1)>unsigned(data2) then
        max2 <= max1_r1;
      else
        max2 <= data2;
      end if;

      if data2_valid_r1 = '1' then
        if f_count = nof_m1 then
          f_count <= (others => '0');
          if col_count = fiw_m1 then
            col_count <= (others => '0');
            row_count <= not row_count;
          else
            col_count <= col_count+1;
          end if;
        else
          f_count <= f_count+1;
        end if;          
      end if;

      data2_valid_r1 <= data2_valid;
      
      max_feature_stream <= max2;
      max_feature_valid <= data2_valid_r1 and row_count and col_count(0);
        
      if rst = '1' or set_length = '1' then
        row_count <= '0';
        col_count <= (others => '0');
        data2_valid_r1 <= '0';
      end if;     
    end if;
  end process;
  


end architecture;
