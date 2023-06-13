import std.stdio;

import common;
import dumbknn;
import bucketknn;
//import your files here

void main()
{

    //because dim is a "compile time parameter" we have to use "static foreach"
    //to loop through all the dimensions we want to test.
    //the {{ are necessary because this block basically gets copy/pasted with
    //dim filled in with 1, 2, 3, ... 7.  The second set of { lets us reuse
    //variable names.
    writeln("dumbKNN results");
    static foreach(dim; 1..8){{
        //get points of the appropriate dimension
        auto trainingPoints = getGaussianPoints!dim(1000);
        auto testingPoints = getUniformPoints!dim(100);
        auto kd = DumbKNN!dim(trainingPoints);
        writeln("tree of dimension ", dim, " built");
        auto sw = StopWatch(AutoStart.no);
        sw.start; //start my stopwatch
        foreach(const ref qp; testingPoints){
            kd.knnQuery(qp, 10);
        }
        sw.stop;
        writeln(dim, sw.peek.total!"usecs"); //output the time elapsed in microseconds
        //NOTE, I SOMETIMES GOT TOTALLY BOGUS TIMES WHEN TESTING WITH DMD
        //WHEN YOU TEST WITH LDC, YOU SHOULD GET ACCURATE TIMING INFO...
    }}


    writeln("BucketKNN results");
    //Same tests for the BucketKNN
    static foreach(dim; 1..8){{
        //get points of the appropriate dimension
        enum numTrainingPoints = 1000;
        auto trainingPoints = getGaussianPoints!dim(numTrainingPoints);
        auto testingPoints = getUniformPoints!dim(100);
        auto kd = BucketKNN!dim(trainingPoints, cast(int)pow(numTrainingPoints/64, 1.0/dim)); //rough estimate to get 64 points per cell on average
        writeln("tree of dimension ", dim, " built");
        auto sw = StopWatch(AutoStart.no);
        sw.start; //start my stopwatch
        foreach(const ref qp; testingPoints){
            kd.knnQuery(qp, 10);
        }
        sw.stop;
        writeln(dim, sw.peek.total!"usecs"); //output the time elapsed in microseconds
        //NOTE, I SOMETIMES GOT TOTALLY BOGUS TIMES WHEN TESTING WITH DMD
        //WHEN YOU TEST WITH LDC, YOU SHOULD GET ACCURATE TIMING INFO...
    }}


}
