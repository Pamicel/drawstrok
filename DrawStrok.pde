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
    if (this.curves.hasSelectedCurve()) {
      this.curves.addPointToSelectedCurve(new Vec2D(mouseX, mouseY));
    } else {
      this.curves.translate(new Vec2D(mouseX - pmouseX, mouseY - pmouseY));
    }
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
      new Vec2D(1 / this.xRatio, 1 / this.yRatio)
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
      println("selected tailCurve");
    }
    if (key == 'h') {
      this.toggleCurve("headCurve");
      println("selected headCurve");
    }
    if (key == 'y') {
      this.toggleStrok();
    }
    if (key == 'l') {
      this.init();
    }
    if (key == 'e') {
      this.curves.clearAllCurves();
      this.strok.clear();
      println("erased");
    }
    if (key == 's') {
      memory.saveCurves(
        this.curves,
        this.canvasPosition.copy().invert(),
        new Vec2D(this.xRatio, this.yRatio)
      );
    }
  }
}