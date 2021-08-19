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
-- prog_length_sr.vhd
-- Programmable length Shift registers, implemented as memory 
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


--use std.textio.all; --  Imports the standard textio package.

entity prog_length_sr is
  generic (
    width : natural := 8;
    memory_depth : natural := 9
    );   
  port (
    clk : in std_logic;
    rst : in std_logic;
    length : in std_logic_vector(memory_depth-1 downto 0);
    set_length : in std_logic;
    data_in : std_logic_vector(width-1 downto 0);
    data_in_valid : in std_logic;
    data_out : out std_logic_vector(width-1 downto 0);
    data_out_valid : out std_logic);
end entity;

architecture rtl of prog_length_sr is

  constant memory_size : integer := 2**memory_depth;
  type memory_type is array (0 to memory_size-1) of std_logic_vector(width-1 downto 0);

  signal mem : memory_type;
  signal mem_out : std_logic_vector(width-1 downto 0);
  signal wr_addr, rd_addr : unsigned(memory_depth-1 downto 0);
  signal dv1 : std_logic;
  
  
  
begin
  
  process (clk)
  begin
    if rising_edge(clk) then
      if data_in_valid = '1' then
        mem(to_integer(wr_addr)) <= data_in;
      end if;
      mem_out <= mem(to_integer(rd_addr));

      if data_in_valid = '1' then
        wr_addr <= wr_addr+1;
        rd_addr <= rd_addr+1;
      end if;
      dv1 <= data_in_valid;
      data_out_valid <= dv1;
      
      if set_length = '1' then
        rd_addr <= (others => '0');
        wr_addr <= unsigned(length)+1;
      end if;
      if rst = '1' then
        rd_addr <= (others => '0');
        wr_addr <= unsigned(length)+1;
        dv1 <= '0';
        data_out_valid <= '0';
      end if;      
    end if;
  end process;
  
  data_out <= mem_out;

end architecture;
