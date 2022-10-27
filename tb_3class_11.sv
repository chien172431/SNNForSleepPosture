`timescale 1ns / 1ps
// testbench for 17 class reconfigurable architecture
module tb_3class_11 ();
parameter NUM_NEURONS = 256,
          CSRAM_WIDTH = 368;

  logic         clk                     ;
  logic         rst                     ;
  logic         tick                    ;
  logic         tick2                   ;
  logic         tick3                   ;
  logic         clk_tick                ;
  logic         input_buffer_empty      ;
  logic [29:0]  packet_in               ;
  logic [7:0]   packet_out              ;
  logic         packet_out_valid        ;
  logic         ren_to_input_buffer     ;
  logic         token_controller_error  ;
  logic         scheduler_error         ;
  logic                             param_wr_neurons_done;
  logic                             param_wr_core_done;
  logic                             param_wen     ;
  logic  [$clog2(NUM_NEURONS)-1:0]  param_addr    ;
  logic  [$clog2(11)-1:0]                      num_core_write;
  logic  [CSRAM_WIDTH-1:0]          param_data_in ;
  logic  [CSRAM_WIDTH-1:0]          param_data_out;
  logic                             clr_avr;
  logic                             clr_avr_2;
  logic                             clr_avr_3;
  logic                             clr_spiked;
  logic                             clr_spiked_2;
  logic                             clr_spiked_3;

//   RANCNetworkGrid #(
//   .GRID_DIMENSION_X        (12),
//   .GRID_DIMENSION_Y        (1),
//   .OUTPUT_CORE_X_COORDINATE(11),
//   .OUTPUT_CORE_Y_COORDINATE(0),
//   .MEMORY_FILEPATH("/data5/workspace/chiennv0/SNN/mem_files_fixed/mems_11_cores/mem_des/")
//   )
// RANCNetworkGrid_inst(
//     .clk                   (clk                   ),
//     .rst                   (rst                   ),
//     .tick                  (tick                  ),
//     .input_buffer_empty    (input_buffer_empty    ),
//     .packet_in             (packet_in             ),
//     .packet_out            (packet_out            ),
//     .packet_out_valid      (packet_out_valid      ),
//     .ren_to_input_buffer   (ren_to_input_buffer   ),
//     .token_controller_error(token_controller_error),
//     .scheduler_error       (scheduler_error       )
//   );

RANCNetworkGrid_tick #(
  .GRID_DIMENSION_X        (12),
  .GRID_DIMENSION_Y        (1),
  .OUTPUT_CORE_X_COORDINATE(11),
  .OUTPUT_CORE_Y_COORDINATE(0),
  .LAYER2_CORE1            (8),
  .LAYER2_CORE2            (9),
  .MEMORY_FILEPATH("/data5/workspace/chiennv0/SNN/sim/trace/bed_posture_11_cores/mem_vector_10x1/")
  )
RANCNetworkGrid_tick_inst(
    .clk                   (clk                   ),
    .rst                   (rst                   ),
    .tick                  (tick                  ),
    .tick2                 (tick2),
    .tick3                 (tick3),
    .input_buffer_empty    (input_buffer_empty    ),
    .packet_in             (packet_in             ),
    .packet_out            (packet_out            ),
    .packet_out_valid      (packet_out_valid      ),
    .ren_to_input_buffer   (ren_to_input_buffer   ),
    .token_controller_error(token_controller_error),
    .scheduler_error       (scheduler_error       )
  );


localparam NUM_SPIKE = 800000;
logic [29:0] spike_mem [0:NUM_SPIKE-1];
logic [367:0] csram_mem [255:0];

logic [255:0] ax_spike_out;
int number_ttn [0:2];
integer cnt, cnt_file;
integer cnt_output;
integer cnt_img;
integer max_votes;
integer f;
integer out_spike_file;

always #10     clk  = ~clk ;
always #803065  clk_tick = ~clk_tick;
localparam STRING_LENGTH = 3;
localparam MAX_NUM_CORES = 999;
localparam [0:MAX_NUM_CORES*STRING_LENGTH*8] STRING_INDICES = {
    "999","998","997","996","995","994","993","992","991","990","989","988","987","986","985","984","983","982","981","980","979","978","977","976","975","974","973","972","971","970","969","968","967","966","965","964","963","962","961","960","959","958","957","956","955","954","953","952","951","950","949","948","947","946","945","944","943","942","941","940","939","938","937","936","935","934","933","932","931","930","929","928","927","926","925","924","923","922","911","920","919","918","917","916","915","914","913","912","911","910","909","908","907","906","905","904","903","902","901","900","899","898","897","896","895","894","893","892","891","890","889","888","887","886","885","884","883","882","881","880","879","878","877","876","875","874","873","872","871","870","869","868","867","866","865","864","863","862","861","860","859","858","857","856","855","854","853","852","851","850","849","848","847","846","845","844","843","842","841","840","839","838","837","836","835","834","833","832","831","830","829","828","827","826","825","824","823","822","811","820","819","818","817","816","815","814","813","812","811","810","809","808","807","806","805","804","803","802","801","800","799","798","797","796","795","794","793","792","791","790","789","788","787","786","785","784","783","782","781","780","779","778","777","776","775","774","773","772","771","770","769","768","767","766","765","764","763","762","761","760","759","758","757","756","755","754","753","752","751","750","749","748","747","746","745","744","743","742","741","740","739","738","737","736","735","734","733","732","731","730","729","728","727","726","725","724","723","722","711","720","719","718","717","716","715","714","713","712","711","710","709","708","707","706","705","704","703","702","701","700","699","698","697","696","695","694","693","692","691","690","689","688","687","686","685","684","683","682","681","680","679","678","677","676","675","674","673","672","671","670","669","668","667","666","665","664","663","662","661","660","659","658","657","656","655","654","653","652","651","650","649","648","647","646","645","644","643","642","641","640","639","638","637","636","635","634","633","632","631","630","629","628","627","626","625","624","623","622","611","620","619","618","617","616","615","614","613","612","611","610","609","608","607","606","605","604","603","602","601","600","599","598","597","596","595","594","593","592","591","590","589","588","587","586","585","584","583","582","581","580","579","578","577","576","575","574","573","572","571","570","569","568","567","566","565","564","563","562","561","560","559","558","557","556","555","554","553","552","551","550","549","548","547","546","545","544","543","542","541","540","539","538","537","536","535","534","533","532","531","530","529","528","527","526","525","524","523","522","511","520","519","518","517","516","515","514","513","512","511","510","509","508","507","506","505","504","503","502","501","500","499","498","497","496","495","494","493","492","491","490","489","488","487","486","485","484","483","482","481","480","479","478","477","476","475","474","473","472","471","470","469","468","467","466","465","464","463","462","461","460","459","458","457","456","455","454","453","452","451","450","449","448","447","446","445","444","443","442","441","440","439","438","437","436","435","434","433","432","431","430","429","428","427","426","425","424","423","422","411","420","419","418","417","416","415","414","413","412","411","410","409","408","407","406","405","404","403","402","401","400","399","398","397","396","395","394","393","392","391","390","389","388","387","386","385","384","383","382","381","380","379","378","377","376","375","374","373","372","371","370","369","368","367","366","365","364","363","362","361","360","359","358","357","356","355","354","353","352","351","350","349","348","347","346","345","344","343","342","341","340","339","338","337","336","335","334","333","332","331","330","329","328","327","326","325","324","323","322","311","320","319","318","317","316","315","314","313","312","311","310","309","308","307","306","305","304","303","302","301","300","299","298","297","296","295","294","293","292","291","290","289","288","287","286","285","284","283","282","281","280","279","278","277","276","275","274","273","272","271","270","269","268","267","266","265","264","263","262","261","260","259","258","257","256","255","254","253","252","251","250","249","248","247","246","245","244","243","242","241","240","239","238","237","236","235","234","233","232","231","230","229","228","227","226","225","224","223","222","211","220","119","118","117","116","115","114","113","112","111","110","209","208","207","206","205","204","203","202","201","200","199","198","197","196","195","194","193","192","191","190","189","188","187","186","185","184","183","182","181","180","179","178","177","176","175","174","173","172","171","170","169","168","167","166","165","164","163","162","161","160","159","158","157","156","155","154","153","152","151","150","149","148","147","146","145","144","143","142","141","140","139","138","137","136","135","134","133","132","131","130","129","128","127","126","125","124","123","122","111","120","119","118","117","116","115","114","113","112","111","110","109","108","107","106","105","104","103","102","101","100","099","098","097","096","095","094","093","092","091","090","089","088","087","086","085","084","083","082","081","080","079","078","077","076","075","074","073","072","071","070","069","068","067","066","065","064","063","062","061","060","059","058","057","056","055","054","053","052","051","050","049","048","047","046","045","044","043","042","041","040","039","038","037","036","035","034","033","032","031","030","029","028","027","026","025","024","023","022","011","020","019","018","017","016","015","014","013","012","011","010","009","008","007","006","005","004","003","002","001","000"
};


initial begin
  $readmemb("/data5/workspace/chiennv0/SNN/sim/trace/bed_posture_11_cores/input_packet_correct_output/tb_input.txt", spike_mem);
  // $readmemb("/data5/workspace/chiennv0/SNN/sim/file_spike_11/spike_trace/file_spike_in.txt", spike_mem);
  // $readmemb("/data5/workspace/chiennv0/SNN/sim/file_spike_11/file_spike.txt", spike_mem);
  f = $fopen("output.txt","w");
  out_spike_file = $fopen("/data5/workspace/chiennv0/SNN/sim/trace/bed_posture_11_cores/input_packet_correct_output/output_spike_hw.txt","w");
  for(int i = 0; i < 3; i++) begin
    number_ttn[i] = 0;
  end
  ax_spike_out = 0;
  max_votes = 0;
  cnt_img = 0;
  cnt_output = 0;
  cnt = 0;
  cnt_file = 0;
  tick = 0;
  tick2 = 0;
  input_buffer_empty = 1;
  rst = 1;
  clk = 0;
  clk_tick = 0;
  clr_avr = 0;
  clr_avr_2 = 0;
  clr_avr_3 = 0;
  clr_spiked = 0;
  clr_spiked_2 = 0;
  clr_spiked_3 = 0;
  repeat(4) @(negedge clk);
  rst = 0;
  param_wen = 0;
  num_core_write = 11;
  for (int i = 0; i < 11; i++) begin
    $readmemb({"/data5/workspace/chiennv0/SNN/mem_files_fixed/mems_11_cores/mem_des/", "csram_", STRING_INDICES[(MAX_NUM_CORES - i)*STRING_LENGTH*8-:STRING_LENGTH*8], ".mem"}, csram_mem);
    for (int i = 0; i < 256; i++) begin
      @(posedge clk);
      param_wen = 1;
      param_addr = i;
      param_data_in = csram_mem[i];
    end
  end
  @(posedge clk);
  param_wen = 0;
  
// non-reconfig
  repeat(1) begin

    input_buffer_empty = 0;
    repeat(4096) begin
      @(posedge clk) begin
        if(ren_to_input_buffer) begin
          if(spike_mem[cnt][0]==0) begin
            packet_in = spike_mem[cnt][29:0];
            cnt = cnt + 1;
          end
          else begin
            cnt = cnt + 1;
            cnt_img = cnt_img + 1;
            break;
          end
        end
      end
    end
    input_buffer_empty = 1;

    repeat(1) begin
      @(posedge clk_tick);
      tick = 1;
      @(posedge clk);
      tick = 0;
    end

    repeat(1) begin
      @(posedge clk_tick);
      tick2 = 1;
      @(posedge clk);
      tick2 = 0;
    end

    repeat(1) begin
      @(posedge clk_tick);
      tick3 = 1;
      @(posedge clk);
      tick3 = 0;
    end

    // repeat(3) begin
    //   @(posedge clk_tick);
    //   tick = 1;
    //   tick2 = 1;
    //   tick3 = 1;
    //   @(posedge clk);
    //   tick = 0;
    //   tick2 = 0;
    //   tick3 = 0;
    // end

    @(posedge clk_tick);
    $display("image %d", cnt_img);
    max_votes = number_ttn[0];
    for(int i = 1; i < 3; i++) begin
      if(max_votes<number_ttn[i])
        max_votes = number_ttn[i];
    end
    for(int i = 0; i < 3; i++) begin
      if(max_votes == number_ttn[i]) begin
        $fwrite(f,"%d\n", i);
        break;
      end
    end
    for(int i = 0; i < 3; i++) begin
      $display("%d : %d", i, number_ttn[i]);
      number_ttn[i] = 0;
    end
    $display("ax_spike_out: %b", ax_spike_out);
    for (int i = 0; i < 256; i++) begin
      $fwrite(out_spike_file,"%b ",ax_spike_out[i]);
    end
    @(posedge clk);
    clr_spiked = 1;
    clr_spiked_2 = 1;
    clr_spiked_3 = 1;
    clr_avr   = 1;
    clr_avr_2 = 1;
    clr_avr_3 = 1;
    @(posedge clk);
    clr_spiked = 0;
    clr_spiked_2 = 0;
    clr_spiked_3 = 0;
    clr_avr   = 0;
    clr_avr_2 = 0;
    clr_avr_3 = 0;
  end
  $finish;
end


initial begin
  forever begin
    @(posedge clk);
    if(packet_out_valid) begin
      ax_spike_out[packet_out] = 1;
      number_ttn[packet_out%3]++;
      cnt_output++;
      // $display("%d",packet_out);
    end
  end
end


endmodule

