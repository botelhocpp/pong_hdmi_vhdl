LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY GamepadDriver IS
PORT (
    -- Main Clock (125 MHz)
    i_Clk : IN STD_LOGIC;
    
    -- Hardware Interface
    i_Gamepad_Up : IN STD_LOGIC;
    i_Gamepad_Down : IN STD_LOGIC;
    i_Gamepad_Left_A : IN STD_LOGIC;
    i_Gamepad_Right_B : IN STD_LOGIC;
    o_Gamepad_Action_Com : OUT STD_LOGIC;
    o_Gamepad_Arrows_Com : OUT STD_LOGIC;
    
    -- Driver Interface
    o_Pressed_Up : OUT STD_LOGIC;
    o_Pressed_Down : OUT STD_LOGIC;
    o_Pressed_Left : OUT STD_LOGIC;
    o_Pressed_Right : OUT STD_LOGIC;
    o_Pressed_A : OUT STD_LOGIC;
    o_Pressed_B : OUT STD_LOGIC
);
END ENTITY;

ARCHITECTURE RTL OF GamepadDriver IS
    SIGNAL r_Pressed_Up : STD_LOGIC := '0';
    SIGNAL r_Pressed_Down : STD_LOGIC := '0';
    SIGNAL r_Pressed_Left : STD_LOGIC := '0';
    SIGNAL r_Pressed_Right : STD_LOGIC := '0';
    SIGNAL r_Pressed_A : STD_LOGIC := '0';
    SIGNAL r_Pressed_B : STD_LOGIC := '0';
    
    SIGNAL r_Sampling_Clk : STD_LOGIC := '0';
BEGIN
    o_Gamepad_Arrows_Com <= r_Sampling_Clk;
    o_Gamepad_Action_Com <= NOT r_Sampling_Clk;
    
    o_Pressed_Up <= r_Pressed_Up;
    o_Pressed_Down <= r_Pressed_Down;
    o_Pressed_Left <= r_Pressed_Left;
    o_Pressed_Right <= r_Pressed_Right;
    o_Pressed_A <= r_Pressed_A;
    o_Pressed_B <= r_Pressed_B;
    
    p_GENERATE_SAMPLING_CLK:
    PROCESS(i_Clk)
        CONSTANT c_SAMPLING_PERIOD : INTEGER := 1250000; -- for 10ms
        VARIABLE v_Sampling_Counter : INTEGER RANGE 0 TO c_SAMPLING_PERIOD/2 := 0;
    BEGIN
        IF(RISING_EDGE(i_Clk)) THEN
            IF(v_Sampling_Counter < c_SAMPLING_PERIOD/2) THEN
                v_Sampling_Counter := v_Sampling_Counter + 1;
            ELSIF(v_Sampling_Counter = c_SAMPLING_PERIOD/2) THEN
                v_Sampling_Counter := 0;
                r_Sampling_Clk <= NOT r_Sampling_Clk;
                
                r_Pressed_Up <= i_Gamepad_Up;
                r_Pressed_Down <= i_Gamepad_Down;
                r_Pressed_Left <= i_Gamepad_Left_A AND r_Sampling_Clk;
                r_Pressed_Right <= i_Gamepad_Right_B AND r_Sampling_Clk;
                r_Pressed_A <= i_Gamepad_Left_A AND NOT r_Sampling_Clk;
                r_Pressed_B <= i_Gamepad_Right_B AND NOT r_Sampling_Clk; 
            END IF; 
        END IF;
    END PROCESS p_GENERATE_SAMPLING_CLK;

END ARCHITECTURE;