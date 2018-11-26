library ieee;
use IEEE.STD_LOGIC_1164.ALL;

entity To32bits is
    port (
        data_128bits: in STD_LOGIC_VECTOR(127 downto 0);
        which_column: in STD_LOGIC_VECTOR(2 downto 0);
        data_32bits: out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity;

architecture To32bits_arch of To32bits is

signal data_32bits_sign: STD_LOGIC_VECTOR(31 downto 0);

begin

data_32bits <= data_32bits_sign;

    process(which_column)
    begin
        case which_column is
            when "001" => data_32bits_sign <= data_128bits(127 downto 96);
            when "010" => data_32bits_sign <= data_128bits(95 downto 64);
            when "011" => data_32bits_sign <= data_128bits(63 downto 32);
            when "100" => data_32bits_sign <= data_128bits(31 downto 0);
            when others => data_32bits_sign <= (others => '0');
        end case;
    end process;
end;