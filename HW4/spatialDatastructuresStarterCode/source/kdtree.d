import common;
import std.stdio, std.algorithm, std.math, std.random;
import dumbknn;

struct KDTreeNode(size_t dim) {
    Point!dim point;
    size_t splitDim = -1;
    KDTreeNode!dim* left, right;
}

struct KDTree(size_t dim) {

    KDTreeNode!dim* root;

    this(Point!dim[] points) {
        KDTreeNode!dim[] KDNodes = new KDTreeNode!dim[](points.length);
        for (size_t i = 0; i < points.length; i++) {
            KDNodes[i] = KDTreeNode!dim(points[i]);
        }
        root = buildTree!(dim, 0)(KDNodes);
    }

    // QuickSelect imitation
    KDTreeNode!dim* findMedianNode(size_t splitDim, size_t dim)(KDTreeNode!dim[] nodes) {
        auto start = nodes.ptr;
        auto end = &nodes[$ - 1] + 1;

        if (end <= start)
            return null;
        if (end == start + 1)
            return start;

        auto mid = start + (end - start) / 2;

        while (true) {
            double pivot = mid.point[splitDim];

            swap(mid.point, (end - 1).point);
            auto store = start;
            foreach (currentPtr; start .. end) {
                if (currentPtr.point[splitDim] < pivot) {
                    if (currentPtr != store)
                        swap(currentPtr.point, store.point);
                    store++;
                }
            }
            swap(store.point, (end - 1).point);

            if (store.point[splitDim] == mid.point[splitDim])
                return mid;

            if (store > mid)
                end = store;
            else
                start = store;
        }
    }


    KDTreeNode!dim* buildTree(size_t dim, size_t splitDim)(KDTreeNode!dim[] nodes) {
        if (nodes.length == 0)
            return null;

        auto pivot = findMedianNode!(splitDim, dim)(nodes);
        if (pivot != null) {
            enum nextSplitDim = (splitDim + 1) % dim;
            immutable size_t nPos = pivot - nodes.ptr;
            pivot.splitDim = splitDim;
            pivot.left = buildTree!(dim, nextSplitDim)(nodes[0 .. nPos]);
            pivot.right = buildTree!(dim, nextSplitDim)(nodes[nPos + 1 .. $]);
        }

        return pivot;
    }

    Point!dim[] rangeQuery(Point!dim center, float radius) {
        Point!dim[] ret;

        void recurse(KDTreeNode!dim* node) {
            if (node is null)
                return;

            float distanceSq = pow(distance(node.point, center), 2);

            if (distanceSq <= radius * radius) {
                ret ~= node.point;
            }

            size_t splitDim = node.splitDim;

            float distToSplit = center[splitDim] - node.point[splitDim];

            if (distToSplit < 0) {
                recurse(node.left);
                if (distToSplit * distToSplit <= radius * radius)
                    recurse(node.right);
            } else {
                recurse(node.right);
                if (distToSplit * distToSplit <= radius * radius)
                    recurse(node.left);
            }
        }

        recurse(root);
        return ret;
    }

    Point!dim[] knnQuery(Point!dim center, int k) {
        auto pq = makePriorityQueue(center);

        float getDistanceToSplit(KDTreeNode!dim* node) {
            return center[node.splitDim] - node.point[node.splitDim];
        }

        void recurse(KDTreeNode!dim* node) {
            if (node is null)
                return;

            pq.insert(node.point);

            if (pq.length > k) {
                pq.removeFront();
            }

            float distToSplit = getDistanceToSplit(node);
            float distPQFront = distance(pq.front(), center);

            if (distToSplit < 0) {
                recurse(node.left);
                if (pow(distToSplit, 2) <= pow(distPQFront, 2))
                    recurse(node.right);
            } else {
                recurse(node.right);
                if (pow(distToSplit, 2) <= pow(distPQFront, 2))
                    recurse(node.left);
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
    auto quadTree = KDTree!2(trainingPoints);

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
    quadTree = KDTree!2(trainingPoints);

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

