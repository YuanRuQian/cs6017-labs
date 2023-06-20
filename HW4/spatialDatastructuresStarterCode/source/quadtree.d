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
    private QuadTreeNode* root;

    this(P2[] points) {
        this.root = buildTree(points);
    }

    QuadTreeNode* buildTree(P2[] points) {
        QuadTreeNode* node = new QuadTreeNode();
        node.aabb = boundingBox!2(points);

        if (points.length <= maxPointsPerAABB) {
            node.isLeaf = true;
            node.points = points;
            return node;
        } else {
            node.isLeaf = false;
            P2 centerNode = getCenter(node.aabb);

            P2[] greaterPointsDividedByX = points.partitionByDimension!0(centerNode[0]);
            P2[] smallerPointsDividedByX = points[0 .. $ - greaterPointsDividedByX.length];

            auto northWestPoints = smallerPointsDividedByX.partitionByDimension!1(centerNode[1]);
            auto southWestPoints = smallerPointsDividedByX[0 .. $ - northWestPoints.length];
            auto northEastPoints = greaterPointsDividedByX.partitionByDimension!1(centerNode[1]);
            auto southEastPoints = greaterPointsDividedByX[0 .. $ - northEastPoints.length];

            node.northWest = buildTree(northWestPoints);
            node.southWest = buildTree(southWestPoints);
            node.northEast = buildTree(northEastPoints);
            node.southEast = buildTree(southEastPoints);

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

unittest {
    // test QuadTree against DumbKNN

    auto trainingPoints = getGaussianPoints!2(1000);
    auto testingPoints = getGaussianPoints!2(100);

    auto dumb = DumbKNN!2(trainingPoints);
    auto quadTree = QuadTree!4(trainingPoints);

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

