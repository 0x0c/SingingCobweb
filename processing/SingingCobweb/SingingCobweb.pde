import ddf.minim.*;
import processing.serial.*;
import controlP5.*;
import java.util.Date;

ControlP5 cp5;
Serial port;

boolean export_mode = false;

String macOSPath(String filename)
{
  if (export_mode) {
    return sketchPath("SingingCobweb.app/Contents/Resources/" + filename);
  }
  return filename;
}

final String serialConfigFile = macOSPath("serialconfig.txt");
int number_of_tracks = 8;

public class Track
{
  String filename;
  AudioPlayer player;
  public Track(String filename, Minim minim) {
    this.player = minim.loadFile(filename);
  }

  public void seek(float position) {
    pause();
    player.cue((int)(position * length()));
    play();
  }

  public boolean isPlaying() {
    return player.isPlaying();
  }

  public void play() {
    player.play();
  }

  public void pause() {
    player.pause();
  }

  public void stop() {
    pause();
    player.rewind();
  }

  public void setGain(int gain) {
    player.setGain(gain);
  }

  public int length() {
    return player.length();
  }

  public int position() {
    return player.position();
  }

  public boolean isMute() {
    return player.getGain() >= 0 ? false : true;
  }

  public void shiftGain(float from, float to, int duration) {
    player.shiftGain(from, to, duration);
  }

  public void mute() {
    if (isMute() == false) {
      shiftGain(player.getGain(), -80, 800);
    }
  }

  public void unmute() {
    if (isMute() == true) {
      shiftGain(player.getGain(), 0, 400);
    }
  }
}

public class Composition
{
  Track representative_track;
  Track[] tracks;
  int length = 0;

  public Composition(Track[] tracks) {
    this.tracks = tracks;
    for (int i = 0; i < tracks.length; i++) {
      Track t = tracks[i];
      if (length < t.length()) {
        representative_track = t;
        length = t.length();
      }
    }
  }


  public void seek(float position) {
    for (int i = 0; i < tracks.length; i++) {
      Track t = tracks[i];
      t.seek(position);
    }
  }

  public boolean isPlaying() {
    return representative_track.isPlaying();
  }

  public void play() {
    for (int i = 0; i < tracks.length; i++) {
      Track t = tracks[i];
      t.play();
    }
  }

  public void pause() {
    for (int i = 0; i < tracks.length; i++) {
      Track t = tracks[i];
      t.pause();
    }
  }

  public void stop() {
    pause();
    for (int i = 0; i < tracks.length; i++) {
      Track t = tracks[i];
      t.stop();
    }
  }

  public Track track(int index) {
    return tracks[index];
  }

  public Track[] all_track() {
    return tracks;
  }

  public int length() {
    return length;
  }

  public int position() {
    return representative_track.position();
  }
}

public class Composer
{
  Composition[] compositions;
  public Composer(Composition[] compositions) {
    this.compositions = compositions;
  }

  int index_of_current_composition = 0;

  public boolean isPlaying() {
    return current_composition().isPlaying();
  }
  
  public void start() {
    Composition c = compositions[index_of_current_composition];
    c.play();
  }
  
  public void pause() {
    Composition c = compositions[index_of_current_composition];
    c.pause();
  }

  public void stop() {
    Composition c = compositions[index_of_current_composition];
    c.stop();
  }

  public void next() {
    this.stop();
    index_of_current_composition += 1;
    index_of_current_composition %= compositions.length;
    this.start();
  }

  public void previous() {
    this.stop();
    index_of_current_composition -= 1;
    index_of_current_composition = max(index_of_current_composition, 0);
    this.start();
  }

  public Composition composition(int index) {
    return compositions[index];
  }

  public Composition current_composition() {
    if (compositions.length <= index_of_current_composition) {
      return null;
    }
    return compositions[index_of_current_composition];
  }

  public void update() {
    Composition c = current_composition();
    if (c.position() + 1 >= c.length()) {
      // play next
      next();
    }
  }
}

Composer composer;

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
boolean[] currentState = new boolean[number_of_tracks];

public void play()
{
  if (composer.isPlaying()) {
    printConsole("pause");
    composer.pause();
  }
  else {
    printConsole("play");
    composer.start();
  }
}

void serial_port(int n)
{
  /* request the selected item based on index n */
  String port_name = serial_ports[n];
  if (port != null) {
    port.stop();
  }
  try {
    port = new Serial(this, port_name, 9600);
    saveStrings(serialConfigFile, new String[] { port_name });
  }
  catch (RuntimeException ex) {
    port = null;
    printConsole("Error to open the serial port");
    ScrollableList list = (ScrollableList)cp5.getController("serial_port");
    list.open();
  }
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
  for (int i = 0; i < number_of_tracks; i++) {
    boolean touched = (flag & inByte) > 0;
    flag = flag << 1;
    currentState[i] = touched;
  }
  reloadState();
}

void reloadState()
{
  for (int i = 0; i < number_of_tracks; i++) {
    Boolean touched = currentState[i];
    Track t = composer.current_composition().track(i);
    if (touched) {
      // unmute
      printConsole("unmute: " + str(i));
      t.unmute();
    }
    else {
      // mute
      printConsole("mute: " + str(i));
      t.mute();
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
  Track[] all_track = composer.current_composition().all_track();
  for (int i = 0; i < all_track.length; i++) {
    Track t = all_track[i];
    for(int j = 0; j < user_interface_left_pane_width - 1 - offset; j++) {
      stroke(65, 105, 225);
      line(j + offset, wave_position_y + t.player.left.get(j) * wave_height + (wave_height * i), j + 1 + offset, wave_position_y + t.player.left.get(j + 1) * wave_height + (wave_height * i));
      stroke(255, 69, 0);
      line(j + offset, wave_position_y + t.player.right.get(j) * wave_height + (wave_height * i), j + 1 + offset, wave_position_y + t.player.right.get(j + 1) * wave_height + (wave_height * i));
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
  for (int i = 0; i < number_of_tracks; i++) {
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
  Composition c = composer.current_composition();
  int position = c.position();

  float playback_position = (float)position / (float)c.length();
  Slider slider = (Slider)cp5.getController("time");
  if (slider.isMousePressed() == false) {
    slider.setValue(playback_position * 100);
  }

  int playbackTime = position / 1000;
  String playbackMin = String.format("%02d", playbackTime / 60);
  String playbackSec = String.format("%02d", playbackTime % 60);
  playbackTimeLabel.setText(playbackMin + ":" + playbackSec);

  int remainingTime = (c.length() - position) / 1000;
  String remainingMin = String.format("%02d", remainingTime / 60);
  String remainingSec = String.format("%02d", remainingTime % 60);
  remainingTimeLabel.setText("-" + remainingMin + ":" + remainingSec);
}

void setup()
{
  size(700, 350);
  Minim _minim = new Minim(this);
  composer = new Composer(
    new Composition[] {
      new Composition(new Track[] {
       new Track(macOSPath("mp3/RhapsodyinBlue/1.mp3"), _minim),
       new Track(macOSPath("mp3/RhapsodyinBlue/2.mp3"), _minim),
       new Track(macOSPath("mp3/RhapsodyinBlue/3.mp3"), _minim),
       new Track(macOSPath("mp3/RhapsodyinBlue/4.mp3"), _minim),
       new Track(macOSPath("mp3/RhapsodyinBlue/5.mp3"), _minim),
       new Track(macOSPath("mp3/RhapsodyinBlue/6.mp3"), _minim),
       new Track(macOSPath("mp3/RhapsodyinBlue/7.mp3"), _minim),
       new Track(macOSPath("mp3/RhapsodyinBlue/8.mp3"), _minim)
      }),
      new Composition(new Track[] {
       new Track(macOSPath("mp3/Bolero/1.mp3"), _minim),
       new Track(macOSPath("mp3/Bolero/2.mp3"), _minim),
       new Track(macOSPath("mp3/Bolero/3.mp3"), _minim),
       new Track(macOSPath("mp3/Bolero/4.mp3"), _minim),
       new Track(macOSPath("mp3/Bolero/5.mp3"), _minim),
       new Track(macOSPath("mp3/Bolero/6.mp3"), _minim),
       new Track(macOSPath("mp3/Bolero/7.mp3"), _minim),
       new Track(macOSPath("mp3/Bolero/8.mp3"), _minim)
      })
  });
  
  cp5 = new ControlP5(this);
  
  cp5.addButton("play")
    .setPosition(0, 0)
    .setSize(50, user_interface_size);
  updateInterfaceHorizontalPosition(50);

  int time_silder_width = user_interface_left_pane_width - horizontal_position;
  Slider slider = cp5.addSlider("time")
    .setPosition(horizontal_position, vertical_position + 15)
    .setSize(time_silder_width, 5)
    .setRange(0, 100);
  slider.getCaptionLabel().setVisible(false);
  slider.getValueLabel().setVisible(false);
  slider.onClick(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      Slider slider = (Slider)theEvent.getController();
      Composition c = composer.current_composition();
      c.seek((float)slider.getValue() / 100);
    }
  });

  playbackTimeLabel = new Textlabel(cp5, "0:00", horizontal_position, vertical_position + 3, user_interface_size, user_interface_size);
  labels.add(playbackTimeLabel);
  updateInterfaceHorizontalPosition(user_interface_size);
  
  remainingTimeLabel = new Textlabel(cp5, "-0:00", user_interface_left_pane_width - user_interface_size * 2, vertical_position + 3, user_interface_size, user_interface_size);
  labels.add(remainingTimeLabel);

  breakInterfaceVerticalPosition();

  // debug switch  
  Textlabel toggle_label = new Textlabel(cp5, "Override Sensor State", horizontal_position, vertical_position - 10, user_interface_size, user_interface_size);
  labels.add(toggle_label);
  for (int i = 0; i < number_of_tracks; i++) {
    String label = str(i);
    cp5.addToggle(label)
      .setValue(false)
      .setLabel(label)
      .setPosition(horizontal_position + 20, vertical_position + (i * user_interface_size))
      .setSize(user_interface_size, user_interface_size);
    cp5.getController(label).getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER).setPaddingX(0);
  }

  breakInterfaceVerticalPosition(user_interface_size * number_of_tracks);

  // serial
  serial_ports = Serial.list();
  ScrollableList list = cp5.addScrollableList("serial_port")
    .setPosition(0, vertical_position)
    .setSize(user_interface_left_pane_width, 100)
    .setBarHeight(user_interface_size)
    .setItemHeight(user_interface_size)
    .addItems(serial_ports);
  
  String[] serialConfig = loadStrings(serialConfigFile);
  if (serialConfig != null && serialConfig.length > 0) {
    String savedPort = serialConfig[0];
    // Check if saved port is in available ports.
    boolean success = false;
    for (int i = 0; i < serial_ports.length; ++i) {
      if (serial_ports[i].equals(savedPort)) {
        list.setValue(i);
        list.setOpen(false);
      } 
    }
  }
  else {
    list.setOpen(true);
  }

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
  consoleTextArea.scroll(1);
  cp5.addToggle("stop_console")
    .setValue(false)
    .setLabel("Stop Console")
    .setPosition(user_interface_left_pane_width, user_interface_window_height - button_height)
    .setSize(user_interface_right_pane_width, button_height);
  cp5.getController("stop_console").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER).setPaddingX(0);

  stop_console(false);
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
   composer.update();
}
