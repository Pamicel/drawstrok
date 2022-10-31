import toxi.geom.*;
import java.util.*;
import processing.svg.*;

DisplayWindow displayWindow;
boolean SECONDARY_MONITOR = false;
int[] CANVAS_SIZE = new int[]{500, 500};
int[] REAL_CANVAS_SIZE = new int[]{1000, 1000};
int[] DISPLAY_WIN_SIZE = new int[]{1000, 1000};
int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{600, -2000} : new int[]{50, 50};
color WINDOW_BACKROUNG_COLOR = 0xffffffff;
color MOUSE_STROKE_COLOR = 0xff000000;
float DISPLAY_WINDOW_LINEAR_DENSITY = 1.0 / 10.0; // 1 point every N pixels
boolean RESAMPLE = false;
int NUMBER_OF_POINTS_FINAL = 20;
void setup() {
  pixelDensity(2);
  displayWindow = new DisplayWindow(this.sketchPath(""));
  this.surface.setVisible(false);
}

void draw() {noLoop();}

class DisplayWindow extends PApplet {
  DisplayWindow(String path) {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
    this.path = path;
  }

  float xRatio = float(REAL_CANVAS_SIZE[0]) / float(CANVAS_SIZE[0]);
  float yRatio = float(REAL_CANVAS_SIZE[1]) / float(CANVAS_SIZE[1]);
  int[] canvasSize = null;

  Vec2D canvasPosition = new Vec2D((DISPLAY_WIN_SIZE[0] - CANVAS_SIZE[0]) / 2, (DISPLAY_WIN_SIZE[1] - CANVAS_SIZE[1]) / 2);

  private String path = "";
  ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
  ArrayList<Vec2D> curveToDraw;
  Vec2D[] finalCurve = null;
  PGraphics targetSurface;
  final float LINEAR_DENSITY = DISPLAY_WINDOW_LINEAR_DENSITY;
  int RESAMPLE_NEW_LEN = NUMBER_OF_POINTS_FINAL;
  boolean RESAMPLE_REGULAR = false;


  // Processing methods
  ArrayList<Vec2D> loadCurve() {
    JSONArray objectCurve = loadJSONArray(path + "data/curve.json");
    if (objectCurve.size() == 0) {
      return null;
    }
    ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
    for (int i = 0; i < objectCurve.size(); i++) {
      JSONObject point = objectCurve.getJSONObject(i);
      float x = point.getFloat("x");
      float y = point.getFloat("y");
      curve.add(new Vec2D(x, y));
    }
    return curve;
  }

  void loadVariables() {
    JSONObject variables = loadJSONObject(path + "data/variables.json");
    RESAMPLE = variables.getBoolean("resample");
    RESAMPLE_REGULAR = variables.getBoolean("resampleRegular");
    RESAMPLE_NEW_LEN = variables.getInt("resampleLen");
  }

  void settings () {
    size(DISPLAY_WIN_SIZE[0], DISPLAY_WIN_SIZE[1]);
  }

  void setup() {
    noFill();
    smooth();
    loadVariables();
    ArrayList<Vec2D> loadedCurve = loadCurve();
    if (loadedCurve != null) {
      finalCurve = applyResample(curveToArray(loadedCurve));
    }
    this.surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
    this.targetSurface = createGraphics(CANVAS_SIZE[0], CANVAS_SIZE[1]);
  }

  void printComposition () {
    //
  }

  void clearCanvas () {
    //
  }

  void draw() {
    this.background(WINDOW_BACKROUNG_COLOR);

    boolean isFinishedDrawing = finalCurve != null && finalCurve.length != 0;

    push();
    stroke(MOUSE_STROKE_COLOR);
    strokeWeight(1);
    if (isFinishedDrawing) {
      fill(120);
    } else {
      noFill();
    }
    rect(
      this.canvasPosition.x,
      this.canvasPosition.y,
      this.width - (2 * this.canvasPosition.x),
      this.height - (2 * this.canvasPosition.y)
    );
    pop();

    if (isFinishedDrawing) {
      stroke(#ff0000);
      Vec2D pos;
      pushMatrix();
      translate(canvasPosition.x, canvasPosition.y);
      scale(1 / this.xRatio, 1 / this.yRatio);
      beginShape();
      for (int i = 0; i < finalCurve.length; i++) {
        pos = finalCurve[i];
        circle(pos.x, pos.y, 5);
        vertex(pos.x, pos.y);
      }
      endShape();
      popMatrix();
    } else {
      stroke(MOUSE_STROKE_COLOR);
      Vec2D pos;
      beginShape();
      for (int i = 0; i < curve.size(); i++) {
        pos = curve.get(i);
        circle(pos.x, pos.y, 5);
        vertex(pos.x, pos.y);
      }
      endShape();
    }

  }

  // Sketch methods

  float signedAngle(Vec2D pos) {
    Vec2D normalVector = new Vec2D(1,0);
    float angle = acos(pos.getNormalized().dot(normalVector));
    if (pos.sub(normalVector).y < 0) {
      angle = -angle;
    }
    return angle;
  }

  Vec2D[] remapCurve(Vec2D[] curve, Vec2D targetPointA, Vec2D targetPointB) {
    Vec2D curvePointA = curve[0];
    Vec2D curvePointB = curve[curve.length - 1];

    Vec2D curveDirVec = curvePointB.sub(curvePointA);
    Vec2D targetDirVec = targetPointB.sub(targetPointA);

    float curveAngle = signedAngle(curveDirVec);
    float targetAngle = signedAngle(targetDirVec);

    float angle = targetAngle - curveAngle;

    float curveLen = curveDirVec.magnitude();
    float targetLen = targetDirVec.magnitude();

    float scale = targetLen / curveLen;

    Vec2D[] remaped = new Vec2D[curve.length];
    remaped[0] = targetPointA.copy();
    for (int i = 1; i < curve.length; i++) {
      remaped[i] = curve[i].sub(curve[0]).scale(scale).getRotated(angle).add(targetPointA);
    }

    return remaped;
  }

  Vec2D getCurrentTranslation() {
    return new Vec2D(this.canvasPosition.x, this.canvasPosition.y);
  }

  void savePathToJSON(Vec2D[] curve) {
    JSONArray values = new JSONArray();
    for (int i = 0; i < curve.length; i++) {
      JSONObject point = new JSONObject();
      point.setFloat("x", curve[i].x);
      point.setFloat("y", curve[i].y);
      values.setJSONObject(i, point);
    }
    int date = (year() % 100) * 10000 + month() * 100 + day();
    int time = hour() * 10000 + minute() * 100 + second();
    saveJSONArray(values, path + "data/curves/curve_date-"+ date + "_time-"+ time + ".json");
    print("saved");
  }

  // Event methods

  boolean extending = false;

  void mouseDragged() {
    curve.add(new Vec2D(mouseX, mouseY));
  }

  void mousePressed() {
    finalCurve = null;
    curve = new ArrayList<Vec2D>();
    curve.add(new Vec2D(mouseX, mouseY));
  }

  Vec2D[] translateCurve(Vec2D[] curve, Vec2D translation) {
    Vec2D[] newCurve = new Vec2D[curve.length];
    for (int i = 0; i < curve.length; i++) {
      newCurve[i] = curve[i].add(translation);
    }
    return newCurve;
  }

  Vec2D[] rescaleCurve(Vec2D[] curve, float xScale, float yScale) {
    Vec2D[] newCurve = new Vec2D[curve.length];
    for (int i = 0; i < curve.length; i++) {
      newCurve[i] = new Vec2D(curve[i].x * xScale, curve[i].y * yScale);
    }
    return newCurve;
  }

  void transformCurve(ArrayList<Vec2D> curve) {
    finalCurve = curveToArray(curve);
    finalCurve = applyResample(finalCurve);
    finalCurve = translateCurve(finalCurve, this.getCurrentTranslation().invert());
    finalCurve = rescaleCurve(finalCurve, this.xRatio, this.yRatio);
  }

  Vec2D[] applyResample(Vec2D[] curve) {
    if (RESAMPLE) {
      if (RESAMPLE_REGULAR) {
        return regularResample(curve, this.RESAMPLE_NEW_LEN);
      } else {
        return resample(curve, this.RESAMPLE_NEW_LEN);
      }
    }
    return curve;
  }

  void mouseReleased() {
    extending = false;

    boolean drewCurve = curve.size() > 1;
    if (drewCurve) {
      transformCurve(curve);
    }
  }

  void keyPressed() {
    if (key == 's') {
      this.savePathToJSON(this.finalCurve);
    }
  }
}
