import std.stdio;

import common;
import dumbknn;
import bucketknn;
import quadtree;
import kdtree;

void plotQuadTreeGraph(string pointsFileName, string rectsFileName, Point!2[] points) {
    File pointsFile = File(pointsFileName, "w");
    File rectsFile = File(rectsFileName, "w");

    pointsFile.writeln("pointX,pointY");
    rectsFile.writeln("rectCenterX,rectCenterY,rectWidth,rectHeight");

    auto quadTree = QuadTree!2(points);

    void recurse(QuadTreeNode* node) {
        if(node == null) {
            return ;
        }

        auto rectCenter = getCenter(node.aabb);
        auto rectWidth = node.aabb.max[0] - node.aabb.min[0];
        auto rectHeight = node.aabb.max[1] - node.aabb.min[1];
        rectsFile.writeln(rectCenter[0], ",", rectCenter[1], ",",rectWidth, ",", rectHeight);

        if(node.isLeaf) {
            foreach(point; node.points) {
                pointsFile.writeln(point[0], ",", point[1]);
            }
        } else {
            recurse(node.northWest);
            recurse(node.southWest);
            recurse(node.northEast);
            recurse(node.southEast);
        }
    }

    recurse(quadTree.root);

    pointsFile.close();
    rectsFile.close();
}

void main()
{
    // visualize quad tree
    plotQuadTreeGraph("QuadTreeGaussianPoints.csv", "QuadTreeGaussianRects.csv",getGaussianPoints!2(100));
    plotQuadTreeGraph("QuadTreeUniformPoints.csv", "QuadTreeUniformRects.csv", getUniformPoints!2(100));
}
