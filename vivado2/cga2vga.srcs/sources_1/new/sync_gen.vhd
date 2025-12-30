library IEEE;
library work;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;
use work.util.all;

entity sync_gen is
    generic (
        TOTAL_SIZE : natural;
        SYNC_SIZE : natural;
        SYNC_POL : std_logic := '0');
    port (
        clk : in std_logic;
        reset : in std_logic;
        enable : in std_logic;
        counter : out std_logic_vector(ceillog2(TOTAL_SIZE) - 1 downto 0);
        sync : out std_logic;
        cascade_enable : out std_logic
    );
end sync_gen;

architecture rtl of sync_gen is
    signal counter_reg : std_logic_vector(ceillog2(TOTAL_SIZE) - 1 downto 0);
    signal counter_int : integer;
    signal address_int : integer;
begin
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                counter_reg <= (others => '0');
            else
                if (enable = '1') then
                    if (counter_reg = TOTAL_SIZE - 1) then
                        counter_reg <= (others => '0');
                    else
                        counter_reg <= counter_reg + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    counter_int <= to_integer(unsigned(counter_reg));

    sync <= SYNC_POL when counter_int < SYNC_SIZE else
        not SYNC_POL;
    cascade_enable <= '1' when counter_int = TOTAL_SIZE - 1 else
        '0';

    counter <= counter_reg;
end rtl;