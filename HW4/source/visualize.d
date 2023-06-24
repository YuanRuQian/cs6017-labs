import std.stdio;

import common;
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

void plot2DKDTreeGraph(string dataFileName, Point!2[] points) {
    File file = File(dataFileName, "w");
    auto kdTree = KDTree!2(points);
    file.writeln("pointX,pointY,lineStartX,lineStartY,lineEndX,lineEndY,splitDim");

    // Write point x, point y, line start, and end of the split line to the file
    void recurse(KDTreeNode!2* node, AABB!2 aabb) {
        if (node == null) {
            return;
        }

        if (node.splitDim == 0) {
            file.writefln("%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f", node.point[0], node.point[1], node.point[0], aabb.min[1], node.point[0], aabb.max[1], node.splitDim);

            AABB!2 leftBoundingBox;
            leftBoundingBox.min = aabb.min;
            leftBoundingBox.max = Point!2([node.point[0], aabb.max[1]]);
            recurse(node.left, leftBoundingBox);

            AABB!2 rightBoundingBox;
            rightBoundingBox.min = Point!2([node.point[0], aabb.min[1]]);
            rightBoundingBox.max = aabb.max;
            recurse(node.right, rightBoundingBox);
        } else {
            file.writefln("%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f", node.point[0], node.point[1], aabb.min[0], node.point[1], aabb.max[0], node.point[1], node.splitDim);

            AABB!2 leftBoundingBox;
            leftBoundingBox.min = aabb.min;
            leftBoundingBox.max = Point!2([aabb.max[0], node.point[1]]);
            recurse(node.left, leftBoundingBox);

            AABB!2 rightBoundingBox;
            rightBoundingBox.min = Point!2([aabb.min[0], node.point[1]]);
            rightBoundingBox.max = aabb.max;
            recurse(node.right, rightBoundingBox);
        }
    }

    auto aabb = boundingBox!2(points);
    recurse(kdTree.root, aabb);

    file.close();
}