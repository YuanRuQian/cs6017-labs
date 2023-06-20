import std.stdio;

import common;
import dumbknn;
import bucketknn;
import quadtree;
import kdtree;

void main()
{
    // Time QuadTree with different points per AABB
    writeln("QuadTree knnQuery with different points per AABB results");
    // Create a file to write the results
    string pointsPerAABBFilename = "QuadTreeWithDifferentPointsPerAABB.csv";
    File pointsPerAABBFile = File(pointsPerAABBFilename, "w");
    pointsPerAABBFile.writeln("numPointsPerAABB,averageTime");
    // Calculate the powers of 2 sequence from 1 to 256
    ulong[] quadTreeNumPointsSequence;
    for (int i = 0; i <= 8; ++i)
    {
        quadTreeNumPointsSequence ~= 2^^i;
    }
    foreach (numPoints; quadTreeNumPointsSequence)
    {{
        enum numTrainingPoints = 1000;
        auto trainingPoints = getGaussianPoints!2(numTrainingPoints);
        auto testingPoints = getUniformPoints!2(100);
        auto qt = QuadTree!2(trainingPoints);
        writeln("Tree with ", numPoints, " points per AABB built");
        auto sw = StopWatch(AutoStart.no);
        sw.start;
        ulong totalTime = 0;
        size_t experimentTimes = 50;
        foreach (const ref qp; testingPoints)
        {
            for (int i = 0; i < experimentTimes; ++i)
            {
                sw.start;
                qt.knnQuery(qp, 10);
                sw.stop;
                totalTime += sw.peek.total!"usecs";
                sw.reset;
            }
        }

        double averageTime = totalTime / experimentTimes / testingPoints.length;
        // Write the results to the file
        pointsPerAABBFile.writeln(numPoints, ",", averageTime);
        writeln("Average time for ", numPoints, " points: ", averageTime, " usecs");
    }}

    pointsPerAABBFile.close();

    // Time QuadTree with different K values
    writeln("QuadTree knnQuery with different K results");

    enum numPointsPerAABB = 4;

    // Create a file to write the results
    string knnFilename = "QuadTreeWithDifferentK.csv";
    File knnFile = File(knnFilename, "w");
    knnFile.writeln("K,averageTime");

    // Define different values of K
    int[] knnValues;
    for (int k = 10; k <= 100; k += 10)
    {
        knnValues ~= k;
    }

    foreach (knn; knnValues)
    {{
        auto trainingPoints = getGaussianPoints!2(1000);
        auto testingPoints = getUniformPoints!2(100);
        auto qt = QuadTree!numPointsPerAABB(trainingPoints);
        auto sw = StopWatch(AutoStart.no);
        sw.start;
        ulong totalTime = 0;
        size_t experimentTimes = 10;

        foreach (const ref qp; testingPoints)
        {
            for (int i = 0; i < experimentTimes; ++i)
            {
                sw.start;
                qt.knnQuery(qp, knn);
                sw.stop;
                totalTime += sw.peek.total!"usecs";
                sw.reset;
            }
        }

        double averageTime = totalTime / experimentTimes / testingPoints.length;
        writeln("Average time with K =", knn, ": ", averageTime, " usecs");

        // Write the results to the file
        knnFile.writeln(knn, ",", averageTime);
    }}

    knnFile.close();

    writeln("QuadTree knnQuery with different point pool size");
    string differentPointPoolResultFileName = "QuadTreeWithDifferentPointPoolSize.csv";
    File differentPointPoolResults = File(differentPointPoolResultFileName, "w");
    differentPointPoolResults.writeln("pointPoolSize,averageTime");

    // Define different values of K
    int[] poolSizes;
    for (int k = 1; k <= 10; k++)
    {
        poolSizes ~= k*1000;
    }

    foreach (trainingPoolSize ; poolSizes)
    {{
        auto trainingPoints = getGaussianPoints!2(trainingPoolSize);
        auto testingPoints = getUniformPoints!2(100);
        auto qt = QuadTree!numPointsPerAABB(trainingPoints);

        auto sw = StopWatch(AutoStart.no);
        sw.start;
        ulong totalTime = 0;
        size_t experimentTimes = 10;

        foreach (const ref qp; testingPoints)
        {
            for (int i = 0; i < experimentTimes; ++i)
            {
                sw.start;
                qt.knnQuery(qp, 10);
                sw.stop;
                totalTime += sw.peek.total!"usecs";
                sw.reset;
            }
        }

        double averageTime = totalTime / experimentTimes / testingPoints.length;
        writeln("Average time with point pool size =", trainingPoolSize, ": ", averageTime, " usecs");
        differentPointPoolResults.writeln(trainingPoolSize, ",", averageTime);
    }}

    differentPointPoolResults.close();

}
