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

    //bool ifPointIsInAABB(P2 point, AABB2 aabb) {
    //    return point[0] >= aabb.min[0] && point[0] <= aabb.max[0] && point[1] >= aabb.min[1] && point[1] <= aabb.max[1];
    //}

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
            printPointPositions!2(greaterPointsDividedByX);
            P2[] smallerPointsDividedByX = points[0 .. $ - greaterPointsDividedByX.length];
            printPointPositions!2(smallerPointsDividedByX);

            auto northWestPoints = smallerPointsDividedByX.partitionByDimension!1(centerPoint[1]);
            auto southWestPoints = smallerPointsDividedByX[0 .. $ - northWestPoints.length];
            auto northEastPoints = greaterPointsDividedByX.partitionByDimension!1(centerPoint[1]);
            auto southEastPoints = greaterPointsDividedByX[0 .. $ - northEastPoints.length];

            AABB2 northWestAABB;
            northWestAABB.min = Point!2([node.aabb.min[0], centerPoint[1]]);
            northWestAABB.max = Point!2([centerPoint[0], node.aabb.max[1]]);

            AABB2 southWestAABB;
            southWestAABB.min = node.aabb.min;
            southWestAABB.max = centerPoint;

            AABB2 northEastAABB;
            northEastAABB.min = centerPoint;
            northEastAABB.max = node.aabb.max;

            AABB2 southEastAABB;
            southEastAABB.min = Point!2([centerPoint[0], node.aabb.min[1]]);
            southEastAABB.max = Point!2([node.aabb.max[0], centerPoint[1]]);
            
            node.northWest = buildTree(northWestPoints, northWestAABB);
            node.southWest = buildTree(southWestPoints, southWestAABB);
            node.northEast = buildTree(northEastPoints, northEastAABB);
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


    P2[] knnQuery(P2 center, int k) {
        auto pq = makePriorityQueue(center);

        bool checkIfPossibleHasCloserPoints(QuadTreeNode* node) {
            auto greatestDistanceInPQ = distance(pq.front(), center);
            auto centerDistanceToAABBMinX = abs(node.aabb.min[0] - center[0]);
            auto centerDistanceToAABBMaxX = abs(node.aabb.max[0] - center[0]);
            auto centerDistanceToAABBMinY = abs(node.aabb.min[1] - center[1]);
            auto centerDistanceToAABBMaxY = abs(node.aabb.max[1] - center[1]);
            auto minDistance = [centerDistanceToAABBMinX, centerDistanceToAABBMaxX, centerDistanceToAABBMinY, centerDistanceToAABBMaxY].minElement;
            return greatestDistanceInPQ >= minDistance;
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
                if(pq.length < k || checkIfPossibleHasCloserPoints(node.northWest)) {
                    recurse(node.northWest);
                }
                if(pq.length < k || checkIfPossibleHasCloserPoints(node.northEast)) {
                    recurse(node.northEast);
                }
                if(pq.length < k || checkIfPossibleHasCloserPoints(node.southWest)) {
                    recurse(node.southWest);
                }
                if(pq.length < k || checkIfPossibleHasCloserPoints(node.southEast)) {
                    recurse(node.southEast);
                }
            }
        }

        recurse(root);
        return pq.array;
    }
}


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
