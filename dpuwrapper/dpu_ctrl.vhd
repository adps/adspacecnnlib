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



entity dpu_ctrl is
  port (
    clk : in std_logic;
    rst : in std_logic;
    -- Start Command
    start_addr : in std_logic_vector(63 downto 0);
    start_addr_valid : in std_logic;
    -- IU Data Mover Control
    iudm_command : out std_logic_vector(103 downto 0);
    iudm_valid   : out std_logic;
    iudm_ready   : in  std_logic;
    iudm_status  : in std_logic_vector(7 downto 0);
    iudm_status_valid : in std_logic;
    iudm_status_ready : out std_logic;
    iudm_data : in std_logic_vector(31 downto 0);
    iudm_data_valid : in std_logic;
    iudm_data_ready : out std_logic;
    iudm_data_last : in std_logic;
    -- Weights Data Mover Control
    wdm_command : out std_logic_vector(103 downto 0);
    wdm_valid   : out std_logic;
    wdm_ready   : in  std_logic;
    wdm_status  : in std_logic_vector(7 downto 0);
    wdm_status_valid : in std_logic;
    wdm_status_ready : out std_logic;
    wdm_data_last : in std_logic;
    -- Inputs Data Mover Control
    idm_command : out std_logic_vector(103 downto 0);
    idm_valid   : out std_logic;
    idm_ready   : in  std_logic;
    idm_status  : in std_logic_vector(7 downto 0);
    idm_status_valid : in std_logic;
    idm_status_ready : out std_logic;
    -- Output Data Mover Control
    odm_command : out std_logic_vector(103 downto 0);
    odm_valid   : out std_logic;
    odm_ready   : in  std_logic;
    odm_status  : in std_logic_vector(7 downto 0);
    odm_status_valid : in std_logic;
    odm_status_ready : out std_logic;
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
    access_error : out std_logic_vector(35 downto 0);
    clear_error  : in  std_logic
  );
end entity;

architecture rtl of dpu_ctrl is

  signal dpu_ctrl_sr, dpu_ctrl_iword : std_logic_vector(1023 downto 0) := (others => '0');

  type iwfsm_type is (idle,read_iw,wait_iw,reading_iw,read_weights,wait_weights,reading_weights,start_writer,start_dpu,dpu_active,in_error);
  
  signal iwfsm_state : iwfsm_type := idle;

  signal next_start_addr : std_logic_vector(63 downto 0);
  signal next_start_addr_valid : std_logic;
  signal iudm_data_last_r1 : std_logic;
  
begin

  relu <= dpu_ctrl_iword(0);
  conv_3x3 <= dpu_ctrl_iword(1);
  use_maxpool <= dpu_ctrl_iword(2);
  stride2 <= dpu_ctrl_iword(3);
  feature_image_width <= dpu_ctrl_iword(16+13 downto 16);
  number_of_features <= dpu_ctrl_iword(32+11 downto 32);
  mp_feature_image_width <= dpu_ctrl_iword(48+13 downto 48);
  mp_number_of_features <= dpu_ctrl_iword(64+11 downto 64);
  number_of_active_neurons <= dpu_ctrl_iword(80+9 downto 80);
  throttle_rate <= dpu_ctrl_iword(96+9 downto 96);

  wdm_command <= dpu_ctrl_iword(103+128 downto 128);
  idm_command <= dpu_ctrl_iword(103+256 downto 256);
  odm_command <= dpu_ctrl_iword(103+384 downto 384);
  next_start_addr <= dpu_ctrl_iword(63+512 downto 512);
  next_start_addr_valid <= dpu_ctrl_iword(64+512);
  
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        iwfsm_state <= idle;
        iudm_valid <= '0';
        iudm_status_ready <= '1';
        iudm_data_ready <= '1';
        wdm_valid <= '0';
        wdm_status_ready <= '1';
        odm_valid <= '0';
        odm_status_ready <= '1';
        idm_valid <= '0';
        idm_status_ready <= '1';
      else
        case iwfsm_state is
          when idle =>
            if start_addr_valid = '1' then
              iwfsm_state <= read_iw;
              iudm_command <= X"00" & start_addr & X"40800080";
              iudm_valid <= '1';
              iudm_status_ready <= '1';
              iudm_data_ready <= '1';
            elsif next_start_addr_valid = '1' then
              iwfsm_state <= read_iw;
              iudm_command <= X"00" & next_start_addr & X"40800080";
              iudm_valid <= '1';
              iudm_status_ready <= '1';
              iudm_data_ready <= '1';
            end if;
          when read_iw =>
            if iudm_ready = '1' then
              iwfsm_state <= wait_iw;
              iudm_valid <= '0';
            end if;
          when wait_iw =>
            if iudm_status_valid = '1' then
              if iudm_status(7) = '1' then
                iwfsm_state <= reading_iw;
              else
                iwfsm_state <= in_error;
              end if;
              iudm_status_ready <= '0';
            end if;
          when reading_iw =>
            if iudm_data_last = '1' then
              iudm_data_ready <= '0';
            end if;
            if iudm_data_last_r1 = '1' then             
              iwfsm_state <= read_weights;
              wdm_valid <= '1';
              wdm_status_ready <= '1';                     
              iudm_data_ready <= '0';
            end if;
          when read_weights =>
            if wdm_ready = '1' then
              iwfsm_state <= wait_weights;
              wdm_valid <= '0';
            end if;
          when wait_weights =>
            if wdm_status_valid = '1' then
              if wdm_status(7) = '1' then
                iwfsm_state <= reading_weights;
              else
                iwfsm_state <= in_error;
              end if;
              wdm_status_ready <= '0';
            end if;
          when reading_weights =>
            if wdm_data_last = '1' then           
              iwfsm_state <= start_writer;
              odm_valid <= '1';
              odm_status_ready <= '1';            
            end if;
          when start_writer =>
            if odm_ready = '1' then
              iwfsm_state <= start_dpu;
              odm_valid <= '0';
              idm_valid <= '1';
              idm_status_ready <= '1';
            end if;
          when start_dpu =>
            if idm_ready = '1' then
              iwfsm_state <= dpu_active;
              idm_valid <= '0';
            end if;
          when dpu_active =>
            if odm_status_valid = '1' then
              if odm_status(7) = '1' then
                iwfsm_state <= idle;
              else
                iwfsm_state <= in_error;
              end if;
              odm_status_ready <= '0';
            end if;
            if idm_status_valid = '1' then
              if idm_status(7) = '0' then
                iwfsm_state <= in_error;
              end if;
            end if;
          when in_error =>
            if clear_error = '1' then
              iwfsm_state <= idle;
            end if;
          when others =>
            iwfsm_state <= idle;
          end case;
      end if;
    end if;
  end process;


  process (clk)
  begin
    if rising_edge(clk) then
      if iudm_data_valid = '1' and iwfsm_state = reading_iw then
        dpu_ctrl_sr <= iudm_data & dpu_ctrl_sr(1023 downto 32);
      end if;
      iudm_data_last_r1 <= iudm_data_last;
      if iudm_data_last_r1 = '1' then
        dpu_ctrl_iword <= dpu_ctrl_sr;
      end if;
      if iwfsm_state /= in_error then
        access_error(31 downto 0) <= odm_status & idm_status & wdm_status & iudm_status;
      end if;
      case iwfsm_state is
        when idle => access_error(35 downto 32) <= "0000";
        when read_iw => access_error(35 downto 32) <= "0001";
        when reading_iw => access_error(35 downto 32) <= "0010";             
        when read_weights => access_error(35 downto 32) <= "0011";
        when reading_weights => access_error(35 downto 32) <= "0100";
        when start_writer => access_error(35 downto 32) <= "0101";
        when start_dpu => access_error(35 downto 32) <= "0110";             
        when dpu_active => access_error(35 downto 32) <= "0111";
        when in_error => access_error(35 downto 32) <= "1111";
        when others => access_error(35 downto 32) <= "1110";
      end case;
      
    end if;
  end process;
  
  
end architecture;
