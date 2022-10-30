import toxi.geom.*;
import java.util.*;
import processing.svg.*;

boolean RESAMPLE = true;
int NUMBER_OF_POINTS_FINAL = 20;

void setup() {
  pixelDensity(2);
  new DrawWindow(this.sketchPath(""));
  this.surface.setVisible(false);
}

void draw() {noLoop();}

class NamedCurves {
  Map<String, Curve> curves = new HashMap<String, Curve>();
  String selectedCurve;

  NamedCurves(String... curveNames) {
    // Print if not all curveNames are unique
    String[] uniqueCurveNames = Arrays.stream(curveNames).distinct().toArray(String[]::new);
    if (uniqueCurveNames.length != curveNames.length) {
      println("Warning: all curve names should be unique, duplicates are ignored.");
    }

    for (String curveName: curveNames) {
      this.createCurve(curveName);
    }
  }

  private boolean has(String curveName) {
    return this.curves.containsKey(curveName);
  }

  boolean isSelected(String curveName) {
    if (this.has(curveName)) {
      return this.curves.get(curveName).isSelected();
    }
    return false;
  }

  private void createCurve(String curveName) {
    this.curves.put(curveName, new Curve());
  }

  boolean hasSelectedCurve() {
    return this.selectedCurve != null;
  }

  void selectCurve(String curveName) {
    if (this.has(curveName)) {
      // unselect all curves
      this.unSelectAllCurves();
      // select the curve
      this.selectedCurve = curveName;
      this.curves.get(curveName).select();
    }
  }

  void unSelectCurve(String curveName) {
    if (this.has(curveName)) {
      this.selectedCurve = this.selectedCurve.equals(curveName) ? null : this.selectedCurve;
      this.curves.get(curveName).unSelect();
    }
  }

  void unSelectAllCurves() {
    for (Curve curve: this.curves.values()) {
      curve.unSelect();
    }
  }

  void resetSelectedCurve() {
    if (this.hasSelectedCurve()) {
      this.curves.get(this.selectedCurve).reset();
    }
  }

  void addPointToSelectedCurve(Vec2D point) {
    if (this.hasSelectedCurve()) {
      this.curves.get(this.selectedCurve).addPoint(point);
    }
  }

  void resampleSelectedCurve(int resampleNewLen, boolean regularResample) {
    if (this.hasSelectedCurve()) {
      if (regularResample) {
        this.curves.get(this.selectedCurve).resampleRegular(resampleNewLen);
      } else {
        this.curves.get(this.selectedCurve).resample(resampleNewLen);
      }
    }
  }

  void draw(PApplet window, color strokeColor) {
    for (Curve curve: this.curves.values()) {
      curve.draw(window, strokeColor);
    }
  }

  JSONObject toJSONObject() {
    JSONObject curveObject = new JSONObject();
    for (Map.Entry<String, Curve> entry : this.curves.entrySet()) {
      String name = entry.getKey();
      Curve curve = entry.getValue();
      curveObject.setJSONArray(name, curve.toJSONArray());
    }
    return curveObject;
  }
}

// class CurveTracer extends Curve {
//   CurveTracer() { super(); }

//   void draw(PApplet window) {
//     this.draw(window, 0xff000000);
//   }
// }

class Curve {
  boolean selected = false;
  ArrayList<Vec2D> rawCurve;
  ArrayList<Vec2D> resampledCurve;

  Curve () {
    this.rawCurve = new ArrayList<Vec2D>();
    this.resampledCurve = null;
  }
  Curve (ArrayList<Vec2D> initialCurve) {
    this.rawCurve = initialCurve;
  }

  void select() {
    this.selected = true;
  }

  void unSelect() {
    this.selected = false;
  }

  private boolean isResampled() {
    return this.resampledCurve != null;
  }

  boolean isSelected () {
    return this.selected;
  }

  JSONArray toJSONArray() {
    JSONArray values = new JSONArray();

    Vec2D position;
    for (int i = 0; i < this.rawCurve.size(); i++) {
      position = this.rawCurve.get(i);
      JSONObject point = new JSONObject();
      point.setFloat("x", position.x);
      point.setFloat("y", position.y);
      values.setJSONObject(i, point);
    }

    return values;
  }

  void addPoint(Vec2D point) {
    this.rawCurve.add(point);
  }

  void reset() {
    this.rawCurve.clear();
    this.resampledCurve = null;
  }

  void resample(int resampleNewLen) {
    this.resampledCurve = Resampler.resample(this.rawCurve, resampleNewLen);
  }

  void resampleRegular(int resampleNewLen) {
    this.resampledCurve = Resampler.regularResample(this.rawCurve, resampleNewLen);
  }

  void draw(PApplet window, color strokeColor) {
    this.draw(window, strokeColor, new Vec2D(0, 0), new Vec2D(1, 1));
  }

  void draw(PApplet window, color strokeColor, Vec2D translation, Vec2D scale) {
    ArrayList<Vec2D> curveToDraw = this.selected || !this.isResampled() ? this.rawCurve : this.resampledCurve;
    window.noFill();
    window.stroke(strokeColor);
    window.strokeWeight(this.selected ? 3 : 1);
    window.pushMatrix();
    window.translate(translation.x, translation.y);
    window.scale(scale.x, scale.y);
    window.beginShape();
    for (Vec2D pos: curveToDraw) {
      window.circle(pos.x, pos.y, 5);
      window.vertex(pos.x, pos.y);
    }
    window.endShape();
    window.popMatrix();
  }
}

class DrawWindow extends PApplet {
  boolean SECONDARY_MONITOR = false;
  int[] CANVAS_SIZE = new int[]{500, 500};
  int[] REAL_CANVAS_SIZE = new int[]{1000, 1000};
  int[] DISPLAY_WIN_SIZE = new int[]{1000, 1000};
  int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{600, -2000} : new int[]{50, 50};
  color WINDOW_BACKROUNG_COLOR = 0xffffffff;
  color MOUSE_STROKE_COLOR = 0xff000000;
  float DISPLAY_WINDOW_LINEAR_DENSITY = 1.0 / 10.0; // 1 point every N pixels
  float xRatio = float(REAL_CANVAS_SIZE[0]) / float(CANVAS_SIZE[0]);
  float yRatio = float(REAL_CANVAS_SIZE[1]) / float(CANVAS_SIZE[1]);
  int[] canvasSize = null;

  Vec2D canvasPosition = new Vec2D((DISPLAY_WIN_SIZE[0] - CANVAS_SIZE[0]) / 2, (DISPLAY_WIN_SIZE[1] - CANVAS_SIZE[1]) / 2);

  private String path = "";

  NamedCurves curves;

  final float LINEAR_DENSITY = DISPLAY_WINDOW_LINEAR_DENSITY;
  int RESAMPLE_NEW_LEN = NUMBER_OF_POINTS_FINAL;
  boolean RESAMPLE_REGULAR = true;

  DrawWindow(String path) {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
    this.path = path;
  }

  void settings () {
    size(DISPLAY_WIN_SIZE[0], DISPLAY_WIN_SIZE[1]);
  }

  void setup() {
    smooth();
    this.surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
    this.curves = new NamedCurves(
      "headCurve",
      "tailCurve"
    );
    this.curves.selectCurve("headCurve");
  }

  void draw() {
    this.background(WINDOW_BACKROUNG_COLOR);
    this.curves.draw(this, color(0));
  }

  // Event methods

  void mouseDragged() {
    this.curves.addPointToSelectedCurve(new Vec2D(mouseX, mouseY));
  }

  void mousePressed() {
    // reset selected curve
    this.curves.resetSelectedCurve();
    // Add point to selected curve
    curves.addPointToSelectedCurve(new Vec2D(mouseX, mouseY));
  }

  void mouseReleased() {
    if (RESAMPLE) {
      this.curves.resampleSelectedCurve(this.RESAMPLE_NEW_LEN, RESAMPLE_REGULAR);
    }
  }

  void toggleCurve(String curveName) {
    if (this.curves.isSelected(curveName)) {
      this.curves.unSelectCurve(curveName);
    } else {
      this.curves.selectCurve(curveName);
    }
  }

  void keyPressed() {
    if (key == 't') {
      this.toggleCurve("tailCurve");
    }
    if (key == 'h') {
      this.toggleCurve("headCurve");
    }
  }
}

//   DrawWindow(String path) {
//     super();
//     PApplet.runSketch(new String[]{this.getClass().getName()}, this);
//     this.path = path;
//   }

//   // JSONArray objectCurve = loadJSONArray(path + "data/" + curveName + ".json");
//   ArrayList<Vec2D> JSONArrayToCurve(JSONArray rawCurve) {
//     if (objectCurve.size() == 0) {
//       return null;
//     }
//     ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
//     for (int i = 0; i < objectCurve.size(); i++) {
//       JSONObject point = objectCurve.getJSONObject(i);
//       float x = point.getFloat("x");
//       float y = point.getFloat("y");
//       curve.add(new Vec2D(x, y));
//     }
//     return curve;
//   }

//   void loadVariables() {
//     JSONObject variables = loadJSONObject(path + "data/variables.json");
//     RESAMPLE = variables.getBoolean("resample");
//     RESAMPLE_REGULAR = variables.getBoolean("resampleRegular");
//     RESAMPLE_NEW_LEN = variables.getInt("resampleLen");
//   }

//   void settings () {
//     size(DISPLAY_WIN_SIZE[0], DISPLAY_WIN_SIZE[1]);
//   }

//   void setup() {
//     smooth();
//     loadVariables();
//     ArrayList<Vec2D> loadedCurves = loadCurves();
//     if (loadedCurve != null) {
//       finalCurve = applyResample(Resampler.curveToArray(loadedCurve));
//     }
//     this.surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
//     this.targetSurface = createGraphics(CANVAS_SIZE[0], CANVAS_SIZE[1]);
//   }

//   void draw() {
//     this.background(WINDOW_BACKROUNG_COLOR);

//     boolean isFinishedDrawing = finalCurve != null && finalCurve.length != 0;

//     push();
//     stroke(MOUSE_STROKE_COLOR);
//     strokeWeight(1);
//     if (isFinishedDrawing) {
//       fill(120);
//     } else {
//       noFill();
//     }
//     rect(
//       this.canvasPosition.x,
//       this.canvasPosition.y,
//       this.width - (2 * this.canvasPosition.x),
//       this.height - (2 * this.canvasPosition.y)
//     );
//     pop();

//     if (isFinishedDrawing) {
//       stroke(#ff0000);
//       Vec2D pos;
//       pushMatrix();
//       translate(canvasPosition.x, canvasPosition.y);
//       scale(1 / this.xRatio, 1 / this.yRatio);
//       beginShape();
//       for (int i = 0; i < finalCurve.length; i++) {
//         pos = finalCurve[i];
//         circle(pos.x, pos.y, 5);
//         vertex(pos.x, pos.y);
//       }
//       endShape();
//       popMatrix();
//     } else {
//       stroke(MOUSE_STROKE_COLOR);
//       Vec2D pos;
//       beginShape();
//       for (int i = 0; i < curves[0].size(); i++) {
//         pos = curves[0].get(i);
//         circle(pos.x, pos.y, 5);
//         vertex(pos.x, pos.y);
//       }
//       endShape();
//     }

//   }

//   // Sketch methods

//   float signedAngle(Vec2D pos) {
//     Vec2D normalVector = new Vec2D(1,0);
//     float angle = acos(pos.getNormalized().dot(normalVector));
//     if (pos.sub(normalVector).y < 0) {
//       angle = -angle;
//     }
//     return angle;
//   }

//   Vec2D[] remapCurve(Vec2D[] curve, Vec2D targetPointA, Vec2D targetPointB) {
//     Vec2D curvePointA = curve[0];
//     Vec2D curvePointB = curve[curve.length - 1];

//     Vec2D curveDirVec = curvePointB.sub(curvePointA);
//     Vec2D targetDirVec = targetPointB.sub(targetPointA);

//     float curveAngle = signedAngle(curveDirVec);
//     float targetAngle = signedAngle(targetDirVec);

//     float angle = targetAngle - curveAngle;

//     float curveLen = curveDirVec.magnitude();
//     float targetLen = targetDirVec.magnitude();

//     float scale = targetLen / curveLen;

//     Vec2D[] remaped = new Vec2D[curve.length];
//     remaped[0] = targetPointA.copy();
//     for (int i = 1; i < curve.length; i++) {
//       remaped[i] = curve[i].sub(curve[0]).scale(scale).getRotated(angle).add(targetPointA);
//     }

//     return remaped;
//   }

//   Vec2D getCurrentTranslation() {
//     return new Vec2D(this.canvasPosition.x, this.canvasPosition.y);
//   }

//   JSONArray curveToJSONArray(Vec2D[] curve) {
//     JSONArray values = new JSONArray();

//     for (int i = 0; i < curve.length; i++) {
//       JSONObject point = new JSONObject();
//       point.setFloat("x", curve[i].x);
//       point.setFloat("y", curve[i].y);
//       values.setJSONObject(i, point);
//     }

//     return values;
//   }

//   void saveCurvesToJSON(Vec2D[][] curves) {
//     JSONObject curveObject = new JSONObject();

//     curveObject.setJSONArray("headsCurve", curveToJSONArray(curves[0]));
//     curveObject.setJSONArray("tailsCurve", curveToJSONArray(curves[1]));

//     String date = "" + year() + String.format("%02d", month()) + String.format("%02d", day());
//     String time = String.format("%02d", hour()) + ":" + String.format("%02d", minute()) + ":" + String.format("%02d", second());
//     String fileName = date + "T" + time + ".json";

//     saveJSONObject(curveObject, path + "data/curves/" + fileName);
//     print("saved");
//   }

//   // Event methods

//   boolean extending = false;

//   void mouseDragged() {
//     curves[0].add(new Vec2D(mouseX, mouseY));
//   }

//   void mousePressed() {
//     finalCurve = null;
//     curves[0] = new ArrayList<Vec2D>();
//     curves[0].add(new Vec2D(mouseX, mouseY));
//   }

//   Vec2D[] translateCurve(Vec2D[] curve, Vec2D translation) {
//     Vec2D[] newCurve = new Vec2D[curve.length];
//     for (int i = 0; i < curve.length; i++) {
//       newCurve[i] = curve[i].add(translation);
//     }
//     return newCurve;
//   }

//   Vec2D[] rescaleCurve(Vec2D[] curve, float xScale, float yScale) {
//     Vec2D[] newCurve = new Vec2D[curve.length];
//     for (int i = 0; i < curve.length; i++) {
//       newCurve[i] = new Vec2D(curve[i].x * xScale, curve[i].y * yScale);
//     }
//     return newCurve;
//   }

//   void transformCurve(ArrayList<Vec2D> curve) {
//     finalCurve = Resampler.curveToArray(curve);
//     finalCurve = applyResample(finalCurve);
//     finalCurve = translateCurve(finalCurve, this.getCurrentTranslation().invert());
//     finalCurve = rescaleCurve(finalCurve, this.xRatio, this.yRatio);
//   }

//   Vec2D[] applyResample(Vec2D[] curve) {
//     if (RESAMPLE) {
//       if (RESAMPLE_REGULAR) {
//         return regularResample(curve, this.RESAMPLE_NEW_LEN);
//       } else {
//         return resample(curve, this.RESAMPLE_NEW_LEN);
//       }
//     }
//     return curve;
//   }

//   void mouseReleased() {
//     extending = false;

//     boolean drewHeadsCurve = curves[0].size() > 1;
//     if (drewHeadsCurve) {
//       transformCurve(curves[0]);
//     }
//   }

//   void keyPressed() {
//     if (key == 's') {
//       this.saveCurvesToJSON(this.finalCurve);
//     }
//   }
// }
