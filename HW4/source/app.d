import std.stdio;

import common;
import visualize;
import timing;

void main()
{
    // visualize quad tree
    // plotQuadTreeGraph("QuadTreeGaussianPoints.csv", "QuadTreeGaussianRects.csv",getGaussianPoints!2(800));
    // plotQuadTreeGraph("QuadTreeUniformPoints.csv", "QuadTreeUniformRects.csv", getUniformPoints!2(800));

    // visualize 2D KD tree
    // plot2DKDTreeGraph("2DKDTreeGaussian.csv", getGaussianPoints!2(200));
    // plot2DKDTreeGraph("2DKDTreeUniform.csv",getUniformPoints!2(200));

    // start timinig experiments

    time2DBucketKNNWithDifferentK("2DBucketKNNWithDifferentK.csv");

    // time2DBucketKNNWithDifferentN("2DBucketKNNWithDifferentN.csv");

    // timeQuadTreeWithDifferentMaxPointsPerLeaf("QuadTreeWithDifferentMaxPointsPerLeaf.csv");

    // timeKDTreeWithDifferentDimension("KDTreeWithDifferentDimension.csv");
}
