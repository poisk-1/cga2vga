library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity address_gen is
    generic (
        X_WIDTH : natural;
        Y_WIDTH : natural;
        VALID_START : integer;
        VALID_END : integer);
    port (
        clk : in std_logic;
        reset : in std_logic;
        x : in std_logic_vector(X_WIDTH - 1 downto 0);
        valid : out std_logic;
        y : out std_logic_vector(Y_WIDTH - 1 downto 0));
end address_gen;

architecture rtl of address_gen is
    signal x_valid : boolean;
    signal x_int : integer;
    signal y_int : integer;
begin
    x_int <= to_integer(unsigned(x));
    x_valid <= x_int >= VALID_START and x_int < VALID_END;
    y_int <= x_int - VALID_START;

    y <= std_logic_vector(to_unsigned(y_int, y'length)) when x_valid else
        (others => '0');
    valid <= '1' when x_valid else
        '0';
end rtl;