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
-- sim_memory.vhd
--
-- Simulation only pre-populated memory to emulate external SDRAM function





library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


-- define feature and weight width
library work;
use work.cnn_tools.all;
use work.cnn_defs.all;



entity sim_memory is
  port (
    s_axi_aclk    : in  std_logic;
    s_axi_aresetn : in  std_logic;
    s_axi_awid    : in  std_logic_vector(5 downto 0);
    s_axi_awaddr  : in  std_logic_vector(18 downto 0);
    s_axi_awlen   : in  std_logic_vector(7 downto 0);
    s_axi_awsize  : in  std_logic_vector(2 downto 0);
    s_axi_awburst : in  std_logic_vector(1 downto 0);
    s_axi_awlock  : in  std_logic;
    s_axi_awcache : in  std_logic_vector(3 downto 0);
    s_axi_awprot  : in  std_logic_vector(2 downto 0);
    s_axi_awvalid : in  std_logic;
    s_axi_awready : out std_logic;
    s_axi_wdata   : in  std_logic_vector(511 downto 0);
    s_axi_wstrb   : in  std_logic_vector(63 downto 0);
    s_axi_wlast   : in  std_logic;
    s_axi_wvalid  : in  std_logic;
    s_axi_wready  : out std_logic;
    s_axi_bid     : out std_logic_vector(5 downto 0);
    s_axi_bresp   : out std_logic_vector(1 downto 0);
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in  std_logic;
    s_axi_arid    : in  std_logic_vector(5 downto 0);
    s_axi_araddr  : in  std_logic_vector(18 downto 0);
    s_axi_arlen   : in  std_logic_vector(7 downto 0);
    s_axi_arsize  : in  std_logic_vector(2 downto 0);
    s_axi_arburst : in  std_logic_vector(1 downto 0);
    s_axi_arlock  : in  std_logic;
    s_axi_arcache : in  std_logic_vector(3 downto 0);
    s_axi_arprot  : in  std_logic_vector(2 downto 0);
    s_axi_arvalid : in  std_logic;
    s_axi_arready : out std_logic;
    s_axi_rid     : out std_logic_vector(5 downto 0);
    s_axi_rdata   : out std_logic_vector(511 downto 0);
    s_axi_rresp   : out std_logic_vector(1 downto 0);
    s_axi_rlast   : out std_logic;
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in  std_logic

    );
end entity;

architecture rtl of sim_memory is


  component axi_bram_ctrl_0
    port (
      s_axi_aclk    : in  std_logic;
      s_axi_aresetn : in  std_logic;
      s_axi_awid    : in  std_logic_vector(5 downto 0);
      s_axi_awaddr  : in  std_logic_vector(18 downto 0);
      s_axi_awlen   : in  std_logic_vector(7 downto 0);
      s_axi_awsize  : in  std_logic_vector(2 downto 0);
      s_axi_awburst : in  std_logic_vector(1 downto 0);
      s_axi_awlock  : in  std_logic;
      s_axi_awcache : in  std_logic_vector(3 downto 0);
      s_axi_awprot  : in  std_logic_vector(2 downto 0);
      s_axi_awvalid : in  std_logic;
      s_axi_awready : out std_logic;
      s_axi_wdata   : in  std_logic_vector(511 downto 0);
      s_axi_wstrb   : in  std_logic_vector(63 downto 0);
      s_axi_wlast   : in  std_logic;
      s_axi_wvalid  : in  std_logic;
      s_axi_wready  : out std_logic;
      s_axi_bid     : out std_logic_vector(5 downto 0);
      s_axi_bresp   : out std_logic_vector(1 downto 0);
      s_axi_bvalid  : out std_logic;
      s_axi_bready  : in  std_logic;
      s_axi_arid    : in  std_logic_vector(5 downto 0);
      s_axi_araddr  : in  std_logic_vector(18 downto 0);
      s_axi_arlen   : in  std_logic_vector(7 downto 0);
      s_axi_arsize  : in  std_logic_vector(2 downto 0);
      s_axi_arburst : in  std_logic_vector(1 downto 0);
      s_axi_arlock  : in  std_logic;
      s_axi_arcache : in  std_logic_vector(3 downto 0);
      s_axi_arprot  : in  std_logic_vector(2 downto 0);
      s_axi_arvalid : in  std_logic;
      s_axi_arready : out std_logic;
      s_axi_rid     : out std_logic_vector(5 downto 0);
      s_axi_rdata   : out std_logic_vector(511 downto 0);
      s_axi_rresp   : out std_logic_vector(1 downto 0);
      s_axi_rlast   : out std_logic;
      s_axi_rvalid  : out std_logic;
      s_axi_rready  : in  std_logic;
      bram_rst_a    : out std_logic;
      bram_clk_a    : out std_logic;
      bram_en_a     : out std_logic;
      bram_we_a     : out std_logic_vector(63 downto 0);
      bram_addr_a   : out std_logic_vector(18 downto 0);
      bram_wrdata_a : out std_logic_vector(511 downto 0);
      bram_rddata_a : in  std_logic_vector(511 downto 0)
      );
  end component;


  type mem_type is array(0 to 524287) of std_logic_vector(31 downto 0);
  shared variable  mem : mem_type := (others => (others => '0'));

    signal bram_rst_a    : std_logic;
    signal  bram_clk_a    : std_logic;
    signal  bram_en_a     : std_logic;
    signal  bram_we_a     : std_logic_vector(63 downto 0);
    signal  bram_addr_a   : std_logic_vector(18 downto 0);
    signal  bram_wrdata_a : std_logic_vector(511 downto 0);
    signal  bram_rddata_a : std_logic_vector(511 downto 0);

  signal  bram_addr   : std_logic_vector(18 downto 0);


  signal mclk : std_logic := '0';
  signal write_weights,write_features,ww_r1,wf_r1 : std_logic := '0';
  signal maddr, waddr : integer := 0;

  signal feature_stream           : std_logic_vector(feature_width-1 downto 0);
  signal feature_valid            : std_logic;
  signal feature_ready            : std_logic := '1';
 
  signal weight_stream            : std_logic_vector(weight_width-1 downto 0);
  signal weight_id                : std_logic_vector(7 downto 0);
  signal weight_first             : std_logic;
  signal weight_last              : std_logic;
  
  signal wcount,fcount : integer := 0;
  signal tmp_data : std_logic_vector(31 downto 0);


  constant DATA_DIR : string := "../../../../../../onelayerdpu/data/";
  constant DATA_DIR2 : string := "../../../../../data/";
  
begin

  mclk <= not mclk after 1 ps; -- Very fast clock for memory set up
  
  bram_addr <= bram_addr_a(18 downto 6) & "000000";
  
  process(bram_clk_a)
    variable tmp : std_logic_vector(31 downto 0);
  begin
    if rising_edge(bram_clk_a) then
      if bram_en_a = '1' then
        for i in 0 to 15 loop
          --tmp := std_logic_vector(to_signed(mem(to_integer(unsigned(bram_addr(18 downto 2)))+i),32));
          --bram_rddata_a(32*i+31 downto 32*i) <= tmp;
          for j in 0 to 3 loop
            if bram_we_a(i*4+j) = '1' then
              --tmp(8*j+7 downto 8*j) := bram_wrdata_a(32*i+8*j+7 downto 32*i+8*j);
              mem(to_integer(unsigned(bram_addr(18 downto 2)))+i)(8*j+7 downto 8*j) := bram_wrdata_a(32*i+8*j+7 downto 32*i+8*j);
            end if;
          end loop;
          --mem(to_integer(unsigned(bram_addr(18 downto 2)))+i) := to_integer(signed(tmp));
          bram_rddata_a(32*i+31 downto 32*i) <= mem(to_integer(unsigned(bram_addr(18 downto 2)))+i);
        end loop;
      end if;
    end if;
  end process;
  


  
  bram_ctrl0 : axi_bram_ctrl_0
    port map (
      s_axi_aclk    => s_axi_aclk,
      s_axi_aresetn => s_axi_aresetn,
      s_axi_awid    => s_axi_awid,
      s_axi_awaddr  => s_axi_awaddr,
      s_axi_awlen   => s_axi_awlen,
      s_axi_awsize  => s_axi_awsize,
      s_axi_awburst => s_axi_awburst,
      s_axi_awlock  => s_axi_awlock,
      s_axi_awcache => s_axi_awcache,
      s_axi_awprot  => s_axi_awprot,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,
      s_axi_wdata   => s_axi_wdata,
      s_axi_wstrb   => s_axi_wstrb,
      s_axi_wlast   => s_axi_wlast,
      s_axi_wvalid  => s_axi_wvalid,
      s_axi_wready  => s_axi_wready,
      s_axi_bid     => s_axi_bid,
      s_axi_bresp   => s_axi_bresp,
      s_axi_bvalid  => s_axi_bvalid,
      s_axi_bready  => s_axi_bready,
      s_axi_arid    => s_axi_arid,
      s_axi_araddr  => s_axi_araddr,
      s_axi_arlen   => s_axi_arlen,
      s_axi_arsize  => s_axi_arsize,
      s_axi_arburst => s_axi_arburst,
      s_axi_arlock  => s_axi_arlock,
      s_axi_arcache => s_axi_arcache,
      s_axi_arprot  => s_axi_arprot,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,
      s_axi_rid     => s_axi_rid,
      s_axi_rdata   => s_axi_rdata,
      s_axi_rresp   => s_axi_rresp,
      s_axi_rlast   => s_axi_rlast,
      s_axi_rvalid  => s_axi_rvalid,
      s_axi_rready  => s_axi_rready,
      bram_rst_a    => bram_rst_a,
      bram_clk_a    => bram_clk_a,
      bram_en_a     => bram_en_a,
      bram_we_a     => bram_we_a,
      bram_addr_a   => bram_addr_a,
      bram_wrdata_a => bram_wrdata_a,
      bram_rddata_a => bram_rddata_a
      );


  -- Simulation process to initialise memory
  init_mem: process
    variable feature : unsigned(feature_width-1 downto 0) := (others => '0');
    variable weight  : unsigned(weight_width-1 downto 0)  := (others => '0');
    variable tmp : std_logic_vector(31 downto 0) := (others => '0');
    variable addr : integer := 0;
    variable byte_count : integer := 0;
  begin
    -- sim_simple 32x32
    -- relu = 0, conv3x3 = 0, use_maxpool = 0, stride2 = 0, feature_image_witdh=32
    mem(0) := X"00200000";
    -- number_of_features = 3, mp_feature_image_width = -1
    mem(1) := X"FFFF0003";
    -- mp_number_of_features = -1, number_of_active_neurons = 10 
    mem(2) := X"000AFFFF";
    -- throttle_rate = 21
    mem(3) := X"00000015";
    -- WDM command read weights (80 bytes) from byte address 256
    mem(4) := X"40800050";
    mem(5) := X"00000100";
    mem(6) := X"00000000";
    mem(7) := X"00000000";
    -- IDM command read features (3072 bytes) from byte address 1024
    mem(8) := X"40800C00";
    mem(9) := X"00000400";
    mem(10) := X"00000000";
    mem(11) := X"00000000";
    -- ODM command write features (10*1024- bytes) from byte address 4096
    mem(12) := X"00802800";
    mem(13) := X"00001000";
    mem(14) := X"00000000";
    mem(15) := X"00000000";
    

    weight := (others => '0');
    addr := 64;  -- DWORD address (byte address/4)
    for i in 1 to 10 loop
      for j in 0 to 3 loop            -- bias + 3 weights
        if j=0 or j=2 then
          tmp(weight_width-1 downto 0) := std_logic_vector(weight);
        else
          tmp(16+weight_width-1 downto 16) := std_logic_vector(weight);
          mem(addr) := tmp;
          addr := addr+1;
        end if;
        weight := weight+1;
      end loop;
    end loop;
     
    addr := 256;  -- DWORD address (byte address/4)
    feature := (others => '0');
    byte_count := 0;
    for i in 0 to 31 loop
      for j in 0 to 31 loop
        for k in 0 to 2 loop
          if k = 0 then
            tmp := tmp(23 downto 0) & std_logic_vector(to_unsigned(j+1, 8));
          else
            if k = 1 then
              tmp := tmp(23 downto 0) & std_logic_vector(to_unsigned(i+1, 8));
            else
              tmp := tmp(23 downto 0) & std_logic_vector(to_unsigned(i+j+1, 8));
            end if;
          end if;
          if byte_count =3 then
            byte_count := 0;
            mem(addr) := tmp;
            addr:= addr+1;
          else
            byte_count := byte_count+1;
          end if;
          feature := feature+1;
        end loop;
      end loop;
    end loop;

    -- Next CNN in list @ byte address 16384
    mem(16) := X"00004000";
    mem(17) := X"00000000";
    mem(18) := X"00000001";


    -- sim_simple 32x32 cov
    -- relu = 0, conv3x3 = 0, use_maxpool = 0, stride2 = 0, feature_image_witdh=32
    mem(4096) := X"00200002";
    -- number_of_features = 3, mp_feature_image_width = -1
    mem(4097) := X"FFFF0003";
    -- mp_number_of_features = -1, number_of_active_neurons = 10 
    mem(4098) := X"000AFFFF";
    -- throttle_rate = 21
    mem(4099) := X"00000015";
    -- WDM command read weights (80 bytes) from byte address 256
    -- Use weights set up above
    mem(4100) := X"40800050";
    mem(4101) := X"00000100";
    mem(4102) := X"00000000";
    mem(4103) := X"00000000";
    -- IDM command read features (3072 bytes) from byte address 1024
    -- Use features set up previously
    mem(4104) := X"40800C00";
    mem(4105) := X"00000400";
    mem(4106) := X"00000000";
    mem(4107) := X"00000000";
    -- Stripe the write 32 stripes of 320 bytes
    -- NB Write 31 into command count
    -- Skipping 32 bytes each time (addr increment 352 bytes)
    
    mem(4108) := X"00800140";
    mem(4109) := X"00005000";
    mem(4110) := X"00000000";
    mem(4111) := X"00001F00";
    mem(4122) := X"00000160";

       -- Next CNN in list @ byte address 32768
    mem(4112) := X"00008000";
    mem(4113) := X"00000000";
    mem(4114) := X"00000001";

    
    -- sim_simple 26x26 maxpool
    -- relu = 0, conv3x3 = 0, use_maxpool = 0, stride2 = 0, feature_image_witdh=26
    mem(8192) := X"001A0005";
    -- number_of_features = 8, mp_feature_image_width = 26
    mem(8193) := X"001A0008";
    -- mp_number_of_features = 34, number_of_active_neurons = 34 
    mem(8194) := X"00220022";
    -- throttle_rate = 78
    mem(8195) := X"0000004E";
    -- WDM command read weights (306*2 bytes) from byte address +256
    mem(8196) := X"40800264";
    mem(8197) := X"00008100";
    mem(8198) := X"00000000";
    mem(8199) := X"00000000";
    -- IDM command read features (3072 bytes) from byte address 1024
    -- Use features set up previously
    mem(8200) := X"40801520";
    mem(8201) := X"00008400";
    mem(8202) := X"00000000";
    mem(8203) := X"00000000";
    -- ODM command write features (10*1024- bytes) from byte address 4096
    mem(8204) := X"00801672";
    mem(8205) := X"0000A000";
    mem(8206) := X"00000000";
    mem(8207) := X"00000000";

    byte_count := 0;
    weight := (others => '0');
    addr := 64;  -- DWORD address (byte address/4)
    for i in 1 to 34 loop
      for j in 0 to 8 loop            -- bias + 8 weights
        if byte_count = 0 then
          tmp(weight_width-1 downto 0) := std_logic_vector(weight);
          byte_count := 1;
        else
          tmp(16+weight_width-1 downto 16) := std_logic_vector(weight);
          mem(addr) := tmp;
          addr := addr+1;
          byte_count := 0;
        end if;
        weight := weight+1;
      end loop;
    end loop;
     
    addr := 256;  -- DWORD address (byte address/4)
    feature := (others => '0');
    byte_count := 0;
    for i in 0 to 25 loop
      for j in 0 to 25 loop
        for k in 0 to 7 loop
          if k = 0 then
            tmp := tmp(23 downto 0) & std_logic_vector(to_unsigned(j+1, 8));
          else
            if k = 1 then
              tmp := tmp(23 downto 0) & std_logic_vector(to_unsigned(i+1, 8));
            else
              tmp := tmp(23 downto 0) & std_logic_vector(to_unsigned(85, 8));
            end if;
          end if;
          if byte_count =3 then
            byte_count := 0;
            mem(addr) := tmp;
            addr:= addr+1;
          else
            byte_count := byte_count+1;
          end if;
          feature := feature+1;
        end loop;
      end loop;
    end loop;

    
       -- Next CNN in list @ byte address 16384*3
    mem(8208) := X"0000C000";
    mem(8209) := X"00000000";
    mem(8210) := X"00000001";


    

    -- sim_yolov3_layer8_xcaffe
    -- relu = 1, conv3x3 = 1, use_maxpool = 1, stride2 = 0, feature_image_width=26
    mem(12288) := X"001A0007";
    -- number_of_features = 128, mp_feature_image_width = 26
    mem(12289) := X"001A0080";
    -- mp_number_of_features = 128, number_of_active_neurons = 128 
    mem(12290) := X"00800080";
    -- throttle_rate = 256
    mem(12291) := X"00000100";
    -- WDM command read weights (2*9*129*128 bytes) from byte address 65536
    mem(12292) := X"40848900";
    mem(12293) := X"00010000";
    mem(12294) := X"00000000";
    mem(12295) := X"00000000";
    -- IDM command read features (26*26*128) from address 960kB
    mem(12296) := X"40815200";
    mem(12297) := X"000E0000";
    mem(12298) := X"00000000";
    mem(12299) := X"00000000";
    -- ODM command write features (13*13*128 bytes) from byte address 1MB
    mem(12300) := X"00800080";
    mem(12301) := X"00100000";
    mem(12302) := X"00000000";
    mem(12303) := X"0000A800";
    mem(12314) := X"00000100";

    -- Next CNN in list @ byte address 0xD000
    mem(12304) := X"0000D000";
    mem(12305) := X"00000000";
    mem(12306) := X"00000001";
    
     -- ODM2 command write features (26*26*128 bytes) from byte address 1+2/16MB
    mem(12316) := X"00800080";
    mem(12317) := X"00120000";
    mem(12318) := X"00000000";
    mem(12319) := X"0002A300";
    mem(12315) := X"00000100";

    maddr <= 16384;

    wait until mclk <= '0';
    wait until mclk <= '1';
    
    write_weights <= '1';

    wait until mclk <= '0';
    wait until mclk <= '1';
    
    read_xcaffe_file(
        xcaffe_filename   => DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer8-conv",
        scale_layer_name  => "layer8-scale",
        bn_layer_name     => "layer8-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 128,
        neuron_skip       => 0,
        clk               => mclk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);

    write_weights <= '0';

    wait until mclk <= '0';
    wait until mclk <= '1';
    
    maddr <= 245760; --131072;
    
    write_features <= '1';

    wait until mclk <= '0';
    wait until mclk <= '1';
    
    read_feature_file(
        feature_filename  => DATA_DIR2 & "output_data5.txt",
        input_bias        => 0,
        input_height      => 26, 
        input_width       => 26,
        input_no_features => 128,
        clk               => mclk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);

    write_features <= '0';
    wait until mclk <= '0';
    wait until mclk <= '1';



    
    -- sim_yolov3_layer8_xcaffe  - 2nd 128 neurons
    -- relu = 1, conv3x3 = 1, use_maxpool = 1, stride2 = 0, feature_image_width=26
    mem(13312) := X"001A0007";
    -- number_of_features = 128, mp_feature_image_width = 26
    mem(13313) := X"001A0080";
    -- mp_number_of_features = 128, number_of_active_neurons = 128 
    mem(13314) := X"00800080";
    -- throttle_rate = 256
    mem(13315) := X"00000100";
    -- WDM command read weights (2*9*129*128 bytes) from byte address +256
    mem(13316) := X"40848900";
    mem(13317) := X"00060000";
    mem(13318) := X"00000000";
    mem(13319) := X"00000000";
    -- IDM command read features (26*26*128) from address 960kB
    mem(13320) := X"40815200";
    mem(13321) := X"000E0000";
    mem(13322) := X"00000000";
    mem(13323) := X"00000000";
    -- ODM command write features (13*13*128 bytes) from byte address 1MB
    mem(13324) := X"00800080";
    mem(13325) := X"00100080";
    mem(13326) := X"00000000";
    mem(13327) := X"0000A800";
    mem(13338) := X"00000100";

    -- Next CNN in list @ byte address 0xE000
    mem(13328) := X"0000E000";
    mem(13329) := X"00000000";
    mem(13330) := X"00000001";
    
     -- ODM2 command write features (26*26*128 bytes) from byte address 1+2/16MB
    mem(13340) := X"00800080";
    mem(13341) := X"00120080";
    mem(13342) := X"00000000";
    mem(13343) := X"0002A300";
    mem(12338) := X"00000100";

    maddr <= 98304;

    wait until mclk <= '0';
    wait until mclk <= '1';
    
    write_weights <= '1';

    wait until mclk <= '0';
    wait until mclk <= '1';
    
    read_xcaffe_file(
        xcaffe_filename   => DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer8-conv",
        scale_layer_name  => "layer8-scale",
        bn_layer_name     => "layer8-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 3,
        input_mask_width  => 3,
        input_no_features => 128,
        neuron_skip       => 128,
        clk               => mclk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);

    write_weights <= '0';

    wait until mclk <= '0';
    wait until mclk <= '1';
    


    -- sim_yolov3_layer20_xcaffe
    -- relu = 1, conv3x3 = 0, use_maxpool = 0, stride2 = 0, feature_image_width=26
    mem(14336) := X"001A0001";
    -- number_of_features = 384, mp_feature_image_width = 26
    mem(14337) := X"001A0180";
    -- mp_number_of_features = 128, number_of_active_neurons = 128 
    mem(14338) := X"00800080";
    -- throttle_rate = 256
    mem(14339) := X"00000100";
    -- WDM command read weights (2*129*128 bytes) from byte address 1+12/16MB
    mem(14340) := X"40808100";
    mem(14341) := X"001C0000";
    mem(14342) := X"00000000";
    mem(14343) := X"00000000";
    -- IDM command read features (26*26*128) from address 1+2/16 MB
    mem(14344) := X"40815200";
    mem(14345) := X"00120000";
    mem(14346) := X"00000000";
    mem(14347) := X"00000000";
    -- ODM command write features (26*26*128 bytes) from byte address 1+4/16MB
    mem(14348) := X"00815200";
    mem(14349) := X"00140000";
    mem(14350) := X"00000000";
    mem(14351) := X"00000000";
    -- IDM2 command read features (13*13*256) from address 1+6/16MB
    mem(14356) := X"4080A900";
    mem(14357) := X"00160000";
    mem(14358) := X"00000000";
    mem(14359) := X"00000000";
    -- 2x Rescale Enable
    mem(14360) := X"00000001";
    -- IDM2 Count -1 : IDM1 Count -1
    mem(14361) := X"00FF007F";
  

    maddr <= 458752;

    wait until mclk <= '0';
    wait until mclk <= '1';
    
    write_weights <= '1';

    wait until mclk <= '0';
    wait until mclk <= '1';
    
    read_xcaffe_file(
        xcaffe_filename   => DATA_DIR & "dk_tiny-yolov3_416_416_5.txt",
        layer_name        => "layer20-conv",
        scale_layer_name  => "layer20-scale",
        bn_layer_name     => "layer20-bn",
        has_bias          => false,
        weight_scaling    => 32767.0,
        layer_size        => 128,
        input_mask_height => 1,
        input_mask_width  => 1,
        input_no_features => 384,
        neuron_skip       => 0,
        clk               => mclk,
        weight_stream     => weight_stream,
        weight_id         => weight_id,
        weight_first      => weight_first,
        weight_last       => weight_last);

    write_weights <= '0';

    wait until mclk <= '0';
    wait until mclk <= '1';
    
    maddr <= 360448;
    
    write_features <= '1';

    wait until mclk <= '0';
    wait until mclk <= '1';
    
    read_feature_file(
        feature_filename  => DATA_DIR2 & "output_data12.txt",
        input_bias        => 0,
        input_height      => 13, 
        input_width       => 13,
        input_no_features => 128,
        clk               => mclk,
        feature_stream    => feature_stream,
        feature_valid     => feature_valid,
        feature_ready     => feature_ready);

    write_features <= '0';
    wait until mclk <= '0';
    wait until mclk <= '1';
    
    wait;
    
  end process;

  -- Code to write weights and features read from files
  -- into memory using very fast simulation clock.
  -- so that memory is pre-programed at start of simulation

  process(mclk)
  begin
    if rising_edge(mclk) then
      ww_r1 <= write_weights;
      wf_r1 <= write_features;
      
      
      if write_weights = '1' then
        if ww_r1 = '0' then
          waddr <= maddr;
          wcount <= 0;
        else
          if wcount = 0 then
            wcount <= 1;
            tmp_data(15 downto 0) <= weight_stream;
          else
            wcount <= 0;
            mem(waddr) := weight_stream & tmp_data(15 downto 0);
            waddr <= waddr+1;
          end if;   
        end if;
      end if;

      if write_features = '1' then
        if wf_r1 = '0' then
          waddr <= maddr;
          fcount <= 0;
        else
          if fcount < 3 then
            fcount <= fcount+1;
            tmp_data <= tmp_data(23 downto 0) & feature_stream;
          else
            fcount <= 0;
            mem(waddr) := feature_stream & tmp_data(23 downto 0);
            waddr <= waddr+1;
          end if;   
        end if;
      end if;

      
    end if;
  end process;
  

end architecture;
