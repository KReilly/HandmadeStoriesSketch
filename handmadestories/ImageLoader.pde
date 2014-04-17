class ImageLoader extends Thread {
  String url;
  String[] u;
  float complete;
  ArrayList<PImage> imgs = new ArrayList<PImage>();
  String[] config;

  ImageLoader(String u, String[] c) {
    this.url = u;
    this.config = c;
  }

  public void run() {
    this.u = loadStrings(this.url);
    if (u.length > 0) {
      u = u[0].split(";");
      for (int i = 0; i < int(u.length); i++) {
        addImage(u[i], i);
      }
    }
    Collections.shuffle(this.imgs);
  }

  public float getComplete() {
    return this.complete;
  }

  private void addImage(String url, int i) {
    try {
      PImage img;
      img = loadImage(url, "jpg");
      this.imgs.add(img);
      this.setComplete((i/(float)this.u.length));
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public ArrayList<PImage> getImages() {
    return this.imgs;
  }
  
  public int countImages() {
    return this.imgs.size();
  }

  private void setComplete(float c) {
    this.complete = c;
  }
}

