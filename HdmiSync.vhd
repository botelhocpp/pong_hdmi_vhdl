LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.HdmiPkg.ALL;

ENTITY HdmiSync IS
PORT (
    i_Clk : IN STD_LOGIC;
    o_Pixel_Clk : OUT STD_LOGIC;
    o_Video_Enable : OUT STD_LOGIC;
    o_H_Sync : OUT STD_LOGIC;
    o_V_Sync : OUT STD_LOGIC;
    o_H_Pos : OUT INTEGER RANGE 0 TO c_H_MAX;
    o_V_Pos : OUT INTEGER RANGE 0 TO c_V_MAX
);
END ENTITY;

ARCHITECTURE RTL OF HdmiSync IS
    -- Wires
    SIGNAL w_Video_Enable : STD_LOGIC := '0';
    
    -- Registers
    SIGNAL r_Pixel_Clk : STD_LOGIC := '0';
    SIGNAL r_H_Active, r_V_Active : STD_LOGIC := '0';
    SIGNAL r_H_Sync, r_V_Sync : STD_LOGIC := '0';
   
    SIGNAL w_H_Pos : INTEGER RANGE 0 TO c_H_MAX := 0;
    SIGNAL w_V_Pos : INTEGER RANGE 0 TO c_V_MAX := 0;
BEGIN
    -- Generate 25MHz clock from 250MHz
    p_GENERATE_PIXEL_CLK:
    PROCESS(i_Clk)
        CONSTANT c_PIXEL_CLK_DIV : INTEGER := 10;
        VARIABLE v_Counter : INTEGER RANGE 0 TO c_PIXEL_CLK_DIV/2;
    BEGIN
        IF RISING_EDGE(i_Clk) THEN
            v_Counter := v_Counter + 1;
            IF (v_Counter = c_PIXEL_CLK_DIV/2) THEN
                r_Pixel_Clk <= NOT r_Pixel_Clk;
                v_Counter := 0;
            END IF;
        END IF;
    END PROCESS p_GENERATE_PIXEL_CLK;
    
    -- Horizontal Synchronization (at the of column) & Active
    p_HORIZONTAL_SYNC:
    PROCESS (r_Pixel_Clk)
        VARIABLE v_H_Pos : INTEGER RANGE 0 TO c_H_MAX := 0;
    BEGIN          
        IF (RISING_EDGE(r_Pixel_Clk)) THEN
            v_H_Pos := v_H_Pos + 1;
          
            IF (v_H_Pos = c_H_MAX) THEN
                r_H_Sync <= '0';
                v_H_Pos := 0;
            ELSIF (v_H_Pos = c_H_PULSE_WIDTH) THEN
                r_H_Sync <= '1';
            END IF;
            
            IF (v_H_Pos > c_H_PULSE_WIDTH + c_H_BACK_PORCH + c_FRAME_WIDTH) THEN
                r_H_Active <= '0';
            ELSIF (v_H_Pos > c_H_PULSE_WIDTH + c_H_BACK_PORCH) THEN
                r_H_Active <= '1';
            END IF;
        END IF;
        
        w_H_Pos <= v_H_Pos;
    END PROCESS p_HORIZONTAL_SYNC;
    
    -- Vertical Synchronization (at the of line) & Active
    p_VERTICAL_SYNC:  
    PROCESS (r_H_Sync)   
        VARIABLE v_V_Pos : INTEGER RANGE 0 TO c_V_MAX := 0;
    BEGIN
        IF (FALLING_EDGE(r_H_Sync)) THEN
            v_V_Pos := v_V_Pos + 1;
            IF (v_V_Pos = c_V_MAX) THEN
                r_V_Sync <= '0';
                v_V_Pos := 0;
            ELSIF (v_V_Pos = c_V_PULSE_WIDTH) THEN
                r_V_Sync <='1';
            END IF;
            
            IF (v_V_Pos > c_V_PULSE_WIDTH + c_V_BACK_PORCH + c_FRAME_HEIGHT) THEN
                r_V_Active <= '0';
            ELSIF (v_V_Pos > c_V_PULSE_WIDTH + c_V_BACK_PORCH) THEN
                r_V_Active <= '1';
            END IF;
        END IF;
        
        w_V_Pos <= v_V_Pos;
    END PROCESS p_VERTICAL_SYNC;

    o_H_Pos <= w_H_Pos;
    o_V_Pos <= w_V_Pos;
    o_V_Sync <= r_V_Sync;
    o_H_Sync <= r_H_Sync;
    o_Pixel_Clk <= r_Pixel_Clk;
    o_Video_Enable <= w_Video_Enable;
    w_Video_Enable <= r_H_Active AND r_V_Active;

END ARCHITECTURE;