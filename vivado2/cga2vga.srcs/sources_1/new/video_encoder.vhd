library IEEE;
library work;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_misc.all;
use ieee.numeric_std.all;
use work.util.all;

entity video_encoder is
    generic (
        PIXEL_WIDTH : natural;

        V_ADDRESS_DIV : natural;
        H_ADDRESS_DIV : natural;

        H_TOTAL_SIZE : natural;
        V_TOTAL_SIZE : natural;

        H_SYNC_SIZE : natural;
        V_SYNC_SIZE : natural;

        H_VALID_SIZE : natural;
        V_VALID_SIZE : natural;

        H_VALID_START : natural;
        V_VALID_START : natural);
    port (
        clk : in std_logic;
        reset : in std_logic;

        pixel : out std_logic_vector(PIXEL_WIDTH - 1 downto 0);

        h_sync : out std_logic;
        v_sync : out std_logic;

        address : out std_logic_vector(ceillog2((H_VALID_SIZE / H_ADDRESS_DIV) * (V_VALID_SIZE / V_ADDRESS_DIV)) - 1 downto 0);
        address_valid : out std_logic;

        data : in std_logic_vector(PIXEL_WIDTH - 1 downto 0)
    );
end video_encoder;

architecture rtl of video_encoder is
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

    component sync_gen is
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
    end component sync_gen;

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

    signal h_sync_unbuffered : std_logic;
    signal v_sync_unbuffered : std_logic;

    signal v_sync_gen_enable : std_logic;

    signal h_counter : std_logic_vector(ceillog2(H_TOTAL_SIZE) - 1 downto 0);
    signal v_counter : std_logic_vector(ceillog2(V_TOTAL_SIZE) - 1 downto 0);

    signal h_address : std_logic_vector(ceillog2(H_VALID_SIZE) - 1 downto 0);
    signal v_address : std_logic_vector(ceillog2(V_VALID_SIZE) - 1 downto 0);
    
    signal h_address_valid : std_logic;
    signal v_address_valid : std_logic;
begin
    h_sync_gen : sync_gen generic map(
        H_TOTAL_SIZE, H_SYNC_SIZE, '0') port map(
        clk => clk,
        reset => reset,
        enable => '1',
        sync => h_sync_unbuffered,
        cascade_enable => v_sync_gen_enable,
        counter => h_counter
    );

    h_sync_address_gen : address_gen generic map(
        h_counter'length, h_address'length, H_VALID_START, H_VALID_START + H_VALID_SIZE) port map(
        clk => clk,
        reset => reset,
        x => h_counter,
        valid => h_address_valid,
        y => h_address
    );

    v_sync_gen : sync_gen generic map(
        V_TOTAL_SIZE, V_SYNC_SIZE, '1') port map(
        clk => clk,
        reset => reset,
        enable => v_sync_gen_enable,
        sync => v_sync_unbuffered,
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

    address_valid <= h_address_valid and v_address_valid;
    address <= std_logic_vector(to_unsigned((to_integer(unsigned(v_address(v_address'length - 1 downto ceillog2(V_ADDRESS_DIV)))) * (H_VALID_SIZE / H_ADDRESS_DIV)) + to_integer(unsigned(h_address(h_address'length - 1 downto ceillog2(H_ADDRESS_DIV)))), address'length));

    v_sync_buffer : \buffer\ generic map(
        2) port map(
        clk => clk,
        reset => reset,
        x(0) => v_sync_unbuffered,
        y(0) => v_sync
    );

    h_sync_buffer : \buffer\ generic map(
        2) port map(
        clk => clk,
        reset => reset,
        x(0) => h_sync_unbuffered,
        y(0) => h_sync
    );

    pixel <= data;
end rtl;