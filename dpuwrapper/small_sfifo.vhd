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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

entity small_sfifo is
  
  generic (
    width : integer := 64);

  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    wadv   : in  std_logic;
    wdata  : in  std_logic_vector(width-1 downto 0);
    nfull  : out std_logic;
    radv   : in  std_logic;
    rempty : out std_logic;
    rdata  : out std_logic_vector(width-1 downto 0));

end small_sfifo;

architecture rtl of small_sfifo is

  type fifo_type is array (0 to 15) of std_logic_vector(width-1 downto 0);

  signal ofifo_regs                    : fifo_type                          := (others => (others => '0'));
  signal ofifo_rptr, ofifo_wptr        : std_logic_vector(3 downto 0)       := "0000";
  signal ofifo_level                   : std_logic_vector(4 downto 0)       := "00000";
  signal ofifo_out, ofifo_in           : std_logic_vector(width-1 downto 0) := (others => '0');
  signal ofifo_empty                   : std_logic                          := '1';
  signal ofifo_wr, ofifo_rd, ofifo_wr1 : std_logic                          := '0';
  
begin  -- rtl

  ofifo_wr <= wadv;
  ofifo_in <= wdata;

  -- 16 word FIFO to allow FWFT operation to make FIFO useful
  ofifo : process (clk)
  begin  -- process ofifo

    if clk'event and clk = '1' then     -- rising clock edge
      if rst = '1' then                 -- asynchronous reset
        ofifo_level <= "00000";
        ofifo_rptr  <= "0000";
        ofifo_wptr  <= "0000";
        ofifo_empty <= '1';
        nfull       <= '0';
        ofifo_wr1   <= '0';
      else
        -- Delayed fifo write for improving timing at cost of
        -- NFULL and EMPTY being delayed wrt WADV
        -- FIFO may have 10 elements before NFULL asserted
        ofifo_wr1 <= ofifo_wr;
        if ofifo_wr1 = '1' and ofifo_rd = '0' then
          ofifo_level <= ofifo_level+1;
          ofifo_empty <= '0';
        elsif ofifo_wr1 = '0' and ofifo_rd = '1' then
          ofifo_level <= ofifo_level-1;
          if ofifo_level = "00001" then
            ofifo_empty <= '1';
          end if;
        end if;
        if ofifo_wr = '1' then
          ofifo_wptr <= ofifo_wptr+1;
        end if;
        if ofifo_rd = '1' and ofifo_level /= "00000" then
          ofifo_rptr <= ofifo_rptr+1;
        end if;
        nfull <= ofifo_level(3) or ofifo_level(4);
      end if;
    end if;
  end process ofifo;

  process (clk) is
  begin  -- process
    if rising_edge(clk) then            -- rising clock edge
      if ofifo_wr = '1' then
        ofifo_regs(conv_integer(ofifo_wptr)) <= ofifo_in;
      end if;
    end if;
  end process;

  ofifo_out <= ofifo_regs(conv_integer(ofifo_rptr));

  ofifo_rd <= radv and not ofifo_empty;
  rempty   <= ofifo_empty;
  rdata    <= ofifo_out;
  
end rtl;

