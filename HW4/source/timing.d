//import common;
//import quadtree;
//
//void timingKDTreeWithDifferentPointsLimitInBoundingBox() {
//    void singleTest(Point!2[] testingPoints, string fileName) {
//        size_t maxTestId = 100;
//
//        File file = File(fileName, "w");
//        file.writeln("maxPointsPerBoundingBox,timing");
//
//        foreach (size_t i; 1 .. 21) {
//            auto totalDuration = 0;
//            auto maxPointsPerBoundingBox = i * 5;
//
//            for (size_t testId = 0; testId < maxTestId; ++testId) {
//                auto quadTree = QuadTree!maxPointsPerBoundingBox(testingPoints);
//                auto sw = StopWatch(AutoStart.no);
//                sw.start;
//                foreach (const ref qp; testingPoints) {
//                    quadTree.knnQuery(qp, 10);
//                }
//                sw.stop;
//
//                auto duration = sw.peek.total!"usecs";
//                totalDuration += duration;
//            }
//
//            auto averageDuration = totalDuration / maxTestId;
//            file.writeln(maxPointsPerBoundingBox, ",", averageDuration);
//        }
//
//        file.close();
//    }
//
//    auto gaussianPoints = getGaussianPoints!2(1000);
//    singleTest(gaussianPoints, "KDTreeWithDifferentPointsLimitInBoundingBoxGaussianPoints.csv");
//
//    auto uniformPoints = getUniformPoints!2(1000);
//    singleTest(uniformPoints, "KDTreeWithDifferentPointsLimitInBoundingBoxUniformPoints.csv");
//}
