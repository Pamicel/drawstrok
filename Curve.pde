class Curve {
  boolean selected = false;
  ArrayList<Vec2D> rawCurve = new ArrayList<Vec2D>();
  ArrayList<Vec2D> resampledCurve = null;

  Curve () {}

  Curve (JSONArray curveDescription) {
    this.fillFromJSONArray(curveDescription);
  }

  Curve (JSONArray curveDescription, Vec2D translation, Vec2D scale) {
    this.fillFromJSONArray(curveDescription, translation, scale);
  }

  Curve copy() {
    Curve newCurve = new Curve();
    newCurve.rawCurve = new ArrayList<Vec2D>(this.rawCurve);
    if (this.resampledCurve != null) {
      newCurve.resampledCurve = new ArrayList<Vec2D>(this.resampledCurve);
    }
    return newCurve;
  }

  private boolean isResampled() {
    return this.resampledCurve != null;
  }

  private void fillFromJSONArray(JSONArray curveDescription) {
    this.fillFromJSONArray(curveDescription, new Vec2D(0, 0), new Vec2D(1, 1));
  }

  private void fillFromJSONArray(JSONArray curveDescription, Vec2D translation, Vec2D scale) {
    for (int i = 0; i < curveDescription.size(); i++) {
      JSONObject point = curveDescription.getJSONObject(i);
      float x = (point.getFloat("x") * scale.x) + translation.x;
      float y = (point.getFloat("y") * scale.y) + translation.y;
      this.addPoint(new Vec2D(x, y));
    }
  }

  /**
   * The "most transformed curve" is either resampled curve (resampledCurve)
   * if it exists, or it is the drawn curve (rawCurve).
   */
  ArrayList<Vec2D> getMostTransformedCurve() {
    return this.isResampled() ? this.resampledCurve : this.rawCurve;
  }

  boolean isLongerThan(Curve otherCurve) {
    return this.getMostTransformedCurve().size() > otherCurve.getMostTransformedCurve().size();
  }

  boolean isEmpty() {
    return this.rawCurve == null || this.rawCurve.size() == 0;
  }

  void equaliseWith(Curve otherCurve) {
    this.resample(otherCurve.getMostTransformedCurve().size());
  }

  void select() {
    this.selected = true;
  }

  void unSelect() {
    this.selected = false;
  }

  boolean isSelected () {
    return this.selected;
  }

  JSONArray toJSONArray() {
    return this.toJSONArray(
      new Vec2D(0, 0),
      new Vec2D(1, 1)
    );
  }

  JSONArray toJSONArray(
    Vec2D translation,
    Vec2D scale
  ) {
    JSONArray values = new JSONArray();

    Vec2D position;
    for (int i = 0; i < this.rawCurve.size(); i++) {
      position = this.rawCurve.get(i);
      JSONObject point = new JSONObject();
      point.setFloat("x", (position.x + translation.x) * scale.x);
      point.setFloat("y", (position.y + translation.y) * scale.y);
      values.setJSONObject(i, point);
    }

    return values;
  }

  void addPoint(Vec2D point) {
    this.rawCurve.add(point);
  }

  void clear() { this.reset(); }

  void reset() {
    this.rawCurve.clear();
    if (this.resampledCurve != null) {
      this.resampledCurve.clear();
      this.resampledCurve = null;
    }
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