-- This module will take incoming horizontal and vertical sync pulses and
-- create Row and Column counters based on these syncs.
-- It will align the Row/Col counters to the output Sync pulses.
-- Useful for any module that needs to keep track of which Row/Col position we
-- are on in the middle of a frame.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.HdmiPkg.ALL;

ENTITY HdmiCountSync IS
PORT (
    i_Clk           : IN STD_LOGIC;
    i_H_Sync        : IN STD_LOGIC;
    i_V_Sync        : IN STD_LOGIC;
    o_Video_Enable  : OUT STD_LOGIC;
    o_H_Sync        : OUT STD_LOGIC;
    o_V_Sync        : OUT STD_LOGIC;
    o_H_Pos         : OUT INTEGER RANGE 0 TO c_H_MAX;
    o_V_Pos         : OUT INTEGER RANGE 0 TO c_V_MAX
);
END ENTITY;

ARCHITECTURE RTL OF HdmiCountSync IS
    -- Wires
    SIGNAL w_Frame_Start : STD_LOGIC := '0';
  
    -- Registers
    SIGNAL r_V_Sync  : STD_LOGIC := '0';
    SIGNAL r_H_Sync  : STD_LOGIC := '0';
    SIGNAL r_H_Pos  : INTEGER RANGE 0 TO c_H_MAX := 0;
    SIGNAL r_V_Pos  : INTEGER RANGE 0 TO c_V_MAX := 0;
BEGIN
    -- Register syncs to align with output data.
    p_SYNC_PULSES:
    PROCESS (i_Clk) IS
    BEGIN
        IF (RISING_EDGE(i_Clk)) THEN
            r_V_Sync <= i_V_Sync;
            r_H_Sync <= i_H_Sync;
        END IF;
    END PROCESS p_SYNC_PULSES; 

    -- Keep track of Row/Column counters.
    p_COUNT_POSITIONS:
    PROCESS (i_Clk) IS
    BEGIN
        IF (RISING_EDGE(i_Clk)) THEN
            IF (w_Frame_Start = '1') THEN
                r_H_Pos <= 0;
                r_V_Pos <= 0;
            ELSE
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
        END IF;
    END PROCESS p_COUNT_POSITIONS;

    o_V_Sync <= r_V_Sync;
    o_H_Sync <= r_H_Sync;
    o_V_Pos <= r_V_Pos;
    o_H_Pos <= r_H_Pos;
    o_Video_Enable <= '1' WHEN (r_H_Pos < c_FRAME_WIDTH AND r_V_Pos < c_FRAME_HEIGHT) ELSE '0';
  
    w_Frame_Start <= '1' WHEN (r_V_Sync = '0' AND i_V_Sync = '1') ELSE '0';
END ARCHITECTURE;
