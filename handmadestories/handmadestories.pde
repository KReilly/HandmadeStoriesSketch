import java.util.Collections;
import java.util.HashSet;
import java.util.Properties;

String PROPERTIES_FILE = "config.properties";
Properties props;

ImageLoader imageLoader;
ArrayList<PImage> images = new ArrayList<PImage>();
boolean showLoading = true;

ProjectedQuads projectedQuads;

boolean fading = true;
boolean fadeOut = true;
float fadeAlphaDecrement = 1;

int HOW_MANY_QUADS_TO_SWITCH_AT_A_TIME = 2;
HashSet<Quad> quadsToSwitch = new HashSet<Quad>();

Quad quadToSwitch1;
Quad quadToSwitch2;

int RESTART_IMAGELOADER_INTERVAL_MILLIS = 120 * 1000;
int nextRestartImageLoaderTime;

int FADE_INTERVAL_MILLIS = 5 * 1000;
int nextFadeTime;

void setup() {
  props = new Properties();
  try {
    props.load(createInput(PROPERTIES_FILE));
  } catch (Exception e) {
    e.printStackTrace();
  }

  size(800, 600, P3D);
  background(0);
  frame.setBackground(new java.awt.Color(0, 0, 0));
  frameRate(30);
  textureMode(IMAGE);
  restartImageLoader();
  // Create and load previous configurations for projected rectangles
  projectedQuads = new ProjectedQuads();
  projectedQuads.load(props.getProperty("quadsConfigFile"));  
}

void restartImageLoader() {
  imageLoader = new ImageLoader(props.getProperty("imageDirectory"));
  imageLoader.start();
  println("ImageLoader restarted at frameCount " + frameCount);
}

boolean imagesAreFinishedLoading() {
  return imageLoader.getState().toString() == "TERMINATED";
}

void draw() {
  background(0);
  
  if (showLoading) {
    // show the loading screen until images are loaded
    showLoadingScreen();
  } else {
    // show the projected pictures
    try {
      projectedQuads.draw();
    } catch(Exception e) {
      e.printStackTrace();
    }
  }

  // check to see if image-loading is done
  if (showLoading && imagesAreFinishedLoading()) {
    showLoading = false;
    createProjections();
    // start timers
    int now = millis();
    nextFadeTime = now + FADE_INTERVAL_MILLIS;
    nextRestartImageLoaderTime = now + RESTART_IMAGELOADER_INTERVAL_MILLIS;
  }

  maybeFade();  
  maybeRestartImageLoader();  
}

/**
 * This will be executed when the first thread finishes.
 * After this, the textures will be just replaced.
 */
void createProjections() {
  // make sure we loaded a sufficient number of images
  int desiredQuads = int(props.getProperty("numberOfQuads"));
  int imagesLoaded = imageLoader.images.size();
  if (desiredQuads > imagesLoaded) {
    println("Wanted "  + desiredQuads + " projected quads, but only loaded " + imagesLoaded + " images.");  
  }  
  projectedQuads.setNumQuads(Math.min(desiredQuads, imagesLoaded));
  
  for (int i = 0; i < projectedQuads.getNumQuads(); i++) {
    projectedQuads.getQuad(i).setTexture(imageLoader.images.get(i));
  }
}

/** 
 * Every 30 seconds, change the images and start a new thread if the
 * previous thread is finished
 */
void maybeFade() {
  int now = millis();  
  if (now >= nextFadeTime && 
    !showLoading && 
    imagesAreFinishedLoading() && 
    !projectedQuads.debugMode) {
    if (!fading) {
      fadeAlphaDecrement = 1;
      fading = true;
    }
    fade();
  }
}

/** 
 * Each 2 minutes, reload images.
 */
void maybeRestartImageLoader() {
  int now = millis();  
  if (now >= nextRestartImageLoaderTime && 
    !showLoading && 
    imagesAreFinishedLoading() && 
    !projectedQuads.debugMode) {
    restartImageLoader();
    nextRestartImageLoaderTime = now + RESTART_IMAGELOADER_INTERVAL_MILLIS;      
  }    
}

/**
 * 
 */
void fade() {

  // pick quads to switch if we haven't already done so 
  if (quadToSwitch1 != null && quadToSwitch2 != null) {
      int rand1 = int(random(0, projectedQuads.quads.size()));
      int rand2 = int(random(0, projectedQuads.quads.size()));    
  }
  
  if (quadsToSwitch.isEmpty()) {
    for (int i = 0; i < HOW_MANY_QUADS_TO_SWITCH_AT_A_TIME; i++) {
      // Get a random quad
      int randIdx = int(random(0, projectedQuads.quads.size()));
      Quad q = projectedQuads.quads.get(randIdx);
      quadsToSwitch.add(q);
    }
  }
  
  // If is time to switch images, start fading
  if (fading) {
    if (fadeOut) {
      fadeAlphaDecrement *= 1.1;
      if (fadeAlphaDecrement > 255) {
        fadeOut = false;
        // Change the images when they are hidden
        for (Quad quad : quadsToSwitch) {
          // pick a random image to switch to
          int randIdx = int(random(0, imageLoader.images.size()));
          PImage randImage = imageLoader.images.get(randIdx);
          quad.setTexture(randImage);
        }
      }
    } else { 
      // fadeIn (end of fading transition)
      fadeAlphaDecrement /= 1.1;
      if (fadeAlphaDecrement < 1) {
        // done fading
        fading = false;
        fadeOut = true;        
        quadsToSwitch.clear();
        int now = millis(); 
        nextFadeTime = now + FADE_INTERVAL_MILLIS;
      }
    } //fadeOut
  } //fading
  
  // Set alpha to projectedQuads textures
  println("applying fade decrement " + fadeAlphaDecrement);
  for (Quad quad : quadsToSwitch) {
    quad.alpha = 255 - fadeAlphaDecrement;
  }
}

/**
 * Show loading bar with text.
 */
void showLoadingScreen() {
  String msg = "";
  if (imageLoader.complete == 0) {
    msg = "Connecting to Dropbox folder";
  } else {
    msg = "Loading images";
  }
  textSize(16);
  fill(255);
  textAlign(CENTER);
  text(msg, width/2, (height/2)-50);

  fill(0);
  stroke(255);
  rect(25, (height/2)-25, width-50, 50);
  fill(255);
  rect(25, (height/2)-25, (width-50) * imageLoader.complete, 50);
}

void keyPressed() {
  // let projectedQuads handle keys by itself
  projectedQuads.keyPressed();
}

void mousePressed() {
  // let projectedQuads handle mousePressed by itself
  projectedQuads.mousePressed();
}

void mouseDragged() {
  // let projectedQuads handle mouseDragged by itself
  projectedQuads.mouseDragged();
}

void mouseReleased() {
  // Auto save movements if in debug mode
  if (projectedQuads.debugMode && !showLoading) {
    projectedQuads.save(props.getProperty("quadsConfigFile"));
  }
}

