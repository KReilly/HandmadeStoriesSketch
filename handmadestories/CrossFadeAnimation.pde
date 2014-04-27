
float FADE_STEP_MULTIPLIER = 1.1;

class CrossFadeAnimation {
  Quad quad;
  PImage newImage;
  float alpha = 255;
  boolean fadeOut = true;
  boolean done = false;
  
  CrossFadeAnimation(Quad quad, PImage newImage) {
    this.quad = quad;
    this.newImage = newImage;
  }
  
  void step() {
    if (done) {
      return;
    }
    
    if (fadeOut) {
      alpha /= FADE_STEP_MULTIPLIER;
      if (alpha < 1) {
        fadeOut = false;
        alpha = 1;
        // switch the image when we're fully faded-out
        quad.setTexture(newImage);
      }
    } else {
      // fade in
      alpha *= FADE_STEP_MULTIPLIER; 
      if (alpha > 255) {
         alpha = 255; 
         done = true;
      }     
    }   
    
    quad.alpha = alpha;
  }
  
  boolean done() {
    return this.done;  
  }  
}

