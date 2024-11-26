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
    -- Registers
    SIGNAL r_Pixel_Clk : STD_LOGIC := '0';
    SIGNAL r_H_Sync : STD_LOGIC := '1';
    SIGNAL r_V_Sync : STD_LOGIC := '1';
    SIGNAL r_H_Pos : INTEGER RANGE 0 TO c_H_MAX := 0;
    SIGNAL r_V_Pos : INTEGER RANGE 0 TO c_V_MAX := 0;
BEGIN
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
    
    p_SYNCHRONIZATION:
    PROCESS (r_Pixel_Clk)
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

            IF(
                (r_H_Pos >= c_FRAME_WIDTH + c_H_FRONT_PORCH) AND 
                (r_H_Pos < c_FRAME_WIDTH + c_H_FRONT_PORCH + c_H_PULSE_WIDTH)
            ) THEN
                r_H_Sync <= '0';
            ELSE
                r_H_Sync <= '1';
            END IF;

            IF(
                (r_V_Pos >= c_FRAME_HEIGHT + c_V_FRONT_PORCH) AND
                (r_V_Pos < c_FRAME_HEIGHT + c_V_FRONT_PORCH + c_V_PULSE_WIDTH)
            ) THEN
                r_V_Sync <= '0';
            ELSE
                r_V_Sync <= '1';
            END IF;
        END IF;
    END PROCESS p_SYNCHRONIZATION;

    o_H_Pos <= r_H_Pos;
    o_V_Pos <= r_V_Pos;
    o_V_Sync <= r_V_Sync;
    o_H_Sync <= r_H_Sync;
    o_Pixel_Clk <= r_Pixel_Clk;
    o_Video_Enable <= '1' WHEN (r_H_Pos < c_FRAME_WIDTH AND r_V_Pos < c_FRAME_HEIGHT) ELSE '0';
END ARCHITECTURE;