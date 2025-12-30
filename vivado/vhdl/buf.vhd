library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buf is
    generic (
        type T;
        DEPTH: natural
    );
    port (
        clk: in std_ulogic;
        din: in T;
        dout: out T
    );
end entity buf;

architecture rtl of buf is 
    type dbuf_t is array(natural range 0 to DEPTH - 1) of T;
    signal dbuf: dbuf_t;
begin
    process(clk) begin
        if rising_edge(clk) then           
            dbuf(dbuf'low) <= din;
        end if;
    end process;

    gen_dbufs: for i in 1 to DEPTH - 1 generate
        process(clk) begin
            if rising_edge(clk) then           
                dbuf(i) <= dbuf(i - 1);
            end if;
        end process;
    end generate;

    dout <= dbuf(dbuf'high);
end architecture rtl;

