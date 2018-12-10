library ieee;
use IEEE.STD_LOGIC_1164.ALL;

entity To128bits is
    port(
        clock, reset, ce, append_contr: in STD_LOGIC;
        data_32bits: in STD_LOGIC_VECTOR(31 downto 0);
        data_128bits: out STD_LOGIC_VECTOR(127 downto 0)
    );
end To128bits;

architecture To128bits_arch of To128bits is

signal reg1_reg2, reg2_reg3, reg3_reg4, 
       reg4_out: STD_LOGIC_VECTOR(31 downto 0);
signal append_out: STD_LOGIC_VECTOR(127 downto 0);

begin

data_128bits <= append_out;

-- Reg 1 
Reg1: process(clock, reset)
  begin
    if reset = '1' then
      reg1_reg2 <= (others => '0');
    elsif rising_edge(clock) then
      if ce = '1' then
        reg1_reg2 <= data_32bits;
      else 
        reg1_reg2 <= reg1_reg2;
      end if;
    end if;
  end process;

-- Reg 2
Reg2: process(clock, reset)
  begin
    if reset = '1' then
      reg2_reg3 <= (others => '0');
    elsif rising_edge(clock) then
      if ce = '1' then
        reg2_reg3 <= reg1_reg2;
      else 
        reg2_reg3 <= reg2_reg3;
      end if;
    end if;
  end process;

-- Reg 3
Reg3: process(clock, reset)
  begin
    if reset = '1' then
      reg3_reg4 <= (others => '0');
    elsif rising_edge(clock) then
      if ce = '1' then
        reg3_reg4 <= reg2_reg3;
      else
        reg3_reg4 <= reg3_reg4;  
      end if;
    end if;
  end process;

-- Reg 4
Reg4: process(clock, reset)
  begin
    if reset = '1' then
      reg4_out <= (others => '0');
    elsif rising_edge(clock) then
      if ce = '1' then
        reg4_out <= reg3_reg4;
      else
        reg4_out <= reg4_out;
      end if;
    end if;
  end process;

-- Append
append: process(reg1_reg2, reg2_reg3, reg3_reg4, reg4_out, append_contr)
    begin
        if append_contr = '1' then
            append_out <= reg4_out & reg3_reg4 & reg2_reg3 & reg1_reg2;
        end if;
    end process;
end;