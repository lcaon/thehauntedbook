PImage img;
float d;
float c; 
float q = 0; 
float z = 0; 

void setup() {
 size(1200, 800, P2D);
 background(0);
 frameRate(1000);
 img = loadImage("01_Ghosts_I.mp3.tif");
}

void draw() {
    background(img);

    //noise  
    for (float y = 0; y < height; y = y + 1) {
       for (float x = 0; x < width; x = x + 1) {
          
      color c = img.get(int(x),int(y));
      stroke(c);
      fill(c);
      point(x, y + map(noise(x/150, y/150), 0, 1, -100, 100));
        }
     }
      z = z + 0.02;
    
    save("1.tif");
}
