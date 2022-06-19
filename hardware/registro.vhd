library IEEE;
use IEEE.std_logic_1164.all;

entity registroNbits is

    generic(ANCHO: natural :=32);
	port(
		d_i: in std_logic_vector(ANCHO-1 downto 0);
		e_i: in std_logic;
		r_i: in std_logic;
		clk_i: in std_logic;
		q_o: out std_logic_vector(ANCHO-1 downto 0) := (others=>'0')
	);
end;

architecture registroNbits_arq of registroNbits is
	
begin
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if r_i = '1' then
                q_o <= (others =>'0');
            elsif e_i = '1' then
                q_o <= d_i;
            end if;
        end if;
    end process;
end registroNbits_arq;


-----------------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use	IEEE.NUMERIC_STD.all;

entity comparator is

    generic(ANCHO: natural :=4);
    
	port(
		dat1_i:   in std_logic_vector(ANCHO-1 downto 0);
		dat2_i:   in std_logic_vector(ANCHO-1 downto 0);
		umbral_i: in std_logic_vector(ANCHO-1 downto 0);
		--clk_i:    in std_logic;
		flag_o:   out std_logic := '0'
	);
end;

architecture comparator_arq of comparator is
	
begin
    process(dat1_i,dat2_i)
    variable diferencia : signed(ANCHO-1 downto 0):= (others=>'0');
    begin
        --if rising_edge(clk_i) then
            if signed(dat1_i) > signed(dat2_i) then
                diferencia := signed(dat1_i) - signed(dat2_i);
            else
                diferencia := signed(dat2_i) - signed(dat1_i);
            end if;
            
            if signed(umbral_i) < diferencia then
                flag_o <= '1';
            else          
                flag_o <= '0';
            end if;
        --end if;            
     end process;  
 
end comparator_arq;
----------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use	IEEE.NUMERIC_STD.all;

entity counterNbits is

    generic(
            ANCHO: natural :=4;
            MAXIMO: natural :=50
            );
    
    
	port(
		clk_i: in std_logic;
		rst_i: in std_logic;
		set_i: in std_logic;
		ena_i: in std_logic;
		cuenta_o: out std_logic_vector(ANCHO-1 downto 0):= (others=>'0')--std_logic_vector(to_unsigned(1,ANCHO))--
	);
end;

architecture counterNbits_arq of counterNbits is
	
begin

    process(clk_i )
        variable count: unsigned (ANCHO-1 downto 0):= (others=>'0');--to_unsigned(1,ANCHO);
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                count := (others=>'0');
            elsif set_i = '1' then
                count := to_unsigned(1,ANCHO);
            elsif ena_i = '1' then
                if count < MAXIMO then            
                    count := count + 1;
                 end if;
            end if;    
            cuenta_o <= std_logic_vector(count); 
         end if;
     end process;      
 
end counterNbits_arq;
----------------------------------------------------------------------------------------------------------
--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

--package bus_multiplexer_pkg is
--        type bus_array is array(natural range <>) of std_logic_vector;
--end package;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity filtroVentana is
    
    generic(
        ANCHO: natural :=32; --ancho en bits del buss
        LARGO: natural :=10 -- cantidad de registros del shifter  
    );
	port(
		adc_i:      in std_logic_vector(ANCHO-1 downto 0);
		umbral_i: in std_logic_vector(ANCHO-1 downto 0);
		clk_i:    in std_logic;
		rst_i:    in std_logic;
		ena_i:    in std_logic;
		promedio_o:      out std_logic_vector(ANCHO-1 downto 0)
	);
end;

architecture filtroVentana_arq of filtroVentana is
	
	component registroNbits is

    generic(ANCHO: natural :=ANCHO);
	port(
		d_i: in std_logic_vector(ANCHO-1 downto 0);
		e_i: in std_logic;
		r_i: in std_logic;
		clk_i: in std_logic;
		q_o: out std_logic_vector(ANCHO-1 downto 0)
	);
    end component;
    
    component comparator is
    
    generic(ANCHO: natural :=ANCHO);
        
        port(
            dat1_i:   in std_logic_vector(ANCHO-1 downto 0);
            dat2_i:   in std_logic_vector(ANCHO-1 downto 0);
            umbral_i: in std_logic_vector(ANCHO-1 downto 0);
            --clk_i:    in std_logic;
            flag_o:   out std_logic := '0'
        );
    end component;
    
    component counterNbits is
    
        generic(
                ANCHO: natural :=ANCHO;
                MAXIMO: natural :=LARGO
                );    
        port(
            clk_i: in std_logic;
            rst_i: in std_logic;
            set_i: in std_logic;
            ena_i: in std_logic;
            cuenta_o: out std_logic_vector(ANCHO-1 downto 0)
        );
    end component;
	
	type BUS_PILA is array (0 to LARGO) of std_logic_vector(ANCHO -1 downto 0);
    signal d:              BUS_PILA := (others=>(others=>'0'));
    signal umbral_flag:    std_logic;
	signal reset:          std_logic;
	signal divisor:        std_logic_vector(ANCHO-1 downto 0);
begin

    reset <= rst_i or umbral_flag;
 
shift_reg1: registroNbits
    generic map(ANCHO => ANCHO)
    port map(
        clk_i   => clk_i,
        d_i     =>d(0),
        r_i     => rst_i,
        e_i     => ena_i,
        q_o     => d(1)
    ); 
    
shift_reg_i: for i in 1 to LARGO-1 generate
    registro_inst: registroNbits
    generic map(ANCHO => ANCHO)
    port map(
        clk_i   => clk_i,
        d_i     =>d(i),
        r_i     => reset,
        e_i     => ena_i,
        q_o     => d(i+1)
    ); 
 end generate;
 
comparador: comparator
 
     generic map(ANCHO => ANCHO)
     
     port map(
         dat1_i     => d(0),
         dat2_i     => d(1),
         umbral_i   => umbral_i,
         --clk_i      => clk_i,
         flag_o     => umbral_flag
     );
contador: counterNbits

    generic map(
            ANCHO => ANCHO,
            MAXIMO => LARGO
            )    
    port map(
        clk_i   => clk_i,
        rst_i   => rst_i,
        set_i   => umbral_flag,
        ena_i   => ena_i,
        cuenta_o => divisor
    );
         
 sumador: process(clk_i)
    variable suma: signed(ANCHO-1 downto 0);
    variable resultado: signed(ANCHO-1 downto 0);
 begin
    --if rising_edge(clk_i) then
    if falling_edge(clk_i) then
        if ena_i = '1' then 
            suma := (others=>'0');
            
            for i in 1 to LARGO loop
                suma:= suma + signed(d(i));
            end loop;
            if signed(divisor) > 0 then
                resultado := suma / signed(divisor);
                promedio_o <= std_logic_vector(resultado);
            else
                promedio_o <= d(1);
            end if;
        end if;
    end if;
 end process;
 
 d(0) <= adc_i;
    
end filtroVentana_arq;