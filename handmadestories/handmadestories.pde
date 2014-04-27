import java.util.Collections;
import java.util.Properties;

String PROPERTIES_FILE = "config.properties";
Properties props;

ImageLoader imageLoader;
ArrayList<PImage> images = new ArrayList<PImage>();

ProjectedQuads projectedQuads;
ArrayList<Quad> qs = new ArrayList<Quad>();
int qn[] = new int[2]; // Indexes of quads that will change 

float timer = 0;
float threadTimer = 0;
boolean showLoading = true;
boolean loaded = false;
boolean fading = true;
boolean fadeOut = true;
float f = 1;

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
  println("imageLoader restarted " + frameCount);
}

void draw() {
  background(0);
  
  if (showLoading) {
    // show the loading screen for the first run
    loading();
  } else {
    // show the projected pictures
    try {
      projectedQuads.draw();
    } catch(Exception e) {
      e.printStackTrace();
    }
  }

  // After the first thread run, create the projection quads and remove loading
  if (imageLoader.getState().toString() == "TERMINATED" && showLoading) {
    showLoading = false;
    createProjections();
  }

  // Every 30 seconds, change the images and start a new thread if the
  // previous thread is finished
  if (timer > 5 && !showLoading && imageLoader.getState().toString() == "TERMINATED" && !projectedQuads.debugMode) {
    if (!fading) {
      f = 1;
      fading = true;
    }
    fade();
  }
  // Each 2 minutes, reload images from the cloud
  if (threadTimer > 120 && !showLoading && imageLoader.getState().toString() == "TERMINATED" && !projectedQuads.debugMode) {
    threadTimer = 0;
    restartImageLoader();
  }
  
  // Only increment time when thread is finished
  // it will make sure you pictures will fade and switch
  // every 5 seconds for 120 seconds
  if (imageLoader.getState().toString() == "TERMINATED") {
    timer += 0.03;
    threadTimer += 0.03;
  }
}

/**
 * This will be executed when the first thread finishes.
 * After this, the textures will be just replaced.
 */
void createProjections() {
  // TODO: check vs. minimum expected image files
  //projectedQuads.load(props.getProperty("quadsConfigFile"));
  projectedQuads.setNumQuads(int(props.getProperty("numberOfQuads")));
  println(imageLoader.images.size() + " pictures loaded");
  for (int i = 0; i < projectedQuads.getNumQuads(); i++) {
    projectedQuads.getQuad(i).setTexture(imageLoader.images.get(i));
  }
}

/**
 * 
 */
void fade() {
  // Verify if you already choose indexes of images
  // to switch
  if (qs.size() == 0) {
    for (int i = 0; i < qn.length; i++) {
      // Choose a random quad index
      qn[i] = int(random(0, projectedQuads.quads.size()));
      // Get a random quad and add to quads that will change
      Quad q = (Quad) projectedQuads.quads.get(qn[i]);
      qs.add(q);
    }
  }

  // If is time to switch images, start fading process
  if (fading) {
    if (fadeOut) {
      f *= 1.1;
      if (f > 255) {
        fadeOut = false;
        // Change the images when they are hidden
        for (int i = 0; i < qn.length; i++) {
          Quad q = (Quad) projectedQuads.quads.get(qn[i]);
          int randIdx = int(random(0, imageLoader.images.size()));
          q.setTexture(imageLoader.images.get(randIdx));
        }
      }
    } else { 
      // fadeIn (end of fading transition
      f /= 1.1;
      if (f < 1) {
        fading = false;
        fadeOut = true;
        // Reset timer
        timer = 0;
        qs.clear();
      }
    } //fadeOut
  } //fading
  
  // Set alpha to projectedQuads textures
  for (int i = 0; i < qn.length; i++) {
    Quad q = (Quad) projectedQuads.quads.get(qn[i]);
    q.alpha = 255-f;
  }
}

// Loading bar with texts
void loading() {
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

