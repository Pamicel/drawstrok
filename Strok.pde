class Strok {
  Curve headCurve;
  Curve tailCurve;
  boolean hidden = false;

  private ArrayList<Vec2D> headFinalCurve;
  private ArrayList<Vec2D> tailFinalCurve;
  private int headFinalCurveSize = 0;
  private int tailFinalCurveSize = 0;
  private int nominalSize = 0;

  Strok() {}

  Strok(Curve headCurve, Curve tailCurve) {
    this.setCurves(headCurve, tailCurve);
  }

  void clear() {
    if (this.headCurve != null) {
      this.headCurve.clear();
    }
    if (this.tailCurve != null) {
      this.tailCurve.clear();
    }
    this.hidden = false;
    this.headFinalCurve = null;
    this.tailFinalCurve = null;
    this.headFinalCurveSize = 0;
    this.tailFinalCurveSize = 0;
    this.nominalSize = 0;
  }

  private void equalise(
  ) {
    this.resampleToSmallest();
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
      this.refresh();
    }
  }

  private void refresh() {
    if (this.isComplete()) {
      this.headFinalCurve = this.headCurve.getMostTransformedCurve();
      this.tailFinalCurve = this.tailCurve.getMostTransformedCurve();
      this.headFinalCurveSize = headFinalCurve.size();
      this.tailFinalCurveSize = tailFinalCurve.size();
      this.nominalSize = min(headFinalCurveSize, tailFinalCurveSize);
    }
  }

  private void drawConnections(PApplet window, color col) {
    window.push();
    window.stroke(col);
    window.strokeWeight(1);
    for (int i = 0; i < this.nominalSize; i++) {
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