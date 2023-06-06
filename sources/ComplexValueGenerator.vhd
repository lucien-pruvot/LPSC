----------------------------------------------------------------------------------
-- hepia / LPSCP / Pr. F. Vannel
--
-- Generateur de nombres complexes a fournir au calculateur de Mandelbrot
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



entity ComplexValueGenerator is
generic
  (SIZE        : integer :=  18;  -- Taille en bits de nombre au format virgule fixe
   COMMA       : integer :=  14;  -- Nombre de bits après la virgule
   X_SIZE      : integer := 1024;  -- Taille en X (Nombre de pixel) de la fractale à afficher
   Y_SIZE      : integer := 600;  -- Taille en Y (Nombre de pixel) de la fractale à afficher
   SCREEN_RES  : integer := 10    -- Nombre de bit pour les vecteurs X et Y de la position du pixel
  );   
port
  (clk         : in  std_logic;
   reset       : in  std_logic;
   -- interface avec le module MandelbrotMiddleware
   next_value  : in  std_logic;
   c_real      : out std_logic_vector (SIZE-1 downto 0);
   c_imaginary : out std_logic_vector (SIZE-1 downto 0);
   X_screen    : out std_logic_vector (SCREEN_RES-1 downto 0);
   Y_screen    : out std_logic_vector (SCREEN_RES-1 downto 0);
   BtnUP			: in std_logic;
   BtnDOWN		: in std_logic;
	BtnLEFT		: in std_logic;
	BtnRIGHT		: in std_logic;
	BtnCENTER	: in std_logic;
	sw0			: in std_logic
   );
end ComplexValueGenerator;


architecture Behavioral of ComplexValueGenerator is


  -- signaux internes
  signal c_re, c_im           : std_logic_vector (SIZE-1 downto 0);
  signal c_re_min, c_im_min       : std_logic_vector (SIZE-1 downto 0);
  signal posx_i, posy_i           : std_logic_vector (SCREEN_RES-1 downto 0);

  
  -- constantes
  
  signal c_bot_left_RE : integer := -2;
  signal c_bot_left_IM : integer := -1;
  signal comma_padding : std_logic_vector (comma-1 downto 0) := (others=>'0');
  signal x_incr         : std_logic_vector (SIZE-1 downto 0) := "000000000000110000";
  signal y_incr         : std_logic_vector (SIZE-1 downto 0) := "000000000000110111";
  
  signal verticalOffset			: signed(15 downto 0);
  signal horizontalOffset		: signed(15 downto 0);
  signal test : unsigned(12 downto 0);

begin

  -- fixe la valeur des signaux utilitaires ----------------------------------
  c_re_min <= conv_std_logic_vector(c_bot_left_RE, (SIZE-COMMA)) & comma_padding; -- -2.0 fixed point arithmetic
  c_im_min <= conv_std_logic_vector(c_bot_left_IM, (SIZE-COMMA)) & comma_padding; -- -1.0 fixed point arithmetic
  --x_incr    <= "000000000000110000"; -- valeur virgule fixe selon regles 
  --y_incr    <= "000000000000110111"; -- valeur virgule fixe selon regles 
	
  -- processus combinatoire --------------------------------------------------
	process (clk, reset)
	begin   
	if (reset = '1') then 
		c_re <= c_re_min;
		c_im <= c_im_min;
		posx_i <= (others => '0');
		posy_i <= (others => '0');
		x_incr <= "000000000000110000";
		y_incr <= "000000000000110111";
		verticalOffset <= (others => '0');
		horizontalOffset <= (others => '0');
		test <= (others => '0');
       
	elsif rising_edge(clk) then
    
		if next_value = '1' then
		
			horizontalOffset <= horizontalOffset;
			verticalOffset <= verticalOffset;
			x_incr <= x_incr;
			y_incr <= y_incr;
		
			if posx_i /= X_SIZE-1 and posy_i /= Y_SIZE-1 then
				c_re <= c_re   + x_incr;
				posx_i <= posx_i + 1;
				c_im  <= c_im;
				posy_i <= posy_i;
				
			elsif posx_i = X_SIZE-1 and posy_i /= Y_SIZE-1 then
				c_re <= c_re_min + conv_std_logic_vector(horizontalOffset, SIZE);
				posx_i <= (others => '0');
				c_im <= c_im + y_incr;
				posy_i <= posy_i + 1;
			
			elsif posx_i /= X_SIZE-1 and posy_i = Y_SIZE-1 then
				c_re <= c_re   + x_incr;
				posx_i <= posx_i + 1;
				c_im  <= c_im;
				posy_i <= posy_i;
			
			elsif posx_i = X_SIZE-1 and posy_i = Y_SIZE-1 then
				--test <= test + 256;
				c_re <= c_re_min + conv_std_logic_vector(horizontalOffset, SIZE);
				--c_re <= c_re_min + std_logic_vector(test);
				posx_i <= (others => '0');
				c_im <= c_im_min  + conv_std_logic_vector(verticalOffset, SIZE);
				--c_im <= c_im_min  + std_logic_vector(test);
				posy_i <= (others => '0');
				
				
				if BtnCENTER = '1'then		-- ZOOM
					if sw0 = '1' then
						x_incr <= x_incr - 1;
						y_incr <= y_incr - 1;
					else
						x_incr <= x_incr + 1;
						y_incr <= y_incr + 1;
					end if;
				elsif BtnRIGHT = '1' then
					horizontalOffset <= horizontalOffset + 1024;
				elsif BtnLEFT = '1' then
					horizontalOffset <= horizontalOffset - 1024;
				elsif BtnDOWN = '1' then
					verticalOffset <= verticalOffset - 1024;
				elsif BtnUP = '1' then
					verticalOffset <= verticalOffset + 1024;
				end if;
			end if;
		end if;
	end if;
	end process;



  -- sorties pour le module calculateur de Mandelbrot ----------------------
  c_real      <= c_re;
  c_imaginary <= c_im;
  X_screen    <= posx_i;
  Y_screen    <= posy_i;

end Behavioral;

