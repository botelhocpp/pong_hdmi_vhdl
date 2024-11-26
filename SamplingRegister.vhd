LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.PongPkg.ALL;

ENTITY SamplingRegister IS
PORT (
    i_Signal : IN STD_LOGIC;
    i_Clk : IN  STD_LOGIC;
    i_Number_Cycles : IN INTEGER RANGE 0 TO c_REFRESH_RATE;
    o_Output : OUT STD_LOGIC
);
END ENTITY;

ARCHITECTURE RTL OF SamplingRegister IS      
    CONSTANT c_TOTAL_CYCLES : INTEGER := c_REFRESH_RATE;          
    SIGNAL r_Output : STD_LOGIC := '0'; 
BEGIN
    o_Output <= r_Output;
    
    p_SAMPLE_INPUT:
    PROCESS(i_Clk)   
        VARIABLE v_Counter : INTEGER RANGE 0 TO c_TOTAL_CYCLES := 0;              
        VARIABLE v_Enable_Read : STD_LOGIC := '1';
    BEGIN
        IF(RISING_EDGE(i_Clk)) THEN
            IF (v_Enable_Read = '1') THEN
                IF (i_Signal = '1') THEN
                    v_Enable_Read := '0';
                    v_Counter := 0;
                    r_Output <= '1';
                ELSE
                    r_Output <= '0';
                END IF;
            ELSE
                r_Output <= '0';
                IF (v_Counter < i_Number_Cycles - 1) THEN
                    v_Counter := v_Counter + 1;
                ELSE
                    v_Enable_Read := '1';
                END IF;
            END IF;
        END IF;
    END PROCESS p_SAMPLE_INPUT;
END ARCHITECTURE;
