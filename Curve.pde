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