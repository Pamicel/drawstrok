
class NamedCurves {
  Map<String, Curve> curves = new HashMap<String, Curve>();
  String selectedCurve;

  NamedCurves() {}

  NamedCurves(JSONObject descriptionObject) {
    this.fillFromJSONObject(descriptionObject);
  }

  NamedCurves(
    JSONObject descriptionObject,
    Vec2D translation,
    Vec2D scale
  ) {
    this.fillFromJSONObject(
      descriptionObject,
      translation,
      scale
    );
  }

  NamedCurves(String... curveNames) {
    // Print if not all curveNames are unique
    String[] uniqueCurveNames = Arrays.stream(curveNames).distinct().toArray(String[]::new);
    if (uniqueCurveNames.length != curveNames.length) {
      println("Warning: all curve names should be unique, duplicates are ignored.");
    }

    for (String curveName: curveNames) {
      this.addEmptyCurve(curveName);
    }
  }

  private boolean has(String curveName) {
    return this.curves.containsKey(curveName);
  }

  private void addEmptyCurve(String curveName) {
    this.addCurve(curveName, new Curve());
  }

  /**
   * Add an instantiated curve to the curves.
   * Overwrite existing curve in case of name collision.
   */
  private void addCurve(String curveName, Curve curve) {
    if (this.has(curveName)) {
      this.curves.get(curveName).clear();
      this.curves.remove(curveName);
    }
    this.curves.put(curveName, curve);
  }

  Curve get(String curveName) {
    if (this.has(curveName)) {
      return this.curves.get(curveName);
    }
    return null;
  }

  boolean isSelected(String curveName) {
    if (this.has(curveName)) {
      return this.curves.get(curveName).isSelected();
    }
    return false;
  }

  void clear() { this.reset(); }

  void reset() {
    for (Curve curve: this.curves.values()) {
      curve.clear();
    }
    this.curves.clear();
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

  void resampleAllCurves(int resampleNewLen, boolean regularResample) {
    for (Curve curve: this.curves.values()) {
      if (regularResample) {
        curve.resampleRegular(resampleNewLen);
      } else {
        curve.resample(resampleNewLen);
      }
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
    return this.toJSONObject(new Vec2D(0, 0), new Vec2D(1, 1));
  }

  JSONObject toJSONObject(
    Vec2D translation,
    Vec2D scale
  ) {
    JSONObject curveObject = new JSONObject();
    JSONArray namesArray = new JSONArray();
    JSONObject curvesDescriptionObject = new JSONObject();

    for (Map.Entry<String, Curve> entry : this.curves.entrySet()) {
      String name = entry.getKey();
      Curve curve = entry.getValue();
      namesArray.append(name);
      curveObject.setJSONArray(name, curve.toJSONArray(translation, scale));
    }

    curvesDescriptionObject.setJSONArray("names", namesArray);
    curvesDescriptionObject.setJSONObject("curves", curveObject);
    return curvesDescriptionObject;
  }

  // Cant be static, use constructor instead, idem with Curve
  private void fillFromJSONObject(JSONObject descriptionObject) {
    this.fillFromJSONObject(descriptionObject, new Vec2D(0, 0), new Vec2D(1, 1));
  }

  private void fillFromJSONObject(
    JSONObject descriptionObject,
    Vec2D translation,
    Vec2D scale
  ) {
    JSONObject curveObject = descriptionObject.getJSONObject("curves");
    JSONArray namesArray = descriptionObject.getJSONArray("names");
    for (int i = 0; i < namesArray.size(); i++) {
      String name = namesArray.getString(i);
      JSONArray curveDescription = curveObject.getJSONArray(name);
      this.addCurve(name, new Curve(curveDescription, translation, scale));
    }
  }
}