library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync_generator_tb is
end entity vga_sync_generator_tb;

architecture tb of vga_sync_generator_tb is
    signal clk: std_ulogic := '0';
    signal resetn: std_ulogic := '0';
begin
    duv: entity work.vga_sync_generator port map (
        clk => clk,
        resetn => resetn);

    clk <= not clk after 5 ns;
    resetn <= '1' after 20 ns;
    
end architecture tb;