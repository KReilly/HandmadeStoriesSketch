import java.io.*;
import java.nio.file.FileSystems;
import java.nio.file.WatchService;
import java.util.*;

class ImageLoader extends Thread {
  String imageDir;
  public ArrayList<File> imageFiles = new ArrayList<File>();
  public ArrayList<PImage> images = new ArrayList<PImage>();
  public float complete;

  /**
   * @param imageDir Directory to load images from. 
   */
  ImageLoader(String imageDir) throws IOException {
    this.imageDir = imageDir;    
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
    int counter = 0;
    for (String imageFilename : imageFilenames) {
      addImage(imageFilename);
      counter++;
      complete = (float)counter / (float)imageCount;  
    }
    
    Collections.shuffle(images);
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
    
    // sort by last modified date
    Arrays.sort(files, new Comparator<File>(){
      public int compare(File f1, File f2) {
        return Long.valueOf(f1.lastModified()).compareTo(f2.lastModified());
      } 
    });
    
    return filenamesFromFiles(files);
  }
    
  /**
   * @returns elements in l2 but not in l1.
   */
  ArrayList elementsOnlyInL2(ArrayList l1, ArrayList l2) {
    ArrayList notPresent = new ArrayList(l2);
    notPresent.removeAll(l1);
    return notPresent;
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
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
}

