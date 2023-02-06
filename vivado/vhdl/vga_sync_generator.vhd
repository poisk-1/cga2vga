library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync_generator is
    port (
        clk   : in std_ulogic;
        resetn : in std_ulogic
    );
end entity vga_sync_generator;

architecture rtl of vga_sync_generator is
    signal cascade_enable: std_ulogic;
begin
    h_sync_generator: entity work.sync_generator port map (
        clk => clk,
        resetn => resetn,
        cascade_enable => cascade_enable,
        enable => '1');
    
    v_sync_generator: entity work.sync_generator port map (
        clk => clk,
        resetn => resetn,
        enable => cascade_enable);
    
end architecture;