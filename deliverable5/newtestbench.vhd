LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE STD.textio.all;
USE ieee.std_logic_textio.all;

entity testbench is
end testbench;

architecture behaviour of testbench is

	component ifstage is
		
		PORT(
		clock: in STD_LOGIC;
		reset: in std_logic := '0';
		insert_stall: in std_logic := '0';
		BranchAddr: in STD_LOGIC_VECTOR (31 DOWNTO 0);
		Branch_taken: in STD_LOGIC := '0';
		next_addr: out STD_LOGIC_VECTOR (31 DOWNTO 0);
		
		s_addr_inst: out std_logic_vector(31 downto 0); -- send address to cache
		s_read_inst: out std_logic; -- send read signal to cache
		inst: out std_logic_vector(31 downto 0); --  send instruction to ID
		s_waitrequest_inst: in std_logic :='0'; -- get waitrequest signal from cache
		s_readdata_inst: in std_logic_vector(31 downto 0); -- get instruction from cache
                mem_data_stall: in std_logic; 
		ismiss: in std_logic := '0'
		
		);
  	end component;
  
  	component ID is
    		generic(
			register_size : integer := 32
		);
   		port (
			clk: in  std_logic;
          		--hazard_detect: in std_logic;   -- stall the instruction when hazard_detect is 1 
          		instruction_addr: in  std_logic_vector(31 downto 0);
                bran_taken_in: in std_logic;-- from mem
          		IR_in: in  std_logic_vector(31 downto 0);
          		writeback_register_address: in  std_Logic_vector(4 downto 0);
          		writeback_register_content: in  std_logic_vector(31 downto 0);
          		ex_state_buffer: in std_logic_vector(10 downto 0);
          		instruction_addr_out: out std_logic_vector(31 downto 0);
          		jump_addr: out std_logic_vector(25 downto 0);
          		rs:  out std_logic_vector(31 downto 0);
          		rt:  out  std_logic_vector(31 downto 0);
          		--rd_addr: out std_logic_vector(4 downto 0);
          		des_addr: out std_logic_vector(4 downto 0);
          		signExtImm: out  std_logic_vector(31 downto 0);
          		insert_stall: out std_logic;
          		EX_control_buffer: out std_logic_vector(10 downto 0);
          		MEM_control_buffer: out std_logic_vector(5 downto 0);
          		WB_control_buffer: out std_logic_vector(5 downto 0);
          		funct_out: out std_logic_vector(5 downto 0);
          		opcode_out: out  std_logic_vector(5 downto 0);
          		write_reg_txt: in std_logic:='0'
		);
	end component;

	component EX is
		PORT( 
              		clk: in  std_logic;
                    
              		-- from id stage 
              		instruction_addr_in: in std_logic_vector(31 downto 0);
              		jump_addr : in std_logic_vector( 25 downto 0); -- changed from 31 dwonto 0 to 25 down to 0
              		rs:  in std_logic_vector(31 downto 0);
              		rt:  in  std_logic_vector(31 downto 0);  
              		des_addr: in std_logic_vector(4 downto 0);
              		signExtImm: in  std_logic_vector(31 downto 0);
              		EX_control_buffer: in std_logic_vector(10 downto 0); --  for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
              		MEM_control_buffer: in std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              		WB_control_buffer: in std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              		opcode_in: in  std_logic_vector(5 downto 0);
              		funct_in: in std_logic_vector(5 downto 0) ;
              
             		-- from mem stage
             		MEM_control_buffer_before: in std_logic_vector(5 downto 0); --control buffer from last instruction which is in mem stage now
                    	bran_taken_in: in std_logic;-- from mem
             		-- MEM_result: in std_logic_vector(31 downto 0); -- if last inst is load word, its data from mem
             		-- last_opcode : in std_logic_vector(5 downto 0);  -- opcode of last instruction
           
              		-- from wb stage
              		WB_control_buffer_before: in std_logic_vector(5 downto 0); --control buffer from the one before last instruction which is in wb stage now
              		writeback_data: in std_logic_vector(31 downto 0); -- data for forwarding of last last instruction
       
              		-- for mem stage 
	      		branch_addr: out std_logic_vector(31 downto 0);
              		bran_taken: out std_logic;
              		opcode_out: out std_logic_vector(5 downto 0);
              		des_addr_out: out std_logic_vector(4 downto 0);
              		ALU_result: out std_logic_vector(31 downto 0);
              		rt_data: out std_logic_vector(31 downto 0);
              		MEM_control_buffer_out: out std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              		WB_control_buffer_out: out std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
             		-- for id stage 
	      		EX_control_buffer_out: out std_logic_vector(10 downto 0) --  for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
		);
	end component;
		
  	component DataMem is
       		GENERIC(
		ram_size : INTEGER := 32768
		);
    		port(
         	clock: in std_logic;
         	opcode: in std_logic_vector(5 downto 0):=(others => '0');
         	dest_addr_in: in std_logic_vector(4 downto 0):=(others => '0');
         	ALU_result: in std_logic_vector(31 downto 0):=(others => '0');
         	rt_data: in std_logic_vector(31 downto 0):=(others => '0');
	     	bran_taken: in std_logic;  -- from mem
	     	bran_addr_in: in std_logic_vector(31 downto 0):=(others => '0');  -- new added 
	     	MEM_control_buffer: in std_logic_vector(5 downto 0):=(others => '0');
	     	WB_control_buffer : in std_logic_vector(5 downto 0):=(others => '0');
	    
	     	MEM_control_buffer_out: out std_logic_vector(5 downto 0):=(others => '0'); --for ex forward 
	     	WB_control_buffer_out : out std_logic_vector(5 downto 0):=(others => '0'); -- for wb stage 
         
	     	mem_data: out std_logic_vector(31 downto 0):=(others => '0');
         	ALU_data: out std_logic_vector(31 downto 0):=(others => '0');
         	dest_addr_out: out std_logic_vector(4 downto 0):=(others => '0');
        	bran_addr: out std_logic_vector(31 downto 0):=(others => '0'); -- for if 
	     	bran_taken_out: out std_logic:= '0';                -- for if 
	     	--write_reg_txt: in std_logic := '0'; -- indicate program ends-- from testbench
	    

                 --mem_data_stall_in: in std_logic;
                 mem_data_stall: out std_logic;

		
		s_addr_data:out std_logic_vector(31 downto 0); -- send address to cache
		s_read_data: out std_logic; -- send read signal to cache
		s_readdata_data: in std_logic_vector(31 downto 0); -- get data from cache
		s_write_data: out std_logic; -- send write signal to cache
		s_writedata_data: out std_logic_vector(31 downto 0);-- send the writedata to cache
		s_waitrequest_data: in std_logic := '0' --get waitrequest signal from cache
                 
			
         );
 end component;


     	component WB is
		PORT( 
              	clk: in  std_logic;
              	memory_data: in std_logic_vector(31 downto 0);
              	alu_result: in std_logic_vector(31 downto 0);
              	opcode : in std_logic_vector(5 downto 0);
              	writeback_addr: in std_logic_vector(4 downto 0);
	      	WB_control_buffer: in std_logic_vector(5 downto 0);
              	-- for ex stage forward
	      	WB_control_buffer_out: out std_logic_vector(5 downto 0);
	      	-- for id stage
	      	writeback_data_out: out std_logic_vector(31 downto 0);
              	writeback_addr_out: out std_logic_vector(4 downto 0)
	   	);
    	end component;

	component InstCache is
		generic(
			ram_size : INTEGER := 32768
			);
		port(
			clock : in std_logic;
			reset : in std_logic;
	
			-- Avalon interface --
			s_addr : in std_logic_vector (31 downto 0);
			s_read : in std_logic;
			s_readdata : out std_logic_vector (31 downto 0);
			--s_write : in std_logic;
			--s_writedata : in std_logic_vector (31 downto 0);
			s_waitrequest : out std_logic; 
			ismiss : out std_logic;
    
			m_addr : out integer range 0 to ram_size-1;
			m_read : out std_logic;
			m_readdata : in std_logic_vector (31 downto 0);
			m_write : out std_logic;
			m_writedata : out std_logic_vector (31 downto 0);
			m_waitrequest : in std_logic
		);
	end component;

	component DataCache is
		generic(
			ram_size : INTEGER := 32768
			);
		port(
			clock : in std_logic;
			reset : in std_logic;
	
			-- Avalon interface --
			s_addr : in std_logic_vector (31 downto 0);
			s_read : in std_logic;
			s_readdata : out std_logic_vector (31 downto 0);
			s_write : in std_logic;
			s_writedata : in std_logic_vector (31 downto 0);
			s_waitrequest : out std_logic; 
			
    		
			m_addr : out integer range 0 to ram_size-1;
			m_read : out std_logic;
			m_readdata : in std_logic_vector (31 downto 0);
			m_write : out std_logic;
			m_writedata : out std_logic_vector (31 downto 0);
			m_waitrequest : in std_logic
		);
	end component;

	component memory is
	GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;

		writedata_instcache: IN STD_LOGIC_VECTOR (31 DOWNTO 0):=(others=>'0');
		address_instcache: IN INTEGER RANGE 0 TO 4*ram_size - 4 := 0;
		memwrite_instcache: IN STD_LOGIC:= '0';
		memread_instcache: IN STD_LOGIC:= '0';
		readdata_instcache: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest_instcache: OUT STD_LOGIC;

		writedata_datacache: IN STD_LOGIC_VECTOR (31 DOWNTO 0):=(others=>'0');
		address_datacache: IN INTEGER RANGE 0 TO 4*ram_size - 4 := 0;
		memwrite_datacache: IN STD_LOGIC:= '0';
		memread_datacache: IN STD_LOGIC:= '0';
		readdata_datacache: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest_datacache: OUT STD_LOGIC;

		readfinish: in std_logic := '0';
		write_reg_txt: in std_logic := '0' -- indicate program ends-- from testbench

	);
	end component;



---------------------------------------------------------------------------------
	signal clock : std_logic;
        signal programend: std_logic := '0';
	constant clock_period: time := 1 ns;
	signal readfinish: std_logic := '0';
 	-- signal into if
        signal reset : std_logic;
	signal insert_stall : std_logic := '0';
	signal branch_addr : std_logic_vector (31 downto 0):=(others => '0');
	signal branch_taken : std_logic := '0';
	signal s_waitrequest_instcache: std_logic :='0';
	signal s_readdata_instcache : std_logic_vector(31 downto 0):=(others => '0');
	signal mem_data_stall: std_logic:= '0';
	signal ismiss: std_logic := '0'; 
	-- signal into id
        signal inst_addr : std_logic_vector (31 downto 0):=(others => '0');
        signal inst : std_logic_vector (31 downto 0):=(others => '0');
	signal writeback_register_address: std_Logic_vector(4 downto 0):= (others => '0'); 
	signal writeback_data: std_logic_vector(31 downto 0):=(others => '0');  -- also into ex, out of wb
        signal EX_control_buffer_from_ex: std_logic_vector(10 downto 0):=(others => '0');
       -- signal into ex 
	  -- from id 
        signal jump_addr: std_logic_vector (25 downto 0):=(others => '0');
        signal inst_addr_from_id : std_logic_vector (31 downto 0):=(others => '0');
        signal rs: std_logic_vector(31 downto 0):=(others => '0');
	signal rt: std_logic_vector(31 downto 0):=(others => '0');
	signal des_addr_from_id: std_logic_vector(4 downto 0):=(others => '0');
	signal funct_from_id: std_logic_vector(5 downto 0):=(others => '0');
	signal signExtImm: std_logic_vector(31 downto 0):=(others => '0');
        signal opcode_bt_IdnEx: std_logic_vector(5 downto 0):=(others => '0'); -- out of id 
        signal EX_control_buffer_from_id: std_logic_vector(10 downto 0):=(others => '0');
	signal MEM_control_buffer_from_id: std_logic_vector(5 downto 0):=(others => '0');
	signal WB_control_buffer_from_id: std_logic_vector(5 downto 0):=(others => '0');
           -- from mem and wb
        signal MEM_control_buffer_from_mem: std_logic_vector(5 downto 0):=(others => '0'); -- out of mem
	signal WB_control_buffer_from_wb: std_logic_vector(5 downto 0):=(others => '0');    -- out of wb
         -- singnal into ex end 
        -- signal into mem
        signal opcode_bt_ExnMem: std_logic_vector(5 downto 0):=(others => '0');  -- out of ex 
        signal ALU_result_from_ex: std_logic_vector(31 downto 0):=(others => '0');
        signal des_addr_from_ex: std_logic_vector(4 downto 0):=(others => '0');
        signal rt_data_from_ex: std_logic_vector(31 downto 0):=(others => '0');
        signal bran_taken_from_ex: std_logic:= '0';
        signal bran_addr_from_ex: std_logic_vector(31 downto 0):=(others => '0');
        signal MEM_control_buffer_from_ex: std_logic_vector(5 downto 0):=(others => '0');
	signal WB_control_buffer_from_ex: std_logic_vector(5 downto 0):=(others => '0');
	
	signal s_readdata_datacache:std_logic_vector(31 downto 0):=(others => '0');
	signal s_waitrequest_datacache:std_logic := '0';
         -- signal into writeback
        signal opcode_bt_MemnWb: std_logic_vector(5 downto 0):=(others => '0') ;  -- out of mem 
        signal memory_data: std_logic_vector(31 downto 0):=(others => '0');
        signal alu_result_from_mem: std_logic_vector(31 downto 0):=(others => '0');
        signal des_addr_from_mem: std_logic_vector(4 downto 0):=(others => '0'); -- writeback_addr in wb stage 
        signal WB_control_buffer_from_mem: std_logic_vector(5 downto 0):=(others => '0'); -- from 

	--signal EX_control_buffer: std_logic_vector(10 downto 0); -- not in use
	--signal MEM_control_buffer: std_logic_vector(5 downto 0);  -- not in use
	--signal WB_control_buffer: std_logic_vector(5 downto 0);     --not in use
	

	-- signal into instruction cache
	signal s_addr_instcache: std_logic_vector (31 downto 0):=(others=>'0');
	signal s_read_instcache: std_logic := '0';
	signal m_readdata_instcache: std_logic_vector (31 downto 0) :=(others =>'0');
	signal m_waitrequest_instcache: std_logic:='0';

	--signal into data cache
	signal s_addr_datacache:std_logic_vector (31 downto 0):=(others=>'0');
	signal s_read_datacache:std_logic := '0';
	signal s_write_datacache:std_logic := '0';
	signal s_writedata_datacache:std_logic_vector (31 downto 0):=(others=>'0');
	signal m_readdata_datacache:std_logic_vector (31 downto 0):=(others=>'0');
	signal m_waitrequest_datacache:std_logic := '0';

	--signal into main memory
	signal writedata_instcache:std_logic_vector (31 downto 0):=(others=>'0');
	signal address_instcache: INTEGER := 0;
	signal memwrite_instcache: std_logic := '0';
	signal memread_instcache:std_logic := '0';
	signal writedata_datacache:std_logic_vector (31 downto 0):=(others=>'0');
	signal address_datacache: INTEGER := 0;
	signal memwrite_datacache:std_logic := '0';
	signal memread_datacache:std_logic := '0';

	
	
--------------------------------------------------------------------

begin
  
fetch : ifstage
port map (
	clock => clock,
        reset => reset,
        insert_stall => insert_stall,
        BranchAddr => branch_addr,
        Branch_taken => branch_taken,
        next_addr => inst_addr,
	s_addr_inst =>  s_addr_instcache,
	s_read_inst => 	s_read_instcache,
        inst =>  inst,	
	s_waitrequest_inst => s_waitrequest_instcache,
	s_readdata_inst => s_readdata_instcache,
	mem_data_stall => mem_data_stall,
	ismiss => ismiss
);
    
decode : ID
generic map (
	register_size => 32
	) 
port map (
	clk => clock,
        bran_taken_in =>branch_taken,
        instruction_addr => inst_addr,
        IR_in => inst,
        writeback_register_address => writeback_register_address,
       	writeback_register_content => writeback_data, -- in
        ex_state_buffer => EX_control_buffer_from_ex,
	instruction_addr_out => inst_addr_from_id,
        jump_addr => jump_addr,
        rs => rs,
        rt => rt,
        des_addr => des_addr_from_id,
        signExtImm => signExtImm,
        insert_stall => insert_stall,  
        EX_control_buffer => EX_control_buffer_from_id,
        MEM_control_buffer => MEM_control_buffer_from_id,
        WB_control_buffer => WB_control_buffer_from_id,
        funct_out => funct_from_id,
        opcode_out => opcode_bt_IdnEx,
        write_reg_txt => programend
	);
	
execute: EX
port map (
	clk => clock,
    bran_taken_in =>branch_taken,
	instruction_addr_in => inst_addr_from_id,
	jump_addr => jump_addr,
	rs => rs,
	rt => rt,
	des_addr => des_addr_from_id,
	signExtImm => signExtImm,
	EX_control_buffer => EX_control_buffer_from_id,
	MEM_control_buffer => MEM_control_buffer_from_id,
	WB_control_buffer => WB_control_buffer_from_id,
	opcode_in => opcode_bt_IdnEx,
	funct_in => funct_from_id,
	MEM_control_buffer_before => MEM_control_buffer_from_mem , --in
	WB_control_buffer_before => WB_control_buffer_from_wb, --in
	writeback_data => writeback_data, --in
	branch_addr => bran_addr_from_ex, -- ?? -- added in mem (runze)
	bran_taken => bran_taken_from_ex,
	opcode_out => opcode_bt_ExnMem,
	des_addr_out => des_addr_from_ex,
	ALU_result => ALU_result_from_ex,
	rt_data => rt_data_from_ex,
	MEM_control_buffer_out => MEM_control_buffer_from_ex,		
	WB_control_buffer_out => WB_control_buffer_from_ex,				
	EX_control_buffer_out => EX_control_buffer_from_ex	
	);

mem: DataMem
port map (
        clock => clock,
        opcode => opcode_bt_ExnMem,
        dest_addr_in => des_addr_from_ex,
        ALU_result => ALU_result_from_ex,
        rt_data => rt_data_from_ex,
        bran_taken => bran_taken_from_ex,
	bran_addr_in =>  bran_addr_from_ex,
        MEM_control_buffer => MEM_control_buffer_from_ex,
        WB_control_buffer => WB_control_buffer_from_ex,
        --write_reg_txt => programend,
        MEM_control_buffer_out => MEM_control_buffer_from_mem,
        WB_control_buffer_out => WB_control_buffer_from_mem,
        mem_data => memory_data,
        ALU_data => ALU_result_from_mem,
        dest_addr_out => des_addr_from_mem,
        bran_addr => branch_addr,
        bran_taken_out => branch_taken,

	mem_data_stall => mem_data_stall,
	s_addr_data => s_addr_datacache,
	s_read_data => s_read_datacache,
	s_readdata_data => s_readdata_datacache,
	s_write_data => s_write_datacache,
	s_writedata_data => s_writedata_datacache,
	s_waitrequest_data => s_waitrequest_datacache
        );
	
writeback: WB
port map (
        clk => clock,
        memory_data => memory_data,
        alu_result => alu_result_from_mem,
        opcode => opcode_bt_MEmnWb,
        writeback_addr => des_addr_from_mem,
        WB_control_buffer => WB_control_buffer_from_mem,
        WB_control_buffer_out => WB_control_buffer_from_wb,
        writeback_addr_out => writeback_register_address,
        writeback_data_out => writeback_data
        );

inst_cache:InstCache
port map(
	clock => clock,
	reset => reset,
	s_addr => s_addr_instcache,
	s_read => s_read_instcache,
	s_readdata => s_readdata_instcache,
	s_waitrequest => s_waitrequest_instcache,
	m_addr => address_instcache,
	m_read => memread_instcache,
	m_readdata => m_readdata_instcache,
	m_write => memwrite_instcache,
	m_writedata => writedata_instcache,
	ismiss => ismiss,
	m_waitrequest => m_waitrequest_instcache
);

data_cache: DataCache
port map(
	clock => clock,
	reset => reset,
	s_addr => s_addr_datacache,
	s_read => s_read_datacache,
	s_readdata => s_readdata_datacache,
	s_write => s_write_datacache,
	s_writedata => s_writedata_datacache,
	s_waitrequest => s_waitrequest_datacache,
	m_addr => address_datacache,
	m_read => memread_datacache,
	m_readdata => m_readdata_datacache,
	m_write => memwrite_datacache,
	m_writedata => writedata_datacache,
	m_waitrequest => m_waitrequest_datacache
);
mainmemory:  memory
port map(
	clock => clock,
	writedata_instcache => writedata_instcache,
	address_instcache => address_instcache,
	memwrite_instcache => memwrite_instcache,
	memread_instcache => memread_instcache,
	readdata_instcache => m_readdata_instcache,
	waitrequest_instcache => m_waitrequest_instcache,
	writedata_datacache =>writedata_datacache,
	address_datacache => address_datacache,
	memwrite_datacache => memwrite_datacache,
	memread_datacache => memread_datacache,
	readdata_datacache => m_readdata_datacache,
	waitrequest_datacache => m_waitrequest_datacache,
	readfinish => readfinish,
	write_reg_txt => programend
);


clk_process : process
begin
	clock <= '0';
	wait for clock_period/2;
	clock <= '1';
	wait for clock_period/2;
end process;

	
test_process : process	
begin
	wait for 100* clock_period;
	programend <= '1';
	wait;

end process;

end behaviour;
