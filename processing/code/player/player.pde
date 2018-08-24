import ddf.minim.*;
import processing.serial.*;
import controlP5.*;

ControlP5 cp5;
Serial port;

Minim minim;
ArrayList<AudioPlayer> players = new ArrayList();

String[] filenames = {
"basson_1.mp3",
"oboe_1.mp3",
"oboe_2.mp3",
"steinway_piano_1.mp3",
"string_1.mp3",
"string_2.mp3",
"string_3.mp3",
"string_4.mp3",
//"string_5.mp3",
//"string_6.mp3",
//"string_7.mp3",
//"string_8.mp3",
//"string_9.mp3"
};

String[] serial_ports;

void setup()
{
  size(700, 400);
  
  serial_ports = Serial.list();
  cp5 = new ControlP5(this);
  cp5.addScrollableList("dropdown")
     .setPosition(100, 100)
     .setSize(200, 100)
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(serial_ports)
     // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
     ;
    
  minim = new Minim(this);
  
  cp5.addButton("play")
     .setPosition(0,100)
     .setSize(50, 19)
     ;
     
  for (int i = 0; i < filenames.length; i++) {
    AudioPlayer player = minim.loadFile("mp3/"+filenames[i]);
    player.pause();
    players.add(player);
  }
}

public void play()
{
  println("play");
  for (int i = 0; i < players.size(); i++) {
    AudioPlayer player = players.get(i);
    player.play();
  }
}

void dropdown(int n) {
  /* request the selected item based on index n */
  String port_name = serial_ports[n];
  port = new Serial(this, port_name, 9600);
  
  CColor c = new CColor();
  c.setBackground(color(255,0,0));
  cp5.get(ScrollableList.class, "dropdown").getItem(n).put("color", c);
}

void serialEvent(Serial p)
{
  try {
    int inByte = p.read();
    println(inByte);
    // mute or unmute a player depends on the serial data.
    int flag = 0x01;
    for (int i = 0; i < 8; i++) {
      println(i + " " + binary(flag));
      AudioPlayer player = players.get(i);
      if ((flag & inByte) > 1) {
        // unmute
        if (player.isMuted() == true) {
          player.unmute();
        }
      }
      else {
        // mute
        if (player.isMuted() == false) {
          player.mute();
        }
      }
      flag = flag << 1;
    }
  }
  catch(RuntimeException e) {
    e.printStackTrace();
  }
}

void draw()
{
  background(0);
}
 
void stop()
{
  for (int i = 0; i < players.size(); i++) {
    AudioPlayer player = players.get(i);
    player.close();
  }
  
  minim.stop();
  super.stop();
}
