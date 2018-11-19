library ieee;
use IEEE.STD_LOGIC_1164.ALL;

entity To32bits is
    port (
        128bits_data: in STD_LOGIC_VECTOR(127 downto 0);
        which_column: in STD_LOGIC_VECTOR(2 downto 0);
        32bits_data: out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity;

architecture To32bits_arch of To32bits is
begin
    process(which_column)
        case which_column is
            when "001" => 32bits_data <= 128bits_data(127 downto 96);
            when "010" => 32bits_data <= 128bits_data(95 downto 64);
            when "011" => 32bits_data <= 128bits_data(63 downto 32);
            when "100" => 32bits_data <= 128bits_data(31 downto 0);
        end case;
    end process;
end;