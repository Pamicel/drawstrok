import toxi.geom.*;
import java.util.*;
import processing.svg.*;

boolean RESAMPLE = true;
int NUMBER_OF_POINTS_FINAL = 20;
int RESAMPLE_NEW_LEN = NUMBER_OF_POINTS_FINAL;
boolean RESAMPLE_REGULAR = true;

boolean SECONDARY_MONITOR = false;
int[] CANVAS_SIZE = new int[]{500, 500};
int[] REAL_CANVAS_SIZE = new int[]{1000, 1000};
int[] DISPLAY_WIN_SIZE = new int[]{800, 800};
int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{600, -2000} : new int[]{50, 50};

SketchMemory memory;

void setup() {
  pixelDensity(2);
  new DrawWindow();
  memory = new SketchMemory(this.sketchPath(""));
  this.surface.setVisible(false);
}

void draw() {noLoop();}

class SketchMemory {
  String path;
  String variablesPath =  "data/variables.json";
  String saveCurvesPath =  "data/curves/";
  String loadCurvesPath =  "data/curves.json";

  SketchMemory(
    String path
  ) {
    this.path = path;
  }

  void loadVariables() {
    JSONObject variables = loadJSONObject(this.path + this.variablesPath);
    this.deserializeVariables(variables);
  }

  NamedCurves loadCurves(Vec2D translation, Vec2D scale) {
    JSONObject lastSaved = loadJSONObject(this.loadCurvesPath);
    String lastCurvePath = lastSaved.getString("path");
    JSONObject savedCurves = loadJSONObject(this.path + lastCurvePath);
    if (savedCurves != null) {
      return new NamedCurves(savedCurves, translation, scale);
    }
    return null;
  }

  void saveCurves(NamedCurves curves) {
    this.saveCurves(curves, new Vec2D(0, 0), new Vec2D(1, 1));
  }

  void saveCurves(NamedCurves curves, Vec2D translation, Vec2D scale) {
    JSONObject curveObject = curves.toJSONObject(translation, scale);

    String date = "" + year() + String.format("%02d", month()) + String.format("%02d", day());
    String time = String.format("%02d", hour()) + ":" + String.format("%02d", minute()) + ":" + String.format("%02d", second());
    String fileName = date + "T" + time + ".json";
    String filePath = this.saveCurvesPath + fileName;

    saveJSONObject(curveObject, this.path + filePath);

    JSONObject lastSaved = new JSONObject();
    lastSaved.setString("path", filePath);
    saveJSONObject(lastSaved, this.loadCurvesPath);

    print("saved curves");
  }

  void deserializeVariables(JSONObject variables) {
    RESAMPLE = variables.getBoolean("resample");
    RESAMPLE_REGULAR = variables.getBoolean("resampleRegular");
    RESAMPLE_NEW_LEN = variables.getInt("resampleLen");
  }
}

class DrawWindow extends PApplet {
  color WINDOW_BACKROUNG_COLOR = 0xffffffff;
  float DISPLAY_WINDOW_LINEAR_DENSITY = 1.0 / 10.0; // 1 point every N pixels
  float xRatio = float(REAL_CANVAS_SIZE[0]) / float(CANVAS_SIZE[0]);
  float yRatio = float(REAL_CANVAS_SIZE[1]) / float(CANVAS_SIZE[1]);
  int[] canvasSize = null;

  Vec2D canvasPosition = new Vec2D((DISPLAY_WIN_SIZE[0] - CANVAS_SIZE[0]) / 2, (DISPLAY_WIN_SIZE[1] - CANVAS_SIZE[1]) / 2);

  NamedCurves curves;

  final float LINEAR_DENSITY = DISPLAY_WINDOW_LINEAR_DENSITY;

  DrawWindow() {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  void settings () {
    this.size(DISPLAY_WIN_SIZE[0], DISPLAY_WIN_SIZE[1]);
  }

  void setup() {
    this.smooth();
    this.loadEverything();
    if (this.curves == null) {
      this.curves = new NamedCurves(
        "headCurve",
        "tailCurve"
      );
    }
    this.curves.selectCurve("headCurve");
    this.applyResampleToAllCurves();
    this.surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
  }

  void draw() {
    this.background(WINDOW_BACKROUNG_COLOR);
    if (this.curves.hasSelectedCurve()) {
      this.push();
      this.fill(0);
      this.textSize(20);
      this.text("\"" + this.curves.selectedCurve + "\" selected", 20, 30);
      this.pop();
    }
    this.push();
    this.noFill();
    this.stroke(0);
    this.strokeWeight(1);
    this.rect(
      this.canvasPosition.x,
      this.canvasPosition.y,
      this.width - (2 * this.canvasPosition.x),
      this.height - (2 * this.canvasPosition.y)
    );
    this.pop();
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
    this.applyResampleToSelectedCurve();
  }

  void toggleCurve(String curveName) {
    if (this.curves.isSelected(curveName)) {
      this.curves.unSelectCurve(curveName);
    } else {
      this.curves.selectCurve(curveName);
    }
  }

  void loadEverything() {
    memory.loadVariables();
    NamedCurves loadedCurves = memory.loadCurves(
      this.canvasPosition,
      new Vec2D(this.xRatio, this.yRatio)
    );
    if (loadedCurves != null) {
      if (this.curves != null) {
        this.curves.clear();
      }
      this.curves = loadedCurves;
    }
  }

  void applyResampleToAllCurves() {
    if (RESAMPLE) {
      this.curves.resampleAllCurves(RESAMPLE_NEW_LEN, RESAMPLE_REGULAR);
    }
  }

  void applyResampleToSelectedCurve() {
    if (RESAMPLE) {
      this.curves.resampleSelectedCurve(RESAMPLE_NEW_LEN, RESAMPLE_REGULAR);
    }
  }

  void keyPressed() {
    if (key == 't') {
      this.toggleCurve("tailCurve");
    }
    if (key == 'h') {
      this.toggleCurve("headCurve");
    }
    if (key == 'l') {
      this.loadEverything();
      this.applyResampleToAllCurves();
    }
    if (key == 's') {
      memory.saveCurves(
        this.curves,
        this.canvasPosition.invert(),
        new Vec2D(1 / this.xRatio, 1 / this.yRatio)
      );
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
//         return regularResample(curve, RESAMPLE_NEW_LEN);
//       } else {
//         return resample(curve, RESAMPLE_NEW_LEN);
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
