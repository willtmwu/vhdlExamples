LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY pwm IS
    GENERIC(
        sys_clk         : INTEGER := 100_000_000;
        pwm_freq        : INTEGER := 50);        
    PORT(
        clk           : IN  STD_LOGIC;                                    
        masterReset   : IN  STD_LOGIC;                                    
        en            : IN  STD_LOGIC;                                    
        duty          : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); 
        pwm_out       : OUT STD_LOGIC);         
END pwm;

ARCHITECTURE logic OF pwm IS
  CONSTANT period  : INTEGER := sys_clk/pwm_freq;
  SIGNAL count     : INTEGER RANGE 0 TO period - 1 := 0;     
  SIGNAL duty_cycle : INTEGER RANGE 0 TO period - 1 := 0;   

BEGIN
  PROCESS(clk, masterReset)
  BEGIN
    IF(masterReset = '1') THEN                                         
      count <= 0;                                           
      pwm_out <= '1';                                       
    ELSIF(clk'EVENT AND clk = '1') THEN                                
      IF(en = '1') THEN                                              
				duty_cycle <= (conv_integer(duty) * period) / ((2**8) - 1);
		  ELSE
			  IF(count = period - 1) THEN                  
					count <= 0;
					pwm_out <= '1';
			  ELSE                                                      
					count <= count + 1;                                   
			  END IF;
			  
			  IF(count < duty_cycle) THEN                             
					pwm_out <= '1';                                            
			  ELSIF(count >= duty_cycle) THEN                      
					pwm_out <= '0';                                            
			  END IF;
		 END IF;
    END IF;
  END PROCESS;
END logic;
