library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync_generator_tb is
end entity vga_sync_generator_tb;

architecture tb of vga_sync_generator_tb is
    signal clk: std_ulogic := '0';
    signal resetn: std_ulogic := '0';    

    constant CYCLE_TIME: time := 39721 ps;
begin
    duv: entity work.vga_sync_generator
        generic map(
            H_SYNC_LENGTH => 96,
            H_BP_LENGTH => 48,
            H_VALID_LENGTH => 640,
            H_FP_LENGTH => 16,
            H_SYNC_POLARITY => '0',
            
            V_SYNC_LENGTH => 2,
            V_BP_LENGTH => 33,
            V_VALID_LENGTH => 480,
            V_FP_LENGTH => 10,
            V_SYNC_POLARITY => '0'            
        )
        port map (
            clk => clk,
            resetn => resetn);

    clk <= not clk after (CYCLE_TIME / 2);
    resetn <= '1' after (CYCLE_TIME * 2);
        
end architecture tb;