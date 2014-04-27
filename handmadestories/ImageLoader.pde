import java.io.*;
import java.nio.file.FileSystems;
import java.nio.file.WatchService;
import java.util.*;

class ImageLoader extends Thread {
  String imageDir;
  public ArrayList<PImage> images = new ArrayList<PImage>();
  public float complete;
  int maxImageCount;

  /**
   * @param imageDir Directory to load images from. 
   */
  ImageLoader(String imageDir, int maxImageCount) throws IOException {
    this.imageDir = imageDir;    
    this.maxImageCount = maxImageCount;
    WatchService watcher = FileSystems.getDefault().newWatchService();
  }

  @Override
  public void run() {
    loadImages();
  }

  /**
   * Load all the images found in our images directory.
   */
  void loadImages() {
    ArrayList<String> imageFilenames = getImageFilenames(imageDir);
    int imageCount = imageFilenames.size();

    // don't keep more than maxImages filenames.
    if (imageCount > maxImageCount) {
      // if we have too many, keep the newest filenames
      imageFilenames = new ArrayList(imageFilenames.subList(0, maxImageCount));
    }

    // load 'em!        
    int counter = 0;
    for (String imageFilename : imageFilenames) {
      addImage(imageFilename);
      counter++;
      complete = (float)counter / (float)imageCount;  
    }
    
    println("ImageLoader loaded " + images.size() + " images from " + imageDir);
  }
  
  /**
   * List *.jpg files in the given directory.
   */
  ArrayList<String> getImageFilenames(String imageDir) {
    File dir = new File(imageDir);
    File[] files = dir.listFiles(new FilenameFilter() {
      @Override
      public boolean accept(File dir, String name) {
        // accept *.jpg
        return name.toLowerCase().endsWith(".jpg");
      }
    });
    
    // sort by last-modified-date descending
    Arrays.sort(files, new Comparator<File>(){
      public int compare(File f1, File f2) {
        return -1 * Long.valueOf(f1.lastModified()).compareTo(f2.lastModified());
      } 
    });
    
    return filenamesFromFiles(files);
  }
    
  /**
   * Get a list of String filenames from a given list of Files.
   */
  ArrayList<String> filenamesFromFiles(File[] files) {
    ArrayList<String> filenames = new ArrayList<String>();
    for (int i = 0, len = files.length; i < len; i++) {
      File file = files[i];
      filenames.add(file.getAbsolutePath()); 
    } 
    return filenames;
  }
  
  private void addImage(String filename) {
    try {
      PImage image = loadImage(filename);
      this.images.add(image);
      println("Added image " + filename);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
}

