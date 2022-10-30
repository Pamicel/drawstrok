
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