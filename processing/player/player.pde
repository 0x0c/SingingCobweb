import ddf.minim.*;
import processing.serial.*;
import controlP5.*;
import java.util.Date;

ControlP5 cp5;
Serial port;

Minim minim;
ArrayList<AudioPlayer> players = new ArrayList();

// String[] filenames = {
// "Bolero/1.mp3",
// "Bolero/2.mp3",
// "Bolero/3.mp3",
// "Bolero/4.mp3",
// "Bolero/5.mp3",
// "Bolero/6.mp3",
// "Bolero/7.mp3",
// "Bolero/8.mp3"
// };

String[] filenames = {
"RhapsodyinBlue/1.mp3",
"RhapsodyinBlue/2.mp3",
"RhapsodyinBlue/3.mp3",
"RhapsodyinBlue/4.mp3",
"RhapsodyinBlue/5.mp3",
"RhapsodyinBlue/6.mp3",
"RhapsodyinBlue/7.mp3",
"RhapsodyinBlue/8.mp3"
};

// String[] filenames = {
// "poruka/1.mp3",
// "poruka/2.mp3",
// "poruka/3.mp3",
// "poruka/4.mp3",
// "poruka/5.mp3",
// "poruka/6.mp3",
// "poruka/7.mp3",
// "poruka/8.mp3"
// };

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

int user_interface_window_height = 350;
int user_interface_left_pane_width = 300;
int user_interface_right_pane_width = 400;
int user_interface_size = 20;
int user_interface_offset = 18;
int vertical_position = 0;
int horizontal_position = 0;

void resetInterfacePosition()
{
  vertical_position = 0;
  horizontal_position = 0;
}

void breakInterfaceVerticalPosition(int position)
{
  vertical_position += position + user_interface_offset;
  horizontal_position = 0;
}

void breakInterfaceVerticalPosition()
{
  breakInterfaceVerticalPosition(user_interface_size);
}

void updateInterfaceHorizontalPosition(int user_interface_width)
{
  horizontal_position += user_interface_width;
}

Textlabel playbackTimeLabel;
Textlabel remainingTimeLabel;
Textarea consoleTextArea;
ArrayList<Textlabel> labels = new ArrayList();
boolean[] currentState = new boolean[8];

void setup()
{
  size(700, 350);
  frame.setTitle("Singing Cobweb");
    
  minim = new Minim(this);
  for (int i = 0; i < filenames.length; i++) {
    AudioPlayer player = minim.loadFile("mp3/"+filenames[i]);
    player.pause();
    players.add(player);
    player.setGain(-80);
  }

  cp5 = new ControlP5(this);
  
  cp5.addButton("play")
    .setPosition(0, 0)
    .setSize(50, user_interface_size);
  updateInterfaceHorizontalPosition(50);

  int time_silder_width = user_interface_left_pane_width - horizontal_position;
  cp5.addSlider("time")
    .setPosition(horizontal_position, vertical_position + 15)
    .setSize(time_silder_width, 5)
    .setRange(0, 100);
  cp5.getController("time").getCaptionLabel().setVisible(false);
  cp5.getController("time").getValueLabel().setVisible(false);

  playbackTimeLabel = new Textlabel(cp5, "0:00", horizontal_position, vertical_position + 3, user_interface_size, user_interface_size);
  labels.add(playbackTimeLabel);
  updateInterfaceHorizontalPosition(user_interface_size);
  
  remainingTimeLabel = new Textlabel(cp5, "-0:00", user_interface_left_pane_width - user_interface_size * 2, vertical_position + 3, user_interface_size, user_interface_size);
  labels.add(remainingTimeLabel);

  // draw progress line
  // line(30, 20, 85, 75)
  breakInterfaceVerticalPosition();

  // cp5.addCheckBox("loop_checkbox")
  //   .setPosition(horizontal_position, vertical_position)
  //   .setSize(user_interface_size, user_interface_size)
  //   .addItem("loop", 0);
  // updateInterfaceHorizontalPosition(user_interface_size);

  // sensitivity
  // cp5.addSlider("sensitivity")
  //   .setPosition(0, vertical_position)
  //   .setSize(200, user_interface_size)
  //   .setRange(0, 7)
  //   .setNumberOfTickMarks(8);
  // updateInterfaceHorizontalPosition(200);

  // debug switch  
  Textlabel toggle_label = new Textlabel(cp5, "Override Sensor State", horizontal_position, vertical_position - 10, user_interface_size, user_interface_size);
  labels.add(toggle_label);
  for (int i = 0; i < filenames.length; i++) {
    String label = str(i);
    cp5.addToggle(label)
      .setValue(false)
      .setLabel(label)
      .setPosition(horizontal_position + 20, vertical_position + (i * user_interface_size))
      .setSize(user_interface_size, user_interface_size);
    cp5.getController(label).getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER).setPaddingX(0);
  }

  breakInterfaceVerticalPosition(user_interface_size * filenames.length);

  // serial
  serial_ports = Serial.list();
  cp5.addScrollableList("serial_port")
    .setPosition(0, vertical_position)
    .setSize(user_interface_left_pane_width, 100)
    .setBarHeight(user_interface_size)
    .setItemHeight(user_interface_size)
    .addItems(serial_ports);
    // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST

  breakInterfaceVerticalPosition();
  updateInterfaceHorizontalPosition(user_interface_left_pane_width);
  int button_height = user_interface_size + 10;
  consoleTextArea = cp5.addTextarea("console")
    .setPosition(horizontal_position, 0)
    .setSize(user_interface_right_pane_width, user_interface_window_height - button_height)
    .setFont(createFont("arial", 12))
    .setLineHeight(14)
    .setColor(color(128))
    .setColorBackground(color(255, 100))
    .setColorForeground(color(255, 100));
  cp5.addToggle("stop_console")
    .setValue(false)
    .setLabel("Stop Console")
    .setPosition(user_interface_left_pane_width, user_interface_window_height - button_height)
    .setSize(user_interface_right_pane_width, button_height);
  cp5.getController("stop_console").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER).setPaddingX(0);

  stop_console(false);
}

public void play()
{
  printConsole("play");
  for (int i = 0; i < players.size(); i++) {
    AudioPlayer player = players.get(i);
    player.loop();
    player.setGain(-80);
  }
}

void serial_port(int n)
{
  /* request the selected item based on index n */
  String port_name = serial_ports[n];
  port = new Serial(this, port_name, 9600);
  
  CColor c = new CColor();
  c.setBackground(color(255, 0, 0));
  cp5.get(ScrollableList.class, "serial_port").getItem(n).put("color", c);
}

boolean stop_console = true;
void stop_console(boolean flag)
{
  stop_console = flag;
  if (stop_console) {
    Date date = new Date();
    consoleTextArea.setText(consoleTextArea.getText() + date.toString() + "> " + "stop console" + "\n");
  }
}

void printConsole(String text)
{
  if (stop_console == false) {
    Date date = new Date();
    consoleTextArea.setText(consoleTextArea.getText() + date.toString() + "> " + text + "\n");
  }
}

int debugStatus = 0x00;
void controlEvent(ControlEvent theEvent)
{
  // Toggle
  if (theEvent.isAssignableFrom(Toggle.class)) {
    if (theEvent.getName() == "stop_console") {
      return;
    }
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

    updatePlayerState(debugStatus);
  }
}

void updatePlayerState(int inByte)
{
  for (int i = 0; i < 8; i++) {
    currentState[i] = false;
  }
  int flag = 0x01;
  for (int i = 0; i < 8; i++) {
    boolean touched = (flag & inByte) > 0;
    flag = flag << 1;
    currentState[i] = touched;

    if (i == 1 || i == 3 || i == 5 || i == 7) {
      // skip 1, 3, 5, 7
      // still mute
      continue;
    }

    int transitionDuration = 500;
    for (int j = 0; j < 2; j++) {
      AudioPlayer player = players.get(i + j);
      if (touched) {
        // unmute
        if (player.getGain() < 0) {
          printConsole("unmute: " + str(i + j));
          // player.unmute();
          player.shiftGain(-80, 10, transitionDuration);
        }
      }
      else {
        // mute
        if (player.getGain() >= 0) {
          printConsole("mute: " + str(i + j));
          // player.mute();
          player.shiftGain(10, -80, transitionDuration);
        }
      }
    }
  }
}

void serialEvent(Serial p)
{
  try {
    int receivedByte = p.read();
    String byteString = String.format("%8s", Integer.toBinaryString(receivedByte & 0xFF)).replace(' ', '0');
    printConsole(byteString);
    updatePlayerState(receivedByte);
  }
  catch(RuntimeException e) {
    e.printStackTrace();
  }
}

void drawWave()
{
  // draw wave
  resetInterfacePosition();
  breakInterfaceVerticalPosition();
  int offset = 20;
  int wave_height = user_interface_size;
  int wave_position_y = vertical_position + user_interface_size / 2;
  for (int i = 0; i < players.size(); i++) {
    AudioPlayer player = players.get(i);
    // for(int j = 0; j < player.bufferSize() - 1; j++) {
    for(int j = 0; j < user_interface_left_pane_width - 1 - offset; j++) {
      stroke(65, 105, 225);
      line(j + offset, wave_position_y + player.left.get(j) * wave_height + (wave_height * i), j + 1 + offset, wave_position_y + player.left.get(j + 1) * wave_height + (wave_height * i));
      stroke(255, 69, 0);
      line(j + offset, wave_position_y + player.right.get(j) * wave_height + (wave_height * i), j + 1 + offset, wave_position_y + player.right.get(j + 1) * wave_height + (wave_height * i));
    }
  }
}

boolean isTouching(int index)
{
  if (index > 8) {
    return false;
  }
  return currentState[index];
}

void drawSensorState()
{
  // ellipse
  for (int i = 0; i < filenames.length; i++) {
    Toggle toggle = (Toggle)cp5.getController(str(i));
    if (toggle.getBooleanValue() == true || isTouching(i)) {
      float[] position = toggle.getPosition();
      noStroke();
      fill(255, 0, 0);
      ellipse(user_interface_size / 2, position[1] + user_interface_size / 2, user_interface_size / 2, user_interface_size / 2);
    }
  }
}

void updatePlaybackTime()
{
  AudioPlayer player = players.get(0);
  float position = (float)player.position() / (float)player.length();
  cp5.getController("time").setValue(position * 100);

  int playbackTime = player.position() / 1000;
  String playbackMin = String.format("%02d", playbackTime / 60);
  String playbackSec = String.format("%02d", playbackTime % 60);
  playbackTimeLabel.setText(playbackMin + ":" + playbackSec);

  int remainingTime = (player.length() - player.position()) / 1000;
  String remainingMin = String.format("%02d", remainingTime / 60);
  String remainingSec = String.format("%02d", remainingTime % 60);
  remainingTimeLabel.setText("-" + remainingMin + ":" + remainingSec);
}

void draw()
{
  background(0);
  for (int i = 0; i < labels.size(); i++) {
    Textlabel label = labels.get(i);
    label.draw(this);
  }
  updatePlaybackTime();
  drawWave();
  drawSensorState();
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
