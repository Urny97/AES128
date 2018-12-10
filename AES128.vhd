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
  signal key_out_ARK_in, to128bits_out_SR_in, to128bits_out_DO_mux_in,
         SR_out_to32bits_in, final_data_out, DI_reg_out: STD_LOGIC_VECTOR(127 downto 0);

  signal to32bits_out_ARK_mux_in, SB_out_to128bits_in,
         to32bits_out_MC_in, ARK_out_reg_in, MC_out_ARK_mux_in,
         ARK_mux_out_ARK_in, reg_out_SB_in: STD_LOGIC_VECTOR(31 downto 0);

  signal rcon_contr_rcon_keys: STD_LOGIC_VECTOR(3 downto 0);
  signal which_column_sign: STD_LOGIC_VECTOR(2 downto 0);
  signal contr_out_ARK_mux_sel: STD_LOGIC_VECTOR(1 downto 0);

  signal done_sign, clear_sign,
         contr_out_DO_mux_sel, read_data_in_sign, append_sign: STD_LOGIC;

  component Control_FSM is
    port(
    clock, reset, ce: in STD_LOGIC;
    roundcounter: out STD_LOGIC_VECTOR(3 downto 0);
    which_column: out STD_LOGIC_VECTOR(2 downto 0);
    ARK_mux_sel: out STD_LOGIC_VECTOR(1 downto 0);
    DO_mux_sel, done, clear,
    read_data_in, append: out STD_LOGIC
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
      key_in : in std_logic_vector(127 downto 0);
	    data_in: in std_logic_vector(31 downto 0);
      which_column: in std_logic_vector(2 downto 0);
	    ARK_out: out std_logic_vector(31 downto 0)
    );
  end component;

  component SubBytes is
    port(
      SB_in: in STD_LOGIC_VECTOR(31 downto 0);
      SB_out: out STD_LOGIC_VECTOR(31 downto 0)
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
      MC_in : in std_logic_vector (31 downto 0);
			MC_out : out std_logic_vector(31 downto 0)
    );
  end component;

  component To32bits is
    port(
      data_128bits: in STD_LOGIC_VECTOR(127 downto 0);
      which_column: in STD_LOGIC_VECTOR(2 downto 0);
      data_32bits: out STD_LOGIC_VECTOR(31 downto 0)
    );
  end component;

  component To128bits is
    port(
      clock, reset, ce, append_contr, hold: in STD_LOGIC;
      data_32bits: in STD_LOGIC_VECTOR(31 downto 0);
      data_128bits: out STD_LOGIC_VECTOR(127 downto 0)
    );
  end component;
begin

  -- instantiaties van componenten
  KeyS: KeyScheduler port map(
    roundcounter => rcon_contr_rcon_keys,
    clock => clock, 
    reset => reset, 
    ce => ce, 
    key => key,
    key_out => key_out_ARK_in
  );

  Ctl_FSM: Control_FSM port map(
    clock => clock, 
    reset=> reset, 
    ce => ce, 
    roundcounter => rcon_contr_rcon_keys,
    ARK_mux_sel => contr_out_ARK_mux_sel, 
    DO_mux_sel => contr_out_DO_mux_sel,
    done => done_sign,
    clear => clear_sign,
    read_data_in => read_data_in_sign,
    which_column => which_column_sign,
    append => append_sign
  );

  Input_to32bits: To32bits port map(
    data_128bits => DI_reg_out,
    which_column => which_column_sign,
    data_32bits => to32bits_out_ARK_mux_in
  );

  ARK: AddRoundKey port map(
    key_in => key_out_ARK_in, 
    data_in => ARK_mux_out_ARK_in, 
    ARK_out => ARK_out_reg_in,
    which_column => which_column_sign
  );

  Output_to128bits: To128bits port map(
    clock => clock,
    reset => reset,
    ce => ce,
    append_contr => append_sign,
    data_32bits => ARK_out_reg_in,
    data_128bits => to128bits_out_DO_mux_in,
    hold => done_sign
  );

  SB: SubBytes port map(
    SB_in => reg_out_SB_in, 
    SB_out => SB_out_to128bits_in
  );

  SB_to128bits: To128bits port map(
    clock => clock,
    reset => reset,
    ce => ce,
    append_contr => append_sign,
    data_32bits => SB_out_to128bits_in,
    data_128bits => to128bits_out_SR_in,
    hold => '0' -- enkel bij de output moet de waarde behouden blijven als de chip klaar is met encrypteren.
  );

  SR: ShiftRow port map(
    shiftrow_in => to128bits_out_SR_in, 
    shiftrow_out => SR_out_to32bits_in
  );

  SR_to32bits: To32bits port map(
    data_128bits => SR_out_to32bits_in,
    which_column => which_column_sign,
    data_32bits => to32bits_out_MC_in
  );

  MC: MixColumn port map(
    MC_in => to32bits_out_MC_in, 
    MC_out => MC_out_ARK_mux_in
  );

  data_out <= final_data_out;
  done <= done_sign;

  -- ARK mux
  ARK_mux: process(contr_out_ARK_mux_sel, to32bits_out_ARK_mux_in, MC_out_ARK_mux_in, to32bits_out_MC_in)
  begin
    case contr_out_ARK_mux_sel is
      when "00" => ARK_mux_out_ARK_in <= to32bits_out_ARK_mux_in;
      when "01" => ARK_mux_out_ARK_in <= MC_out_ARK_mux_in;
      when "11" => ARK_mux_out_ARK_in <= to32bits_out_MC_in;
      when others => ARK_mux_out_ARK_in <= (others => '0');
    end case;
  end process;

  -- DataOut mux
  DO_mux: process(contr_out_DO_mux_sel, to128bits_out_DO_mux_in)
  begin
    case contr_out_DO_mux_sel is
      when '0' => final_data_out <= (others => '0');
      when '1' => final_data_out <= to128bits_out_DO_mux_in;
      when others => final_data_out <= (others => '0');
    end case;
  end process;

  -- SB_reg
  SB_reg: process(clock, reset, clear_sign, ARK_out_reg_in)
  begin
    if reset = '1' then
      reg_out_SB_in <= (others => '0');
    elsif rising_edge(clock) then
      if ce = '1' then
        if clear_sign = '1' then
          reg_out_SB_in <= (others => '0');
        else
          reg_out_SB_in <= ARK_out_reg_in;
        end if;
      end if;
    end if;
  end process;

  --data_in_reg
  DI_reg: process(clock, reset, read_data_in_sign)
  begin
    if reset = '1' then
      DI_reg_out <= (others => '0');
    elsif rising_edge(clock) then
      if ce = '1' then
        if read_data_in_sign = '1' then
          DI_reg_out <= data_in;
        end if;
      end if;
    end if;
  end process;

end Behavioural;