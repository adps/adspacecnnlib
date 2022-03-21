library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity led_driver is
  generic(
    invert : in    boolean := false
  );
  port(              
    clk    : in    std_logic;
    d      : in    std_logic;
    q      : out   std_logic
  );
end entity;

architecture rtl of led_driver is
  
  signal d_q1, d_q2 : std_logic;
  
begin

  drive_q : process(clk)
  begin
    if rising_edge(clk) then
      d_q1 <= d;

      if invert then
        d_q2 <= not d_q1;
      else
        d_q2 <= d_q1;
      end if;
      
      q <= d_q2;
    end if;
  end process;
    
end architecture;
