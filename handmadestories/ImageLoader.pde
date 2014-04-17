class ImageLoader extends Thread {
  String url;
  String[] imageURLs;
  float complete;
  ArrayList<PImage> imgs = new ArrayList<PImage>();
  String[] config;

  ImageLoader(String u) {
    this.url = u;
  }

  public void run() {
    // the URL content is a bunch of other URLs
    imageURLs = loadStrings(this.url);
    if (imageURLs != null) {
      for (int i = 0; i < imageURLs.length; i++) {
        addImage(imageURLs[i], i);      
      }
      Collections.shuffle(this.imgs);
    }
  }

  public float getComplete() {
    return this.complete;
  }

  private void addImage(String url, int i) {
    try {
      PImage img;
      img = loadImage(url, "jpg");
      this.imgs.add(img);
      this.setComplete((i/(float)imageURLs.length));
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public ArrayList<PImage> getImages() {
    return imgs;
  }
  
  public int countImages() {
    return imgs.size();
  }

  private void setComplete(float c) {
    this.complete = c;
  }
}

