import std.stdio;
import common;
import bucketknn;
import quadtree;
import kdtree;

// To reduce noise, tim3 several KNN queries (10, or 100) and using the average time.
size_t maxTestingTimesPerSingleTest = 51;

void time2DBucketKNNWithDifferentK(string fileName) {
    File file = File(fileName, "w");
    file.writeln("k,averageTime");

    static foreach (ki; 1..51){
        {
            auto k = ki*2;
            enum numTrainingPoints = 1000;
            auto totalTime = 0;
            foreach (testId; 1..maxTestingTimesPerSingleTest) {
                auto trainingPoints = getGaussianPoints!2(1000);
                auto testingPoints = getUniformPoints!2(100);
                auto kd = BucketKNN!2(trainingPoints, cast(int)pow(numTrainingPoints/64, 1.0/2));
                auto sw = StopWatch(AutoStart.no);
                sw.start;
                foreach (const ref qp; testingPoints){
                    kd.knnQuery(qp, k);
                }
                sw.stop;
                totalTime += sw.peek.total!"usecs";
            }
            auto averageTime = totalTime / (maxTestingTimesPerSingleTest - 1);
            file.writeln(k, ",", averageTime);
        }
    }

    file.close();

}

void time2DBucketKNNWithDifferentN(string fileName) {
    File file = File(fileName, "w");
    file.writeln("n,averageTime");

    static foreach (ni; 1..21){
        {
            auto n = ni*1000;
            auto totalTime = 0;
            foreach (testId; 1..maxTestingTimesPerSingleTest) {
                auto trainingPoints = getGaussianPoints!2(n);
                auto testingPoints = getUniformPoints!2(100);
                auto kd = BucketKNN!2(trainingPoints, cast(int)pow(n/64, 1.0/2));
                auto sw = StopWatch(AutoStart.no);
                sw.start;
                foreach (const ref qp; testingPoints){
                    kd.knnQuery(qp, 10);
                }
                sw.stop;
                totalTime += sw.peek.total!"usecs";
            }
            auto averageTime = totalTime / (maxTestingTimesPerSingleTest - 1);
            file.writeln(n, ",", averageTime);
        }
    }

    file.close();
}

void timeQuadTreeWithDifferentMaxPointsPerLeaf(string fileName) {
    File file = File(fileName, "w");
    file.writeln("maxPointsPerLeaf,averageTime");

    static foreach (mi; 1..51){
        {
            auto totalTime = 0;
            foreach (testId; 1..maxTestingTimesPerSingleTest) {
                auto trainingPoints = getGaussianPoints!2(1000);
                auto testingPoints = getUniformPoints!2(100);
                auto kd = QuadTree!mi(trainingPoints);
                auto sw = StopWatch(AutoStart.no);
                sw.start;
                foreach (const ref qp; testingPoints){
                    kd.knnQuery(qp, 10);
                }
                sw.stop;
                totalTime += sw.peek.total!"usecs";
            }
            auto averageTime = totalTime / (maxTestingTimesPerSingleTest - 1);
            file.writeln(mi, ",", averageTime);
        }
    }

    file.close();
}

void timeKDTreeWithDifferentDimension(string fileName)
{
    File file = File(fileName, "w");
    file.writeln("dimension,averageTime");

    static foreach (di; 1..8){
        {
            auto totalTime = 0;
            foreach (testId; 1..maxTestingTimesPerSingleTest) {
                auto trainingPoints = getGaussianPoints!di(1000);
                auto testingPoints = getUniformPoints!di(100);
                auto kd = KDTree!di(trainingPoints);
                auto sw = StopWatch(AutoStart.no);
                sw.start;
                foreach (const ref qp; testingPoints){
                    kd.knnQuery(qp, 10);
                }
                sw.stop;
                totalTime += sw.peek.total!"usecs";
            }
            auto averageTime = totalTime / (maxTestingTimesPerSingleTest - 1);
            file.writeln(di, ",", averageTime);
        }
    }

    file.close();
}