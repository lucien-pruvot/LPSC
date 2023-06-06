----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.03.2023 10:33:59
-- Design Name: 
-- Module Name: top_level - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity mandelBrot_compute is

    generic(
    dataWidth : integer := 16;
    nbrOfIntegerDigits : integer := 4;
    nbrOfDecimalDigits : integer := 12
    );
   
    Port ( 
            clk_i : in std_logic;
            reset_i : in std_logic;
            
            zr_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
            zi_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
            cr_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
            ci_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
            
            zrNext_o : out std_logic_vector(dataWidth-1 downto 0);
            ziNext_o : out std_logic_vector(dataWidth-1 downto 0)
            );
end mandelBrot_compute;

architecture Behavioral of mandelBrot_compute is

signal zr2 : std_logic_vector(2*dataWidth-1 downto 0);
signal zi2 : std_logic_vector(2*dataWidth-1 downto 0);
signal zir : std_logic_vector(2*dataWidth-1 downto 0);
signal z2ir : std_logic_vector(2*dataWidth-1 downto 0);
signal zadd1 : std_logic_vector(2*dataWidth-1 downto 0);

signal add1_cout : std_logic;
signal add2_cout : std_logic;
signal add3_cout : std_logic;

signal zrNext : std_logic_vector(2*dataWidth-1 downto 0) := (others => '0');
signal ziNext : std_logic_vector(2*dataWidth-1 downto 0) := (others => '0');

--signal nbrOfDecimalDigits : integer := data_width - nbrOfIntegerDigits;

signal ci : std_logic_vector(2*dataWidth-1 downto 0);
signal ci_sign_bit : std_logic;
signal ci_lsb_conc : std_logic_vector(nbrOfDecimalDigits-1 downto 0);
signal ci_msb_conc : std_logic_vector(nbrOfIntegerDigits-1 downto 0);

signal cr : std_logic_vector(2*dataWidth-1 downto 0);
signal cr_sign_bit : std_logic;
signal cr_lsb_conc : std_logic_vector(nbrOfDecimalDigits-1 downto 0);
signal cr_msb_conc : std_logic_vector(nbrOfIntegerDigits-1 downto 0);

begin

-- double ci and cr dynamics
ci_sign_bit <= ci_i(dataWidth-1);
ci_lsb_conc <= (others => '0');
ci_msb_conc <= (others => ci_sign_bit);
ci <= ci_msb_conc & ci_i &ci_lsb_conc;

cr_sign_bit <= cr_i(dataWidth-1);
cr_lsb_conc <= (others => '0');
cr_msb_conc <= (others => cr_sign_bit);
cr <= cr_msb_conc & cr_i &cr_lsb_conc;

-- left shift -> x2
z2ir <= zir(2*dataWidth-2 downto 0) & '0';

-- troncature outputs
zrNext_o <= zrNext(2*dataWidth - 1 - nbrOfIntegerDigits downto nbrOfDecimalDigits);
ziNext_o <= ziNext(2*dataWidth - 1 - nbrOfIntegerDigits downto nbrOfDecimalDigits);

MULT1 : MULT_MACRO
generic map (
  DEVICE => "7SERIES",    -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6" 
  LATENCY => 0,           -- Desired clock cycle latency, 0-4
  WIDTH_A => dataWidth,          -- Multiplier A-input bus width, 1-25 
  WIDTH_B => dataWidth)          -- Multiplier B-input bus width, 1-18
port map (
  P => zr2,     -- Multiplier ouput bus, width determined by WIDTH_P generic 
  A => zr_i,     -- Multiplier input A bus, width determined by WIDTH_A generic 
  B => zr_i,     -- Multiplier input B bus, width determined by WIDTH_B generic 
  CE => '1',   -- 1-bit active high input clock enable
  CLK => clk_i, -- 1-bit positive edge clock input
  RST => reset_i  -- 1-bit input active high reset
);
   
MULT2 : MULT_MACRO
generic map (
  DEVICE => "7SERIES",    -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6" 
  LATENCY => 0,           -- Desired clock cycle latency, 0-4
  WIDTH_A => dataWidth,          -- Multiplier A-input bus width, 1-25 
  WIDTH_B => dataWidth)          -- Multiplier B-input bus width, 1-18
port map (
  P => zi2,     -- Multiplier ouput bus, width determined by WIDTH_P generic 
  A => zi_i,     -- Multiplier input A bus, width determined by WIDTH_A generic 
  B => zi_i,     -- Multiplier input B bus, width determined by WIDTH_B generic 
  CE => '1',   -- 1-bit active high input clock enable
  CLK => clk_i, -- 1-bit positive edge clock input
  RST => reset_i  -- 1-bit input active high reset
);
   
MULT3 : MULT_MACRO
generic map (
  DEVICE => "7SERIES",    -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6" 
  LATENCY => 0,           -- Desired clock cycle latency, 0-4
  WIDTH_A => dataWidth,          -- Multiplier A-input bus width, 1-25 
  WIDTH_B => dataWidth)          -- Multiplier B-input bus width, 1-18
port map (
  P => zir,     -- Multiplier ouput bus, width determined by WIDTH_P generic 
  A => zi_i,     -- Multiplier input A bus, width determined by WIDTH_A generic 
  B => zr_i,     -- Multiplier input B bus, width determined by WIDTH_B generic 
  CE => '1',   -- 1-bit active high input clock enable
  CLK => clk_i, -- 1-bit positive edge clock input
  RST => reset_i  -- 1-bit input active high reset
);

ADD1 : ADDSUB_MACRO
generic map (
  DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6" 
  LATENCY => 0,        -- Desired clock cycle latency, 0-2
  WIDTH => 2*dataWidth)         -- Input / Output bus width, 1-48
port map (
  CARRYOUT => add1_cout, -- 1-bit carry-out output signal
  RESULT => zadd1,     -- Add/sub result output, width defined by WIDTH generic
  A => zr2,               -- Input A bus, width defined by WIDTH generic
  ADD_SUB => '0',   -- 1-bit add/sub input, high selects add, low selects subtract
  B => zi2,               -- Input B bus, width defined by WIDTH generic
  CARRYIN => '0',   -- 1-bit carry-in input
  CE => '1',             -- 1-bit clock enable input
  CLK => clk_i,           -- 1-bit clock input
  RST => reset_i            -- 1-bit active high synchronous reset
);

ADD2 : ADDSUB_MACRO
generic map (
  DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6" 
  LATENCY => 0,        -- Desired clock cycle latency, 0-2
  WIDTH => 2*dataWidth)         -- Input / Output bus width, 1-48
port map (
  CARRYOUT => add2_cout, -- 1-bit carry-out output signal
  RESULT => zrNext,     -- Add/sub result output, width defined by WIDTH generic
  A => cr,               -- Input A bus, width defined by WIDTH generic
  ADD_SUB => '1',   -- 1-bit add/sub input, high selects add, low selects subtract
  B => zadd1,               -- Input B bus, width defined by WIDTH generic
  CARRYIN => add1_cout,   -- 1-bit carry-in input
  CE => '1',             -- 1-bit clock enable input
  CLK => clk_i,           -- 1-bit clock input
  RST => reset_i            -- 1-bit active high synchronous reset
);

ADD3 : ADDSUB_MACRO
generic map (
  DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6" 
  LATENCY => 0,        -- Desired clock cycle latency, 0-2
  WIDTH => 2*dataWidth)         -- Input / Output bus width, 1-48
port map (
  CARRYOUT => add3_cout, -- 1-bit carry-out output signal
  RESULT => ziNext,     -- Add/sub result output, width defined by WIDTH generic
  A => z2ir,               -- Input A bus, width defined by WIDTH generic
  ADD_SUB => '1',   -- 1-bit add/sub input, high selects add, low selects subtract
  B => ci,               -- Input B bus, width defined by WIDTH generic
  CARRYIN => '0',   -- 1-bit carry-in input
  CE => '1',             -- 1-bit clock enable input
  CLK => clk_i,           -- 1-bit clock input
  RST => reset_i            -- 1-bit active high synchronous reset
);



    
end Behavioral;
