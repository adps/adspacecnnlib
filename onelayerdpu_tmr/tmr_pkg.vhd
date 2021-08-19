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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package tmr is

  type tmr_logic is array (0 to 2) of std_logic;
  type tmr_logic_vector is array (natural range <>) of tmr_logic;
  type tmr_unsigned is array (natural range <>) of tmr_logic;



  function "=" (L : tmr_logic; R : tmr_logic) return boolean;
  function "=" (L : tmr_logic; R : std_logic) return boolean;
  function "=" (L : std_logic; R : tmr_logic) return boolean;
  function "not" (x : tmr_logic) return tmr_logic

;

  function "and" (L : tmr_logic; R : tmr_logic) return tmr_logic;
  function "or" (L : tmr_logic; R : tmr_logic) return tmr_logic;
  
  function tmr_resolve(x : tmr_logic) return std_logic;
  function to_tmr_logic(x : std_logic) return tmr_logic;
  
  function to_tmr_logic_vector(x : std_logic_vector) return tmr_logic_vector;
  function to_tmr_logic_vector(x0 : std_logic_vector; x1 : std_logic_vector; x2 : std_logic_vector) return tmr_logic_vector;
  function to_std_logic_vector(x : tmr_logic_vector; index : integer) return std_logic_vector;
  function to_tmr_logic_vector(x : tmr_unsigned) return tmr_logic_vector;
    
  function tmr_resolve(x : tmr_logic_vector) return std_logic_vector;
  function tmr_flatten(x : tmr_logic_vector) return std_logic_vector;
  function tmr_unflatten(x : std_logic_vector) return tmr_logic_vector;
  
  function to_tmr_unsigned(x : unsigned) return tmr_unsigned;
  function to_tmr_unsigned(x0 : unsigned; x1 : unsigned; x2 : unsigned) return tmr_unsigned;

  function to_unsigned(x : tmr_unsigned; index : integer) return unsigned;
  function to_tmr_unsigned(x : tmr_logic_vector) return tmr_unsigned;
  
  function tmr_resolve(x : tmr_unsigned) return unsigned;

  function "+" (L: tmr_unsigned; R: tmr_unsigned) return tmr_unsigned;
  function "-" (L: tmr_unsigned; R: tmr_unsigned) return tmr_unsigned;
  function "-" (L: tmr_unsigned; R: integer) return tmr_unsigned;
  function "+" (L: tmr_unsigned; R: integer) return tmr_unsigned;

  function "=" (L : tmr_logic_vector; R : tmr_logic_vector) return boolean;
  function "/=" (L : tmr_logic_vector; R : tmr_logic_vector) return boolean;

  function ">=" (L : tmr_unsigned; R : integer) return boolean;
  function "<" (L : tmr_unsigned; R : tmr_unsigned) return boolean;
  function ">" (L : tmr_unsigned; R : tmr_unsigned) return boolean; 
  function "*" (L: tmr_unsigned; R: tmr_unsigned) return tmr_unsigned;
  
  
end;

package body tmr is
  
  function "=" (L : tmr_logic; R : tmr_logic) return boolean is
  begin
    if L(0) = R(0) then
      if L(1) = R(1) or L(2) = R(2) then
        return true;
      else
        return false;
      end if;
    else
      if L(1) = R(1) and L(2) = R(2) then
        return true;
      else
        return false;
      end if;
    end if;
  end function;
    
  function "=" (L:tmr_logic; R:std_logic) return boolean is
  begin
    if L(0) = R then
      if L(1) = R or L(2) = R then
        return true;
      else
        return false;
      end if;
    else
      if L(1) = R and L(2) = R then
        return true;
      else
        return false;
      end if;
    end if;
  end function;


  function "=" (L:std_logic; R:tmr_logic) return boolean is
  begin
    if L = R(0) then
      if L = R(1) or L = R(2) then
        return true;
      else
        return false;
      end if;
    else
      if L = R(1) and L = R(2) then
        return true;
      else
        return false;
      end if;
    end if;
  end function;

  function "not" (x : tmr_logic) return tmr_logic is
    variable y : tmr_logic;
  begin
    y(0) := not x(0);
    y(1) := not x(1);
    y(2) := not x(2);
    return y;
  end function; 


  function "and" (L : tmr_logic; R : tmr_logic) return tmr_logic is
    variable y : tmr_logic;
  begin
    y(0) := L(0) and R(0);
    y(1) := L(1) and R(1);
    y(2) := L(2) and R(2);
    return y;
  end function; 
    
  function "or" (L : tmr_logic; R : tmr_logic) return tmr_logic is 
  variable y : tmr_logic;
  begin
    y(0) := L(0) or R(0);
    y(1) := L(1) or R(1);
    y(2) := L(2) or R(2);
    return y;
  end function; 
  
  function tmr_resolve(x : tmr_logic) return std_logic is
  begin
    if (x(0) = '0' or x(0) = '1') and (x(1) = '0' or x(1) = '1') and (x(2) = '0' or x(2) = '1') then
      if x="111" or x="110" or x="101" or x="011" then
        return '1';
      else
        return '0';
      end if;
    else
      return 'X';
    end if;   
  end function;        

  function to_tmr_logic(x : std_logic) return tmr_logic is
    variable y : tmr_logic;
  begin
    y := (others => x);
    return y;
  end function;
  

    
  function to_tmr_logic_vector(x : std_logic_vector) return tmr_logic_vector is
    variable y : tmr_logic_vector(x'range);
  begin
    for i in x'low to x'high loop
      y(i)(0) := x(i);
      y(i)(1) := x(i);
      y(i)(2) := x(i);      
    end loop;
    return y;
  end function;

  function to_tmr_logic_vector(x0 : std_logic_vector ; x1 : std_logic_vector; x2 : std_logic_vector) return tmr_logic_vector is
    variable y : tmr_logic_vector(x0'range);
  begin
    for i in x0'low to x0'high loop
      y(i)(0) := x0(i);
      y(i)(1) := x1(i);
      y(i)(2) := x2(i);      
    end loop;
    return y;
  end function;

  function to_std_logic_vector(x : tmr_logic_vector; index : integer) return std_logic_vector is
    variable y : std_logic_vector(x'range);
  begin
    for i in x'low to x'high loop
      y(i) := x(i)(index);     
    end loop;
    return y;
  end function;

  function to_tmr_logic_vector(x : tmr_unsigned) return tmr_logic_vector is
    variable y : tmr_logic_vector(x'range);
  begin
    for i in x'low to x'high loop
      y(i)(0) := x(i)(0);
      y(i)(1) := x(i)(1);
      y(i)(2) := x(i)(2);      
    end loop;
    return y;
  end function;
  
  
  function tmr_resolve(x : tmr_logic_vector) return std_logic_vector is
    variable y : std_logic_vector(x'range);
  begin
     for i in x'low to x'high loop
      y(i) := tmr_resolve(x(i));     
    end loop;
    return y;     
  end function;


 function tmr_flatten(x : tmr_logic_vector) return std_logic_vector is
    variable y : std_logic_vector(x'high*3+2 downto 0);
  begin
     for i in x'low to x'high loop
       for j in 0 to 2 loop
         y(3*i+j) := x(i)(j);
       end loop;
    end loop;
    return y;     
  end function;
    
  function tmr_unflatten(x : std_logic_vector) return tmr_logic_vector is
    variable y : tmr_logic_vector((x'high+1)/3-1 downto 0);
  begin
     for i in y'low to y'high loop
        for j in 0 to 2 loop
         y(i)(j) := x(3*i+j);
        end loop;
     end loop;
    return y;     
  end function;
  

  function to_tmr_unsigned(x : unsigned) return tmr_unsigned is
    variable y : tmr_unsigned(x'range);
  begin
    for i in x'low to x'high loop
      y(i)(0) := x(i);
      y(i)(1) := x(i);
      y(i)(2) := x(i);      
    end loop;
    return y;
  end function;

  function to_tmr_unsigned(x : tmr_logic_vector) return tmr_unsigned is
    variable y : tmr_unsigned(x'range);
  begin
    for i in x'low to x'high loop
      y(i)(0) := x(i)(0);
      y(i)(1) := x(i)(1);
      y(i)(2) := x(i)(2);      
    end loop;
    return y;
  end function;

  function to_tmr_unsigned(x0 : unsigned; x1 : unsigned; x2 : unsigned) return tmr_unsigned is
    variable y : tmr_unsigned(x0'range);
  begin
    for i in x0'low to x0'high loop
      y(i)(0) := x0(i);
      y(i)(1) := x1(i);
      y(i)(2) := x2(i);      
    end loop;
    return y;
  end function;  

  function to_unsigned(x : tmr_unsigned; index : integer) return unsigned is
    variable y : unsigned(x'range);
  begin
    for i in x'low to x'high loop
      y(i) := x(i)(index);     
    end loop;
    return y;
  end function;

  function tmr_resolve(x : tmr_unsigned) return unsigned is
    variable y : unsigned(x'range);
  begin
     for i in x'low to x'high loop
      y(i) := tmr_resolve(x(i));     
    end loop;
    return y;     
  end function; 
  
  function "+" (L: tmr_unsigned; R: tmr_unsigned) return tmr_unsigned is
    variable y : tmr_unsigned(L'range);
    variable s0,s1,s2 : unsigned(L'range);
    constant l0 : integer := L'length;
    constant l1 : integer := R'length;
  begin
    assert l0 = l1 report "tmr_unsigned width mismatch" severity failure;
    s0 := to_unsigned(L,0) + to_unsigned(R,0);
    s1 := to_unsigned(L,1) + to_unsigned(R,1);
    s2 := to_unsigned(L,2) + to_unsigned(R,2);
    y := to_tmr_unsigned(s0,s1,s2);
    return y;
  end function;

  function "-" (L: tmr_unsigned; R: tmr_unsigned) return tmr_unsigned is
    variable y : tmr_unsigned(L'range);
    variable s0,s1,s2 : unsigned(L'range);
    constant l0 : integer := L'length;
    constant l1 : integer := R'length;
  begin
   assert l0 = l1 report "tmr_unsigned width mismatch" severity failure;
    s0 := to_unsigned(L,0) - to_unsigned(R,0);
    s1 := to_unsigned(L,1) - to_unsigned(R,1);
    s2 := to_unsigned(L,2) - to_unsigned(R,2);
    y := to_tmr_unsigned(s0,s1,s2);
    return y;
  end function;

  function "-" (L: tmr_unsigned; R: integer) return tmr_unsigned is
    variable y : tmr_unsigned(L'range);
    variable s0,s1,s2 : unsigned(L'range);
  begin
    s0 := to_unsigned(L,0) - R;
    s1 := to_unsigned(L,1) - R;
    s2 := to_unsigned(L,2) - R;
    y := to_tmr_unsigned(s0,s1,s2);
    return y;
  end function;

  function "+" (L: tmr_unsigned; R: integer) return tmr_unsigned is
    variable y : tmr_unsigned(L'range);
    variable s0,s1,s2 : unsigned(L'range);
  begin
    s0 := to_unsigned(L,0) + R;
    s1 := to_unsigned(L,1) + R;
    s2 := to_unsigned(L,2) + R;
    y := to_tmr_unsigned(s0,s1,s2);
    return y;
  end function;
  

  function "=" (L : tmr_logic_vector; R : tmr_logic_vector) return boolean is
    variable e0,e1,e2 : boolean;
    constant l0 : integer := L'length;
    constant l1 : integer := R'length;
  begin
    assert l0 = l1 report "tmr_unsigned width mismatch" severity failure;
    e0 := (to_std_logic_vector(L,0) = to_std_logic_vector(R,0));
    e1 := (to_std_logic_vector(L,1) = to_std_logic_vector(R,1));
    e2 := (to_std_logic_vector(L,2) = to_std_logic_vector(R,2));
    return ((e0 and e1) or (e0 and e2) or (e1 and e2));
  end function; 

    
  function "/=" (L : tmr_logic_vector; R : tmr_logic_vector) return boolean is
  begin
    return not (L=R);
  end function;


  function "=" (L : tmr_unsigned; R : tmr_unsigned) return boolean is
    variable e0,e1,e2 : boolean;
    constant l0 : integer := L'length;
    constant l1 : integer := R'length;
  begin
    assert l0 = l1 report "tmr_unsigned width mismatch" severity failure;
    e0 := (to_unsigned(L,0) = to_unsigned(R,0));
    e1 := (to_unsigned(L,1) = to_unsigned(R,1));
    e2 := (to_unsigned(L,2) = to_unsigned(R,2));
    return ((e0 and e1) or (e0 and e2) or (e1 and e2));
  end function;


  function ">=" (L : tmr_unsigned; R : integer) return boolean is
    variable e0,e1,e2 : boolean;
  begin
    
    e0 := (to_unsigned(L,0) >= R);
    e1 := (to_unsigned(L,1) >= R);
    e2 := (to_unsigned(L,2) >= R);
    return ((e0 and e1) or (e0 and e2) or (e1 and e2));
  end function;

  function "<" (L : tmr_unsigned; R : tmr_unsigned) return boolean is
    variable e0,e1,e2 : boolean;
    constant l0 : integer := L'length;
    constant l1 : integer := R'length;
  begin
    assert l0 = l1 report "tmr_unsigned width mismatch" severity failure;
    e0 := (to_unsigned(L,0) < to_unsigned(R,0));
    e1 := (to_unsigned(L,1) < to_unsigned(R,1));
    e2 := (to_unsigned(L,2) < to_unsigned(R,2));
    return ((e0 and e1) or (e0 and e2) or (e1 and e2));
  end function;

  function ">" (L : tmr_unsigned; R : tmr_unsigned) return boolean is
    variable e0,e1,e2 : boolean;
    constant l0 : integer := L'length;
    constant l1 : integer := R'length;
  begin
    assert l0 = l1 report "tmr_unsigned width mismatch" severity failure;
    e0 := (to_unsigned(L,0) > to_unsigned(R,0));
    e1 := (to_unsigned(L,1) > to_unsigned(R,1));
    e2 := (to_unsigned(L,2) > to_unsigned(R,2));
    return ((e0 and e1) or (e0 and e2) or (e1 and e2));
  end function;

   function "*" (L: tmr_unsigned; R: tmr_unsigned) return tmr_unsigned is
    variable y : tmr_unsigned(L'high+R'high+1 downto 0);
    variable s0,s1,s2 : unsigned(L'high+R'high+1 downto 0);
  begin
    s0 := to_unsigned(L,0) * to_unsigned(R,0);
    s1 := to_unsigned(L,1) * to_unsigned(R,1);
    s2 := to_unsigned(L,2) * to_unsigned(R,2);
    y := to_tmr_unsigned(s0,s1,s2);
    return y;
  end function;

    
end;
