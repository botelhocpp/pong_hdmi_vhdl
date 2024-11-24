LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY UNISIM;
USE UNISIM.VComponents.all;

LIBRARY WORK;
USE WORK.HdmiPkg.ALL;

ENTITY HdmiOut IS
PORT (
    i_Channel_R : IN t_Byte;
    i_Channel_G : IN t_Byte;
    i_Channel_B : IN t_Byte;
    i_Clk : IN STD_LOGIC;
    i_Pixel_Clk : IN STD_LOGIC;
    i_H_Sync : IN STD_LOGIC;
    i_V_Sync : IN STD_LOGIC;
    o_Hdmi_Data_N : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    o_Hdmi_Data_P : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    o_Hdmi_Clk_N : OUT STD_LOGIC;
    o_Hdmi_Clk_P : OUT STD_LOGIC
);
END ENTITY;

ARCHITECTURE Structural OF HdmiOut IS
    SIGNAL w_Tmds_R_Shift, w_Tmds_G_Shift, w_Tmds_B_Shift : STD_LOGIC := '0';
    SIGNAL w_Tmds_R ,w_Tmds_G, w_Tmds_B : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');

    SIGNAL r_Align_Channel_R : t_Byte := (OTHERS => '0');
    SIGNAL r_Align_Channel_G : t_Byte := (OTHERS => '0');
    SIGNAL r_Align_Channel_B : t_Byte := (OTHERS => '0');
    SIGNAL r_Channel_R : t_Byte := (OTHERS => '0');
    SIGNAL r_Channel_G : t_Byte := (OTHERS => '0');
    SIGNAL r_Channel_B : t_Byte := (OTHERS => '0');

    SIGNAL w_Video_Enable : STD_LOGIC := '0';
    SIGNAL r_H_Sync : STD_LOGIC := '0';
    SIGNAL r_V_Sync : STD_LOGIC := '0';
    SIGNAL w_H_Sync : STD_LOGIC := '0';
    SIGNAL w_V_Sync : STD_LOGIC := '0';
    SIGNAL w_H_Pos  : INTEGER RANGE 0 TO c_H_MAX;
    SIGNAL w_V_Pos  : INTEGER RANGE 0 TO c_V_MAX;
BEGIN
    e_SYNC_TO_COUNT: ENTITY work.HdmiCountSync
    PORT MAP (
        i_Clk           => i_Pixel_Clk,
        i_H_Sync        => i_H_Sync,
        i_V_Sync        => i_V_Sync,
        o_Video_Enable  => w_Video_Enable,
        o_H_Sync        => w_H_Sync,
        o_V_Sync        => w_V_Sync,
        o_H_Pos         => w_H_Pos,
        o_V_Pos         => w_V_Pos
    );

    -- Modifies the HSync and VSync signals to include Front/Back Porch
    p_SYNC_PULSES:
    PROCESS (i_Pixel_Clk) IS
    BEGIN
        IF (RISING_EDGE(i_Pixel_Clk)) THEN
            IF (
                w_H_Pos < c_H_FRONT_PORCH + c_FRAME_WIDTH OR 
                w_H_Pos > c_H_MAX - c_H_BACK_PORCH - 1
            ) THEN
                r_H_Sync <= '1';
            ELSE
                r_H_Sync <= w_H_Sync;
            END IF;

            IF (
                w_V_Pos < c_V_FRONT_PORCH + c_FRAME_HEIGHT OR
                w_V_Pos > c_V_MAX - c_V_BACK_PORCH - 1
            ) THEN
                r_V_Sync <= '1';
            ELSE
                r_V_Sync <= w_V_Sync;
            END IF;
        END IF;
    END PROCESS p_SYNC_PULSES;

    -- Align input video to modified Sync pulses. (2 Clock Cycles of Delay)
    p_VIDEO_ALIGN:
    PROCESS (i_Pixel_Clk) IS
    BEGIN
        IF RISING_EDGE(i_Pixel_Clk) THEN
            r_Channel_R <= i_Channel_R;
            r_Channel_G <= i_Channel_G;
            r_Channel_B <= i_Channel_B;

            r_Align_Channel_R <= r_Channel_R;
            r_Align_Channel_G <= r_Channel_G;
            r_Align_Channel_B <= r_Channel_B;
        END IF;
    END PROCESS p_VIDEO_ALIGN;
    
    -- TMDS Channel Encoders
    e_TMDS_ENCODER_R: ENTITY WORK.TdmsEncoder
    PORT MAP (  
        i_Data => r_Align_Channel_R,
        i_Clk => i_Pixel_Clk,
        i_Video_Enable => w_Video_Enable,
        i_Control_1 => '0',
        i_Control_0 => '0',
        o_Encoded_Data => w_Tmds_R
    );
    e_TMDS_ENCODER_G: ENTITY WORK.TdmsEncoder
    PORT MAP (  
        i_Data => r_Align_Channel_G,
        i_Clk => i_Pixel_Clk,
        i_Video_Enable => w_Video_Enable,
        i_Control_1 => '0',
        i_Control_0 => '0',
        o_Encoded_Data => w_Tmds_G
    );
    e_TMDS_ENCODER_B: ENTITY WORK.TdmsEncoder
    PORT MAP (  
        i_Data => r_Align_Channel_B,
        i_Clk => i_Pixel_Clk,
        i_Video_Enable => w_Video_Enable,
        i_Control_1 => r_V_Sync,
        i_Control_0 => r_H_Sync,
        o_Encoded_Data => w_Tmds_B
    );
    
    -- Channel Shift Registers
    e_SHIFT_REGISTER_R: ENTITY WORK.shift_register
    GENERIC MAP (g_N => 10)
    PORT MAP (
        i_Data_In => w_Tmds_R,  
        i_Clk => i_Clk,  
        i_Data_Out => w_Tmds_R_Shift   
    );
    e_SHIFT_REGISTER_G: ENTITY WORK.shift_register
    GENERIC MAP (g_N => 10)
    PORT MAP (
        i_Data_In => w_Tmds_G,  
        i_Clk => i_Clk,  
        i_Data_Out => w_Tmds_G_Shift   
    );
    e_SHIFT_REGISTER_B: ENTITY WORK.shift_register
    GENERIC MAP (g_N => 10)
    PORT MAP (
        i_Data_In => w_Tmds_B,  
        i_Clk => i_Clk,  
        i_Data_Out => w_Tmds_B_Shift   
    );
 
    -- Create Differential Pairs (TMDS)
    e_DIFF_CLK : OBUFDS
    GENERIC MAP (IOSTANDARD => "TMDS_33")
    PORT MAP (
        I => i_Pixel_Clk,
        O => o_Hdmi_Clk_P,
        OB => o_Hdmi_Clk_N
    );
    e_DIFF_R : OBUFDS
    GENERIC MAP (IOSTANDARD => "TMDS_33")
    PORT MAP (
        I => w_Tmds_R_Shift,
        O => o_Hdmi_Data_P(2),
        OB => o_Hdmi_Data_N(2)
    );
    e_DIFF_G : OBUFDS
    GENERIC MAP (IOSTANDARD => "TMDS_33")
    PORT MAP (
        I => w_Tmds_G_Shift,
        O => o_Hdmi_Data_P(1),
        OB => o_Hdmi_Data_N(1)
    );
    e_DIFF_B : OBUFDS
    GENERIC MAP (IOSTANDARD => "TMDS_33")
    PORT MAP (
        I => w_Tmds_B_Shift,
        O => o_Hdmi_Data_P(0),
        OB => o_Hdmi_Data_N(0)
    );
END ARCHITECTURE;