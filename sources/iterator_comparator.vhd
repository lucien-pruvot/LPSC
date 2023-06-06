----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.04.2023 15:03:03
-- Design Name: 
-- Module Name: iterator_comparator - Behavioral
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

entity iterator_comparator is
    generic ( 
        comma : integer := 12; -- nombre de bits après la virgule
        max_iter : integer := 100;
        SIZE : integer := 18);
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
        iterations_o : out std_logic_vector(SIZE-1 downto 0);
        
        keep_compute_o : out std_logic;
        smaller_nGreater_o : out std_logic;
        zr_s_o : out std_logic_vector(SIZE-1 downto 0);
		zi_s_o : out std_logic_vector(SIZE-1 downto 0));
end iterator_comparator;


architecture Behavioral of iterator_comparator is                                                                                                       

    component mandelBrot_compute
        generic(
            dataWidth : integer := SIZE;
            nbrOfIntegerDigits : integer := SIZE - comma;
            nbrOfDecimalDigits : integer := comma);
        port ( 
            clk_i : in std_logic;
            reset_i : in std_logic;
            
            zr_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
            zi_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
            cr_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
            ci_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
            
            zrNext_o : out std_logic_vector(dataWidth-1 downto 0);
            ziNext_o : out std_logic_vector(dataWidth-1 downto 0)
        );
    end component;
    
    component complexModule_comparator is
	generic(
		dataWidth : integer := SIZE;
		nbrOfIntegerDigits : integer := SIZE - comma;
		nbrOfDecimalDigits : integer := comma);
    Port (
    	clk : in std_logic;
    	rst : in std_logic; 
    	zr_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
        zi_i : in STD_LOGIC_VECTOR (dataWidth-1 downto 0);
        smaller_nGreater_o : out std_logic
        );
	end component;

    -- outputs copied signals
    signal zr_os : STD_LOGIC_VECTOR (SIZE-1 downto 0) := (others => '0'); -- output of the system and input of comparator
    signal zi_os : STD_LOGIC_VECTOR (SIZE-1 downto 0) := (others => '0'); -- output of the system and input of comparator
    signal ready_os : STD_LOGIC;
    signal finished_os : STD_LOGIC;
    
    -- state machine signals
    type states is (IDLE, READY, COMPUTE, COMPARE, DONE);
	signal system_currentState : states;
	signal system_nextState : states;
	
	-- other signals
	signal cr_is : STD_LOGIC_VECTOR (SIZE-1 downto 0); -- these 2 are retained at start
    signal ci_is : STD_LOGIC_VECTOR (SIZE-1 downto 0);
	
	signal zr_s : STD_LOGIC_VECTOR (SIZE-1 downto 0) := (others => '0'); -- output of the calculator
    signal zi_s : STD_LOGIC_VECTOR (SIZE-1 downto 0) := (others => '0'); -- output of the calculator
    
    signal stop_compute_s : std_logic;
    --signal flag_compute_s : std_logic;
    signal flag_compare_s : std_logic;
    signal keep_compute_s : std_logic;
    
    signal smaller_nGreater_s : std_logic;
    
    signal zr_in_s : STD_LOGIC_VECTOR (SIZE-1 downto 0); -- input of the calculator
    signal zi_in_s : STD_LOGIC_VECTOR (SIZE-1 downto 0); -- input of the calculator
    
    signal iteration_counter_s : unsigned(SIZE-1 downto 0);

begin

	smaller_nGreater_o <= smaller_nGreater_s;
	zr_s_o <= zr_s;
	zi_s_o <= zi_s;

    -- assign outputs to their intern signals
    z_real_o <= zr_os;
    z_imaginary_o <= zi_os;
    ready_o <= ready_os;
    iterations_o <= std_logic_vector(iteration_counter_s);
    finished_o <= finished_os;
    
    process(clk, rst)
	begin
		if rst = '1' then
			cr_is <= (others => '0');
			ci_is <= (others => '0');
		elsif rising_edge(clk) then
			if ready_os = '1' and start_i = '1' then
				cr_is <= c_real_i;
				ci_is <= c_imaginary_i;
			else
				cr_is <= cr_is;
				ci_is <= ci_is;
			end if;
		end if;
	end process;
   
	process(system_currentState, start_i, keep_compute_s)
	begin
	
		-- default values
		ready_os <= '0';
		--flag_compute_s <= '0';
		flag_compare_s <= '0';
		finished_os <= '0';
		
        case(system_currentState) is  
			when IDLE =>
			    system_nextState <= READY;
				
		    when READY =>
		    	ready_os <= '1';
		    	if  start_i = '1' then
		    		system_nextState <= COMPUTE;
		        else
		        	system_nextState <= READY;
		        end if;
		        
			when COMPUTE =>					-- MAX 1 TCLK TO COMPUTE
				--flag_compute_s <= '1';
				system_nextState <= COMPARE;

			when COMPARE =>					-- MAX 1 TCLK TO COMPARE
				flag_compare_s <= '1';                                                                                                                                              
				if keep_compute_s = '1' then
					system_nextState <= COMPUTE;
				else
					system_nextState <= DONE;
				end if;
				
			when DONE =>
			system_nextState <= IDLE;
				finished_os <= '1';
					
			when others =>
				system_nextState <= IDLE;
		end case;
	end process;
	
	process(clk, rst)
	begin
		if rst = '1' then
			system_currentState <= IDLE;
		elsif rising_edge(clk) then
			system_currentState <= system_nextState;
		end if;
	end process;
	
	process(clk, rst)
	begin
		if rst = '1' then
			iteration_counter_s <= (others => '0');
		elsif rising_edge(clk) then
			if system_currentState = COMPUTE then
				iteration_counter_s <= iteration_counter_s + 1;
			elsif system_currentState = DONE then
				iteration_counter_s <= (others => '0');
			else 
				iteration_counter_s <= iteration_counter_s;
			end if;
		end if;
	end process;
	
	keep_compute_s <= 	'1' when flag_compare_s = '1' and smaller_nGreater_s = '1' and (iteration_counter_s < max_iter) else
						'0';
	keep_compute_o <= keep_compute_s;
	
	process(clk, rst)
	begin
		if rst = '1' then
			zr_os <= (others => '0');
			zi_os <= (others => '0');
		elsif rising_edge(clk) then
			zr_os <= zr_s;
			zi_os <= zi_s;
		end if;
	end process;
	
	process(clk, rst)
	begin
		if rst = '1' then
			zr_in_s <= (others => '0');
			zi_in_s <= (others => '0');
		elsif rising_edge(clk) then
			if finished_os = '1' then
				zr_in_s <= (others => '0');		-- reset value when pixel is finished
				zi_in_s <= (others => '0');
			else 
				if keep_compute_s = '1' then
					zr_in_s <= zr_os;			-- refresh value for next iteration
					zi_in_s <= zi_os;
				else 
					zr_in_s <= zr_in_s;			-- hold value 
					zi_in_s <= zi_in_s;
				end if;
			end if;
		end if;
	end process;
	
	calculator : mandelBrot_compute
	generic map (
		dataWidth => SIZE,
		nbrOfIntegerDigits => (SIZE - comma),
		nbrOfDecimalDigits => comma)
	port map (
		clk_i => clk,
		reset_i => rst,
		
		zr_i => zr_in_s,
		zi_i => zi_in_s,
		cr_i => cr_is,
		ci_i => ci_is,
		
		zrNext_o => zr_s,
		ziNext_o => zi_s
	);
	
	comparator : complexModule_comparator
	generic map (
		dataWidth => SIZE,
		nbrOfIntegerDigits => (SIZE - comma),
		nbrOfDecimalDigits => comma)
	port map (
		clk => clk,
		rst => rst,
    	zr_i => zr_s,
        zi_i => zi_s,
        smaller_nGreater_o => smaller_nGreater_s
	);

end Behavioral;
