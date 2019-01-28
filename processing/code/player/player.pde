import ddf.minim.*;
import processing.serial.*;
import controlP5.*;

ControlP5 cp5;
Serial port;

Minim minim;
ArrayList<AudioPlayer> players = new ArrayList();

String[] filenames = {
"poruka/1.mp3",
"poruka/2.mp3",
"poruka/3.mp3",
"poruka/4.mp3",
"poruka/5.mp3",
"poruka/6.mp3",
"poruka/7.mp3",
"poruka/8.mp3"
};

//String[] filenames = {
//"kageki/1.mp3",
//"kageki/2.mp3",
//"kageki/3.mp3",
//"kageki/4.mp3",
//"kageki/5.mp3"
//};

// String[] filenames = {
// "sample/basson_1.mp3",
// "sample/oboe_1.mp3",
// "sample/oboe_2.mp3",
// "sample/steinway_piano_1.mp3",
// "sample/string_1.mp3",
// "sample/string_2.mp3",
// "sample/string_3.mp3",
// "sample/string_4.mp3",
// //"string_5.mp3",
// //"string_6.mp3",
// //"string_7.mp3",
// //"string_8.mp3",
// //"string_9.mp3"
// };

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
  
  for (int i = 0; i < filenames.length; i++) {
    cp5.addToggle(str(i))
      .setValue(false)
      .setLabel(str(i))
      .setPosition((i * 40), 180)
      .setSize(40, 40)
      ;
  }

}

public void play()
{
  println("play");
  for (int i = 0; i < players.size(); i++) {
    AudioPlayer player = players.get(i);
    player.play();
    player.mute();
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

int debugStatus = 0x00;
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Toggle.class)) {
    int index = Integer.parseInt(theEvent.getName());
    int flag = theEvent.getValue() == 1 ? 0x01 : 0x00;
    if (flag > 0) {
       // change to 1
       debugStatus |= (0x01 << index);
    }
    else {
      // change to 0
      debugStatus &= ~(0x01 << index);
    }
    println("on: " + str(index) + " -> " + binary(debugStatus));
    updatePlayerState(debugStatus);
  }
}

void updatePlayerState(int inByte)
{
  int flag = 0x01;
  for (int i = 0; i < 8; i++) {
    boolean touched = (flag & inByte) > 0;
    flag = flag << 1;
    if (i == 1 || i == 3 || i == 5 || i == 7) {
      // skip 1, 3, 5, 7
      // still mute
      continue;
    }

    for (int j = 0; j < 2; j++) {
      AudioPlayer player = players.get(i + j);
      if (touched) {
        // unmute
        if (player.isMuted() == true) {
          println("unmute: " + str(i + j));
          player.unmute();
        }
      }
      else {
        // mute
        if (player.isMuted() == false) {
          println("mute: " + str(i + j));
          player.mute();
        }
      }
    }
  }
}

void serialEvent(Serial p)
{
  try {
    int inByte = p.read();
    println(inByte);
    // mute or unmute a player depends on the serial data.
    updatePlayerState(inByte);
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
