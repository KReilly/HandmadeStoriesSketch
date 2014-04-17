import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.Collections; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class handmadestories extends PApplet {



ArrayList<PImage> images = new ArrayList<PImage>();
ProjectedQuads projectedQuads;
String configFile = "data/quadsconfig.txt";
String url = "http://handmadestories.herokuapp.com/";
ImageLoader il;
String[] config;
float timer = 0;
float threadTimer = 0;
boolean showLoading = true;
boolean loaded = false;
boolean fading = true;
boolean fadeOut = true;
float f = 1;

ArrayList<Quad> qs = new ArrayList<Quad>();
int qn[] = new int[2]; // Indexes of quads that will change 

public void setup() {
  size(800, 600, P3D);
  background(0);
  frame.setBackground(new java.awt.Color(0, 0, 0));
  frameRate(30);
  textureMode(IMAGE);
  // Load configuration string file
  config = loadStrings("config.txt");
  // Actually, start the thread
  restartThread();
  // Create and load previous configurations for
  // projected rectangles
  projectedQuads = new ProjectedQuads();
  projectedQuads.load(configFile);
}

public void draw() {
  background(0);
  // If it is the first run, show loading
  if (showLoading) {
    loading();
  } 
  else {
    // Else, show the projected pictures
    try {
      projectedQuads.draw();
    } 
    catch(Exception e) {
      e.printStackTrace();
    }
  }

  // After the first thread run, create the projection quads and remove loading
  if (il.getState().toString() == "TERMINATED" && showLoading) {
    showLoading = false;
    createProjections();
  }

  // Every 30 seconds, change the images and start a new thread if the
  // previous thread is finished
  if (timer > 5 
    && !showLoading 
    && il.getState().toString() == "TERMINATED"
    && !projectedQuads.debugMode) {
    if (!fading) {
      f = 1;
      fading = true;
    }
    fade();
  }
  // Each 2 minutes, reload images from the cloud
  if (threadTimer > 120
    && !showLoading 
    && il.getState().toString() == "TERMINATED"
    && !projectedQuads.debugMode) {
    // reset timer
    threadTimer = 0;
    // Restart the threat and repopulate images
    restartThread();
  }
  
  // Only increment time when thread is finished
  // it will make sure you pictures will fade and switch
  // every 5 seconds for 120 seconds
  if(il.getState().toString() == "TERMINATED") {
    timer += 0.03f;
    threadTimer += 0.03f;
  }
}

public void fade() {
  // Verify if you already choose indexes of images
  // to switch
  if (qs.size() == 0) {
    for (int i = 0; i < qn.length; i++) {
      // Choose a random quad index
      qn[i] = PApplet.parseInt(random(0, projectedQuads.quads.size()));
      // Get a random quad and add to quads that will change
      Quad q = (Quad) projectedQuads.quads.get(qn[i]);
      qs.add(q);
    }
  }

  // If is time to switch images, start fading process
  if (fading) {
    if (fadeOut) {
      f*=1.1f;
      if (f > 255) {
        fadeOut = false;
        // Change the images when they are hidden
        for (int i = 0; i < qn.length; i++) {
          Quad q = (Quad) projectedQuads.quads.get(qn[i]);
          q.setTexture(il.getImages().get(PApplet.parseInt(random(0, il.countImages()))));
        }
      }
    } 
    else { //fadeIn (end of fading transition
      f/=1.1f;
      if (f < 1) {
        fading = false;
        fadeOut = true;
        // Reset timer
        timer = 0;
        qs.clear();
      }
    }//fadeOut
  }//fading
  
  // Set alpha to projectedQuads textures
  for (int i = 0; i < qn.length; i++) {
    Quad q = (Quad) projectedQuads.quads.get(qn[i]);
    q.alpha = 255-f;
  }
}

// Loading bar with texts
public void loading() {
  String msg = "";
  if (il.getComplete() == 0) {
    msg = "Connecting to Dropbox folder";
  } 
  else {
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
  rect(25, (height/2)-25, (width-50)*il.getComplete(), 50);
}

// This will be executed when the first thread finish.
// After this, the textures will be just replaced
public void createProjections() {
  projectedQuads.load(configFile);
  projectedQuads.setNumQuads(PApplet.parseInt(config[1]));
  println(il.getImages().size() + " pictures loaded");
  for (int i = 0; i < projectedQuads.getNumQuads(); i++) {
    projectedQuads.getQuad(i).setTexture(il.getImages().get(i));
  }
}

// Call thread again to reload images
public void restartThread() {
  il = new ImageLoader(url, config);
  il.start();
  println("Thread restarted " + frameCount);
}

public void keyPressed() {
  //let projectedQuads handle keys by itself
  projectedQuads.keyPressed();
}

public void mousePressed() {
  //let projectedQuads handle mousePressed by itself
  projectedQuads.mousePressed();
}

public void mouseDragged() {
  //let projectedQuads handle mouseDragged by itself
  projectedQuads.mouseDragged();
}

public void mouseReleased() {
  // Auto save movements if in debug mode
  if (projectedQuads.debugMode && !showLoading) {
    projectedQuads.save(configFile);
  }
}

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
      for (int i = 0; i < PApplet.parseInt(u.length); i++) {
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
    } 
    catch (Exception e) {
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

/*
  ProjectedQuads / ProjectedQuads.pde 
 v1.0 / 2010.01.30
 */
 
 /*
  ProjectedQuads - a simple class for projection mapping demo
  
  ProjectedQuads / ProjectedQuadsTest.pde
  v1.0 / 2010.01.30
  
  Keyboard:
  - 'd' toggle debug mode
  - 'S' save settings
  - 'L' load settings
  - 'o' select next quad in debug mode
  - 'p' select prev quad in debug mode
  - '1', '2', '3', '4' select one of selected quad's corners 
  - Arrow keys (left, right, up, down) move selected corner's position (you can also use mouse for that)  
*/

/* 
 * Copyright (c) 2010 Marcin Ignac http://marcinignac.com
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * http://creativecommons.org/licenses/LGPL/2.1/
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

class ProjectedQuads {
  private ArrayList quads;
  private boolean debugMode = true;
  private int selectedQuad = 0;
  private int selectedPoint = 0;  
  private float numSubdivisions = 5;
  PFont debugFont;

  public ProjectedQuads() {
    quads = new ArrayList();
    debugFont = createFont("Arial", 24);
  }

  public boolean getDebugMode() {
    return debugMode;
  }

  public void setDebugMode(boolean debugMode) {
    this.debugMode = debugMode;
  }

  public void setNumQuads(int num) {
    while (quads.size () > num) {
      quads.remove(quads.size()-1);
    }
    while (quads.size () < num) {
      quads.add(new Quad());
    }
    selectedQuad = quads.size()-1;
  }

  public int getNumQuads() {
    return quads.size();
  }

  public Quad getQuad(int i) {
    return (Quad)quads.get(i);
  }

  public void load(String configFile) {
    String[] data = loadStrings(configFile);
    if (data == null) {
      return;
    }
    setNumQuads(data.length);
    for (int i=0; i<data.length; i++) {
      PVector[] points = ((Quad)quads.get(i)).getPoints();
      String[] lineArr = data[i].split(" ");
      for (int j=0; j<4; j++) {
        points[j].x = parseFloat(lineArr[j*2]);
        points[j].y = parseFloat(lineArr[j*2+1]);
      }
    }
    println("ProjectedQuads loaded from: " + configFile);
  }

  public void save(String configFile) {
    String data = "";
    for (int i=0; i<quads.size(); i++) {
      PVector[] points = ((Quad)quads.get(i)).getPoints();
      for (int j=0; j<4; j++) {
        data += points[j].x + " " + points[j].y;
        if (j < 3) data += " ";
      }
      if (i < quads.size()-1) data += "\n";
    }
    saveStrings(configFile, data.split("\n"));
    println("ProjectedQuads saved to: " + configFile);
  }


  //draw all the quads
  public void draw() {    
    if (debugMode) {
      textFont(debugFont);
    }

    for (int i=0; i<quads.size(); i++) {    
      if (debugMode) {
        if (i == selectedQuad) {
          stroke(255);
        }
        else {
          stroke(255, 50);
        }
      }
      else {
        noStroke();
      }    
      beginShape(QUADS);   
      Quad q = (Quad)quads.get(i);
      tint(q.alpha);
      texture(q.getTexture());
      
      for (int x=0; x<numSubdivisions; x++) {
        for (int y=0; y<numSubdivisions; y++) {
          calcVertex(q, x/numSubdivisions, y/numSubdivisions);
          calcVertex(q, (x+1)/numSubdivisions, y/numSubdivisions);
          calcVertex(q, (x+1)/numSubdivisions, (y+1)/numSubdivisions);
          calcVertex(q, x/numSubdivisions, (y+1)/numSubdivisions);
        }
      }
      
      endShape();
      if (debugMode) {
        PVector center = q.getCenterPoint();

        fill(0, 0, 0);  
        text(""+i, center.x-22, center.y+22);           

        if (i == selectedQuad) {
          fill(255);
        }
        else {
          fill(200);
        }

        text(""+i, center.x-20, center.y+20);
      }
    }

    if (debugMode) {
      drawAnchors();
    }
  }  

  //calculates vertex for sub quads
  public void calcVertex(Quad q, float sx, float sy) {
    PVector[] points = q.getPoints();
    float tx = points[0].x + (points[1].x - points[0].x)*sx;
    float ty = points[0].y + (points[1].y - points[0].y)*sx;        
    float bx = points[3].x + (points[2].x - points[3].x)*sx;
    float by = points[3].y + (points[2].y - points[3].y)*sx;   
    float gw = q.getTexture().width;
    float gh = q.getTexture().height;    

    if (q.isMirrored()) {
      vertex(tx + (bx - tx) * sy, ty + (by - ty) * sy, gw-sx*gw, sy*gh);
    }
    else {
      vertex(tx + (bx - tx) * sy, ty + (by - ty) * sy, sx*gw, sy*gh);
    }
  }

  public void drawAnchors() {
    stroke(255, 255, 255);
    strokeWeight(2);
    ellipseMode(CENTER);  
    if (selectedQuad > -1) {    
      Quad q = (Quad)quads.get(selectedQuad);
      noFill();
      for (int i=0; i<4; i++) {  
        ellipse(q.getPoints()[i].x, q.getPoints()[i].y, 10, 10);
      }
    }
  }


  public void keyPressed() {
    if (selectedQuad > -1 && selectedPoint > -1) {
      PVector[] points = ((Quad)quads.get(selectedQuad)).getPoints();
      switch(keyCode) {
      case LEFT: 
        points[selectedPoint].x -= 1; 
        break;
      case RIGHT: 
        points[selectedPoint].x += 1; 
        break;
      case UP: 
        points[selectedPoint].y -= 1; 
        break;
      case DOWN: 
        points[selectedPoint].y += 1; 
        break;
      }
    }

    if (key == '1') {
      selectedPoint = 0;
    }
    if (key == '2') {
      selectedPoint = 1;
    }
    if (key == '3') {
      selectedPoint = 2;
    }
    if (key == '4') {
      selectedPoint = 3;
    }
    if (key == 'o' || key == 'O') {
      selectedQuad = (selectedQuad - 1 + quads.size()) % quads.size();
    }
    if (key == 'p' || key == 'P') {
      selectedQuad = (selectedQuad + 1) % quads.size();
    }

    //Shift + 's' to avoid accidental saving
    if (key == 'S' || key == 's') {
      projectedQuads.save(configFile);
    }

    //Shift + 'l' to avoid accidental loading
    if (key == 'L' || key == 'l') {
      projectedQuads.load(configFile);
    }

    //Toggle debug/design/setup mode
    if (key == 'd' || key == 'D') {
      projectedQuads.setDebugMode(!projectedQuads.getDebugMode());
    }
  }

  public void mousePressed() {
    selectedPoint = -1;
    if (selectedQuad > -1) {
      PVector[] points = ((Quad)quads.get(selectedQuad)).getPoints();
      for (int i=0; i<4; i++) {
        if ((Math.abs(mouseX - points[i].x) < 10) && (Math.abs(mouseY - points[i].y) < 10)) {
          selectedPoint = i;
          break;
        }
      }
    }
  }

  public void mouseDragged() {
    if (selectedQuad > -1 && selectedPoint > -1) {
      PVector[] points = ((Quad)quads.get(selectedQuad)).getPoints();
      points[selectedPoint].x = mouseX;
      points[selectedPoint].y = mouseY;   
      //snapping
      for (int i=0; i<quads.size(); i++) {
        if (i == selectedQuad) continue;
        PVector[] otherPoints = ((Quad)quads.get(i)).getPoints();
        for (int j=0; j<4; j++) {
          if ((abs(otherPoints[j].x - points[selectedPoint].x) < 5) 
            && (abs(otherPoints[j].y - points[selectedPoint].y) < 5)) {
            points[selectedPoint].x = otherPoints[j].x;
            points[selectedPoint].y = otherPoints[j].y;
            break;
          }
        }
      }
    }
  }
}
/*
  ProjectedQuads / Quads.pde 
 v1.0 / 2010.01.30
 */

/* 
 * Copyright (c) 2010 Marcin Ignac http://marcinignac.com
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * http://creativecommons.org/licenses/LGPL/2.1/
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

class Quad {
  private PVector[] points;
  private PImage texture;
  private boolean mirrored = false;
  public float alpha;

  public Quad() {
    points = new PVector[4];
    points[0] = new PVector(width/4, height/4);
    points[1] = new PVector(width/4*2, height/4);
    points[2] = new PVector(width/4*2, height/4*2);
    points[3] = new PVector(width/4, height/4*2);
    alpha = 255;
  }

  public PVector[] getPoints() {
    return points;
  }

  public PImage getTexture() {
    return texture;
  }

  public void setTexture(PImage texture) {
    this.texture = texture;
  }


  public boolean isMirrored() {
    return mirrored;
  }

  public void setMirrored(boolean mirrored) {
    this.mirrored = mirrored;
  } 

  public PVector getCenterPoint() {
    return new PVector(
    (points[0].x + points[1].x + points[2].x + points[3].x)/4, 
    (points[0].y + points[1].y + points[2].y + points[3].y)/4
      );
  }
}

  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--full-screen", "--bgcolor=#666666", "--stop-color=#cccccc", "handmadestories" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
