
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

use std.textio.all;  --  Imports the standard textio package.


library work;
use work.cnn_defs.all;



package cnn_tools is


  procedure read_weights_files (
    constant bias_filename     : in  string;
    constant weight_filename   : in  string;
    constant weight_scaling    : in  integer;
    constant bias_scaling      : in  integer;
    constant layer_size        : in  integer;
    constant input_mask_height : in  integer;
    constant input_mask_width  : in  integer;
    constant input_no_features : in  integer;
    signal clk                 : in  std_logic;
    signal weight_stream       : out std_logic_vector(weight_width-1 downto 0);
    signal weight_id           : out std_logic_vector(weight_id_width-1 downto 0);
    signal weight_first        : out std_logic;
    signal weight_last         : out std_logic);

  procedure read_feature_file (
    constant feature_filename  : in  string;
    constant input_bias        : in  integer;
    constant input_height      : in  integer;
    constant input_width       : in  integer;
    constant input_no_features : in  integer;
    signal clk                 : in  std_logic;
    signal feature_stream      : out std_logic_vector(feature_width-1 downto 0);
    signal feature_valid       : out std_logic;
    signal feature_ready       : in  std_logic);


  procedure read_weights_file_nobias (
    constant weight_filename   : in  string;
    constant weight_scaling    : in  integer;
    constant layer_size        : in  integer;
    constant input_mask_height : in  integer;
    constant input_mask_width  : in  integer;
    constant input_no_features : in  integer;
    signal clk                 : in  std_logic;
    signal weight_stream       : out std_logic_vector(weight_width-1 downto 0);
    signal weight_id           : out std_logic_vector(weight_id_width-1 downto 0);
    signal weight_first        : out std_logic;
    signal weight_last         : out std_logic);


  procedure read_xcaffe_file (
    constant xcaffe_filename   : in  string;
    constant layer_name        : in  string;
    constant scale_layer_name  : in  string;
    constant bn_layer_name  : in  string;
    constant has_bias          : in  boolean;
    constant weight_scaling    : in  real;
    constant layer_size        : in  integer;
    constant input_mask_height : in  integer;
    constant input_mask_width  : in  integer;
    constant input_no_features : in  integer;
    constant neuron_skip      : in  integer;
    signal clk                 : in  std_logic;
    signal weight_stream       : out std_logic_vector(weight_width-1 downto 0);
    signal weight_id           : out std_logic_vector(weight_id_width-1 downto 0);
    signal weight_first        : out std_logic;
    signal weight_last         : out std_logic);



  function string_find(s : string; p : string) return boolean;
  function string_pos(s  : string; p : string; start : natural := 0) return integer;

  type integer_array is array (natural range <>) of integer;
  type real_array is array (natural range <>) of real;
  
end;

package body cnn_tools is


  function string_find(s : string; p : string) return boolean is
  begin
    return (string_pos(s, p) > 0);
  end function;


  function string_pos(s : string; p : string; start : natural := 0) return integer is
  begin
    for i in s'low to (s'high - p'length + 1) loop
      exit when (s(i) = '~');
      if (s(i to i + p'length - 1) = p) then
        return i;
      end if;
    end loop;
    return -1;
  end function;


  procedure read_xcaffe_file (
    constant xcaffe_filename   : in  string;
    constant layer_name        : in  string;
    constant scale_layer_name  : in  string;
    constant bn_layer_name     : in  string;
    constant has_bias          : in  boolean;
    constant weight_scaling    : in  real;
    constant layer_size        : in  integer;
    constant input_mask_height : in  integer;
    constant input_mask_width  : in  integer;
    constant input_no_features : in  integer;
    constant neuron_skip      : in  integer;
    signal clk                 : in  std_logic;
    signal weight_stream       : out std_logic_vector(weight_width-1 downto 0);
    signal weight_id           : out std_logic_vector(weight_id_width-1 downto 0);
    signal weight_first        : out std_logic;
    signal weight_last         : out std_logic) is
    
    variable l                      : line;
    variable il                     : line;
    variable ils                    : string(1 to 255);
    variable ill : integer; 
    variable real_file              : real;
    variable int_file               : integer;
    variable read_weights           : boolean;
    variable found_line_of_interest : boolean;
    file xcaffe_file                : text is in xcaffe_filename;   
    variable weight_array           : real_array (0 to 65535*4);
    variable bias_array             : real_array (0 to 1023*4);
    variable weight_index           : integer;
    variable bias_index             : integer;
    variable x                      : integer;
    variable p                      : real;
    variable skip                   : integer;
  begin
    read_weights           := false;
    found_line_of_interest := false;
    -- Read in weights and bias from files into arrays.
    write (l, string'("Opening file : "));
    write (l,xcaffe_filename);
    writeline(output, l);
    if endfile(xcaffe_file) then
      assert false report "file not found" severity error;
    end if;
    
    while (not endfile(xcaffe_file)) and (not found_line_of_interest) loop
      readline(xcaffe_file, il);
      ils := (others => '~');
      ill := il'length;
      read(il, ils(1 to ill)); 
      if string_find(ils(1 to ill), "name:") then
        write (l, string'("Found a name line:"));
        write(l,string'(ils(1 to ill)));
        writeline(output, l);
        if string_find(ils(1 to ill), layer_name) then
          found_line_of_interest := true;
        end if;
      end if;
    end loop;
    found_line_of_interest := false;
    while (not endfile(xcaffe_file)) and (not found_line_of_interest) loop
      readline(xcaffe_file, il);
      ils := (others => '~');
      ill := il'length;
      read(il, ils(1 to ill));
      if string_find(ils(1 to ill), "blobs") then
        write (l, string'("Found Weights blob start line:"));
        write(l,string'(ils(1 to ill)));
        writeline(output, l);
        found_line_of_interest := true;
      end if;
    end loop;

    weight_index := 0;
    -- Skip over data for partially implementing layers larger than the DPU size
    skip := 0;
    while skip < (neuron_skip*input_mask_height*input_mask_width*input_no_features) loop
      skip := skip+1;
      readline(xcaffe_file, il);    
    end loop;
    for n in 1 to layer_size loop
      for j in 1 to input_mask_height loop
        for k in 1 to input_mask_width loop
          for i in 1 to input_no_features loop
            if (not endfile(xcaffe_file)) then
              readline(xcaffe_file, il);             
              ils := (others => '~');
              ill := il'length;
              read(il, ils(1 to ill));
              x := string_pos(ils(1 to ill), "data:");
              if x < 0 then
                write (l, string'("Incorrect layer size specified -end of data blob reached early"));
                writeline(output, l);
                assert false report "Incorrect Layer Size Specification" severity failure;
              else
                write(il,string'(ils((x+5) to ill)));
                read(il,real_file);
                p            := real_file;
                weight_array(weight_index):= p;
                write (l, integer'(weight_index));
                write (l, string'(":"));
                write (l, string'(ils((x+5) to ill)));
                write (l, string'(":"));
                write (l, integer'(integer(weight_array(weight_index))));
                writeline(output, l);
                weight_index := weight_index+1;
                if n = layer_size and j = input_mask_height and k = input_mask_width and i = input_no_features then
                  read_weights := true;
                end if;
              end if;
            else
              write (l, string'("Incorrect layer size specified -end of file reached early"));
              writeline(output, l);
              assert false report "Incorrect Layer Size Specification" severity failure;
            end if;          
          end loop;
        end loop;
      end loop;
    end loop;

    if has_bias then

      -- Bias is next blob
      found_line_of_interest := false;
      while (not endfile(xcaffe_file)) and (not found_line_of_interest) loop
        readline(xcaffe_file, il);
        ils := (others => '~');
        ill := il'length;
        read(il, ils(1 to ill));
        if string_find(ils(1 to ill), "blobs") then
          write (l, string'("Found Conv blob bias start line:"));
          write(l,string'(ils(1 to ill)));
          writeline(output, l);
          found_line_of_interest := true;
        end if;
      end loop;

      -- Skip over data for partially implementing layers larger than the DPU size
      skip := 0;
      while skip < (neuron_skip) loop
        skip := skip+1;
        readline(xcaffe_file, il);    
      end loop;
      weight_index := 0;
      read_weights := false;
      for n in 1 to layer_size loop
        if (not endfile(xcaffe_file)) then
          readline(xcaffe_file, il);             
          ils := (others => '~');
          ill := il'length;
          read(il, ils(1 to ill));
          x := string_pos(ils(1 to ill), "data:");
          if x < 0 then
            write (l, string'("Incorrect layer size specified -end of data blob reached early"));
            writeline(output, l);
            assert false report "Incorrect Layer Size Specification" severity failure;
          else
            write(il,string'(ils((x+5) to ill)));
            read(il,real_file);
            p            := real_file;
            bias_array(weight_index):= p;
            write (l, integer'(weight_index));
            write (l, string'(":"));
            write (l, string'(ils((x+5) to ill)));
            write (l, string'(":"));
            write (l, integer'(integer(bias_array(weight_index))));
            writeline(output, l);
            weight_index := weight_index+1;
            if n = layer_size then
              read_weights := true;
            end if;
          end if;
        else
          write (l, string'("Incorrect layer size specified -end of file reached early"));
          writeline(output, l);
          assert false report "Incorrect Layer Size Specification" severity failure;
        end if;
        
      end loop;


    else
      

      -- Find the BN Layer name, to modify the weights (to scale output by
      -- that factor) and also to get the bias
      if bn_layer_name'length>0 then    
        while (not endfile(xcaffe_file)) and (not found_line_of_interest) loop
          readline(xcaffe_file, il);
          ils := (others => '~');
          ill := il'length;
          read(il, ils(1 to ill)); 
          if string_find(ils(1 to ill), "name:") then
            write (l, string'("Found a name line:"));
            write(l,string'(ils(1 to ill)));
            writeline(output, l);
            if string_find(ils(1 to ill), bn_layer_name) then
              found_line_of_interest := true;
            end if;
          end if;
        end loop;
        
        if found_line_of_interest then
          -- Found bn layer, scale weights by 1st blob
          -- Set Bias is 2nd blob
          found_line_of_interest := false;
          while (not endfile(xcaffe_file)) and (not found_line_of_interest) loop
            readline(xcaffe_file, il);
            ils := (others => '~');
            ill := il'length;
            read(il, ils(1 to ill));
            if string_find(ils(1 to ill), "blobs") then
              write (l, string'("Found BN blob scale start line:"));
              write(l,string'(ils(1 to ill)));
              writeline(output, l);
              found_line_of_interest := true;
            end if;
          end loop;


          -- Skip over data for partially implementing layers larger than the DPU size
          skip := 0;
          while skip < (neuron_skip) loop
            skip := skip+1;
            readline(xcaffe_file, il);    
          end loop;
          weight_index := 0;
          for n in 1 to layer_size loop       
            if (not endfile(xcaffe_file)) then
              readline(xcaffe_file, il);             
              ils := (others => '~');
              ill := il'length;
              read(il, ils(1 to ill));
              x := string_pos(ils(1 to ill), "data:");
              if x < 0 then
                write (l, string'("Incorrect layer size specified -end of data blob reached early"));
                writeline(output, l);
                assert false report "Incorrect Layer Size Specification" severity failure;
              else
                write(il,string'(ils((x+5) to ill)));
                read(il,real_file);
                
                for j in 1 to input_mask_height loop
                  for k in 1 to input_mask_width loop
                    for i in 1 to input_no_features loop
                      p := real_file * weight_array(weight_index);
                      weight_array(weight_index):= p;
                      
                      write (l, integer'(weight_index));
                      write (l, string'(":"));
                      write (l, string'(ils((x+5) to ill)));
                      write (l, string'(":"));
                      write (l, integer'(integer(weight_array(weight_index))));
                      writeline(output, l);
                      weight_index := weight_index+1;
                    end loop;
                  end loop;
                end loop;
              end if;
            else
              write (l, string'("Incorrect layer size specified -end of file reached early"));
              writeline(output, l);
              assert false report "Incorrect Layer Size Specification" severity failure;
            end if;             
          end loop;

          -- Bias is next blob
          found_line_of_interest := false;
          while (not endfile(xcaffe_file)) and (not found_line_of_interest) loop
            readline(xcaffe_file, il);
            ils := (others => '~');
            ill := il'length;
            read(il, ils(1 to ill));
            if string_find(ils(1 to ill), "blobs") then
              write (l, string'("Found BN blob bias start line:"));
              write(l,string'(ils(1 to ill)));
              writeline(output, l);
              found_line_of_interest := true;
            end if;
          end loop;

          -- Skip over data for partially implementing layers larger than the DPU size
          skip := 0;
          while skip < (neuron_skip) loop
            skip := skip+1;
            readline(xcaffe_file, il);    
          end loop;
          weight_index := 0;
          read_weights := false;
          for n in 1 to layer_size loop
            if (not endfile(xcaffe_file)) then
              readline(xcaffe_file, il);             
              ils := (others => '~');
              ill := il'length;
              read(il, ils(1 to ill));
              x := string_pos(ils(1 to ill), "data:");
              if x < 0 then
                write (l, string'("Incorrect layer size specified -end of data blob reached early"));
                writeline(output, l);
                assert false report "Incorrect Layer Size Specification" severity failure;
              else
                write(il,string'(ils((x+5) to ill)));
                read(il,real_file);
                p            := real_file;
                bias_array(weight_index):= p;
                write (l, integer'(weight_index));
                write (l, string'(":"));
                write (l, string'(ils((x+5) to ill)));
                write (l, string'(":"));
                write (l, integer'(integer(bias_array(weight_index))));
                writeline(output, l);
                weight_index := weight_index+1;
                if n = layer_size then
                  read_weights := true;
                end if;
              end if;
            else
              write (l, string'("Incorrect layer size specified -end of file reached early"));
              writeline(output, l);
              assert false report "Incorrect Layer Size Specification" severity failure;
            end if;
            
          end loop;
          
        end if;
      end if;

      if scale_layer_name'length > 0 then   
        -- Find the Scale Layer name, to modify the weights (to scale output by
        -- that factor) and also to modify the bias
        found_line_of_interest := false;
        while (not endfile(xcaffe_file)) and (not found_line_of_interest) loop
          readline(xcaffe_file, il);
          ils := (others => '~');
          ill := il'length;
          read(il, ils(1 to ill)); 
          if string_find(ils(1 to ill), "name:") then
            write (l, string'("Found a name line:"));
            write(l,string'(ils(1 to ill)));
            writeline(output, l);
            if string_find(ils(1 to ill), scale_layer_name) then
              found_line_of_interest := true;
            end if;
          end if;
        end loop;
        
        if found_line_of_interest then
          -- Found scale layer, scale weights by 1st blob
          -- Modify Bias using 2nd blob
          found_line_of_interest := false;
          while (not endfile(xcaffe_file)) and (not found_line_of_interest) loop
            readline(xcaffe_file, il);
            ils := (others => '~');
            ill := il'length;
            read(il, ils(1 to ill));
            if string_find(ils(1 to ill), "blobs") then
              write (l, string'("Found Scale blob start line:"));
              write(l,string'(ils(1 to ill)));
              writeline(output, l);
              found_line_of_interest := true;
            end if;
          end loop;

          -- Skip over data for partially implementing layers larger than the DPU size
          skip := 0;
          while skip < (neuron_skip) loop
            skip := skip+1;
            readline(xcaffe_file, il);    
          end loop;
          weight_index := 0;
          for n in 1 to layer_size loop       
            if (not endfile(xcaffe_file)) then
              readline(xcaffe_file, il);
              ils := (others => '~');
              ill := il'length;
              read(il, ils(1 to ill));
              x := string_pos(ils(1 to ill), "data:");
              if x < 0 then
                write (l, string'("Incorrect layer size specified -end of data blob reached early :"));
                write (l, string'(ils));
                writeline(output, l);
                assert false report "Incorrect Layer Size Specification" severity failure;
              else
                write(il,string'(ils((x+5) to ill)));
                read(il,real_file);
                
                for j in 1 to input_mask_height loop
                  for k in 1 to input_mask_width loop
                    for i in 1 to input_no_features loop
                      p := real_file * weight_array(weight_index);
                      weight_array(weight_index):= p;
                      -- N.B. also need to Scale bias by "Scale"
                      bias_array(n-1) :=bias_array(n-1)*real_file;
                      write (l, integer'(weight_index));
                      write (l, string'(":"));
                      write (l, string'(ils((x+5) to ill)));
                      write (l, string'(":"));
                      write (l, integer'(integer(weight_array(weight_index)*weight_scaling)));
                      writeline(output, l);
                      weight_index := weight_index+1;
                    end loop;
                  end loop;
                end loop;
              end if;
            else
              write (l, string'("Incorrect layer size specified -end of file reached early"));
              writeline(output, l);
              assert false report "Incorrect Layer Size Specification" severity failure;
            end if;             
          end loop;

          -- Bias is next blob
          found_line_of_interest := false;
          while (not endfile(xcaffe_file)) and (not found_line_of_interest) loop
            readline(xcaffe_file, il);
            ils := (others => '~');
            ill := il'length;
            read(il, ils(1 to ill));
            if string_find(ils(1 to ill), "blobs") then
              write (l, string'("Found Scale blob Bias start line:"));
              write(l,string'(ils(1 to ill)));
              writeline(output, l);
              found_line_of_interest := true;
            end if;
          end loop;

          -- Skip over data for partially implementing layers larger than the DPU size
          skip := 0;
          while skip < (neuron_skip) loop
            skip := skip+1;
            readline(xcaffe_file, il);    
          end loop;
          weight_index := 0;
          read_weights := false;
          for n in 1 to layer_size loop
            if (not endfile(xcaffe_file)) then
              readline(xcaffe_file, il);             
              ils := (others => '~');
              ill := il'length;
              read(il, ils(1 to ill));
              x := string_pos(ils(1 to ill), "data:");
              if x < 0 then
                write (l, string'("Incorrect layer size specified -end of data blob reached early"));
                writeline(output, l);
                assert false report "Incorrect Layer Size Specification" severity failure;
              else
                write(il,string'(ils((x+5) to ill)));
                read(il,real_file);
                p  := bias_array(weight_index) + real_file;
                bias_array(weight_index):= p;
                write (l, integer'(weight_index));
                write (l, string'(":"));
                write (l, string'(ils((x+5) to ill)));
                write (l, string'(":"));
                write (l, integer'(integer(weight_scaling*bias_array(weight_index))));
                writeline(output, l);
                weight_index := weight_index+1;
                if n = layer_size then
                  read_weights := true;
                end if;
              end if;
            else
              write (l, string'("Incorrect layer size specified -end of file reached early"));
              writeline(output, l);
              assert false report "Incorrect Layer Size Specification" severity failure;
            end if;
            
          end loop;
          
        end if;
      end if;
    end if;    
    if read_weights then
      weight_index := 0;
      for n in 1 to layer_size loop
        write (l, string'("Reading in weights, for neuron #"));
        write(l,n);
        writeline (output, l);
        
        int_file := integer(bias_array(n-1)*weight_scaling);
        
        -- First weight is the BIAS
        write (l, string'("Bias: "));   
        write (l, int_file);
        writeline (output, l);
        weight_stream <= std_logic_vector(to_signed(int_file, weight_width));
        weight_id <= std_logic_vector(to_unsigned(n, weight_id_width));  
        weight_first <= '1';   
        weight_last <= '0';

        wait until clk = '0';
        wait until clk = '1';

        for j in 1 to input_mask_height loop
          for k in 1 to input_mask_width loop
            for i in 1 to input_no_features loop
              
              int_file := integer(weight_array(weight_index)*weight_scaling);
              weight_index := weight_index+1;
              weight_stream <= std_logic_vector(to_signed(int_file, weight_width));

              write (l, int_file);
              write (l, string'(" "));
              weight_first <= '0';
              if j = input_mask_height and k = input_mask_width and i = input_no_features then
                weight_last <= '1';
              else
                weight_last <= '0';
              end if;

              wait until clk = '0';
              wait until clk = '1';
              
            end loop;
            write (l, string'(" : "));
          end loop;
          writeline (output, l);
        end loop;
        weight_last <= '0';
      end loop;
    end if;
    file_close(xcaffe_file);
  end procedure;

  
  procedure read_weights_files (
    constant bias_filename     : in  string;
    constant weight_filename   : in  string;
    constant weight_scaling    : in  integer;
    constant bias_scaling      : in  integer;
    constant layer_size        : in  integer;
    constant input_mask_height : in  integer;
    constant input_mask_width  : in  integer;
    constant input_no_features : in  integer;
    signal clk                 : in  std_logic;
    signal weight_stream       : out std_logic_vector(weight_width-1 downto 0);
    signal weight_id           : out std_logic_vector(weight_id_width-1 downto 0);
    signal weight_first        : out std_logic;
    signal weight_last         : out std_logic) is

    variable l        : line;
    variable il       : line;
    variable int_file : integer;
    -- Use text files for maximum portability
    file weight_file  : text is in weight_filename;
    file bias_file    : text is in bias_filename;
  begin
    for n in 1 to layer_size loop
      write (l, string'("Reading in weights, for neuron #"));
      write(l, n);
      writeline (output, l);
      if not endfile(bias_file) then
        readline(bias_file, il);
        read(il, int_file);
      else
        write (l, string'("Input file too small"));
        writeline(output, l);
      end if;
      int_file := int_file/bias_scaling;  -- Shift down bias as text
                                          -- file is Bias * 2^31
      --bias(n) := to_signed(int_file, weight_width);

      -- First weight is the BIAS
      write (l, string'("Bias: "));
      write (l, int_file);
      writeline (output, l);
      weight_stream <= std_logic_vector(to_signed(int_file, weight_width));
      weight_id     <= std_logic_vector(to_unsigned(n, weight_id_width));
      weight_first  <= '1';
      weight_last   <= '0';

      wait until clk = '0';
      wait until clk = '1';

      for j in 1 to input_mask_height loop
        for k in 1 to input_mask_width loop
          for i in 1 to input_no_features loop
            if not endfile(weight_file) then
              readline(weight_file, il);
              read(il, int_file);
            else
              write (l, string'("Input file too small"));
              writeline(output, l);
            end if;
            int_file      := int_file/weight_scaling;  -- Shift down weights as text
                                                       -- file is W * 2^31
            weight_stream <= std_logic_vector(to_signed(int_file, weight_width));

            write (l, int_file);
            write (l, string'(" "));
            weight_first <= '0';
            if j = input_mask_height and k = input_mask_width and i = input_no_features then
              weight_last <= '1';
            else
              weight_last <= '0';
            end if;

            wait until clk = '0';
            wait until clk = '1';

          end loop;
          write (l, string'(" : "));
        end loop;
        writeline (output, l);
      end loop;
      weight_last <= '0';
    end loop;
    file_close(weight_file);
    file_close(bias_file);
  end;


  procedure read_feature_file (
    constant feature_filename  : in  string;
    constant input_bias        : in  integer;
    constant input_height      : in  integer;
    constant input_width       : in  integer;
    constant input_no_features : in  integer;
    signal clk                 : in  std_logic;
    signal feature_stream      : out std_logic_vector(feature_width-1 downto 0);
    signal feature_valid       : out std_logic;
    signal feature_ready       : in  std_logic) is

    variable l        : line;
    variable il       : line;
    variable int_file : integer;
    -- Use text files for maximum portability
    file feature_file : text is in feature_filename;
  begin

    write (l, string'("Reading File"));
    writeline(output, l);
    for i in 1 to input_height loop
      for j in 1 to input_width loop
        for k in 1 to input_no_features loop
          if not endfile(feature_file) then
            readline(feature_file, il);
            read(il, int_file);
          else
            write (l, string'("Input file too small"));
            writeline(output, l);
          end if;
          int_file       := int_file-input_bias;
          feature_stream <= std_logic_vector(to_signed(int_file, feature_width));
          feature_valid  <= '1';
          wait until clk = '0';
          if feature_ready = '0' then
            wait until feature_ready = '1';
          end if;
          wait until clk = '1';

        end loop;
      end loop;
    end loop;
    feature_valid <= '0';
    file_close(feature_file);
  end;

  procedure read_weights_file_nobias (
    constant weight_filename   : in  string;
    constant weight_scaling    : in  integer;
    constant layer_size        : in  integer;
    constant input_mask_height : in  integer;
    constant input_mask_width  : in  integer;
    constant input_no_features : in  integer;
    signal clk                 : in  std_logic;
    signal weight_stream       : out std_logic_vector(weight_width-1 downto 0);
    signal weight_id           : out std_logic_vector(weight_id_width-1 downto 0);
    signal weight_first        : out std_logic;
    signal weight_last         : out std_logic) is

    variable l        : line;
    variable il       : line;
    variable int_file : integer;
    -- Use text files for maximum portability
    file weight_file  : text is in weight_filename;
  begin
    for n in 1 to layer_size loop
      write (l, string'("Reading in weights, for neuron #"));
      write(l, n);
      writeline (output, l);

      int_file := 0;                    -- Shift down bias as text
      -- file is Bias * 2^31
      --bias(n) := to_signed(int_file, weight_width);

      -- First weight is the BIAS
      write (l, string'("Bias: "));
      write (l, int_file);
      writeline (output, l);
      weight_stream <= std_logic_vector(to_signed(int_file, weight_width));
      weight_id     <= std_logic_vector(to_unsigned(n, weight_id_width));
      weight_first  <= '1';
      weight_last   <= '0';

      wait until clk = '0';
      wait until clk = '1';

      for j in 1 to input_mask_height loop
        for k in 1 to input_mask_width loop
          for i in 1 to input_no_features loop
            if not endfile(weight_file) then
              readline(weight_file, il);
              read(il, int_file);
            else
              write (l, string'("Input file too small"));
              writeline(output, l);
            end if;
            int_file      := int_file/weight_scaling;  -- Shift down weights as text
                                                       -- file is W * 2^31
            weight_stream <= std_logic_vector(to_signed(int_file, weight_width));

            write (l, int_file);
            write (l, string'(" "));
            weight_first <= '0';
            if j = input_mask_height and k = input_mask_width and i = input_no_features then
              weight_last <= '1';
            else
              weight_last <= '0';
            end if;

            wait until clk = '0';
            wait until clk = '1';

          end loop;
          write (l, string'(" : "));
        end loop;
        writeline (output, l);
      end loop;
      weight_last <= '0';
    end loop;
    file_close(weight_file);
  end;


  


  

end;


