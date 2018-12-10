library ieee;
use IEEE.STD_LOGIC_1164.ALL;

entity AddRoundKey is
  port (  key_in : in std_logic_vector(127 downto 0);
	  data_in: in std_logic_vector(31 downto 0);
    which_column: in std_logic_vector(2 downto 0);
	  ARK_out: out std_logic_vector(31 downto 0)
  );
end entity;

architecture AddRoundKey_arch of AddRoundKey is
begin
  process(key_in, data_in, which_column)
  begin
    case which_column is
      -- 1e kolom
      when "001" => ARK_out <= key_in(127 downto 96) xor data_in;
      -- 2e kolom
      when "010" => ARK_out <= key_in(95 downto 64) xor data_in;
      -- 3e kolom
      when "011" => ARK_out <= key_in(63 downto 32) xor data_in;
      -- 4e kolom
      when "100" => ARK_out <= key_in(31 downto 0) xor data_in;
      when others => ARK_out <= (others => '0');
    end case;
  end process;

end;
