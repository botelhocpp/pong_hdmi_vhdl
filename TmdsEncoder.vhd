LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

LIBRARY WORK;
USE WORK.HdmiPkg.ALL;

ENTITY TdmsEncoder IS
PORT(  
    i_Data : IN t_Byte;
	i_Clk : IN STD_LOGIC;
    i_Video_Enable : IN STD_LOGIC; 
    i_Control_1 : IN STD_LOGIC := '0';
	i_Control_0 : IN STD_LOGIC := '0';
    o_Encoded_Data : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
);
END ENTITY;

ARCHITECTURE RTL OF TdmsEncoder IS
    -- Wires
    SIGNAL w_Control : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL w_Intermediary_Data : STD_LOGIC_VECTOR(8 DOWNTO 0) := (OTHERS => '0'); 
    SIGNAL w_Number_Ones_Data : INTEGER RANGE 0 TO 8 := 0; 
    SIGNAL w_Number_Ones_Intermediary_Data : INTEGER RANGE 0 TO 8 := 0;
    SIGNAL w_Diff_Ones_Zeros : INTEGER RANGE -8 TO 8 := 0; 
BEGIN
    -- Count the ones in the input byte
    p_COUNT_DATA_ONES:
    PROCESS(i_Data)
        VARIABLE v_Number_Ones : INTEGER RANGE 0 TO i_Data'LENGTH := 0;
    BEGIN
        v_Number_Ones := 0;
        FOR i IN i_Data'RANGE LOOP
            IF(i_Data(i) = '1') THEN
                v_Number_Ones := v_Number_Ones + 1;
            END IF;
        END LOOP;
        w_Number_Ones_Data <= v_Number_Ones;
    END PROCESS p_COUNT_DATA_ONES;

    -- Process intermediary data to minimize transitions
    p_XOR_XNOR_ENCODING:
    PROCESS(i_Data, w_Intermediary_Data, w_Number_Ones_Data)
    BEGIN
        IF(w_Number_Ones_Data > 4 OR (w_Number_Ones_Data = 4 AND i_Data(0) = '0')) THEN
            w_Intermediary_Data(0) <= i_Data(0);
            w_Intermediary_Data(1) <= w_Intermediary_Data(0) XNOR i_Data(1);
            w_Intermediary_Data(2) <= w_Intermediary_Data(1) XNOR i_Data(2);
            w_Intermediary_Data(3) <= w_Intermediary_Data(2) XNOR i_Data(3);
            w_Intermediary_Data(4) <= w_Intermediary_Data(3) XNOR i_Data(4);
            w_Intermediary_Data(5) <= w_Intermediary_Data(4) XNOR i_Data(5);
            w_Intermediary_Data(6) <= w_Intermediary_Data(5) XNOR i_Data(6);
            w_Intermediary_Data(7) <= w_Intermediary_Data(6) XNOR i_Data(7);
            w_Intermediary_Data(8) <= '0';
        ELSE
            w_Intermediary_Data(0) <= i_Data(0);
            w_Intermediary_Data(1) <= w_Intermediary_Data(0) XOR i_Data(1);
            w_Intermediary_Data(2) <= w_Intermediary_Data(1) XOR i_Data(2);
            w_Intermediary_Data(3) <= w_Intermediary_Data(2) XOR i_Data(3);
            w_Intermediary_Data(4) <= w_Intermediary_Data(3) XOR i_Data(4);
            w_Intermediary_Data(5) <= w_Intermediary_Data(4) XOR i_Data(5);
            w_Intermediary_Data(6) <= w_Intermediary_Data(5) XOR i_Data(6);
            w_Intermediary_Data(7) <= w_Intermediary_Data(6) XOR i_Data(7);
            w_Intermediary_Data(8) <= '1';
        END IF;
    END PROCESS p_XOR_XNOR_ENCODING;
  
    -- Count the ones in the intermediary data
    p_COUNT_INTERMEDIARY_DATA_ONES:
    PROCESS(w_Intermediary_Data)
        VARIABLE v_Number_Ones : INTEGER RANGE 0 TO i_Data'LENGTH := 0;
    BEGIN
        v_Number_Ones := 0;
        FOR i IN i_Data'RANGE LOOP
            IF(w_Intermediary_Data(i) = '1') THEN
                v_Number_Ones := v_Number_Ones + 1;
            END IF;
        END LOOP;
        w_Number_Ones_Intermediary_Data <= v_Number_Ones;
        w_Diff_Ones_Zeros <= v_Number_Ones + v_Number_Ones - i_Data'LENGTH;
    END PROCESS p_COUNT_INTERMEDIARY_DATA_ONES;
  
    -- Determine output and new disparity
    p_DETERMINE_DISPARITY:
    PROCESS(i_Clk)
	   VARIABLE v_Disparity : INTEGER RANGE -16 TO 15 := 0;
    BEGIN
        IF(RISING_EDGE(i_Clk)) THEN
            -- Send Data
            IF(i_Video_Enable = '1') THEN  
                IF(v_Disparity = 0 OR w_Number_Ones_Intermediary_Data = 4) THEN
                    IF(w_Intermediary_Data(8) = '0') THEN
                        o_Encoded_Data <= NOT w_Intermediary_Data(8) & w_Intermediary_Data(8) & NOT w_Intermediary_Data(7 DOWNTO 0);
                        v_Disparity := v_Disparity - w_Diff_Ones_Zeros;
                    ELSE
                        o_Encoded_Data <= NOT w_Intermediary_Data(8)& w_Intermediary_Data(8 DOWNTO 0);
                        v_Disparity := v_Disparity + w_Diff_Ones_Zeros;
                    END IF;
                ELSE
                    IF((v_Disparity > 0 AND w_Number_Ones_Intermediary_Data > 4) OR (v_Disparity < 0 AND w_Number_Ones_Intermediary_Data < 4)) THEN
                        o_Encoded_Data <= '1' & w_Intermediary_Data(8) & NOT w_Intermediary_Data(7 DOWNTO 0);
                        IF(w_Intermediary_Data(8) = '0') THEN
                            v_Disparity := v_Disparity - w_Diff_Ones_Zeros;
                        ELSE
                            v_Disparity := v_Disparity - w_Diff_Ones_Zeros + 2;
                        END IF;
                    ELSE
                        o_Encoded_Data <= '0' & w_Intermediary_Data(8 DOWNTO 0);
                        IF(w_Intermediary_Data(8) = '0') THEN
                            v_Disparity := v_Disparity + w_Diff_Ones_Zeros - 2;
                        ELSE
                            v_Disparity := v_Disparity + w_Diff_Ones_Zeros;
                        END IF;
                    END IF;
                END IF;
                
            -- Send Control
            ELSE
                CASE w_Control IS
                    WHEN "00" => o_Encoded_Data <= "1101010100";
                    WHEN "01" => o_Encoded_Data <= "0010101011";
                    WHEN "10" => o_Encoded_Data <= "0101010100";
                    WHEN "11" => o_Encoded_Data <= "1010101011";
                    WHEN OTHERS => NULL;
                END CASE;
                v_Disparity := 0;
            END IF;
        END IF;
  END PROCESS p_DETERMINE_DISPARITY;
  
  w_Control <= i_Control_1 & i_Control_0;
END ARCHITECTURE;