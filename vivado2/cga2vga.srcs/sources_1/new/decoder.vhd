library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity decoder is
    generic (
        DEPTH : natural := 1;
        MAJORITY : natural := 1);
    port (
        clk : in std_logic;
        reset : in std_logic;
        decode : in std_logic;
        x : in std_logic;
        valid : out std_logic;
        y : out std_logic);
end decoder;

architecture rtl of decoder is
    signal x_reg : std_logic_vector(0 to DEPTH - 1);
    signal y_reg : std_logic;
    signal prev_decode_reg : std_logic;
    signal valid_reg : std_logic;

    function majority_bits(vec : std_logic_vector; majority : natural) return std_logic is
        variable count : integer := 0;
        constant len : integer := vec'length;
    begin
        for i in vec'range loop
            if vec(i) = '1' then
                count := count + 1;
            end if;
        end loop;
        if count >= majority then
            return '1';
        else
            return '0';
        end if;
    end function;

begin
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                x_reg(0) <= '0';
                y_reg <= '0';
                prev_decode_reg <= '0';
            else
                if (prev_decode_reg /= decode) then
                    y_reg <= majority_bits(x_reg, MAJORITY);
                    valid_reg <= '1';
                else
                    y_reg <= '0';
                    valid_reg <= '0';
                end if;

                prev_decode_reg <= decode;
                x_reg(0) <= x;
            end if;
        end if;
    end process;

    G0 : for I in 1 to DEPTH - 1 generate
        process (clk)
        begin
            if (rising_edge(clk)) then
                if (reset = '1') then
                    x_reg(I) <= '0';
                else
                    x_reg(I) <= x_reg(I - 1);
                end if;
            end if;
        end process;
    end generate G0;

    y <= y_reg;
    valid <= valid_reg;
end rtl;