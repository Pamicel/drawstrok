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

class Strok {
  Curve headCurve;
  Curve tailCurve;
  boolean hidden = false;

  Strok() {}

  Strok(Curve headCurve, Curve tailCurve) {
    this.setCurves(headCurve, tailCurve);
  }

  private void equalise(
  ) {
    if (this.isComplete()) {
      this.resampleToSmallest();
    }
  }

  private boolean isComplete() {
    return (
      this.headCurve != null &&
      this.tailCurve != null &&
      !this.headCurve.isEmpty() &&
      !this.tailCurve.isEmpty()
    );
  }

  private void resampleToSmallest() {
    if (this.isComplete()) {
      // If the curves don't have the same length
      // Resample to the smallest
      if (tailCurve.isLongerThan(headCurve)) {
        this.tailCurve.equaliseWith(headCurve);
      } else if (headCurve.isLongerThan(tailCurve)) {
        this.headCurve.equaliseWith(tailCurve);
      }
    }
  }

  private void drawConnections(PApplet window, color col) {
    window.push();
    window.stroke(col);
    window.strokeWeight(1);
    ArrayList<Vec2D> headFinalCurve = this.headCurve.getMostTransformedCurve();
    ArrayList<Vec2D> tailFinalCurve = this.tailCurve.getMostTransformedCurve();
    int headFinalCurveSize = headFinalCurve.size();
    int tailFinalCurveSize = tailFinalCurve.size();
    for (int i = 0; i < min(headFinalCurveSize, tailFinalCurveSize); i++) {
      Vec2D headPos = headFinalCurve.get(i);
      Vec2D tailPos = tailFinalCurve.get(i);
      window.line(headPos.x, headPos.y, tailPos.x, tailPos.y);
    }
    window.pop();
  }

  void setCurves(Curve headCurve, Curve tailCurve) {
    if (headCurve != null) {
      if (this.headCurve != null) { this.headCurve.clear(); }
      this.headCurve = headCurve.copy();
    }
    if (tailCurve != null) {
      if (this.tailCurve != null) { this.tailCurve.clear(); }
      this.tailCurve = tailCurve.copy();
    }
    this.equalise();
  }

  void hide() {
    this.hidden = true;
  }
  void show() {
    this.hidden = false;
  }

  void draw(PApplet window, color col) {
    if (this.isComplete() && !this.hidden) {
      this.headCurve.draw(window, col);
      this.tailCurve.draw(window, col);
      this.drawConnections(window, col);
    }
  }
}

class SketchMemory {
  String path;
  String variablesPath =  "data/variables.json";
  String saveCurvesPath =  "data/curves/";
  String lastSavedFile =  "data/curves/lastSaved.json";

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
    JSONObject lastSaved = loadJSONObject(this.lastSavedFile);
    println(lastSaved);
    if (lastSaved == null) {
      return null;
    }
    String lastCurvePath = lastSaved.getString("path");
    if (lastCurvePath == null) {
      return null;
    }
    JSONObject savedCurves = loadJSONObject(this.path + lastCurvePath);
    if (savedCurves == null) {
      return null;
    }
    return new NamedCurves(savedCurves, translation, scale);
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
    saveJSONObject(lastSaved, this.lastSavedFile);

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
  Strok strok = new Strok();

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
    this.init();
    this.surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
  }

  void draw() {
    this.background(WINDOW_BACKROUNG_COLOR);
    //
    this.push();
    this.fill(0);
    this.textSize(20);
    if (this.curves.hasSelectedCurve()) {
      this.text("Curve \"" + this.curves.selectedCurve + "\"", 20, 30);
    } else {
      this.text("Use H or T to select and draw a curve", 20, 30);
    }
    if (this.strok.hidden) {
      this.text("Use Y to show Strok", 20, 60);
    } else {
      this.text("Use Y to hide Strok", 20, 60);
    }
    this.pop();
    //
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
    this.strok.draw(this, color(255, 0, 0));
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
    this.strok.setCurves(
      this.curves.get("headCurve"),
      this.curves.get("tailCurve")
    );
  }

  void toggleCurve(String curveName) {
    if (this.curves.isSelected(curveName)) {
      this.curves.unSelectCurve(curveName);
    } else {
      this.curves.selectCurve(curveName);
    }
  }

  void toggleStrok() {
    if (this.strok.hidden) {
      this.strok.show();
    } else {
      this.strok.hide();
    }
  }

  void init() {
    memory.loadVariables();
    String curveToSelect = null;
    NamedCurves loadedCurves = memory.loadCurves(
      this.canvasPosition,
      new Vec2D(this.xRatio, this.yRatio)
    );
    if (loadedCurves != null) {
      if (this.curves != null) {
        // Save the selected curve name so that we can keep it selected.
        if (this.curves.hasSelectedCurve()) {
          curveToSelect = this.curves.selectedCurve;
        }
        this.curves.clear();
      }
      this.curves = loadedCurves;
    } else {
      this.curves = new NamedCurves(
        "headCurve",
        "tailCurve"
      );
    }
    if (curveToSelect != null) {
      this.curves.selectCurve(curveToSelect);
    }
    this.applyResampleToAllCurves();
    this.strok.setCurves(
      this.curves.get("headCurve"),
      this.curves.get("tailCurve")
    );
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
    if (key == 'y') {
      this.toggleStrok();
    }
    if (key == 'l') {
      this.init();
    }
    if (key == 's') {
      memory.saveCurves(
        this.curves,
        this.canvasPosition.copy().invert(),
        new Vec2D(1 / this.xRatio, 1 / this.yRatio)
      );
    }
  }
}