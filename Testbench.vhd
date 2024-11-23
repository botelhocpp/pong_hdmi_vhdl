LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

LIBRARY WORK;
USE WORK.HdmiPkg.ALL;
 
ENTITY Testbench IS
  PORT (
    -- Main Clock (125 MHz)
    i_Clk : IN STD_LOGIC;
 
    -- Gamepad
    i_Gamepad_Up : IN STD_LOGIC;
    i_Gamepad_Down : IN STD_LOGIC;
    i_Gamepad_Left_A : IN STD_LOGIC;
    i_Gamepad_Right_B : IN STD_LOGIC;
    o_Gamepad_Action_Com : OUT STD_LOGIC;
    o_Gamepad_Arrows_Com : OUT STD_LOGIC;
     
    -- HDMI
    o_Hdmi_Data_N : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    o_Hdmi_Data_P : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    o_Hdmi_Clk_N : OUT STD_LOGIC;
    o_Hdmi_Clk_P : OUT STD_LOGIC
    );
END ENTITY;
 
ARCHITECTURE RTL OF Testbench IS
    SIGNAL w_Clk_250_MHz : STD_LOGIC;
    
    SIGNAL w_Pressed_Up : STD_LOGIC := '0';
    SIGNAL w_Pressed_Down : STD_LOGIC := '0';
    SIGNAL w_Pressed_Left : STD_LOGIC := '0';
    SIGNAL w_Pressed_Right : STD_LOGIC := '0';
    SIGNAL w_Pressed_A : STD_LOGIC := '0';
    SIGNAL w_Pressed_B : STD_LOGIC := '0';
    SIGNAL w_Pixel_Clk : STD_LOGIC := '0';
    SIGNAL w_Video_Enable : STD_LOGIC := '0';
    SIGNAL w_H_Sync : STD_LOGIC := '0';
    SIGNAL w_V_Sync : STD_LOGIC := '0';
    SIGNAL w_H_Pos : INTEGER RANGE 0 TO c_H_MAX := 0;
    SIGNAL w_V_Pos : INTEGER RANGE 0 TO c_V_MAX := 0;
    
    SIGNAL w_Channel_R : t_Byte := (OTHERS => '0');
    SIGNAL w_Channel_G : t_Byte := (OTHERS => '0');
    SIGNAL w_Channel_B : t_Byte := (OTHERS => '0');
BEGIN
    e_CLK_DOUBLER : ENTITY WORK.ClockDoubler
    PORT MAP (
        i_Clk => i_Clk,
        reset => '0',
        o_Clk => w_Clk_250_MHz,
        o_Locked => OPEN
    );

    e_GAMEPAD_DRIVER: ENTITY WORK.GamepadDriver
    PORT MAP (
        i_Clk                => i_Clk,
        i_Gamepad_Up         => i_Gamepad_Up,
        i_Gamepad_Down       => i_Gamepad_Down,
        i_Gamepad_Left_A     => i_Gamepad_Left_A,
        i_Gamepad_Right_B    => i_Gamepad_Right_B,
        o_Gamepad_Action_Com => o_Gamepad_Action_Com,
        o_Gamepad_Arrows_Com => o_Gamepad_Arrows_Com,
        o_Pressed_Up         => w_Pressed_Up,
        o_Pressed_Down       => w_Pressed_Down,
        o_Pressed_Left       => w_Pressed_Left,
        o_Pressed_Right      => w_Pressed_Right,
        o_Pressed_A          => w_Pressed_A,
        o_Pressed_B          => w_Pressed_B
    );
    
    e_HDMI_SYNC: ENTITY WORK.HdmiSync
    PORT MAP (
        i_Clk           => w_Clk_250_MHz,
        o_Pixel_Clk     => w_Pixel_Clk,
        o_Video_Enable  => w_Video_Enable,
        o_H_Sync        => w_H_Sync,
        o_V_Sync        => w_V_Sync,
        o_H_Pos         => w_H_Pos,
        o_V_Pos         => w_V_Pos
    );
   
    e_PONG_GAME: ENTITY WORK.PongGame
    PORT MAP (
        i_Clk           => w_Pixel_Clk,
        i_Video_Enable  => w_Video_Enable,
        i_Pressed_Up    => w_Pressed_Up,
        i_Pressed_Down  => w_Pressed_Down,
        i_Pressed_Left  => w_Pressed_Left,
        i_Pressed_Right => w_Pressed_Right,
        i_Pressed_A     => w_Pressed_A,
        i_Pressed_B     => w_Pressed_B,
        i_H_Pos         => w_H_Pos,
        i_V_Pos         => w_V_Pos,
        o_Channel_R     => w_Channel_R,
        o_Channel_G     => w_Channel_G,
        o_Channel_B     => w_Channel_B
    );
    
    e_HDMI_OUT: ENTITY WORK.HdmiOut
    PORT MAP (
        i_Channel_R     => w_Channel_R,
        i_Channel_G     => w_Channel_G,
        i_Channel_B     => w_Channel_B,
        i_Clk           => w_Clk_250_MHz,
        i_Pixel_Clk     => w_Pixel_Clk,
        i_H_Sync        => w_H_Sync,
        i_V_Sync        => w_V_Sync,
        i_Video_Enable  => w_Video_Enable,
        o_Hdmi_Data_N   => o_Hdmi_Data_N,
        o_Hdmi_Data_P   => o_Hdmi_Data_P,
        o_Hdmi_Clk_N    => o_Hdmi_Clk_N,
        o_Hdmi_Clk_P    => o_Hdmi_Clk_P
    );
   
END ARCHITECTURE;