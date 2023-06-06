----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.04.2023 15:40:07
-- Design Name: 
-- Module Name: complexModule_comparator - Behavioral
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
--library UNISIM;
--use UNISIM.VComponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity complexModule_comparator is
	generic(
		dataWidth : integer := 16;
		nbrOfIntegerDigits : integer := 4;
		nbrOfDecimalDigits : integer := 12);
    Port (
    	clk : in std_logic;
    	rst : in std_logic; 
    	zr_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
        zi_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
        smaller_nGreater_o : out std_logic
        );
end complexModule_comparator;

architecture Behavioral of complexModule_comparator is

signal zr2_s : STD_LOGIC_VECTOR (2*dataWidth-1 downto 0);
signal zi2_s : STD_LOGIC_VECTOR (2*dataWidth-1 downto 0);

signal squareModule : unsigned(2*dataWidth-1 downto 0);

signal decimalPartOfFour : unsigned(2*nbrOfDecimalDigits-1 downto 0);
signal integerPartOfFour : unsigned(2*nbrOfIntegerDigits-1 downto 0);
signal four : unsigned(2*dataWidth-1 downto 0);

begin

	decimalPartOfFour <= (others => '0');
	integerPartOfFour <= (2 => '1', others => '0'); 		-- b"100" = 4			
	four <= integerPartOfFour & decimalPartOfFour;

	squareModule <= unsigned(zr2_s) + unsigned(zi2_s);

	smaller_nGreater_o <= 	'1' when squareModule < four else
						 	'0';

	MULT1 : MULT_MACRO
	generic map (
		DEVICE => "7SERIES",    -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6" 
		LATENCY => 0,           -- Desired clock cycle latency, 0-4
		WIDTH_A => dataWidth,          -- Multiplier A-input bus width, 1-25 
		WIDTH_B => dataWidth)          -- Multiplier B-input bus width, 1-18
	port map (
		P => zr2_s,     -- Multiplier ouput bus, width determined by WIDTH_P generic 
		A => zr_i,     -- Multiplier input A bus, width determined by WIDTH_A generic 
		B => zr_i,     -- Multiplier input B bus, width determined by WIDTH_B generic 
		CE => '1',   -- 1-bit active high input clock enable
		CLK => clk, -- 1-bit positive edge clock input
		RST => rst  -- 1-bit input active high reset
	);
	
	MULT2 : MULT_MACRO
	generic map (
		DEVICE => "7SERIES",    -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6" 
		LATENCY => 0,           -- Desired clock cycle latency, 0-4
		WIDTH_A => dataWidth,          -- Multiplier A-input bus width, 1-25 
		WIDTH_B => dataWidth)          -- Multiplier B-input bus width, 1-18
	port map (
		P => zi2_s,     -- Multiplier ouput bus, width determined by WIDTH_P generic 
		A => zi_i,     -- Multiplier input A bus, width determined by WIDTH_A generic 
		B => zi_i,     -- Multiplier input B bus, width determined by WIDTH_B generic 
		CE => '1',   -- 1-bit active high input clock enable
		CLK => clk, -- 1-bit positive edge clock input
		RST => rst  -- 1-bit input active high reset
	);
	
end Behavioral;
