import 'dart:math';
import 'dart:collection';
import 'package:rive_core/math/aabb.dart';

// Inspired from Box2D Dynamic Tree:
// https://github.com/behdad/box2d/blob/master/Box2D/Box2D/Collision/b2DynamicTree.h

const int NullNode = -1;
// const int AABBExtension = 10;
const double AABBMultiplier = 2.0;

typedef bool QueryCallback<T>(int id, T userData);

class TreeNode<T> {
  int next = 0;
  int child1 = NullNode;
  int child2 = NullNode;
  AABB _aabb = AABB();
  int height = -1;
  T userData;

  TreeNode();

  AABB get aabb {
    return _aabb;
  }

  bool get isLeaf {
    return child1 == NullNode;
  }

  int get parent {
    return next;
  }

  set parent(n) {
    next = n;
  }
}

class AABBTree<T> {
  final int padding;
  int _root = NullNode;
  int _capacity = 0;
  int _nodeCount = 0;
  List<TreeNode> _nodes = [];
  int _freeNode = 0;

  AABBTree({this.padding = 10}) {
    _allocateNodes();
  }

  clear() {
    _root = NullNode;
    _capacity = 0;
    _nodeCount = 0;
    _nodes = [];
    _freeNode = 0;
    _allocateNodes();
  }

  _allocateNodes() {
    List<TreeNode> list = _nodes;
    _freeNode = _nodeCount;

    if (_capacity == 0) {
      _capacity = 16;
    } else {
      _capacity *= 2;
    }
    int count = _capacity;
    for (int i = _nodeCount; i < count; i++) {
      TreeNode<T> node = TreeNode<T>();
      node.next = list.length + 1;
      list.add(node);
    }
    list[list.length - 1].next = NullNode;
  }

  int _allocateNode() {
    if (_freeNode == NullNode) {
      _allocateNodes();
    }

    int nodeId = _freeNode;
    TreeNode<T> node = _nodes[nodeId];
    _freeNode = node.next;
    node.parent = NullNode;
    node.child1 = NullNode;
    node.child2 = NullNode;
    node.height = 0;
    node.userData = null;
    _nodeCount++;
    return nodeId;
  }

  _disposeNode(nodeId) {
    if (nodeId < 0 || nodeId >= _capacity) {
      throw RangeError.range(nodeId, 0, _capacity, 'NodeID', 'Out of bounds!');
    }
    if (_nodeCount <= 0) {
      throw StateError('Node count is not valid');
    }

    TreeNode<T> node = _nodes[nodeId];
    node.next = _freeNode;
    node.userData = null;
    node.height = -1;
    _freeNode = nodeId;
    _nodeCount--;
  }

  int createProxy(AABB aabb, T userData) {
    int proxyId = _allocateNode();
    TreeNode<T> node = _nodes[proxyId];
    node.aabb[0] = aabb[0] - padding;
    node.aabb[1] = aabb[1] - padding;
    node.aabb[2] = aabb[2] + padding;
    node.aabb[3] = aabb[3] + padding;
    node.userData = userData;
    node.height = 0;

    insertLeaf(proxyId);

    return proxyId;
  }

  destroyProxy(int proxyId) {
    if (proxyId < 0 || proxyId >= _capacity) {
      throw RangeError.range(
          proxyId, 0, _capacity, 'proxyId', 'Out of bounds!');
    }

    TreeNode<T> node = _nodes[proxyId];
    if (!node.isLeaf) {
      throw StateError('Node is not a leaf!');
    }

    removeLeaf(proxyId);
    _disposeNode(proxyId);
  }

  bool placeProxy(int proxyId, AABB aabb) {
    if (proxyId == null || proxyId < 0 || proxyId >= _capacity) {
      throw RangeError.range(
          proxyId, 0, _capacity, 'proxyId', 'Out of bounds!');
    }

    TreeNode<T> node = _nodes[proxyId];
    if (!node.isLeaf) {
      throw StateError('Node is not a leaf!');
    }

    if (AABB.contains(node.aabb, aabb)) {
      return false;
    }

    removeLeaf(proxyId);

    AABB extended = AABB.clone(aabb);
    extended[0] = aabb[0] - padding;
    extended[1] = aabb[1] - padding;
    extended[2] = aabb[2] + padding;
    extended[3] = aabb[3] + padding;
    AABB.copy(node.aabb, extended);

    insertLeaf(proxyId);
    return true;
  }

  bool moveProxy(int proxyId, AABB aabb, AABB displacement) {
    if (proxyId < 0 || proxyId >= _capacity) {
      throw RangeError.range(
          proxyId, 0, _capacity, 'proxyId', 'Out of bounds!');
    }

    TreeNode<T> node = _nodes[proxyId];
    if (!node.isLeaf) {
      throw StateError('Node is not a leaf!');
    }

    if (AABB.contains(node.aabb, aabb)) {
      return false;
    }

    removeLeaf(proxyId);

    AABB extended = AABB.clone(aabb);
    extended[0] = aabb[0] - padding;
    extended[1] = aabb[1] - padding;
    extended[2] = aabb[2] + padding;
    extended[3] = aabb[3] + padding;

    double dx = AABBMultiplier * displacement[0];
    double dy = AABBMultiplier * displacement[1];

    if (dx < 0.0) {
      extended[0] += dx;
    } else {
      extended[2] += dx;
    }

    if (dy < 0.0) {
      extended[1] += dy;
    } else {
      extended[3] += dy;
    }

    AABB.copy(node.aabb, extended);

    insertLeaf(proxyId);
    return true;
  }

  insertLeaf(int leaf) {
    List<TreeNode> nodes = _nodes;

    if (_root == NullNode) {
      _root = leaf;
      nodes[_root].parent = NullNode;
      return;
    }

    // Find the best sibling for this node
    AABB leafAABB = nodes[leaf].aabb;
    int index = _root;

    while (nodes[index].isLeaf == false) {
      int child1 = nodes[index].child1;
      int child2 = nodes[index].child2;

      double area = AABB.perimeter(nodes[index].aabb);

      AABB combinedAABB = AABB.combine(AABB(), nodes[index].aabb, leafAABB);
      double combinedArea = AABB.perimeter(combinedAABB);

      // Cost of creating a parent for this node and the leaf
      double cost = 2.0 * combinedArea;

      // Min cost of pushing the leaf further down the tree
      double inheritanceCost = 2.0 * (combinedArea - area);

      // Cost of descending into child1
      double cost1;
      if (nodes[child1].isLeaf) {
        AABB aabb = AABB.combine(AABB(), leafAABB, nodes[child1].aabb);
        cost1 = AABB.perimeter(aabb) + inheritanceCost;
      } else {
        AABB aabb = AABB.combine(AABB(), leafAABB, nodes[child1].aabb);
        double oldArea = AABB.perimeter(nodes[child1].aabb);
        double newArea = AABB.perimeter(aabb);
        cost1 = (newArea - oldArea) + inheritanceCost;
      }

      double cost2;
      if (nodes[child2].isLeaf) {
        AABB aabb = AABB.combine(AABB(), leafAABB, nodes[child2].aabb);
        cost2 = AABB.perimeter(aabb) + inheritanceCost;
      } else {
        AABB aabb = AABB.combine(AABB(), leafAABB, nodes[child2].aabb);
        double oldArea = AABB.perimeter(nodes[child2].aabb);
        double newArea = AABB.perimeter(aabb);
        cost2 = (newArea - oldArea) + inheritanceCost;
      }

      // Descend according to the min cost
      if (cost < cost1 && cost < cost2) {
        break;
      }

      // Descend
      if (cost1 < cost2) {
        index = child1;
      } else {
        index = child2;
      }
    }

    int sibling = index;

    // Create parent
    int oldParent = nodes[sibling].parent;
    int newParent = _allocateNode();
    nodes[newParent].parent = oldParent;
    nodes[newParent].userData = null;
    AABB.combine(nodes[newParent].aabb, leafAABB, nodes[sibling].aabb);
    nodes[newParent].height = nodes[sibling].height + 1;

    if (oldParent != NullNode) {
      // The sibling was not the root
      if (nodes[oldParent].child1 == sibling) {
        nodes[oldParent].child1 = newParent;
      } else {
        nodes[oldParent].child2 = newParent;
      }

      nodes[newParent].child1 = sibling;
      nodes[newParent].child2 = leaf;
      nodes[sibling].parent = newParent;
      nodes[leaf].parent = newParent;
    } else {
      // The sibling was the root
      nodes[newParent].child1 = sibling;
      nodes[newParent].child2 = leaf;
      nodes[sibling].parent = newParent;
      nodes[leaf].parent = newParent;
      _root = newParent;
    }

    // Walk back up the tree fixing heights and AABBs
    index = nodes[leaf].parent;
    while (index != NullNode) {
      index = _balance(index);

      int child1 = nodes[index].child1;
      int child2 = nodes[index].child2;

      if (child1 == NullNode) {
        throw StateError('Child1 is NULL!');
      }
      if (child2 == NullNode) {
        throw StateError('Child2 is NULL!');
      }

      nodes[index].height = 1 + max(nodes[child1].height, nodes[child2].height);
      AABB.combine(nodes[index].aabb, nodes[child1].aabb, nodes[child2].aabb);

      index = nodes[index].parent;
    }
  }

  removeLeaf(int leaf) {
    if (leaf == _root) {
      _root = NullNode;
      return;
    }

    List<TreeNode> nodes = _nodes;

    int parent = nodes[leaf].parent;
    int grandParent = nodes[parent].parent;
    int sibling;

    if (nodes[parent].child1 == leaf) {
      sibling = nodes[parent].child2;
    } else {
      sibling = nodes[parent].child1;
    }

    if (grandParent != NullNode) {
      // Destroy parent and connect sibling to grandParent
      if (nodes[grandParent].child1 == parent) {
        nodes[grandParent].child1 = sibling;
      } else {
        nodes[grandParent].child2 = sibling;
      }

      nodes[sibling].parent = grandParent;
      _disposeNode(parent);

      // Adjust ancestor bounds

      int index = grandParent;
      while (index != NullNode) {
        index = _balance(index);

        int child1 = nodes[index].child1;
        int child2 = nodes[index].child2;

        AABB.combine(nodes[index].aabb, nodes[child1].aabb, nodes[child2].aabb);
        nodes[index].height =
            1 + max(nodes[child1].height, nodes[child2].height);

        index = nodes[index].parent;
      }
    } else {
      _root = sibling;
      nodes[sibling].parent = NullNode;
      _disposeNode(parent);
    }
  }

  // Perform a left or right rotation if node A is imbalanced
  // Returns the root index
  int _balance(int iA) {
    if (iA == NullNode) {
      throw StateError('iA should not be Null!');
    }

    List<TreeNode> nodes = _nodes;
    TreeNode<T> A = nodes[iA];
    if (A.isLeaf || A.height < 2) {
      return iA;
    }

    int iB = A.child1;
    int iC = A.child2;

    if (iB < 0 || iB >= _capacity) {
      throw RangeError.range(iB, 0, _capacity, 'iB', 'Out of bounds!');
    }
    if (iC < 0 || iC >= _capacity) {
      throw RangeError.range(iC, 0, _capacity, 'iC', 'Out of bounds!');
    }

    TreeNode<T> B = nodes[iB];
    TreeNode<T> C = nodes[iC];

    int balance = C.height - B.height;

    // Rotate C up
    if (balance > 1) {
      int iF = C.child1;
      int iG = C.child2;
      TreeNode<T> F = nodes[iF];
      TreeNode<T> G = nodes[iG];

      if (iF < 0 || iF >= _capacity) {
        throw RangeError.range(iF, 0, _capacity, 'iF', 'Out of bounds!');
      }
      if (iG < 0 || iG >= _capacity) {
        throw RangeError.range(iG, 0, _capacity, 'iG', 'Out of bounds!');
      }

      // Swap A and C
      C.child1 = iA;
      C.parent = A.parent;
      A.parent = iC;

      // A's old parent should point to C
      if (C.parent != NullNode) {
        if (nodes[C.parent].child1 == iA) {
          nodes[C.parent].child1 = iC;
        } else {
          if (nodes[C.parent].child2 != iA) {
            throw StateError('Bad child2');
          }
          nodes[C.parent].child2 = iC;
        }
      } else {
        _root = iC;
      }

      // Rotate
      if (F.height > G.height) {
        C.child2 = iF;
        A.child2 = iG;
        G.parent = iA;
        AABB.combine(A.aabb, B.aabb, G.aabb);
        AABB.combine(C.aabb, A.aabb, F.aabb);

        A.height = 1 + max(B.height, G.height);
        C.height = 1 + max(A.height, F.height);
      } else {
        C.child2 = iG;
        A.child2 = iF;
        F.parent = iA;
        AABB.combine(A.aabb, B.aabb, F.aabb);
        AABB.combine(C.aabb, A.aabb, G.aabb);

        A.height = 1 + max(B.height, F.height);
        C.height = 1 + max(A.height, G.height);
      }

      return iC;
    }

    // Rotate B up
    if (balance < -1) {
      int iD = B.child1;
      int iE = B.child2;
      TreeNode<T> D = nodes[iD];
      TreeNode<T> E = nodes[iE];

      if (iD < 0 || iD >= _capacity) {
        throw RangeError.range(iD, 0, _capacity, 'iD', 'Out of bounds!');
      }
      if (iE < 0 || iE >= _capacity) {
        throw RangeError.range(iE, 0, _capacity, 'iE', 'Out of bounds!');
      }

      // Swap A and B
      B.child1 = iA;
      B.parent = A.parent;
      A.parent = iB;

      // A's old parent should point to B
      if (B.parent != NullNode) {
        if (nodes[B.parent].child1 == iA) {
          nodes[B.parent].child1 = iB;
        } else {
          if (nodes[B.parent].child2 != iA) {
            throw StateError('Bad child2, expected equal iA: $iA');
          }
          nodes[B.parent].child2 = iB;
        }
      } else {
        _root = iB;
      }

      // Rotate
      if (D.height > E.height) {
        B.child2 = iD;
        A.child1 = iE;
        E.parent = iA;
        AABB.combine(A.aabb, C.aabb, E.aabb);
        AABB.combine(B.aabb, A.aabb, D.aabb);

        A.height = 1 + max(C.height, E.height);
        B.height = 1 + max(A.height, D.height);
      } else {
        B.child2 = iE;
        A.child1 = iD;
        D.parent = iA;
        AABB.combine(A.aabb, C.aabb, D.aabb);
        AABB.combine(B.aabb, A.aabb, E.aabb);

        A.height = 1 + max(C.height, D.height);
        B.height = 1 + max(A.height, E.height);
      }

      return iB;
    }

    return iA;
  }

  int getHeight() {
    if (_root == NullNode) {
      return 0;
    }

    return _nodes[_root].height;
  }

  double getAreaRatio() {
    if (_root == NullNode) {
      return 0.0;
    }

    List<TreeNode> nodes = _nodes;
    TreeNode<T> root = nodes[_root];
    double rootArea = AABB.perimeter(root.aabb);

    double totalArea = 0.0;
    int capacity = _capacity;
    for (int i = 0; i < capacity; i++) {
      TreeNode<T> node = nodes[i];
      if (node.height < 0) {
        continue;
      }

      totalArea += AABB.perimeter(node.aabb);
    }

    return totalArea / rootArea;
  }

  // Compute the height of a subtree
  int computeHeight(int nodeId) {
    if (nodeId == null) {
      nodeId = _root;
    }

    if (nodeId < 0 || nodeId >= _capacity) {
      throw RangeError.range(nodeId, 0, _capacity, 'nodeId', 'Out of bounds!');
    }
    TreeNode<T> node = _nodes[nodeId];

    if (node.isLeaf) {
      return 0;
    }

    int height1 = computeHeight(node.child1);
    int height2 = computeHeight(node.child2);
    return 1 + max(height1, height2);
  }

  validateStructure(int index) {
    if (index == NullNode) {
      return;
    }

    List<TreeNode> nodes = _nodes;
    if (index == _root) {
      if (nodes[index].parent != NullNode) {
        throw StateError('Expected parent to be null!');
      }
    }

    TreeNode<T> node = nodes[index];
    int child1 = node.child1;
    int child2 = node.child2;

    if (node.isLeaf) {
      if (child1 != NullNode) {
        throw StateError('Expected child1 to be null!');
      }
      if (child2 != NullNode) {
        throw StateError('Expected child2 to be null!');
      }
      if (node.height != 0) {
        throw StateError('Expected node\'s height to be 0!');
      }
      return;
    }

    if (child1 < 0 || child1 >= _capacity) {
      throw RangeError.range(child1, 0, _capacity, 'child1', 'Out of bounds!');
    }
    if (child2 < 0 || child2 >= _capacity) {
      throw RangeError.range(child2, 0, _capacity, 'child2', 'Out of bounds!');
    }

    if (nodes[child1].parent != index) {
      throw StateError('Expected child1 parent to be $index');
    }
    if (nodes[child2].parent != index) {
      throw StateError('Expected child2 parent to be $index');
    }

    validateStructure(child1);
    validateStructure(child2);
  }

  validateMetrics(int index) {
    if (index == NullNode) {
      return;
    }

    List<TreeNode> nodes = _nodes;
    TreeNode<T> node = nodes[index];

    int child1 = node.child1;
    int child2 = node.child2;

    if (node.isLeaf) {
      if (child1 != NullNode) {
        throw StateError('Expected child1 to be null!');
      }
      if (child2 != NullNode) {
        throw StateError('Expected child2 to be null!');
      }
      if (node.height != 0) {
        throw StateError('Expected node\'s height to be 0!');
      }
      return;
    }

    if (child1 < 0 || child1 >= _capacity) {
      throw RangeError.range(child1, 0, _capacity, 'child1', 'Out of bounds!');
    }
    if (child2 < 0 || child2 >= _capacity) {
      throw RangeError.range(child2, 0, _capacity, 'child2', 'Out of bounds!');
    }

    int height1 = nodes[child1].height;
    int height2 = nodes[child2].height;
    int height;
    height = 1 + max(height1, height2);

    if (node.height != height) {
      throw StateError('Expected node\'s height to be $height');
    }

    AABB aabb = AABB.combine(AABB(), nodes[child1].aabb, nodes[child2].aabb);

    if (aabb[0] != node.aabb[0] || aabb[1] != node.aabb[1]) {
      throw StateError('Lower Bound is not equal!');
    }
    if (aabb[2] != node.aabb[2] || aabb[3] != node.aabb[3]) {
      throw StateError('Upper Bound is not equal!');
    }

    validateMetrics(child1);
    validateMetrics(child2);
  }

  void validate() {
    validateStructure(_root);
    validateMetrics(_root);

    int freeCount = 0;
    int freeIndex = _freeNode;
    while (freeIndex != NullNode) {
      if (freeIndex < 0 || freeIndex >= _capacity) {
        throw RangeError.range(
            freeIndex, 0, _capacity, 'freeIndex', 'Out of bounds!');
      }
      freeIndex = _nodes[freeIndex].next;
      ++freeCount;
    }

    if (getHeight() != computeHeight(null)) {
      throw StateError('Expected height to match computed height.');
    }

    if (_nodeCount + freeCount != _capacity) {
      throw AssertionError(
          'Expected node count + free count to equal capactiy!');
    }
  }

  getMaxBalance() {
    int maxBalance = 0;
    int capacity = _capacity;
    List<TreeNode> nodes = _nodes;
    for (int i = 0; i < capacity; i++) {
      TreeNode<T> node = nodes[i];
      if (node.height < 1) {
        continue;
      }

      if (node.isLeaf) {
        throw StateError('Expected node not to be a leaf!');
      }

      int child1 = node.child1;
      int child2 = node.child2;
      int balance = (nodes[child2].height - nodes[child1].height).abs();
      maxBalance = max(maxBalance, balance);
    }

    return maxBalance;
  }

  T getUserdata(int proxyId) {
    return _nodes[proxyId].userData;
  }

  AABB getFatAABB(int proxyId) {
    return _nodes[proxyId].aabb;
  }

  all(QueryCallback callback) {
    List<TreeNode> nodes = _nodes;
    ListQueue stack = ListQueue();
    stack.addLast(_root);

    while (stack.length > 0) {
      int nodeId = stack.removeLast();
      if (nodeId == NullNode) {
        continue;
      }

      TreeNode<T> node = nodes[nodeId];

      if (node.isLeaf) {
        bool proceed = callback(nodeId, node.userData);
        if (!proceed) {
          return;
        }
      } else {
        stack.addLast(node.child1);
        stack.addLast(node.child2);
      }
    }
  }

  query(AABB aabb, QueryCallback<T> callback) {
    List<TreeNode> nodes = _nodes;
    ListQueue stack = ListQueue();
    stack.addLast(_root);

    while (stack.length > 0) {
      int nodeId = stack.removeLast();
      if (nodeId == NullNode) {
        continue;
      }

      TreeNode<T> node = nodes[nodeId];

      if (AABB.testOverlap(node.aabb, aabb)) {
        if (node.isLeaf) {
          bool proceed = callback(nodeId, node.userData);
          if (proceed == false) {
            return;
          }
        } else {
          stack.addLast(node.child1);
          stack.addLast(node.child2);
        }
      }
    }
  }
}
