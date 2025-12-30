library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity sync_cap is
    generic (
        DEPTH : natural := 1;
        WIDTH : natural);
    port (
        clk : in std_logic;
        reset : in std_logic;
        sync : in std_logic;
        enable : in std_logic;
        counter : out std_logic_vector(width - 1 downto 0);
        cascade_enable : out std_logic
    );
end sync_cap;

architecture rtl of sync_cap is
    constant sync_marker : std_logic_vector(0 to (DEPTH * 2) - 1) := (0 to DEPTH - 1 => '1', others => '0');
    
    signal counter_reg : std_logic_vector(WIDTH - 1 downto 0);
    signal sync_reg : std_logic_vector(0 to (DEPTH * 2) - 1);
begin
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                counter_reg <= (others => '0');
                sync_reg(0) <= '0';
            else
                if (sync_reg = sync_marker) then
                    counter_reg <= (others => '0');
                elsif (enable = '1') then
                    counter_reg <= counter_reg + "1";
                end if;
                sync_reg(0) <= sync;
            end if;
        end if;
    end process;

    G0 : for I in 1 to DEPTH * 2 - 1 generate
        process (clk)
        begin
            if (rising_edge(clk)) then
                if (reset = '1') then
                    sync_reg(I) <= '0';
                else
                    sync_reg(I) <= sync_reg(I - 1);
                end if;
            end if;
        end process;
    end generate G0;

    counter <= counter_reg;
    cascade_enable <= '1' when sync_reg = sync_marker else '0';
end rtl;