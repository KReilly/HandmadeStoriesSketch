import java.io.FilenameFilter;

class ImageLoader extends Thread {
  public ArrayList<PImage> images = new ArrayList<PImage>();
  public float complete;
  String imageDir;
  String[] config;

  /**
   * @param imageDir Directory to load images from. 
   */
  ImageLoader(String imageDir) {
    this.imageDir = imageDir;
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
   * List *.jpg from this.imageDir.
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

