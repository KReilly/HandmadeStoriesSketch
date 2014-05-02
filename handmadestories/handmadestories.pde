import java.nio.file.*;
import java.util.*;

String PROPERTIES_FILE = "config.properties";
Properties props;

ImageLoader imageLoader;
boolean showLoading = true;

ProjectedQuads projectedQuads;
LinkedList<PImage> images = new LinkedList<PImage>();
Map<PImage,Quad> image2Quad = new HashMap<PImage,Quad>();

int SWAP_TWO_IMAGES_INTERVAL_MILLIS = 10 * 1000;
int nextSwapTwoImagesTime;

ArrayList<CrossFadeAnimation> animations = new ArrayList<CrossFadeAnimation>();

WatchService watchService;
Path watchDir;
WatchKey watchKey;
boolean watching = false;

/**
 * Processing setup().
 */
@Override
void setup() {
  props = new Properties();
  try {
    props.load(createInput(PROPERTIES_FILE));
  } catch (IOException e) {
    // no config, so bail
    e.printStackTrace();
    exit();
    return;
  }

  size(1024, 768, P3D);
  background(0);
  frame.setBackground(new java.awt.Color(0, 0, 0));
  frameRate(30);
  textureMode(IMAGE);

  projectedQuads = new ProjectedQuads();
  projectedQuads.load(props.getProperty("quadsConfigFile"));  

  try {
    // load [up to] as many images as we have quads
    imageLoader = new ImageLoader(props.getProperty("imageDirectory"), int(props.getProperty("numberOfQuads")));
    imageLoader.start();
    println("ImageLoader restarted at frameCount " + frameCount);
  } catch (IOException e) {
    e.printStackTrace();
  }
}

/**
 * Processing draw().
 */
@Override
void draw() {
  background(0);
  
  if (showLoading) {
    // show the loading screen until images are loaded
    showLoadingScreen();
  } else {
    // show the projected pictures
    projectedQuads.draw();
  }

  // check to see if image-loading is done
  if (showLoading && imageLoader.getState().toString() == "TERMINATED") {
    showLoading = false;
    doOneTimePostImageLoading();
  }

  if (mainScreenReady()) {
    maybeSwapTwoImages();  
    stepAnimations();
    checkForNewImages();
  }
}

/**
 * Various do-after-we-load-images things.
 */
void doOneTimePostImageLoading() {
  // imageLoader loads images in last-modified-date descending order,
  // so oldest image is now at the FIFO end of our queue, ready for
  // first eviction.
  images.addAll(imageLoader.images);
  imageLoader = null;    
  createProjections();
  
  // start timers
  int now = millis();
  nextSwapTwoImagesTime = now + SWAP_TWO_IMAGES_INTERVAL_MILLIS;  

  startWatchingImageDir();    
}

void startWatchingImageDir() {
  try {
    watchService = FileSystems.getDefault().newWatchService();
    watchDir = FileSystems.getDefault().getPath(props.getProperty("imageDirectory"));
    watchKey = watchDir.register(watchService, StandardWatchEventKinds.ENTRY_CREATE);
    watching = true;
  } catch (IOException e) {
    e.printStackTrace();
  }
}

void checkForNewImages() {
  if (!watching) {
    return;
  }
  
  WatchKey pollKey = watchService.poll();
  if (pollKey != null) {
    for (WatchEvent event : pollKey.pollEvents()) {
      if (event.kind() == StandardWatchEventKinds.ENTRY_CREATE) {
        // new file!

        // The filename is the context of the event.
        WatchEvent<Path> ev = (WatchEvent<Path>)event;
        Path filename = ev.context();
        Path child = watchDir.resolve(filename);        
        if (child.toString().toLowerCase().endsWith(".jpg")) {
          loadNewImagePath(child);
        }                
      }  
    }
    
    // reset the key so we keep getting watch events
    pollKey.reset();
  }  
}

void loadNewImagePath(Path path) {
  println("Loading new image " + path);
  String filename = path.toString();
  PImage newImage = loadImage(filename);
  images.addFirst(newImage);

  // evict the oldest image
  PImage oldestImage = images.removeLast();

  // change the quad holding the oldest image to the new image, with animation  
  Quad quad = image2Quad.get(oldestImage);
  CrossFadeAnimation anim = new CrossFadeAnimation(quad, newImage);
  animations.add(anim);
}

/** 
 * Step any animations, removing any finished ones.
 */
void stepAnimations() {
  Iterator<CrossFadeAnimation> iter = animations.iterator();
  while (iter.hasNext()) {
    CrossFadeAnimation anim = iter.next();
    if (anim.done()) {
      iter.remove();
      // update our image=>quad map
      image2Quad.put(anim.newImage, anim.quad);
    } else {
      anim.step();
    }
  }  
}

/**
 * Put images into our quads.
 */
void createProjections() {
  // make sure we loaded a sufficient number of images
  int desiredQuads = int(props.getProperty("numberOfQuads"));
  int imagesLoaded = images.size();
  if (desiredQuads > imagesLoaded) {
    println("Wanted "  + desiredQuads + " projected quads, but only loaded " + imagesLoaded + " images.");  
  }  
  projectedQuads.setNumQuads(Math.min(desiredQuads, imagesLoaded));
  
  for (int i = 0; i < projectedQuads.getNumQuads(); i++) {
    PImage image = images.get(i);
    Quad quad = projectedQuads.getQuad(i);
    quad.setTexture(image);
    image2Quad.put(image, quad);
  }
}

/** 
 * Every N seconds, swap 2 visible images.
 */
void maybeSwapTwoImages() {
  int now = millis();  
  if (now >= nextSwapTwoImagesTime && mainScreenReady()) {
    // pick 2 random images to swap
    int idx1 = int(random(0, images.size()));
    int idx2 = int(random(0, images.size()));
    
    // only swap if we picked two different images
    if (idx1 != idx2) {
      PImage image1 = images.get(idx1);
      PImage image2 = images.get(idx2);          
      Quad quad1 = image2Quad.get(image1);
      Quad quad2 = image2Quad.get(image2);      
      CrossFadeAnimation anim1 = new CrossFadeAnimation(quad1, image2);
      animations.add(anim1);      
      CrossFadeAnimation anim2 = new CrossFadeAnimation(quad2, image1);
      animations.add(anim2);      
    }
    
    nextSwapTwoImagesTime = now + SWAP_TWO_IMAGES_INTERVAL_MILLIS;
  }
}

/**
 * Whether the main quads screen is ready for fading, animating, reloading, etc.
 */
boolean mainScreenReady() {
  return (!showLoading && 
    !projectedQuads.debugMode);
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

