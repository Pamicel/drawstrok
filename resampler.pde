interface Resampler {
  static Vec2D[] curveToArray(ArrayList<Vec2D> curve) {
    int curveLen = curve.size();
    Vec2D[] arrayCurve = new Vec2D[curveLen];
    return curve.toArray(arrayCurve);
  }

  static ArrayList<Vec2D> densityResample(ArrayList<Vec2D> curve, float linearDensity) {
    float distSum = 0;
    int curveLen = curve.size();
    for (int i = 0; i < curveLen - 1; i++) {
      distSum += curve.get(i).distanceTo(curve.get(i + 1));
    }
    int resampleSize = floor(linearDensity * distSum);
    return regularResample(curve, resampleSize);
  }

  /**
  * Resample with regular-ish intervals
  */
  static ArrayList<Vec2D> regularResample (ArrayList<Vec2D> curve, int newLen) {
    int currentLen = curve.size();
    if (currentLen == 0) {
      return curve;
    }
    float maxDist = 0;
    float minDist = 0;

    Vec2D pointA = curve.get(0);
    Vec2D pointB;
    for (int i = 1; i < currentLen - 1; i++) {
      pointB = curve.get(i);
      float distance = pointA.distanceTo(pointB);
      if (minDist == 0 || distance < minDist) {
        minDist = distance;
      }
      if (distance > maxDist) {
        maxDist = distance;
      }
    }

    // If the ratio maxDist / minDist is too high, resample so as to cut longer distances
    // to hopefully have only distances shorter or equal to the current shortest distance
    int variation = floor(maxDist / minDist);
    if (variation > 1) {
      ArrayList<Vec2D> upSample = resample(curve, currentLen * variation);
      ArrayList<Vec2D> curveRegular = new ArrayList<Vec2D>();

      // only keep the points that are at least 95% of minDist away from each other
      Vec2D currentPoint, lastAddedPoint;
      try {
        curveRegular.add(upSample.get(0));
      } catch (Exception e) {
        println(curve);
        println("currentLen: "+currentLen);
        println("currentLen * variation: "+currentLen * variation);
        println(upSample);
        throw e;
      }
      for (int i = 1; i < upSample.size() - 1; i++) {
        currentPoint = upSample.get(i);
        lastAddedPoint = curveRegular.get(curveRegular.size() - 1);
        if (currentPoint.distanceTo(lastAddedPoint) >= (.99 * minDist)) {
          curveRegular.add(currentPoint.copy());
        }
      }

      curveRegular.add(upSample.get(upSample.size() - 1).copy());

      // Resample that new regularized curve
      return resample(curveRegular, newLen);
    }

    return resample(curve, newLen);
  }

  static ArrayList<Vec2D> resample (ArrayList<Vec2D> curve, int newLen) {
    if (newLen <= 1) {
      return new ArrayList<Vec2D>();
    }
    int currentLen = curve.size();
    if (currentLen == 0) {
      return curve;
    }
    // Ratio of current num of segments and desired num of segments
    float ratio = (float)(currentLen - 1) / (float)(newLen - 1);
    Vec2D[] newCurve = new Vec2D[newLen];

    float fIndex = 0, dfIndex;
    int minIndex, maxIndex;
    Vec2D maxPoint, minPoint;
    for (int i = 0; i < newLen; i++) {
      fIndex = i * ratio; // floating index
      minIndex = floor(fIndex);
      maxIndex = ceil(fIndex);

      if (minIndex > currentLen - 1) {
        maxIndex = currentLen - 1;
      }
      if (maxIndex > currentLen - 1) {
        maxIndex = currentLen - 1;
      }

      dfIndex = fIndex - minIndex; // decimal part of the floating index
      minPoint = curve.get(minIndex);
      maxPoint = curve.get(maxIndex);
      newCurve[i] = new Vec2D(
        maxPoint.x * dfIndex + minPoint.x * (1 - dfIndex),
        maxPoint.y * dfIndex + minPoint.y * (1 - dfIndex)
      );
    }
    return new ArrayList<Vec2D>(Arrays.asList(newCurve));
  }
}