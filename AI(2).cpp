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

struct Node
{
    int g; 
    int h;
    int f; // heuristic: f = g + h

    int x; // position_x
    int y; // position_y
    
    Node * last_one; // last node to arrive the current node
    
    // ZERO = -20, NEG_ONE = -21, EMPTY = -22, SAVEPOINT = -23, GOAL = -24,
    // BLACK_WALL = -40, MEMBRANE = -41, BLUE_WALL = -42, RED_WALL = -43
    int type;

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
{{-40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40}, 
{-40, -22, -22, -22, -22, -22, -22, 1, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -40},
 {-40, -22, 1, 1, 1, 1, -22, 1, -22, 1, 1, 1, -22, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -22, -40},
 {-40, -22, 1, -22, -22, 1, -22, 1, -22, -22, -22, 1, -22, 1, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, 1, -22, -40},
 {-40, -22, 1, -22, 1, -22, -22, 1, 1, 1, -22, 1, -22, 1, -22, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -22, 1, -22, -40}, 
{-40, -22, -22, -22, 1, 1, -22, -22, -22, -22, -22, 1, -22, 1, -22, 1, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, 1, -22, -40}, 
{-40, 1, -22, 1, 1, -22, 1, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -22, 1, -22, -40}, 
{-40, -22, -22, 1, -22, -22, -22, -22, 1, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, 1, -22, 1, -22, -40},
 {-40, -22, 1, -22, -22, 1, 1, -22, -22, -22, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, 1, -22, 1, -22, -22, 1, 1, 1, 1, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, 1, -22, 1, -22, 1, -22, -22, -22, -22, -22, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, 1, -22, 1, -22, -22, -22, 1, 1, 1, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -22, -22, -22, -22, -22, -22, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, 1, -22, 1, -22, 1, 1, -22, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, 1, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, 1, -22, 1, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -22, -22, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, 1, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, -22, 1, -22, 1, 1, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, 1, -22, 1, -22, -22, -22, -22, 1, 1, -22, -22, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -24, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, -22, 1, 1, 1, 1, -22, -22, -22, 1, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, 1, -22, -22, -22, -22, 1, 1, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -22, -22, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, 1, -22, 1, 1, -22, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, 1, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, -22, -22, -22, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -22, -22, -22, -22, -22, -22, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -22, -22, -22, -22, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40},
 {-40, -22, 1, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40},
 {-40, -22, 1, -22, -22, -22, -22, -22, -22, 1, -22, 1, -22, 1, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, 1, -22, 1, -22, 1, -22, 1, -22, -40},
 {-40, -22, 1, -22, 1, 1, 1, 1, 1, 1, -22, 1, -22, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, 1, -22, -40},
 {-40, 1, 1, -22, 1, -22, -22, -22, -22, -22, -22, 1, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, 1, -22, 1, -22, 1, -22, -40},
 {-40, -22, -22, -22, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -22, 1, -22, 1, -22, -40}, 
{-40, -41, -41, -22, 1, -41, -41, 0, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, -22, 1, -22, -22, -22, -40},
 {-40, -22, -22, -40, -40, -22, -22, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40, -40}};


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


vector<Node> findPath(std::vector<std::vector<int>> stuff_id, int tile_push_limit, pair<int, int> start, pair<int, int> end)
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
            while (local_node->x != start.second || local_node->y != start.first)
            {
                cout<<"local: "<<local_node->y<<" - "<< local_node->x<<endl;
                ans.push_back(*local_node);

                local_node = local_node->last_one;
            }
            cout<<"no!";
            std::reverse(ans.begin(), ans.end());
            return ans;
        }

        // loop the neighbour nood in four directions
        int neighbour_node_x;
        int neighbour_node_y;
        //cout<<"local: "<<local_node.y<<" - "<< local_node.x<<endl;

        // +- x
        for (int i = -1; i < 2; i+=2)
        {
            neighbour_node_x = local_node->x + i;
            neighbour_node_y = local_node->y;

            // check vaild column index or not 
            if (neighbour_node_x > 39 || neighbour_node_x < 0)
                continue;
            if (local_node->level[neighbour_node_y][neighbour_node_x] != -22 && local_node->level[neighbour_node_y][neighbour_node_x] != -24)
                continue;

            // create a new level layout base on new neighbour node
            std::vector<std::vector<int>> level_copy;
            level_copy = local_node->level;

            level_copy[neighbour_node_y][neighbour_node_x - i] = -22;
            level_copy[neighbour_node_y][neighbour_node_x] = 0;
            
            if (levels[level_copy])
                continue;
            //cout<<"yes!! "<<endl;
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
            //cout<<"x: "<<neighbour_node_x<<" y: "<<neighbour_node_y<<endl;
            nodes_queue.push(neighbour_node);
            
        }
        // +- y
        for (int i = -1; i < 2; i+=2)
        {
            neighbour_node_y = local_node->y + i;
            neighbour_node_x = local_node->x;

            // check vaild column index or not 
            if (neighbour_node_y > 29 || neighbour_node_y < 0)
                continue;
            if (local_node->level[neighbour_node_y][neighbour_node_x] != -22 && local_node->level[neighbour_node_y][neighbour_node_x] != -24)
                continue;

            // create a new level layout base on new neighbour node
            std::vector<std::vector<int>> level_copy;
            level_copy = local_node->level;

            level_copy[neighbour_node_y - i][neighbour_node_x] = -22;
            level_copy[neighbour_node_y][neighbour_node_x] = 0;
            
           if (levels[level_copy])
                continue;
            //cout<<"yes!! "<<endl;
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
            //cout<<"x: "<<neighbour_node_x<<" y: "<<neighbour_node_y<<endl;
            nodes_queue.push(neighbour_node);
        }

    
    }

    return ans;
}

int main() {

    vector<Node> a = findPath(stuff_ids, 1, make_pair(28, 8), make_pair(10, 34));
    cout<<"size: "<<a.size()<<endl;
    for (int i = 0; i < a.size(); i++)
    {
        cout<<a[i].y<<", "<<a[i].x<<endl;
    }

    return 0;
}