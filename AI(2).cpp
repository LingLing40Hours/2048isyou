#include <iostream>
#include <math.h>
#include <vector>
#include <algorithm>
#include <queue>
#include <unordered_set>
#include <stdbool.h>
#include <unordered_map>
using namespace std;



// ****************** global value ******************

/*
enum StuffId {
	RED_WALL = -3,
	BLUE_WALL = -2,
	BLACK_WALL = -1,
	ZERO = 1,
	NEG_ONE = 31,
	POW_OFFSET = 16,
	EMPTY = 0,
	MEMBRANE = 32,
	SAVEPOINT = 64,
	GOAL = 96,
};
*/

struct Node
{
    int g; 
    int h;
    int f; // heuristic: f = g + h

    int x; // position_x
    int y; // position_y
    
    Node * last_one; // last node to arrive the current node
    
    int type; // stuff id;

    std::vector<std::vector<int>> level;
};

// Custom hash function for 2D int vector
struct Vector2dHash {
    std::size_t operator()(const std::vector<std::vector<int>>& arr) const {
        std::size_t hash_value = 0;
        for (const auto& row : arr) {
            for (int num : row) {
                hash_value ^= std::hash<int>{}(num) + 0x9e3779b9 + (hash_value << 6) + (hash_value >> 2);
            }
        }
        return hash_value;
    }
};

// Custom equality comparison function for 2D int arrays
struct VectorEqual {
    bool operator()(const std::vector<std::vector<int>>& arr1, const std::vector<std::vector<int>>& arr2) const {
        return arr1 == arr2;
    }
};

std::unordered_map<std::vector<std::vector<int>>, bool, Vector2dHash, VectorEqual> levels;

std::vector<std::vector<int>> stuff_ids =
/*
{{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
 {-1, 0, 0, 0, 0, 0, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1}, 
 {-1, 0, -2, -2, -2, -2, 0, -2, 0, -2, -2, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -1}, 
 {-1, 0, -2, 0, 0, -2, 0, -2, 0, 0, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -1},
{-1, 0, -2, 0, -2, 0, 0, -2, -2, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -1},
{-1, 0, 0, 0, -2, -2, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -1},
   {-1, -2, 0, -2, -2, 0, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -1},
    {-1, 0, 0, -2, 0, 0, 0, 0, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -1}, 
    {-1, 0, -2, 0, 0, -2, -2, 0, 0, 0, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -1}, 
    {-1, 0, -2, 0, -2, 0, 0, -2, -2, -2, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -1}, 
    {-1, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
    {-1, 0, -2, 0, -2, 0, 0, 0, -2, -2, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1},
     {-1, 0, -2, 0, -2, 0, -2, -2, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
     {-1, 0, -2, 0, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
     {-1, 0, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1},
      {-1, 0, 0, -2, 0, -2, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
      {-1, -2, 0, -2, 0, 0, 0, 0, -2, -2, 0, 0, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
      {-1, 0, 0, -2, -2, -2, -2, 0, 0, 0, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
      {-1, 0, -2, 0, 0, 0, 0, -2, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
      {-1, 0, -2, 0, -2, -2, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
      {-1, 0, 0, 0, 0, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
      {-1, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
      {-1, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
      {-1, 0, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1},
{-1, 0, -2, 0, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -1},
{16, 32, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -1},
{0, 32, 0, 0, -2, 32, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, 0, 0, -1}, 
{-1, -1, -1, -1, -1, 96, 96, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}};
*/

{
{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
{-1, 0, 0, 0, 0, 0, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1}, 
{-1, 0, -2, -2, -2, -2, 0, -2, 0, -2, -2, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -1}, 
{-1, 0, -2, 0, 0, -2, 0, -2, 0, 0, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -1},
{-1, 0, -2, 0, -2, 0, 0, -2, -2, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -1},
{-1, 0, 0, 0, -2, -2, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -1},
{-1, -2, 0, -2, -2, 0, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -1},
{-1, 0, 0, -2, 0, 0, 0, 0, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, 0, -2, -2, 0, 0, 0, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, -2, 0, 0, -2, -2, -2, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, -2, 0, 0, 0, -2, -2, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1},
{-1, 0, -2, 0, -2, 0, -2, -2, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 18, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1},
{-1, 0, 0, -2, 0, -2, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 18, 1, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, -2, 0, -2, 0, 0, 0, 0, -2, -2, 0, 0, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 18, 17, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, 0, -2, -2, -2, -2, 0, 0, 0, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, 17, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, 0, 0, 0, -2, -2, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, -2, -2, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, 0, 0, 0, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -2, 0, -1},
{-1, 0, -2, 0, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -2, 0, -1}, 
{-1, 0, -2, 0, -2, 0, 0, 0, 0, 0, 0, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, -2, 0, -2, 0, -1},
{16, 32, -2, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 0, -2, 0, -2, 0, -1},
{0, 32, 0, 0, -2, 32, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, 0, 0, 0, -1}, 
{-1, -1, -1, -1, -1, 96, 96, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}};


struct Nodes_queue
{
    bool operator()(Node* first_node, Node* second_node)
    {
        return first_node->f > second_node->f;
    }
};

// ****************** helper function ******************

int heuristic(pair<int, int> start, pair<int, int> end)
{
    return abs(start.first - end.first) + abs(start.second - end.second);
}


vector<Node> findPath(std::vector<std::vector<int>> stuff_id, int tile_push_limit, pair<int, int> start, pair<int, int> end, bool is_player)
{
    vector<Node> ans; // ans

    //cout<<"P: "<<node_player.y<<", "<<node_player.x<<endl;
    //cout<<"G: "<<node_goal.y<<", "<<node_goal.x<<endl;
    
    
    Node start_node;
    Node* local_node = & start_node;
    local_node->g = 0;
    local_node->h = heuristic(start, end);
    local_node->f = start_node.g + start_node.h;
    local_node->y = start.first;
    local_node->x = start.second;
    local_node->last_one = NULL;
    local_node->type = stuff_id[start.first][start.second];
    local_node->level = stuff_id;

    std::priority_queue<Node*, std::vector<Node*>, Nodes_queue> nodes_queue;
    nodes_queue.push(local_node);
    
    while (nodes_queue.size() > 0)
    {
        //cout<<nodes_queue.size()<<endl;
        cout<<levels.size()<<endl;
        /*Node* node_to_delete = nodes_queue.top();
        
        if (node_to_delete->y != start.first || node_to_delete->x != start.second)
        {
            // copy new node
            *local_node = *node_to_delete;
            // delete new node
            //delete node_to_delete;
        }
        */
        // not go backwards
        local_node = nodes_queue.top();
        nodes_queue.pop();

        
        // first time reach the goal
        if (local_node->x == end.second && local_node->y == end.first)
        {
            cout<<"yes"<<endl;
            while (local_node->x != start.second || local_node->y != start.first)
            {
                //cout<<"local: "<<local_node->y<<" - "<< local_node->x<<endl;
                ans.push_back(*local_node);

                local_node = local_node->last_one;
            }
            cout<<"no!"<<endl;
            std::reverse(ans.begin(), ans.end());
            return ans;
        }

        // loop the neighbour nood in four directions
        int neighbour_node_x;
        int neighbour_node_y;
        int neighbour_node_type;

        cout<<"local: "<<local_node->y<<" - "<< local_node->x<<endl;
        
        // +- x
        for (int delta_x = -1; delta_x < 2; delta_x += 2)
        {
            // create a new level layout base on new neighbour node
            std::vector<std::vector<int>> level_copy;
            level_copy = local_node->level;
            
            neighbour_node_x = local_node->x + delta_x;
            neighbour_node_y = local_node->y;
            neighbour_node_type = local_node->level[neighbour_node_y][neighbour_node_x];

            // check vaild column index or not 
            // within the level window
            if (neighbour_node_x >= stuff_id[0].size() || neighbour_node_x < 0)
                continue;
            // can not move in walls
            if (neighbour_node_type == -40 || 
                neighbour_node_type == -42 ||
                neighbour_node_type == -43)
                continue;

            

            int current_x;
            int current_y;
            int current_type;
            int next_x;
            int next_y;
            int next_type;

            bool wall_encounter = false;
            int merge_counter;
            bool merge_happen = false;
            bool regular_shift = false;

            // detect any merge in the direction of pushing
            for (merge_counter = 0; merge_counter <= tile_push_limit; merge_counter++)
            {
                current_x = local_node->x + delta_x * merge_counter;
                current_y = local_node->y;              
                current_type = local_node->level[current_y][current_x];

                next_x = current_x + delta_x;
                next_y = current_y;
                next_type = local_node->level[next_y][next_x];
                
                // walls
                if (next_type == -3 || next_type == -2 || next_type == -1)
                {
                    wall_encounter = true;
                    break;
                }    

                // tiles merge
                if (current_type == next_type || next_type == 1)
                {
                    merge_happen = true;
                    break;
                }

                // empty or save point
                if (next_type == 0 || next_type == 64)
                {
                    merge_happen = true;
                    regular_shift = true;
                    break;
                }

                // membrane or goal
                if ((next_type == 32 || next_type == 96) && merge_counter == 0)
                {
                    merge_happen = true;
                    regular_shift = true;
                    break;
                }

            }
            
            if (wall_encounter)
            {
                continue;
            }
            
            // make new level
            if (merge_happen)
            {
                // shift all tiles before the merge position
                for (int i = 0; i < merge_counter; i++)
                {
                    level_copy[current_y][local_node->x + merge_counter - i] = level_copy[current_y][local_node->x + merge_counter - (i + 1)];
                }
                level_copy[current_y][local_node->x] = 0;
                
                if (!regular_shift)
                    // merge
                    level_copy[next_y][next_x] = (next_type == 1) ? current_type : current_type + 1;
                else
                    level_copy[next_y][next_x] = current_type;
            }

            
            if (levels[level_copy])
            {
                cout<<"yes?? "<<endl;
                continue;
            }
            
            levels[level_copy] = true;

            Node* neighbour_node = new Node;

            
            neighbour_node->level = level_copy;

            neighbour_node->g = local_node->g + 1;
            neighbour_node->h = heuristic(make_pair(neighbour_node_y, neighbour_node_x), end);
            neighbour_node->f = neighbour_node->g + neighbour_node->h;

            neighbour_node->y = neighbour_node_y;
            neighbour_node->x = neighbour_node_x;
            
            neighbour_node->last_one = local_node;
            neighbour_node->type = level_copy[neighbour_node_y][neighbour_node_x];
            //cout<<"x: "<<neighbour_node_x<<" y: "<<neighbour_node_y<<" Cur type: "<<local_node->type<<" Nei type: "<<neighbour_node->type<<endl;
            nodes_queue.push(neighbour_node);
            
        }
        // +- y
        for (int delta_y = -1; delta_y < 2; delta_y += 2)
        {
            // create a new level layout base on new neighbour node
            std::vector<std::vector<int>> level_copy;
            level_copy = local_node->level;

            neighbour_node_x = local_node->x;
            neighbour_node_y = local_node->y + delta_y;
            neighbour_node_type = local_node->level[neighbour_node_y][neighbour_node_x];

            // check vaild column index or not 
            // within the level window
            if (neighbour_node_y >= stuff_id.size() || neighbour_node_y < 0)
                continue;
            // can not move in walls
            if (neighbour_node_type == -40 || 
                neighbour_node_type == -42 ||
                neighbour_node_type == -43)
                continue;

            int current_x;
            int current_y;
            int current_type;
            int next_x;
            int next_y;
            int next_type;

            bool wall_encounter = false;
            int merge_counter;
            bool merge_happen = false;
            bool regular_shift = false;


            // detect any merge in the direction of pushing
            for (merge_counter = 0; merge_counter <= tile_push_limit; merge_counter++)
            {
                current_x = local_node->x;
                current_y = local_node->y + delta_y * merge_counter;              
                current_type = local_node->level[current_y][current_x];

                next_x = current_x;
                next_y = current_y + delta_y;
                next_type = local_node->level[next_y][next_x];
                
                // walls
                if (next_type == -3 || next_type == -2 || next_type == -1)
                {
                    wall_encounter = true;
                    break;
                }    

                // tiles merge
                if (current_type == next_type || next_type == 1)
                {
                    merge_happen = true;
                    break;
                }

                // empty or save point
                if (next_type == 0 || next_type == 64)
                {
                    merge_happen = true;
                    regular_shift = true;
                    break;
                }

                // membrane or goal
                if ((next_type == 32 || next_type == 96) && merge_counter == 0)
                {
                    merge_happen = true;
                    regular_shift = true;
                    break;
                }

            }
            
           if (wall_encounter)
            {
                continue;
            }
            
            // make new level
            if (merge_happen)
            {
                // shift all tiles before the merge position
                for (int i = 0; i < merge_counter; i++)
                {
                    level_copy[local_node->y + merge_counter - i][current_x] = level_copy[local_node->y + merge_counter - (i + 1)][current_x];
                }
                level_copy[local_node->y][current_x] = 0;
                
                if (!regular_shift)
                    // merge
                    level_copy[next_y][next_x] = (next_type == 1) ? current_type : current_type + 1;
                else
                    level_copy[next_y][next_x] = current_type;
            }

            if (levels[level_copy])
            {
                cout<<"yes!! "<<endl;
                continue;
            }
            levels[level_copy] = true;
            
            // update neighbour node information and push it into nodes_queue
            Node* neighbour_node = new Node;
            
            neighbour_node->level = level_copy;

            neighbour_node->g = local_node->g + 1;
            neighbour_node->h = heuristic(make_pair(neighbour_node_y, neighbour_node_x), end);
            neighbour_node->f = neighbour_node->g + neighbour_node->h;

            neighbour_node->y = neighbour_node_y;
            neighbour_node->x = neighbour_node_x;
            
            neighbour_node->last_one = local_node;
            neighbour_node->type = level_copy[neighbour_node_y][neighbour_node_x];
            //cout<<"x: "<<neighbour_node_x<<" y: "<<neighbour_node_y<<" Cur type: "<<local_node->type<<" Nei type: "<<neighbour_node->type<<endl;
            nodes_queue.push(neighbour_node);
        }

    
    }

    return ans;
}

int main() {

    vector<Node> a = findPath(stuff_ids, 1, make_pair(27, 0), make_pair(29, 6), true);
    cout<<"size: "<<a.size()<<endl;
    for (int i = 0; i < a.size(); i++)
    {
        cout<<a[i].y<<", "<<a[i].x<<endl;
    }

    return 0;
}
