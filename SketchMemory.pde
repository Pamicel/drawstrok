
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