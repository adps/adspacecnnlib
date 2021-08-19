--Copyright (c) 2017, Alpha Data Parallel Systems Ltd.
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
-- Module for zero padding streams 
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- synthesis translate_off
--use std.textio.all; --  Imports the standard textio package.
-- synthesis translate_on

-- Assume Zero padding is always just 1 pixel around image.
-- Assuming Square Image for CNN use
-- Assuming maximum image size of 16381x16381 pixels

entity zero_pad_dynamic is
  generic (
    stream_width : natural := 8
    );   
  port (
    clk : in std_logic;
    rst : in std_logic;
    image_width : in std_logic_vector(13 downto 0);
    number_of_features : in std_logic_vector(11 downto 0);
    stream_in : in std_logic_vector(stream_width-1 downto 0);
    stream_in_valid  : in  std_logic;
    stream_in_ready  : out  std_logic;
    stream_out : out  std_logic_vector(stream_width-1 downto 0);
    stream_out_valid : out std_logic;
    stream_out_ready : in std_logic);
end entity;

architecture rtl of zero_pad_dynamic is


  
  signal feat : unsigned(11 downto 0) := (others => '0');
  signal row : unsigned(15 downto 0) := (others => '0');
  signal col : unsigned(15 downto 0) := (others => '0');
  signal op_data : std_logic := '0';
  signal adv : std_logic := '0';
  signal wait_for_data : std_logic := '1';

  signal output_width, output_height : unsigned(15 downto 0);

  signal im_width : std_logic_vector(15 downto 0);

  
  
  
begin

  stream_out_valid <= stream_in_valid when op_data = '1' else ((not wait_for_data) or stream_in_valid);
  stream_out <= stream_in when op_data = '1' else (others => '0');
  
  stream_in_ready <= stream_out_ready when op_data = '1' else '0';

  adv <= (stream_out_ready and stream_in_valid) when op_data = '1' else
         stream_out_ready and ((not wait_for_data) or stream_in_valid);
        
  
  process(clk)
--    variable l : line;
  begin
    if rising_edge(clk) then
      if stream_in_valid = '1' then
        wait_for_data <= '0';
      end if;

      im_width <= "00" & image_width;

      output_width <= unsigned(im_width)+2;
      output_height <= unsigned(im_width)+2;
      
      if adv = '1' then
        if feat = unsigned(number_of_features)-1 then
          feat <= (others => '0');
          if col = output_width-1 then
            col <= (others => '0');
            if row = output_height-1 then
              row <= (others => '0');
              wait_for_data <= '1';
            else
              row <= row+1;
            end if;
          else
            col <= col+1;
          end if;        
          if row >= 1 and row < unsigned(image_width)+1 then
            if col = 0 then
              op_data <= '1';
            elsif col = unsigned(image_width) then
              op_data <= '0';
            end if;
          end if;
        else
          feat <= feat+1;
        end if;
      end if;
      if rst = '1' then
        op_data <= '0';
        wait_for_data <= '1';
        row <= (others => '0');
        col <= (others => '0');
        feat <= (others => '0');
      end if;
    end if;
  end process;    

    
 
end architecture;
