import ddf.minim.*;
import ddf.minim.analysis.*;

// Window Function Size for FFT
static int WINDOW_SIZE = 2048;//1024;

// Statusbar Height
static int STATUS_HEIGHT = 32;

// Brightness Coefficient (100:full-scale)
static float BRIGHTNESS_COEF = 180;

String file;
String fileName;
PImage img;

Minim minim;
InterpolatedSpectrum is;

SpectrumStream[] streams = new SpectrumStream[2];
int graph = 0;
int helpTime = 0;

boolean autoplay = false;

class SD implements StreamStruct {
  int time = -1;
  
  float maxPeek = 0f;
  float maxFreq = 0f;
  
  float maxPeek500ms = 0f;
  float maxFreq500ms = 0f;
  int maxPos500ms = 0;
  
  color[] spectrum;
  
  SD() {
    this.spectrum = new color[(height - STATUS_HEIGHT)];
  }
}

void setup() {
  size(1200, 800, P3D);
  colorMode(HSB, 360, 100, 100);
  frameRate(60);
  background(0);

  minim = new Minim(this);
  
  for (int i = 0; i < streams.length; i++) {
    streams[i] = new SpectrumStream(minim, WINDOW_SIZE);
    streams[i].struct = new SD();
  }
  
  // Spectrum Configure
  is = new InterpolatedSpectrum();
  is.logScaleFreq = true;
  is.coefFreq = 1.0f;
  is.logScalePower = true;
  is.coefPower = 1.0f;
  is.interpolation = true;
  is.interpolateRange = 0.5f;
  
  selectAudioFile();  
}

void selectAudioFile() {
  streams[graph].stop();
  selectInput("Please choose your wav(PCM) or mp3 file", "fileSelected");
}

void fileSelected(File selection) {
  if (selection == null) return;
  
  file = selection.getAbsolutePath();
  fileName = selection.getName();
  SpectrumStream stream = streams[graph];
  
  stream.close();
  stream.initFile(file);
  stream.struct = new SD();
  autoplay = true;
  
  is.setFFT(stream.getFFT());
}
      

void selectAudioInput() {
  SpectrumStream stream = streams[graph];
  
  stream.close();
  stream.initInput();
  stream.struct = new SD();
  
  is.setFFT(stream.getFFT());
}


void draw() {
  SpectrumStream stream = streams[graph];
  drawStatus();
 
  if (!stream.isInitialized()) return;
  if (!autoplay && !stream.isStreaming()) return;
  if (stream.hasBuffered()) drawSpectrogram();
  
  save (fileName);
}
 

void drawSpectrogram() {
  SpectrumStream stream = streams[graph];
  SD s = (SD) stream.struct;
  
  is.load(stream.getFFT());
  
  int x = s.time/5;
  int h = (height-32); 
  float prevFreqIndex = 0f;
  s.maxFreq = s.maxPeek = 0f;
  stroke(0); line(0.5f+s.time/5, h*graph, 0.5f+s.time/5, h*(graph+1));
  
  for (int i = 0; i < h; ++i)
  {
    float freqRatio = (float)(i) / h;
    float freqIndex = is.getIndex(freqRatio);
   
    float power = is.getMaxPower(prevFreqIndex, freqIndex); // Peek
    prevFreqIndex = freqIndex;
  
    color c = (color(max(0, 0), 0, BRIGHTNESS_COEF*power)); //bianco e nero
   
    if (is.interpolation) {
      // Linear interpolation
      set(x, h*(graph+1)-i, lerpColor(s.spectrum[i], c, .5));
    } else {
      set(x, h*(graph+1)-i, c);
    }
    set(x, h*(graph+1)-i, c);
    
    s.spectrum[i] = c;
    
    if (s.maxPeek < power) {
      s.maxFreq = freqIndex;
      s.maxPeek = power;
    }
  }
  
  if (stream.position() - s.maxPos500ms > 500 || s.maxPeek500ms < s.maxPeek) {
    s.maxPeek500ms = s.maxPeek;
    s.maxFreq500ms = s.maxFreq;
    s.maxPos500ms = stream.position();
  }
  
  
  s.time+=2; if (x >= width) s.time = 0;
  stroke(255); line(0.5f+s.time/5, h*graph, 0.5f+s.time/5, h*(graph+1));


  line(0, h, width, h);
  line(0, h*2, width, h*2);
  
  if (autoplay) {
    stream.start();
    autoplay = false;
  }
}


void drawStatus() { //barra sotto
  SpectrumStream stream = streams[graph];
  SD s = (SD) stream.struct;
  noStroke();
  fill(0);
  rect(0,height-32, width,height);
  fill(240);
  if (stream.isInitialized() && is.fft != null && millis() - helpTime >= 5000) {
    helpTime = 0;
    text(
      "Title "+fileName.intern()+
      "  Graph"+(graph+1)+
      ", WindowWidth="+floor(stream.windowSize)+
      ", Time="+nfc(stream.position())+"ms"+
      ", Peek="+nfs(is.dbPower(s.maxPeek), 2, 3)+"dB"+
      "("+nf(is.indexToFreq(s.maxFreq), 5, 1)+"Hz)"+
      ", 500ms="+nfs(is.dbPower(s.maxPeek500ms), 2, 3)+
      "dB("+nf(is.indexToFreq(s.maxFreq500ms), 5, 1)+"Hz)"
      , 8, height-8);
  } 
}
