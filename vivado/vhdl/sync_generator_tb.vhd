library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_generator_tb is
end entity sync_generator_tb;

architecture tb of sync_generator_tb is
    signal clk: std_ulogic := '0';
    signal resetn: std_ulogic := '0';
    signal sync: std_ulogic;
    signal sync_prev: std_ulogic;
begin
    duv: entity work.sync_generator port map (
            clk => clk,
            resetn => resetn,
            enable => '1',
            sync => sync);

    clk <= not clk after 5 ns;
    resetn <= '1' after 20 ns;
    sync_prev <= sync;

    process begin
        wait on sync;

        if sync = '1' then
            assert sync_prev'stable(40 ns)
            report "bad sync"
            severity failure;
        elsif sync = '0' then
            assert sync_prev'stable(140 ns)
            report "bad sync"
            severity failure;
        end if;
    end process;

end architecture tb;