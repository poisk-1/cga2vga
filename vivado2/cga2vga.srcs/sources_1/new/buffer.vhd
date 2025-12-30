library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity \buffer\ is
    generic (
        DEPTH : natural := 1;
        WIDTH : natural := 1);
    port (
        clk : in std_logic;
        reset : in std_logic;
        x : in std_logic_vector(WIDTH - 1 downto 0);
        y : out std_logic_vector(WIDTH - 1 downto 0));
end \buffer\;

architecture rtl of \buffer\ is
    type x_reg_type is array (0 to DEPTH - 1) of std_logic_vector(WIDTH - 1 downto 0);
    signal x_reg : x_reg_type;
begin
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                x_reg(0) <= (others => '0');
            else
                x_reg(0) <= x;
            end if;
        end if;
    end process;

    G0 : for I in 1 to DEPTH - 1 generate
        process (clk)
        begin
            if (rising_edge(clk)) then
                if (reset = '1') then
                    x_reg(I) <= (others => '0');
                else
                    x_reg(I) <= x_reg(I - 1);
                end if;
            end if;
        end process;
    end generate G0;

    y <= x_reg(DEPTH - 1);

end rtl;