library IEEE;
library work;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_misc.all;
use ieee.numeric_std.all;
use work.util.all;

entity video_decoder is
    generic (
        PIXEL_WIDTH : natural;

        INPUT_BUFFER_DEPTH : natural;
        H_SYNC_CAPTURE_DEPTH : natural;
        V_SYNC_CAPTURE_DEPTH : natural;
        PIXEL_DECODE_OFFSET : natural;

        CLOCK_MUL : natural;

        H_TOTAL_SIZE : natural;
        V_TOTAL_SIZE : natural;

        H_VALID_SIZE : natural;
        V_VALID_SIZE : natural;

        H_VALID_START : natural;
        V_VALID_START : natural);
    port (
        clk : in std_logic;
        reset : in std_logic;

        pixel : in std_logic_vector(PIXEL_WIDTH - 1 downto 0);

        h_sync : in std_logic;
        v_sync : in std_logic;

        address : out std_logic_vector(ceillog2(H_VALID_SIZE * V_VALID_SIZE) - 1 downto 0);
        address_valid : out std_logic;

        data : out std_logic_vector(PIXEL_WIDTH - 1 downto 0)
    );
end video_decoder;

architecture rtl of video_decoder is
    component \buffer\ is
        generic (
            DEPTH : natural := 1;
            WIDTH : natural := 1);
        port (
            clk : in std_logic;
            reset : in std_logic;
            x : in std_logic_vector(WIDTH - 1 downto 0);
            y : out std_logic_vector(WIDTH - 1 downto 0));
    end component \buffer\;

    component sync_cap is
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
    end component sync_cap;

    component decoder is
        generic (
            depth : natural := 1;
            MAJORITY : natural := 1);
        port (
            clk : in std_logic;
            reset : in std_logic;
            decode : in std_logic;
            x : in std_logic;
            valid : out std_logic;
            y : out std_logic);
    end component decoder;

    component address_gen is
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
    end component address_gen;

    signal buffered_pixel : std_logic_vector(PIXEL_WIDTH - 1 downto 0);
    signal decoded_valid : std_logic_vector(PIXEL_WIDTH - 1 downto 0);
    signal unbuffered_data : std_logic_vector(PIXEL_WIDTH - 1 downto 0);

    signal buffered_h_sync : std_logic;

    signal v_sync_cap_enable : std_logic;

    signal h_counter : std_logic_vector(ceillog2(H_TOTAL_SIZE * CLOCK_MUL) - 1 downto 0);

    signal h_decoded_counter : std_logic_vector(ceillog2(H_TOTAL_SIZE) - 1 downto 0);
    signal h_decoded_buffered_counter : std_logic_vector(ceillog2(H_TOTAL_SIZE) - 1 downto 0);

    signal h_address : std_logic_vector(ceillog2(H_VALID_SIZE) - 1 downto 0);
    signal h_address_valid : std_logic;

    signal buffered_v_sync : std_logic;

    signal v_counter : std_logic_vector(ceillog2(V_TOTAL_SIZE) - 1 downto 0);

    signal v_address : std_logic_vector(ceillog2(V_VALID_SIZE) - 1 downto 0);
    signal v_address_valid : std_logic;

    signal unbuffered_address_valid : std_logic;
    signal unbuffered_address : std_logic_vector(ceillog2(H_VALID_SIZE * V_VALID_SIZE) - 1 downto 0);
begin
    -- handle h_sync and decode pixel

    pixel_buffer : \buffer\ generic map(
        INPUT_BUFFER_DEPTH + 1 + H_SYNC_CAPTURE_DEPTH + PIXEL_DECODE_OFFSET, pixel'length) port map(
        clk => clk,
        reset => reset,
        x => pixel,
        y => buffered_pixel
    );

    h_sync_buffer : \buffer\ generic map(
        INPUT_BUFFER_DEPTH) port map(
        clk => clk,
        reset => reset,
        x(0) => h_sync,
        y(0) => buffered_h_sync
    );

    h_sync_cap : sync_cap generic map(
        DEPTH => H_SYNC_CAPTURE_DEPTH,
        WIDTH => h_counter'length) port map(
        clk => clk,
        reset => reset,
        sync => buffered_h_sync,
        enable => '1',
        counter => h_counter,
        cascade_enable => v_sync_cap_enable
    );

    h_decoded_counter <= h_counter(h_counter'length - 1 downto ceillog2(CLOCK_MUL));

    pixel_decoder : for I in 0 to buffered_pixel'length - 1 generate
        channel_decoder : decoder generic map(
            CLOCK_MUL, CLOCK_MUL / 2) port map(
            clk => clk,
            reset => reset,
            decode => h_decoded_counter(0),
            x => buffered_pixel(I),
            valid => decoded_valid(I),
            y => unbuffered_data(I)
        );
    end generate pixel_decoder;

    h_sync_decoded_buffer : \buffer\ generic map(
        CLOCK_MUL + 1, h_decoded_counter'length) port map(
        clk => clk,
        reset => reset,
        x => h_decoded_counter,
        y => h_decoded_buffered_counter
    );

    h_sync_address_gen : address_gen generic map(
        h_decoded_buffered_counter'length, h_address'length, H_VALID_START, H_VALID_START + H_VALID_SIZE) port map(
        clk => clk,
        reset => reset,
        x => h_decoded_buffered_counter,
        valid => h_address_valid,
        y => h_address
    );

    -- handle v_sync

    v_sync_buffer : \buffer\ generic map(
        INPUT_BUFFER_DEPTH) port map(
        clk => clk,
        reset => reset,
        x(0) => v_sync,
        y(0) => buffered_v_sync
    );

    v_sync_cap : sync_cap generic map(
        DEPTH => V_SYNC_CAPTURE_DEPTH,
        WIDTH => v_counter'length) port map(
        clk => clk,
        reset => reset,
        sync => buffered_v_sync,
        enable => v_sync_cap_enable,
        counter => v_counter
    );

    v_sync_address_gen : address_gen generic map(
        v_counter'length, v_address'length, V_VALID_START, V_VALID_START + V_VALID_SIZE) port map(
        clk => clk,
        reset => reset,
        x => v_counter,
        valid => v_address_valid,
        y => v_address
    );

    -- integrate valid and address

    unbuffered_address <= std_logic_vector(to_unsigned((to_integer(unsigned(v_address)) * H_VALID_SIZE) + to_integer(unsigned(h_address)), unbuffered_address'length));
    unbuffered_address_valid <= and_reduce(decoded_valid) and h_address_valid and v_address_valid;

    address_valid_buffer : \buffer\ generic map(
        1) port map(
        clk => clk,
        reset => reset,
        x(0) => unbuffered_address_valid,
        y(0) => address_valid
    );
    address_buffer : \buffer\ generic map(
        1, address'length) port map(
        clk => clk,
        reset => reset,
        x => unbuffered_address,
        y => address
    );
    data_buffer : \buffer\ generic map(
        1, unbuffered_data'length) port map(
        clk => clk,
        reset => reset,
        x => unbuffered_data,
        y => data
    );

end rtl;