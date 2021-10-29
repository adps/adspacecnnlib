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
-- write_striper
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;



entity write_striper is
  port (
    clk : in std_logic;
    rst : in std_logic;
  
    -- Data Mover Control
    odm_command : out std_logic_vector(103 downto 0);
    odm_valid   : out std_logic;
    odm_ready   : in  std_logic;
    odm_status  : in std_logic_vector(7 downto 0);
    odm_status_valid : in std_logic;
    odm_status_ready : out std_logic;

    -- Data Mover Connection to FSM
    int_odm_command : in std_logic_vector(103 downto 0);
    int_odm_valid   : in std_logic;
    int_odm_ready   : out std_logic;
    int_odm_status  : out std_logic_vector(7 downto 0);
    int_odm_status_valid : out std_logic;
    int_odm_status_ready : in std_logic;

    -- Striping Control
    striping_command_count : in std_logic_vector(23 downto 0);
    striping_addr_incr : in std_logic_vector(31 downto 0)

    );
end entity;

architecture rtl of write_striper is

  signal odm_command_reg : std_logic_vector(103 downto 0);
  signal odm_valid_reg : std_logic := '0';
  signal odm_command_count : unsigned(23 downto 0);
  signal odm_status_count : unsigned(23 downto 0);
  signal odm_addr_incr : unsigned(31 downto 0);

  signal int_odm_ready_reg : std_logic := '1';
  
begin
--
-- ODM Control FSMs
-- Allows repeats of the ODM command to be sent with address increments
-- This allows support of striping writes
--

  odm_fsm1: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        odm_command_reg <= (others => '0');
        odm_valid_reg <= '0';
        int_odm_ready_reg <= '1';
        int_odm_status_valid <= '0';
        odm_command_count <= (others => '0');
        odm_status_count <= (others => '0');
        odm_addr_incr <= (others => '0');
      else
        int_odm_status_valid <= '0';
        
        if int_odm_ready_reg = '1' then
          if int_odm_valid = '1' then
            odm_command_reg <= int_odm_command;
            odm_command_count <= unsigned(striping_command_count);
            odm_status_count <= unsigned(striping_command_count);
            odm_addr_incr <= unsigned(striping_addr_incr);
            int_odm_ready_reg <= '0';
            odm_valid_reg <= '1';
          end if;
        else
          if odm_valid_reg = '1' then
            if odm_ready = '1' then
              odm_valid_reg <= '0';
            end if;
          else
            if odm_command_count = 0 then
              if odm_status_count = 0 then
                if odm_status_valid = '1' then
                  int_odm_ready_reg <= '1';
                end if;
              end if;
            else
              odm_command_count <= odm_command_count-1;
              -- Note Writes must not cross 4GB boundary
              odm_command_reg(63 downto 32) <= std_logic_vector(unsigned(odm_command_reg(63 downto 32)) + odm_addr_incr);
              odm_valid_reg <= '1';
            end if;
          end if;

          if odm_status_valid = '1' then
            if odm_status(7) = '1' then
              if odm_status_count = 0 then
                int_odm_status <= odm_status;
                int_odm_status_valid <= '1';
              else
                odm_status_count <= odm_status_count-1;
              end if;
            else
              odm_status_count <= (others => '0');
              int_odm_status <= odm_status;
              int_odm_status_valid <= '1';
            end if;
          end if;          
        end if;
      end if;
    end if;
  end process; 

  odm_command <= odm_command_reg;
  odm_valid <= odm_valid_reg;
  int_odm_ready <= int_odm_ready_reg;
  odm_status_ready <= not int_odm_ready_reg;

end architecture;  
