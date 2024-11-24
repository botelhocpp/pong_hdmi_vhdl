LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.HdmiPkg.ALL;

ENTITY HdmiSync IS
PORT (
    i_Clk : IN STD_LOGIC;
    o_Pixel_Clk : OUT STD_LOGIC;
    o_H_Sync : OUT STD_LOGIC;
    o_V_Sync : OUT STD_LOGIC
);
END ENTITY;

ARCHITECTURE RTL OF HdmiSync IS
    -- Registers
    SIGNAL r_Pixel_Clk : STD_LOGIC := '0';
    SIGNAL r_H_Sync : STD_LOGIC := '0';
    SIGNAL r_V_Sync : STD_LOGIC := '0';
    SIGNAL r_H_Pos : INTEGER RANGE 0 TO c_H_MAX := 0;
    SIGNAL r_V_Pos : INTEGER RANGE 0 TO c_V_MAX := 0;
BEGIN
    -- Generate 25MHz clock from 250MHz
    p_GENERATE_PIXEL_CLK:
    PROCESS(i_Clk)
        CONSTANT c_PIXEL_CLK_DIV : INTEGER := 10;
        VARIABLE v_Counter : INTEGER RANGE 0 TO c_PIXEL_CLK_DIV/2;
    BEGIN
        IF (RISING_EDGE(i_Clk)) THEN
            v_Counter := v_Counter + 1;
            IF (v_Counter = c_PIXEL_CLK_DIV/2) THEN
                r_Pixel_Clk <= NOT r_Pixel_Clk;
                v_Counter := 0;
            END IF;
        END IF;
    END PROCESS p_GENERATE_PIXEL_CLK;
    
    -- Keep track of Row/Column counters.
    p_COUNT_POSITIONS:
    PROCESS (r_Pixel_Clk) IS
    BEGIN
        IF (RISING_EDGE(r_Pixel_Clk)) THEN
            IF (r_H_Pos = c_H_MAX - 1) THEN
                r_H_Pos <= 0;

                IF (r_V_Pos = c_V_MAX - 1) THEN
                    r_V_Pos <= 0;
                ELSE
                    r_V_Pos <= r_V_Pos + 1;
                END IF;
            ELSE
                r_H_Pos <= r_H_Pos + 1;
            END IF;
        END IF;
    END PROCESS p_COUNT_POSITIONS;

    o_H_Sync <= '1' when r_H_Pos < c_FRAME_WIDTH else '0';
    o_V_Sync <= '1' when r_V_Pos < c_FRAME_HEIGHT else '0';

    o_Pixel_Clk <= r_Pixel_Clk;
END ARCHITECTURE;