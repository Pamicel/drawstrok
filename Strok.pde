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