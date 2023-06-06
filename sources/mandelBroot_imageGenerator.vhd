----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.04.2023 11:05:44
-- Design Name: 
-- Module Name: mandelBroot_imageGenerator - Behavioral
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library lpsc_lib;
use lpsc_lib.lpsc_hdmi_interface_pkg.all;

entity mandelBroot_imageGenerator is

    generic (
        MANDEL_DATA_SIZE  : integer     := 18;
        C_PIXEL_SIZE : integer     := 8;
        C_VGA_CONFIG : t_VgaConfig := C_DEFAULT_VGACONFIG);

    port (
        ClkVgaxCI    : in  std_logic;
        RstxRAI      : in  std_logic;
        PllLockedxSI : in  std_logic;
        HCountxDI    : in  std_logic_vector((16 - 1) downto 0);
        VCountxDI    : in  std_logic_vector((16 - 1) downto 0);
        VidOnxSI     : in  std_logic;
        DataxDO      : out std_logic_vector(((C_PIXEL_SIZE * 3) - 1) downto 0);
        Color1xDI    : in  std_logic_vector(((C_PIXEL_SIZE * 3) - 1) downto 0);
        write_BRAM_o : out std_logic;
        wAddr_o		: out std_logic_vector(19 downto 0);
		BtnUP			: in std_logic;
		BtnDOWN		: in std_logic;
		BtnLEFT		: in std_logic;
		BtnRIGHT		: in std_logic;
		BtnCENTER	: in std_logic;
		sw0			: in std_logic
        );

end entity mandelBroot_imageGenerator;

architecture behavioral of mandelBroot_imageGenerator is

    constant commaDigits : integer := MANDEL_DATA_SIZE - 4;
    constant screenRes : integer := 10;
    --constant xIncrement : unsigned 

	component ComplexValueGenerator is
	generic(
		SIZE        : integer :=  MANDEL_DATA_SIZE;  -- Taille en bits de nombre au format virgule fixe
		COMMA       : integer :=  commaDigits;  -- Nombre de bits aprÃ¨s la virgule
		X_SIZE      : integer := 1024;  -- Taille en X (Nombre de pixel) de la fractale Ã  afficher
		Y_SIZE      : integer := 600;  -- Taille en Y (Nombre de pixel) de la fractale Ã  afficher
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
	end component;
	
	component iterator_comparator is
    generic ( 
        comma : integer := commaDigits; -- nombre de bits après la virgule
        max_iter : integer := 100;
        SIZE : integer := MANDEL_DATA_SIZE);
    port(
        clk : in std_logic;
        rst : in std_logic;
        ready_o : out std_logic;
        start_i : in std_logic;
        finished_o : out std_logic;
        c_real_i : in std_logic_vector(SIZE-1 downto 0);
        c_imaginary_i : in std_logic_vector(SIZE-1 downto 0);
        z_real_o : out std_logic_vector(SIZE-1 downto 0);
        z_imaginary_o : out std_logic_vector(SIZE-1 downto 0);
        iterations_o : out std_logic_vector(SIZE-1 downto 0)
        
        --keep_compute_o : out std_logic;
        --smaller_nGreater_o : out std_logic;
        --zr_s_o : out std_logic_vector(SIZE-1 downto 0);
		--zi_s_o : out std_logic_vector(SIZE-1 downto 0)
		);
	end component;

    signal VgaConfigxD            : t_VgaConfig                                         := C_VGA_CONFIG;
    signal DataxD                 : std_logic_vector(((C_PIXEL_SIZE * 3) - 1) downto 0) := (others => '0');
    signal HCountxD               : std_logic_vector((MANDEL_DATA_SIZE - 1) downto 0)        := (others => '0');
    signal VCountxD               : std_logic_vector((MANDEL_DATA_SIZE - 1) downto 0)        := (others => '0');
    
    -- signals for complexValueGenerator
    signal c_real : std_logic_vector(MANDEL_DATA_SIZE-1 downto 0);
    signal c_im : std_logic_vector(MANDEL_DATA_SIZE-1 downto 0);
    signal x_screen : std_logic_vector(screenRes-1 downto 0);
    signal y_screen : std_logic_vector(screenRes-1 downto 0);
    
    type state is (READY_DONE, START_COMPUTE, COMPUTE, SAVE);
	signal currentState : state;
	signal nextState : state;
	
	signal start_it : std_logic;
	signal it_finished : std_logic;
	signal it_ready : std_logic;
	signal next_value : std_logic;
	signal write_BRAM : std_logic;
	
	signal z_real : std_logic_vector(MANDEL_DATA_SIZE-1 downto 0);
	signal z_im : std_logic_vector(MANDEL_DATA_SIZE-1 downto 0);
	signal iterations : std_logic_vector(MANDEL_DATA_SIZE-1 downto 0);
	signal iterations_save : std_logic_vector(7 downto 0);
	
	signal maxVal255 : unsigned(7 downto 0);
	
	
    


begin  -- architecture behavioural

	process(currentState, it_finished)
	begin
		-- default values
		start_it <= '0';
		next_value <= '0';
		write_BRAM_o <= '0';
		
        case(currentState) is
        
			when READY_DONE =>
				if VidOnxSI = '1' then
					nextState <= START_COMPUTE;
				else
					nextState <= READY_DONE;
				end if;
					
		    when START_COMPUTE =>
		    	start_it <= '1';
		    	next_value <= '1';
		    	nextState <= COMPUTE;
		        
			when COMPUTE =>					-- MAX 1 TCLK TO COMPUTE
				if it_finished = '1' then
					nextState <= SAVE;
				else
					nextState <= COMPUTE;
				end if;
				
			when SAVE =>					-- MAX 1 TCLK TO COMPUTE
				write_BRAM_o <= '1';
				nextState <= READY_DONE;
					
			when others =>
				nextState <= READY_DONE;
		end case;
	end process;

	process(ClkVgaxCI, RstxRAI)
	begin
		if RstxRAI = '1' then
			currentState <= READY_DONE;
		elsif rising_edge(ClkVgaxCI) then
			currentState <= nextState;
		end if;
	end process;

	c_values_generator : ComplexValueGenerator
	generic map(
		SIZE        => MANDEL_DATA_SIZE,  -- Taille en bits de nombre au format virgule fixe
		COMMA       =>  commaDigits,  -- Nombre de bits aprÃ¨s la virgule
		X_SIZE      => 1024,  -- Taille en X (Nombre de pixel) de la fractale Ã  afficher
		Y_SIZE      => 600,  -- Taille en Y (Nombre de pixel) de la fractale Ã  afficher
		SCREEN_RES  => 10    -- Nombre de bit pour les vecteurs X et Y de la position du pixel
		)
	port map(
		clk         => ClkVgaxCI,
		reset       => RstxRAI,
		-- interface avec le module MandelbrotMiddleware
		next_value  => next_value,
		c_real      => c_real,
		c_imaginary => c_im,
		X_screen    => x_screen,
		Y_screen    => y_screen,
		BtnUP					=> BtnUP,
      BtnDOWN				=> BtnDOWN,
		BtnRIGHT				=> BtnRIGHT,
      BtnLEFT				=> BtnLEFT,
		BtnCENTER			=> BtnCENTER,
      sw0					=> sw0
		);
		
	mandelBroot_caclculator : iterator_comparator
    generic map( 
        comma 		=> commaDigits,
        max_iter 	=> 100,
        SIZE 		=> MANDEL_DATA_SIZE
        )
    port map(
        clk 			=> ClkVgaxCI,
        rst 			=> RstxRAI,
        ready_o 		=> it_ready,
        start_i  		=> start_it,
        finished_o 		=> it_finished,
        c_real_i		=> c_real,
        c_imaginary_i	=> c_im,
        z_real_o 		=> z_real,
        z_imaginary_o 	=> z_im,
        iterations_o 	=> iterations
        
        --keep_compute_o : out std_logic;
        --smaller_nGreater_o : out std_logic;
        --zr_s_o : out std_logic_vector(SIZE-1 downto 0);
		--zi_s_o : out std_logic_vector(SIZE-1 downto 0)
		);

	maxVal255 <= x"FF";

--	process(iterations_save)
--	begin
--		if unsigned(iterations_save) >= 100 then
--			DataxDO <= x"8A2BE2";
--		elsif unsigned(iterations_save) = 1 then
--			DataxDO <= (15 downto 8 => '1', others => '0');
--		elsif unsigned(iterations_save) = 2 then
--			DataxDO <= (7 downto 0 => '1', others => '0');
--		elsif unsigned(iterations_save) = 3 then
--			DataxDO <= (23 downto 16 => '1', others => '0');
--		elsif unsigned(iterations_save) = 4 then
--			DataxDO <= (22 downto 16 => '1', others => '0');
--		else
--			DataxDO(7 downto 1) <= std_logic_vector(maxVal255(7 downto 1) - unsigned(iterations_save(6 downto 0)));
--			DataxDO(0) <= '0';
--			--DataxDO(15 downto 9) <= std_logic_vector(maxVal255(7 downto 1) - unsigned(iterations_save(6 downto 0)));
--			--DataxDO(8) <= '0';
--			DataxDO(15 downto 8) <= (others => '0');
--			DataxDO(23 downto 17) <= std_logic_vector(maxVal255(7 downto 1) - unsigned(iterations_save(6 downto 0)));
--			DataxDO(16) <= '0';
--		end if;
--	end process;
	
--	process(iterations_save)
--	begin
--		if unsigned(iterations_save) >= 100 then
--			DataxDO <= x"8A2BE2";
--		else
--			DataxDO(23 downto 21) <= iterations_save(2 downto 0);
--			DataxDO(15 downto 13) <= iterations_save(5 downto 3);
--			DataxDO(7 downto 6) <= iterations_save(7 downto 6);
--			DataxDO(5) <= '0';
--		end if;
--	end process;
	
	process(iterations_save)
	begin
		if unsigned(iterations_save) >= 100 then
			DataxDO <= x"8A2BE2";
		else
			DataxDO(23 downto 21) <= iterations_save(5 downto 3);
			DataxDO(15) <= iterations_save(6);
			DataxDO(7 downto 5) <= not iterations_save(2 downto 0);
		end if;
	end process;
	
	process(iterations)
	begin
		if RstxRAI = '1' then
			iterations_save <= (others => '0');
		elsif rising_edge(ClkVgaxCI) then
			if currentState = COMPUTE and it_finished = '1' then
				iterations_save <= iterations(7 downto 0);
			else
				iterations_save <= iterations_save;
			end if;
		end if;
	end process;
	
	wAddr_o <= y_screen & x_screen;
	
	
    
end Behavioral;