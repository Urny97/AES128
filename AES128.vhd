library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity AES128 is
  port(
    reset: in std_logic;
    clock: in std_logic;
    ce: in std_logic;
    data_in: in std_logic_vector(127 downto 0);
    key: in std_logic_vector(127 downto 0);
    data_out: out std_logic_vector(127 downto 0);
    done: out std_logic
  );
end AES128;

architecture Behavioural of AES128 is

  -- signalen om componenten aan elkaar te hangen
  signal key_out_ARK_in, ARK_out_SB_in, SB_out_shiftrow_in,
         SR_out_MC_in, MC_out_reg_in, MC_out_reg_out,
         ARK_mux_out_ARK_in, data_in_reg_out,
         final_data_out, reg_out_ARK_mux_in,
         SR_reg_out: STD_LOGIC_VECTOR(127 downto 0);

  signal rcon_contr_rcon_keys: STD_LOGIC_VECTOR(3 downto 0);
  signal contr_out_ARK_mux_sel: STD_LOGIC_VECTOR(1 downto 0);
  signal done_sign, clear_sign, hold_data_out_sign,
         contr_out_DO_mux_sel: STD_LOGIC;

  component Control_FSM is
    port(
    clock, reset, ce: in STD_LOGIC;
    roundcounter: out STD_LOGIC_VECTOR(3 downto 0);
    ARK_mux_sel: out STD_LOGIC_VECTOR(1 downto 0);
    DO_mux_sel, done, clear, hold_data_out: out STD_LOGIC
    );
  end component;

  component KeyScheduler is
    port(
      roundcounter: in STD_LOGIC_VECTOR(3 downto 0);
		  clock: in std_logic;
			reset: in std_logic;
			ce: in std_logic;
			key: in std_logic_vector(127 downto 0);
			key_out: out std_logic_vector(127 downto 0)
    );
  end component;

  component AddRoundKey is
    port(
      key_in: in std_logic_vector(127 downto 0);
      text_in: in std_logic_vector(127 downto 0);
      ARK_out: out std_logic_vector(127 downto 0)
    );
  end component;

  component SubBytes is
    port(
      SB_in: in std_logic_vector( 127 downto 0 );
      SB_out: out std_logic_vector( 127 downto 0 )
    );
  end component;

  component ShiftRow is
    port(
      shiftrow_in: in std_logic_vector(127 downto 0);
      shiftrow_out: out std_logic_vector(127 downto 0)
    );
  end component;

  component MixColumn is
    port(
      MC_in: in std_logic_vector (127 downto 0);
		  MC_out: out std_logic_vector(127 downto 0)
    );
  end component;

begin

  -- instantiaties van componenten
  KeyS: KeyScheduler port map(rcon_contr_rcon_keys, clock, reset, ce, key,
                            key_out_ARK_in);
  Ctl_FSM: Control_FSM port map(clock, reset, ce, rcon_contr_rcon_keys,
                           contr_out_ARK_mux_sel, contr_out_DO_mux_sel,
                           done_sign, clear_sign, hold_data_out_sign);
  ARK: AddRoundKey port map(key_out_ARK_in, ARK_mux_out_ARK_in, ARK_out_SB_in);
  SB: SubBytes port map(ARK_out_SB_in, SB_out_shiftrow_in);
  SR: ShiftRow port map(SB_out_shiftrow_in, SR_out_MC_in);
  MC: MixColumn port map(SR_out_MC_in, MC_out_reg_in);

  data_out <= final_data_out;
  done <= done_sign;

  -- ARK mux
  ARK_mux: process(contr_out_ARK_mux_sel, reg_out_ARK_mux_in, MC_out_reg_out, data_in_reg_out)
  begin
    case contr_out_ARK_mux_sel is
      when "00" => ARK_mux_out_ARK_in <= reg_out_ARK_mux_in;
      when "01" => ARK_mux_out_ARK_in <= MC_out_reg_out;
      when "11" => ARK_mux_out_ARK_in <= data_in_reg_out;
      when others => ARK_mux_out_ARK_in <= MC_out_reg_out;
    end case;
  end process;

  -- DataOut mux
  DO_mux: process(contr_out_DO_mux_sel, SR_reg_out)
  begin
    case contr_out_DO_mux_sel is
      when '0' => final_data_out <= (others => '0');
      when '1' => final_data_out <= SR_reg_out;
      when others => final_data_out <= (others => '0');
    end case;
  end process;

  -- ARK_reg
  ARK_reg: process(clock, reset, clear_sign, data_in,
                   MC_out_reg_in, ARK_mux_out_ARK_in)
  begin
    if reset = '1' then
      data_in_reg_out <= (others => '0');
      MC_out_reg_out <= (others => '0');
      reg_out_ARK_mux_in <= (others => '0');
    elsif rising_edge(clock) then
      if clear_sign = '1' then
        data_in_reg_out <= (others => '0');
        MC_out_reg_out <= (others => '0');
        reg_out_ARK_mux_in <= (others => '0');
      else
        data_in_reg_out <= data_in;
        MC_out_reg_out <= MC_out_reg_in;
        reg_out_ARK_mux_in <= ARK_mux_out_ARK_in;
      end if;
    end if;
  end process;

  -- SR_reg
  SR_reg: process(clock, reset, hold_data_out_sign)
  begin
    if reset = '1' then
      SR_reg_out <= (others => '0');
    elsif rising_edge(clock) then
      if hold_data_out_sign = '1' then
        SR_reg_out <= SR_out_MC_in;
      end if;
    end if;
  end process;

end Behavioural;
