import std.container;
import std.algorithm;
import std.range;
import std.math;
import common;
import std.format;
import dumbknn;

alias P2 = Point!2;
alias AABB2 = AABB!2;

struct QuadTreeNode {
    P2[] points;
    QuadTreeNode* northWest;
    QuadTreeNode* northEast;
    QuadTreeNode* southWest;
    QuadTreeNode* southEast;
    AABB2 aabb;
    bool isLeaf;
}

struct QuadTree(size_t maxPointsPerAABB) {
    QuadTreeNode* root;

    this(P2[] points) {
        this.root = buildTree(points, boundingBox!2(points));
    }

    bool ifPointIsInAABB(P2 point, AABB2 aabb) {
        return point[0] >= aabb.min[0] && point[0] <= aabb.max[0] && point[1] >= aabb.min[1] && point[1] <= aabb.max[1];
    }

    QuadTreeNode* buildTree(P2[] points, AABB2 aabb) {
        QuadTreeNode* node = new QuadTreeNode();
        node.aabb = aabb;

        if (points.length <= maxPointsPerAABB) {
            node.isLeaf = true;
            node.points = points;
            return node;
        } else {
            node.isLeaf = false;
            P2 centerPoint = getCenter(node.aabb);

            P2[] greaterPointsDividedByX = points.partitionByDimension!0(centerPoint[0]);
            writeln("greaterPointsDividedByX:");
            printPointPositions!2(greaterPointsDividedByX);
            P2[] smallerPointsDividedByX = points[0 .. $ - greaterPointsDividedByX.length];
            writeln("smallerPointsDividedByX:");
            printPointPositions!2(smallerPointsDividedByX);

            // smaller x, greater y
            auto northWestPoints = smallerPointsDividedByX.partitionByDimension!1(centerPoint[1]);
            // smaller x, smaller y
            auto southWestPoints = smallerPointsDividedByX[0 .. $ - northWestPoints.length];
            // greater x, greater y
            auto northEastPoints = greaterPointsDividedByX.partitionByDimension!1(centerPoint[1]);
            // greater x, smaller y
            auto southEastPoints = greaterPointsDividedByX[0 .. $ - northEastPoints.length];

            // smaller x, greater y
            AABB2 northWestAABB;
            northWestAABB.min = Point!2([node.aabb.min[0], centerPoint[1]]);
            northWestAABB.max = Point!2([centerPoint[0], node.aabb.max[1]]);

            // smaller x, smaller y
            AABB2 southWestAABB;
            southWestAABB.min = node.aabb.min;
            southWestAABB.max = centerPoint;

            AABB2 northEastAABB;
            northEastAABB.min = centerPoint;
            northEastAABB.max = node.aabb.max;

            AABB2 southEastAABB;
            southEastAABB.min = Point!2([centerPoint[0], node.aabb.min[1]]);
            southEastAABB.max = Point!2([node.aabb.max[0], centerPoint[1]]);

            writeln("================");
            writeln("north west aabb: ");
            writeln(northWestAABB.min[0], ",", northWestAABB.min[1], ",", northWestAABB.max[0], ",", northWestAABB.max[1]);
            writeln("north west points: ");
            printPointPositions!2(northWestPoints);
            foreach(p; northWestPoints) {
                // assert(ifPointIsInAABB(p, northWestAABB) == true);
            }
            node.northWest = buildTree(northWestPoints, northWestAABB);

            writeln("south west aabb: ");
            writeln(southWestAABB.min[0], ",", southWestAABB.min[1], ",", southWestAABB.max[0], ",", southWestAABB.max[1]);
            writeln("south west points: ");
            printPointPositions!2(southWestPoints);
            foreach(p; southWestPoints) {
                // assert(ifPointIsInAABB(p, southWestAABB) == true);
            }
            node.southWest = buildTree(southWestPoints, southWestAABB);

            writeln("north east aabb: ");
            writeln(northEastAABB.min[0], ",", northEastAABB.min[1], ",", northEastAABB.max[0], ",", northEastAABB.max[1]);
            writeln("north east points: ");
            printPointPositions!2(northEastPoints);
            foreach(p; northEastPoints) {
                // assert(ifPointIsInAABB(p, northEastAABB) == true);
            }
            node.northEast = buildTree(northEastPoints, northEastAABB);

            writeln("south east aabb: ");
            writeln(southEastAABB.min[0], ",", southEastAABB.min[1], ",", southEastAABB.max[0], ",", southEastAABB.max[1]);
            writeln("south east points: ");
            printPointPositions!2(southEastPoints);
            foreach(p; southEastPoints) {
                writeln("check if p:", p[0], "," , p[1]);
                // assert(ifPointIsInAABB(p, southEastAABB) == true);
            }
            node.southEast = buildTree(southEastPoints, southEastAABB);

            return node;
        }
    }

    P2[] rangeQuery(P2 center, float radius) {
        P2[] ret;

        void recurse(QuadTreeNode* node) {
            if (node is null) {
                return;
            }

            if (node.isLeaf) {
                foreach (const point; node.points) {
                    if (distance(center, point) <= radius) {
                        ret ~= point;
                    }
                }
            } else {
                if (circleRectangleOverlap(center, radius, node.northWest.aabb)) {
                    recurse(node.northWest);
                }
                if (circleRectangleOverlap(center, radius, node.southWest.aabb)) {
                    recurse(node.southWest);
                }
                if (circleRectangleOverlap(center, radius, node.northEast.aabb)) {
                    recurse(node.northEast);
                }
                if (circleRectangleOverlap(center, radius, node.southEast.aabb)) {
                    recurse(node.southEast);
                }
            }
        }

        recurse(root);
        return ret;
    }

    float closetDistanceInAABB(QuadTreeNode* node, P2 center) {
        float minDistance = float.infinity;

        void recurse(QuadTreeNode* currentNode) {
            if (currentNode is null) {
                return;
            }

            if (currentNode.isLeaf) {
                foreach (const point; currentNode.points) {
                    float distanceToPoint = distance(center, point);
                    minDistance = min(minDistance, distanceToPoint);
                }
            } else {
                if (circleRectangleOverlap(center, minDistance, currentNode.northWest.aabb)) {
                    recurse(currentNode.northWest);
                }
                if (circleRectangleOverlap(center, minDistance, currentNode.southWest.aabb)) {
                    recurse(currentNode.southWest);
                }
                if (circleRectangleOverlap(center, minDistance, currentNode.northEast.aabb)) {
                    recurse(currentNode.northEast);
                }
                if (circleRectangleOverlap(center, minDistance, currentNode.southEast.aabb)) {
                    recurse(currentNode.southEast);
                }
            }
        }

        recurse(node);
        return minDistance;
    }


    P2[] knnQuery(P2 center, int k) {
        auto pq = makePriorityQueue(center);

        bool checkIfHasCloserPoints(QuadTreeNode* node) {
            return closetDistanceInAABB(node, center) <= distance(pq.front(), center);
        }

        void recurse(QuadTreeNode* node) {
            if (node is null)
                return;

            if(node.isLeaf) {
                foreach (const point; node.points) {
                    pq.insert(point);
                    if(pq.length > k) {
                        pq.popFront();
                    }
                }
            } else {
                if(pq.length < k || checkIfHasCloserPoints(node.northWest)) {
                    recurse(node.northWest);
                }
                if(pq.length < k || checkIfHasCloserPoints(node.northEast)) {
                    recurse(node.northEast);
                }
                if(pq.length < k || checkIfHasCloserPoints(node.southWest)) {
                    recurse(node.southWest);
                }
                if(pq.length < k || checkIfHasCloserPoints(node.southEast)) {
                    recurse(node.southEast);
                }
            }
        }

        recurse(root);
        return pq.array;
    }
}

/*
unittest {
    // test QuadTree against DumbKNN

    auto trainingPoints = getGaussianPoints!2(1000);
    auto testingPoints = getGaussianPoints!2(100);

    auto dumb = DumbKNN!2(trainingPoints);
    auto quadTree = QuadTree!4(trainingPoints);

    foreach(testingCenter; testingPoints) {
        auto dumbRange = dumb.rangeQuery(testingCenter, 0.5);
        auto quadRange = quadTree.rangeQuery(testingCenter, 0.5);
        writeln("pass testing center for quad tree range query: ", testingCenter[0], ", ", testingCenter[1]);
        assert(quadRange.length == dumbRange.length && isSameArray(quadRange, dumbRange));
    }

    foreach(testingCenter; testingPoints) {
        auto dumbQuery = dumb.knnQuery(testingCenter, 10);
        auto quadQuery = quadTree.knnQuery(testingCenter, 10);
        assert(dumbQuery.length == quadQuery.length && isSameArray(dumbQuery, quadQuery));
    }

    trainingPoints = getUniformPoints!2(1000);
    testingPoints = getUniformPoints!2(100);

    dumb = DumbKNN!2(trainingPoints);
    quadTree = QuadTree!4(trainingPoints);

    foreach(testingCenter; testingPoints) {
        auto dumbRange = dumb.rangeQuery(testingCenter, 0.5);
        auto quadRange = quadTree.rangeQuery(testingCenter, 0.5);
        assert(quadRange.length == dumbRange.length && isSameArray(quadRange, dumbRange));
    }

    foreach(testingCenter; testingPoints) {
        auto dumbQuery = dumb.knnQuery(testingCenter, 10);
        auto quadQuery = quadTree.knnQuery(testingCenter, 10);
        assert(dumbQuery.length == quadQuery.length && isSameArray(dumbQuery, quadQuery));
    }
}
*/


unittest{
    //I'd include unitttesting code for each of your data structures to test with
    //use a small # of points and manually check that you get the answers you expect
    auto points = [Point!2([.5, .5]), Point!2([1, 1]),
    Point!2([0.75, 0.4]), Point!2([0.4, 0.74])];
    //since the points are 2D, the data structure is a DumbKNN!2
    auto quadTree = QuadTree!1(points);
    auto quadTreeRQ = quadTree.rangeQuery(Point!2([0,0]), 1);

    writeln("quadTreeRQ length: ", quadTreeRQ.length);

    auto dumbKnn = DumbKNN!2(points);
    auto dumbKnnRQ = dumbKnn.rangeQuery(Point!2([0,0]), 1);

    writeln("dumbKnnRQ length: ", dumbKnnRQ.length);
}

