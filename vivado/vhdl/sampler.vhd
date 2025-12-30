library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sampler is
    generic (
        SAMPLE_BITS: natural;
        SAMPLE_DIVISOR: natural;
        SAMPLE_THRESHOLD: natural;
        ADDRESS_RANGE: natural
    );
    port (
        clk: in std_ulogic;
        resetn: in std_ulogic;
        address: in integer range 0 to ADDRESS_RANGE - 1;
        data: in std_logic_vector(SAMPLE_BITS - 1 downto 0);
        valid: out std_ulogic;
        sample_address: out integer range 0 to (ADDRESS_RANGE / SAMPLE_DIVISOR) - 1;
        sample_data: out std_logic_vector(SAMPLE_BITS - 1 downto 0)
    );
end entity sampler;

architecture rtl of sampler is
    subtype counter_t is integer range 0 to SAMPLE_DIVISOR - 1;
    type sample_counter_t is array(natural range 0 to SAMPLE_BITS - 1) of counter_t;
    
    signal data_as_counter: sample_counter_t;
    signal sample_counter: sample_counter_t;
    signal sample_pos: counter_t;
begin
    sample_pos <= address mod SAMPLE_DIVISOR;

    gen_bit_samplers: for i in 0 to SAMPLE_BITS - 1 generate
        data_as_counter(i) <= 1 when data(i) = '1' else 0;

        process(clk) begin
            if rising_edge(clk) then            
                if resetn = '0' then
                    sample_counter(i) <= 0;
                else                
                    if sample_pos = 0 then
                        sample_counter(i) <= data_as_counter(i);
                    elsif sample_pos /= SAMPLE_DIVISOR - 1 then
                        sample_counter(i) <= sample_counter(i) + data_as_counter(i);
                    end if;
                end if;
            end if;
        end process;
        

        sample_data(i) <= '1' when (sample_counter(i) + data_as_counter(i)) >= SAMPLE_THRESHOLD else '0';
    end generate;

    valid <= '1' when sample_pos = SAMPLE_DIVISOR - 1 else '0';
end architecture rtl;

