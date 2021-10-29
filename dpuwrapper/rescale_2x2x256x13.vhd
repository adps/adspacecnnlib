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
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


-- define feature and weight width
library work;
use work.cnn_defs.all;

entity rescale_2x2x256x13 is
  port (
    clk : in std_logic;
    rst : in std_logic;
      -- Input Data Stream
    feature_stream : in std_logic_vector(feature_width-1 downto 0);
    feature_valid  : in std_logic;
    feature_ready  : out std_logic;
    -- Input Data Stream
    rs_stream : out std_logic_vector(feature_width-1 downto 0);
    rs_valid  : out std_logic;
    rs_ready  : in std_logic
  );
end entity;

architecture rtl of rescale_2x2x256x13 is


  type mem_type is array (0 to 256*13-1) of std_logic_vector(feature_width-1 downto 0);
  signal mem_buffer0, mem_buffer1 : mem_type := (others => (others => '0'));
  
  signal input_addr : unsigned(15 downto 0) := (others => '0');

  signal wr_buffer : std_logic := '0';
  signal rd_buffer : std_logic := '0';
  signal buffer0_full, buffer1_full : std_logic := '0';
  
  signal pixel_rs : std_logic := '0';
  signal line_rs : std_logic := '0';
  signal fcount : unsigned(7 downto 0) := (others => '0');
  signal pcount : unsigned(3 downto 0) := (others => '0');
  signal rd_addr : unsigned(15 downto 0) := (others => '0');


  component small_sfifo is
    generic (
      width : integer);
    port (
      clk    : in  std_logic;
      rst    : in  std_logic;
      wadv   : in  std_logic;
      wdata  : in  std_logic_vector(width-1 downto 0);
      nfull  : out std_logic;
      radv   : in  std_logic;
      rempty : out std_logic;
      rdata  : out std_logic_vector(width-1 downto 0));
  end component small_sfifo;




  signal wadv   : std_logic;
  signal wdata  : std_logic_vector(feature_width-1 downto 0);
  signal nfull  : std_logic;
  signal radv   : std_logic;
  signal rempty : std_logic;
  signal rdata  : std_logic_vector(feature_width-1 downto 0);
  
begin

  feature_ready <= (not buffer1_full) when wr_buffer = '1' else (not buffer0_full);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        buffer0_full <= '0';
        buffer1_full <= '0';
        wr_buffer <= '0';
        input_addr <= (others => '0');
        rd_addr <= (others => '0');
        wadv <= '0';
      else
        if wr_buffer = '0' then
          if buffer0_full = '0' and feature_valid = '1' then
            mem_buffer0(to_integer(input_addr)) <= feature_stream;
            if input_addr = 256*13-1 then
              input_addr <= (others => '0');
              wr_buffer <= '1';
              buffer0_full <= '1';
            else
              input_addr <= input_addr+1;
            end if;
          end if;
        else
          if buffer1_full = '0' and feature_valid = '1' then
            mem_buffer1(to_integer(input_addr)) <= feature_stream;
            if input_addr = 256*13-1 then
              input_addr <= (others => '0');
              wr_buffer <= '0';
              buffer1_full <= '1';
            else
              input_addr <= input_addr+1;
            end if;
          end if;
        end if;
        wadv <= '0';
        if rd_buffer = '0' then
          if buffer0_full = '1' and nfull = '0' then
            wadv <= '1';
            if fcount = 255 then
              fcount <= (others => '0');
              if pixel_rs = '0' then
                rd_addr <= rd_addr-255;
                pixel_rs <= '1';
              else
                pixel_rs <= '0';
                if pcount = 12 then
                  rd_addr <= (others => '0');
                  pcount <= (others => '0');
                  if line_rs = '0' then
                    line_rs <= '1';
                  else
                    line_rs <= '0';
                    buffer0_full <= '0';
                    rd_buffer <= '1';
                  end if;
                else
                  rd_addr <= rd_addr+1;
                  pcount <= pcount+1;
                end if;
              end if;
            else
              fcount <= fcount+1;
              rd_addr <= rd_addr+1;
            end if;
          end if;
        else
          if buffer1_full = '1' and nfull = '0' then
            wadv <= '1';
            if fcount = 255 then
              fcount <= (others => '0');
              if pixel_rs = '0' then
                rd_addr <= rd_addr-255;
                pixel_rs <= '1';
              else
                pixel_rs <= '0';
                if pcount = 12 then
                  rd_addr <= (others => '0');
                  pcount <= (others => '0');
                  if line_rs = '0' then
                    line_rs <= '1';
                  else
                    line_rs <= '0';
                    buffer1_full <= '0';
                    rd_buffer <= '0';
                  end if;
                else
                  rd_addr <= rd_addr+1;
                  pcount <= pcount+1;
                end if;
              end if;
            else
              fcount <= fcount+1;
              rd_addr <= rd_addr+1;
            end if;
          end if;
        end if;
        
      end if;
      if rd_buffer = '0' then
        wdata <= mem_buffer1(to_integer(rd_addr));
      else
        wdata <= mem_buffer0(to_integer(rd_addr));
      end if;
    end if;
  end process;

  small_sfifo_1: small_sfifo
    generic map (
      width => feature_width)
    port map (
      clk    => clk,
      rst    => rst,
      wadv   => wadv,
      wdata  => wdata,
      nfull  => nfull,
      radv   => radv,
      rempty => rempty,
      rdata  => rdata);

  rs_valid <= not rempty;
  radv <= rs_ready and not rempty;
  rs_stream <= rdata;
 
end architecture;
