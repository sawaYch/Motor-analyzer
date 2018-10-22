/**
version: 4 July 2018
TO-DO:
- auto increase the limit (when raw data max/min update)                         ->ok!
- pause, stop serial communication, stop updating graph (for user see the data)  ->ok! spacebar stop; c,v,b clear data;
- serial data also output as txt for further offline analyze                     ->ok!
- fix out of range drawing                                                       ->ok!
- fix txt output format                                                          ->ok!
- auto remove space in textfield                                                 ->ok!
- show number in graph(but not exactly that data point, just position of cursor) ->ok!
**/


import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

int COM_NUM = 0;
Serial serialPort;

// interface stuff
ControlP5 cp5;

// Settings for the plotter are saved in this file
JSONObject plotterConfigJSON;
PrintWriter output_data;
String output_data_file_name = "motorData" + year() + "-" + month() + "-" + day() + "-" +
                      hour() + "_" + minute() + "_" + second();

// Define how many data points you want to plot in the graph at a time
final int enc_visible_data_range = 100;
final int velo_visible_data_range = 100;
final int pwm_visible_data_range = 100;

// plots
Graph EncoderPosGraph = new Graph(100, 70, 1440, 200, color(20, 20, 200));
float[][] EncoderPosGraphValues = new float[2][enc_visible_data_range];
float[] EncoderPosGraphSampleNumbers = new float[enc_visible_data_range];
color[] EncoderPosGraphColors = new color[2];

Graph VeloGraph = new Graph(100, 395, 1440, 200, color(20, 20, 200));
float[][] VeloGraphValues = new float[2][velo_visible_data_range];
float[] VeloGraphSampleNumbers = new float[velo_visible_data_range];
color[] VeloGraphColors = new color[2];

Graph PwmGraph = new Graph(100, 720, 1440, 200, color(20, 20, 200));
float[][] PwmGraphValues = new float[1][pwm_visible_data_range];
float[] PwmGraphSampleNumbers = new float[pwm_visible_data_range];
color[] PwmGraphColors = new color[1];

// helper for saving the executing path
String topSketchPath = "";

float encMax = 0;
float encMin = 0;
float pathposMax = 0;
float pathposMin = 0;
float unitveloMax = 0;
float unitveloMin = 0;
float pathveloMax = 0;
float pathveloMin = 0;
float pwmMax = 0;
float pwmMin = 0;
int x_label_additon = 190;
boolean stopUpdate = false;
boolean clearencBuffer = false;
boolean clearveloBuffer = false;
boolean clearpwmBuffer = false;
Textlabel kplabel;
Textlabel kilabel;
Textlabel kdlabel;
Textlabel enclabel;
Textlabel poslabel;
Textlabel unitvelo;
Textlabel pathvelo;
Textlabel currpwm;
Textlabel running_noti;
Textlabel connection_noti;
boolean first_launch = true;


// key event, spacebar to stop update
void keyPressed() {
  if (key == ' ') {
    stopUpdate = ! stopUpdate;
  } 
  if (key == 'c'){
    clearencBuffer = ! clearencBuffer;
  }
  if (key == 'v'){
    clearveloBuffer = ! clearveloBuffer;
  }
   if (key == 'b'){
    clearpwmBuffer = ! clearpwmBuffer;
  }
}


// save remaining data when program stop
void stop() {
  output_data.flush();
  output_data.close();
  super.stop();
}
 
void exit() {
  output_data.flush();
  output_data.close();
  super.exit();
}

boolean initOk = false;
String serialPortName;
void setup() {
  surface.setTitle("Motor Analyzer");
  size(1600, 985);
   // setup com
  //  if(!initOk){
  //  initOk = true;
  //  try {
  //    serialPortName = Serial.list()[COM_NUM];
  //    serialPort = new Serial(this, serialPortName, 115200);
  //  }
  //    catch (Exception e) {
  //      initOk = false;
  //  }
  //}

  // set line graph colors
  EncoderPosGraphColors[0] = color(255, 0, 0, 95);
  EncoderPosGraphColors[1] = color(0, 255, 0, 95);
  VeloGraphColors[0] = color(0, 0, 255, 95);
  VeloGraphColors[1] = color(255, 0, 255, 95);
  PwmGraphColors[0] = color(128, 128 , 255, 100);

  // settings save file
  topSketchPath = sketchPath();
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");
  
  output_data = createWriter(output_data_file_name + ".txt"); 

  // gui
  cp5 = new ControlP5(this);
  
  // init charts
  setChartSettings();
  // build x axis values for the EncoderPosGraph
  for (int i=0; i<EncoderPosGraphValues.length; i++) {
    for (int k=0; k<EncoderPosGraphValues[0].length; k++) {
      EncoderPosGraphValues[i][k] = 0;
      if (i==0)
        EncoderPosGraphSampleNumbers[k] = k;
    }
  }
  
  // build x axis values for the VeloGraph
  for (int i=0; i<VeloGraphValues.length; i++) {
    for (int k=0; k<VeloGraphValues[0].length; k++) {
      VeloGraphValues[i][k] = 0;
      if (i==0)
        VeloGraphSampleNumbers[k] = k;
    }
  }
  
  // build x axis values for the PwmGraph
  for (int i=0; i<PwmGraphValues.length; i++) {
    for (int k=0; k<PwmGraphValues[0].length; k++) {
      PwmGraphValues[i][k] = 0;
      if (i==0)
        PwmGraphSampleNumbers[k] = k;
    }
  }
  
  // build the gui
  int x = 8;
  int y = 20;
  cp5.addTextfield("EncMax").setPosition(x, y).setText(getPlotterConfigString("EncMax")).setWidth(40).setAutoClear(false).getCaptionLabel().setColor(color(0) );
  cp5.addTextfield("EncMin").setPosition(x, y=y+270).setText(getPlotterConfigString("EncMin")).setWidth(40).setAutoClear(false).getCaptionLabel().setColor(color(0) );
  cp5.addTextfield("VelMax").setPosition(x, y=y+50).setText(getPlotterConfigString("VelMax")).setWidth(40).setAutoClear(false).getCaptionLabel().setColor(color(0) );
  cp5.addTextfield("VelMin").setPosition(x, y=y+275).setText(getPlotterConfigString("VelMin")).setWidth(40).setAutoClear(false).getCaptionLabel().setColor(color(0) );
  cp5.addTextfield("PwmMax").setPosition(x, y=y+50).setText(getPlotterConfigString("PwmMax")).setWidth(40).setAutoClear(false).getCaptionLabel().setColor(color(0) );
  cp5.addTextfield("PwmMin").setPosition(x, y=y+275).setText(getPlotterConfigString("PwmMin")).setWidth(40).setAutoClear(false).getCaptionLabel().setColor(color(0) );
  cp5.addTextlabel("encodercnt_label").setText("encoder_cnt").setPosition(x_label_additon+450,300).setColor(0).setFont(createFont("Lucida Sans",12));
  cp5.addTextlabel("pathpos_label").setText("path_pos").setPosition(x_label_additon+800,300).setColor(0).setFont(createFont("Lucida Sans",12));
  cp5.addTextlabel("unitvelo_label").setText("unit_vel").setPosition(x_label_additon+20+450,300+325).setColor(0).setFont(createFont("Lucida Sans",12));
  cp5.addTextlabel("pathvelo_label").setText("path_vel").setPosition(x_label_additon+5+800,300+325).setColor(0).setFont(createFont("Lucida Sans",12));
  cp5.addTextlabel("pwm_label").setText("pwm").setPosition(x_label_additon+20+450,300+325+325).setColor(0).setFont(createFont("Lucida Sans",12));
  
  
  //pid label
  kplabel = cp5.addTextlabel("kp_label").setText("Kp: 0").setPosition(100,30).setColor(0).setFont(createFont("Lucida Sans",14));
  kilabel = cp5.addTextlabel("ki_label").setText("Ki: 0").setPosition(100,50).setColor(0).setFont(createFont("Lucida Sans",14));
  kdlabel = cp5.addTextlabel("kd_label").setText("Kd: 0").setPosition(100,70).setColor(0).setFont(createFont("Lucida Sans",14));
  enclabel = cp5.addTextlabel("enc_label").setText("Enc: 0").setPosition(100,90).setColor(0).setFont(createFont("Lucida Sans",14));
  poslabel = cp5.addTextlabel("pathpos_message_label").setText("Pos: 0").setPosition(100,110).setColor(0).setFont(createFont("Lucida Sans",14));
  unitvelo = cp5.addTextlabel("unitvelo_message_label").setText("UnitVelo: 0").setPosition(100,130).setColor(0).setFont(createFont("Lucida Sans",14));
  pathvelo = cp5.addTextlabel("pathvelo_message_label").setText("PathVelo: 0").setPosition(100,150).setColor(0).setFont(createFont("Lucida Sans",14));
  currpwm = cp5.addTextlabel("currpwm_label").setText("PWM: 0").setPosition(100,170).setColor(0).setFont(createFont("Lucida Sans",14));
  running_noti = cp5.addTextlabel("running_noti_label").setText(" ").setPosition(200,35).setColor(0).setFont(createFont("Lucida Sans",14));
  connection_noti = cp5.addTextlabel("connection_noti_label").setText(" ").setPosition(300,35).setColor(0).setFont(createFont("Lucida Sans",14));
  
  
 
}

byte[] inBuffer = new byte[100]; // holds serial message
int i = 0; // loop variable
void draw() {
    /* reinit uart if disconected */
    if (Serial.list().length == 0){
      initOk = false;    
      connection_noti.setText("Uart Not Connected").setColor(color(255,0,0));     
    }else{
      connection_noti.setText("Uart Connected").setColor(color(0,255,0));
    }
    
  
  for(int i = 0; i < inBuffer.length; ++i){
    inBuffer[i] = ' '; 
  }
  
  /* Read serial and update values */
  if (serialPort!= null && serialPort.available() > 0 ) {
    first_launch = false;
    String myString = "";
    try {
      serialPort.readBytesUntil('\r', inBuffer);
    }
    catch (Exception e) {
    }
    
    int counter = 0;
    for(int i =0; i < 100;++i){
       if (inBuffer[i] == '\r') break;
       else counter++;
    }
    if (counter == 100)return;
    
    // condition for stop update graph
    if (stopUpdate == true) {    
      running_noti.setText("Pause").setColor(color(255,100,100));
      return;
    }else{
      running_noti.setText("Running").setColor(color(0,255,0));
    }
    
    if (clearencBuffer == true) {
      for (int i=0; i<EncoderPosGraphValues.length; i++)
        for (int k=0; k<EncoderPosGraphValues[0].length; k++)
            EncoderPosGraphValues[i][k] = 0;             
      clearencBuffer = ! clearencBuffer;
    }
    if (clearveloBuffer == true) {
      for (int i=0; i<VeloGraphValues.length; i++)
        for (int k=0; k<VeloGraphValues[0].length; k++)
            VeloGraphValues[i][k] = 0;             
      clearveloBuffer = ! clearveloBuffer;
    }
    if (clearpwmBuffer == true) {
      for (int i=0; i<PwmGraphValues.length; i++)
        for (int k=0; k<PwmGraphValues[0].length; k++)
            PwmGraphValues[i][k] = 0;             
      clearpwmBuffer = ! clearpwmBuffer;
    }
    
    if (counter >= 15){
    //println(counter);
    myString = new String(inBuffer);
    myString = myString.split("\r")[0];
    println(myString);
    output_data.println(myString);

    // split the string at delimiter (space)
    String[] nums = split(myString, ' ');
    
    
    // build the arrays for bar charts and line graphs
    for (i=0; i<nums.length; i++) {
    // update max num, for auto increase graph axis value
    encMax = (float(nums[0]) > encMax)? float(nums[0]): encMax;
    encMin = (float(nums[0]) < encMin)? float(nums[0]): encMin;
    
    pathposMax = (float(nums[1]) > pathposMax)? float(nums[1]): pathposMax;
    pathposMin = (float(nums[1]) < pathposMin)? float(nums[1]): pathposMin;
    
    unitveloMax = (float(nums[2]) > unitveloMax)? float(nums[2]): unitveloMax;
    unitveloMin = (float(nums[2]) < unitveloMin)? float(nums[2]): unitveloMin;
           
    pathveloMax = (float(nums[3]) > pathveloMax)? float(nums[3]): pathveloMax;
    pathveloMin = (float(nums[3]) < pathveloMin)? float(nums[3]): pathveloMin;
    
    pwmMax = (float(nums[4]) > pwmMax)? float(nums[4]): pathveloMax;
    pwmMin = (float(nums[4]) < pwmMin)? float(nums[4]): pwmMin;
    
    if (EncoderPosGraph.yMax < encMax)
      EncoderPosGraph.yMax = encMax;
    if (EncoderPosGraph.yMin > encMin)
      EncoderPosGraph.yMin = encMin;
        
    if (EncoderPosGraph.yMax < pathposMax)
      EncoderPosGraph.yMax = pathposMax;
    if (EncoderPosGraph.yMin > pathposMin)
      EncoderPosGraph.yMin = pathposMin;
      
    if (VeloGraph.yMax < unitveloMax)
      VeloGraph.yMax = unitveloMax;
    if (VeloGraph.yMin > unitveloMin)
      VeloGraph.yMin = unitveloMin;      
            
    if (VeloGraph.yMax < pathveloMax)
      VeloGraph.yMax = pathveloMax;
    if (VeloGraph.yMin > pathveloMin)
      VeloGraph.yMin = pathveloMin;
      
    if (PwmGraph.yMax < pwmMax)
      PwmGraph.yMax = pwmMax;
    if (PwmGraph.yMin > pwmMin)
      PwmGraph.yMin = pwmMin;
      
    kplabel.setText("Kp: "+nums[5]);
    kilabel.setText("Ki: "+nums[6]);
    kdlabel.setText("Kd: "+nums[7]);
    enclabel.setText("Enc:" + nums[0]);
    poslabel.setText("Pos:" + nums[1]);
    unitvelo.setText("UnitVelo:" + nums[2]);
    pathvelo.setText("PathVelo" + nums[3]);
    currpwm.setText("PWM:" + nums[4]);
     // update line graph
      try {
        if (i<2) {
          for (int k=0; k<EncoderPosGraphValues[i].length-1; k++) {
            EncoderPosGraphValues[i][k] = EncoderPosGraphValues[i][k+1];
          }
          EncoderPosGraphValues[i][EncoderPosGraphValues[i].length-1] = float(nums[i]);
        }
      }
      catch (Exception e) {
      }
      // update line graph
      try {
        if (i>=2) {
          for (int k=0; k<VeloGraphValues[i-2].length-1; k++) {
            VeloGraphValues[i-2][k] = VeloGraphValues[i-2][k+1];
          }
          VeloGraphValues[i-2][VeloGraphValues[i-2].length-1] = float(nums[i]);
        }
      }
      catch (Exception e) {
      }
      
      // update line graph
      try {
        if (i==4) {
          for (int k=0; k<PwmGraphValues[0].length-1; k++) {
             PwmGraphValues[0][k] = PwmGraphValues[0][k+1];
          }
          PwmGraphValues[0][PwmGraphValues[0].length-1] = float(nums[i]);
        }
      }
      catch (Exception e) {
      }
    }
  }
  }

  // draw the encoder graph
  background(10); 
  EncoderPosGraph.DrawAxis();
  for (int i=0;i<EncoderPosGraphValues.length; i++) {
    EncoderPosGraph.GraphColor = EncoderPosGraphColors[i];
      EncoderPosGraph.LineGraph(EncoderPosGraphSampleNumbers, EncoderPosGraphValues[i]);     
  }
  // draw the velocity graphs
  VeloGraph.DrawAxis();
  for (int i=0;i<VeloGraphValues.length; i++) {
    VeloGraph.GraphColor = VeloGraphColors[i];
      VeloGraph.LineGraph(VeloGraphSampleNumbers, VeloGraphValues[i]);
  }
  
  // draw the pwm graphs
  PwmGraph.DrawAxis();
  for (int i=0;i<PwmGraphValues.length; i++) {
    PwmGraph.GraphColor = PwmGraphColors[i];
      PwmGraph.LineGraph(PwmGraphSampleNumbers, PwmGraphValues[i]);
  }
  
  // color label
   stroke(255);
   fill(EncoderPosGraphColors[0]); // use color to fill
   rect(x_label_additon+525,305,25,10); // draw rectangle
   
   stroke(255);
   fill(EncoderPosGraphColors[1]); // use color to fill
   rect(x_label_additon+860,305,25,10); // draw rectangle
   
   stroke(255);
   fill(VeloGraphColors[0]); // use color to fill
   rect(x_label_additon+525,305+325,25,10); // draw rectangle
   
   stroke(255);
   fill(VeloGraphColors[1]); // use color to fill
   rect(x_label_additon+860,305+325,25,10); // draw rectangle
   
   stroke(255);
   fill(PwmGraphColors[0]); // use color to fill
   rect(700,305+325+325,25,10); // draw rectangle 
   
    if(!initOk){
        initOk = true;
        try {
          serialPortName = Serial.list()[COM_NUM];
          serialPort = new Serial(this, serialPortName, 115200);
        }
          catch (Exception e) {
            initOk = false;
        }
      }
}

// called each time the chart settings are changed by the user 
void setChartSettings() {
  EncoderPosGraph.xLabel="";
  EncoderPosGraph.yLabel="Value";
  EncoderPosGraph.Title="Encoder";  
  EncoderPosGraph.xDiv=100;  
  EncoderPosGraph.xMax=0; 
  EncoderPosGraph.xMin=-100;  
  EncoderPosGraph.yMax=int(getPlotterConfigString("EncMax")); 
  EncoderPosGraph.yMin=int(getPlotterConfigString("EncMin"));
  
  
  VeloGraph.xLabel="";
  VeloGraph.yLabel="Value";
  VeloGraph.Title="Velocity";  
  VeloGraph.xDiv=100;  
  VeloGraph.xMax=0; 
  VeloGraph.xMin=-100;  
  VeloGraph.yMax=int(getPlotterConfigString("VelMax")); 
  VeloGraph.yMin=int(getPlotterConfigString("VelMin"));
  
  PwmGraph.xLabel="";
  PwmGraph.yLabel="Value";
  PwmGraph.Title="PWM";
  PwmGraph.xDiv=100;  
  PwmGraph.xMax=0; 
  PwmGraph.xMin=-100;  
  PwmGraph.yMax=int(getPlotterConfigString("PwmMax")); 
  PwmGraph.yMin=int(getPlotterConfigString("PwmMin"));
}

// handle gui actions
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Textfield.class) || theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class)) {
    String parameter = theEvent.getName();
    String value = "";
    if (theEvent.isAssignableFrom(Textfield.class))
      value = theEvent.getStringValue();
    else if (theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class))
    value = theEvent.getValue()+"";
    
    /* remove all whitespace & invisible character */
    //value = value.replaceAll("\\s+","");
    if (theEvent.isFrom("PwmMin")){
      Textfield txt = ((Textfield)cp5.getController("PwmMin"));
      txt.setValue(value);
    }else
    if (theEvent.isFrom("PwmMax")){
      Textfield txt = ((Textfield)cp5.getController("PwmMax"));
      txt.setValue(value);
    }else
    if (theEvent.isFrom("EncMin")){
      Textfield txt = ((Textfield)cp5.getController("EncMin"));
      txt.setValue(value);
    }else
     if (theEvent.isFrom("EncMax")){
      Textfield txt = ((Textfield)cp5.getController("EncMax"));
      txt.setValue(value);
    }else
     if (theEvent.isFrom("VelMin")){
      Textfield txt = ((Textfield)cp5.getController("VelMin"));
      txt.setValue(value);
    }else
     if (theEvent.isFrom("VelMax")){
      Textfield txt = ((Textfield)cp5.getController("VelMax"));
      txt.setValue(value);
    }
    
        
    plotterConfigJSON.setString(parameter, value);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
  }
  setChartSettings();
}

// get gui settings from settings file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}