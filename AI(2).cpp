#include <iostream>
#include <math.h>
#include <vector>
#include <algorithm>
#include <queue>
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
};
std::vector<std::vector<Node>> Nodes; 

int stuff_id[30][40] =
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
    bool operator()(Node first_node, Node second_node)
    {
        return first_node.f > second_node.f;
    }
};

// ****************** helper function ******************

void Nodes_clear(int stuff_id[30][40])
{   
    Nodes.resize(30);
    for (int row_counter = 0; row_counter < 30; ++row_counter)
    {
        
        Nodes[row_counter].resize(40);
        for (int column_counter = 0; column_counter < 40; ++column_counter)
        {

            
            Nodes[row_counter][column_counter].f = 999;
            Nodes[row_counter][column_counter].g = 999;
            Nodes[row_counter][column_counter].h = 0;

            Nodes[row_counter][column_counter].y = row_counter;
            Nodes[row_counter][column_counter].x = column_counter;

            Nodes[row_counter][column_counter].last_one = NULL;

            Nodes[row_counter][column_counter].type = stuff_id[row_counter][column_counter];
        }
        
    }
}

// return the player node and goal node
std::pair<Node, Node> findStartAndEndPos(int stuff_id[30][40])
{
    Node node_player;
    Node node_goal;

    for (int row_counter = 0; row_counter < 30; ++row_counter)
    {
        for (int column_counter = 0; column_counter < 40; ++column_counter)
        {
            if (Nodes[row_counter][column_counter].type == 0)
            {
                node_player = Nodes[row_counter][column_counter];
            }
            else if (Nodes[row_counter][column_counter].type == -24)
            {
                node_goal = Nodes[row_counter][column_counter];
            }

        }
    }

    return std::make_pair(node_player, node_goal);
}


int heuristic(Node first_node, Node second_node)
{
    return abs(first_node.x - second_node.x) + abs(first_node.y - second_node.y);
}


vector<Node> findPath(int stuff_id[30][40])
{
    vector<Node> ans; // ans
    
    Nodes_clear(stuff_id);
    
    
    std::pair<Node, Node> nodes_pair = findStartAndEndPos(stuff_id);

    
    Node node_player = nodes_pair.first;
    Node node_goal = nodes_pair.second;

    cout<<"P: "<<node_player.y<<", "<<node_player.x<<endl;
    cout<<"G: "<<node_goal.y<<", "<<node_goal.x<<endl;
    
    Nodes[node_player.y][node_player.x].g = 0;
    
    Nodes[node_player.y][node_player.x].h = heuristic(node_player, node_goal);
    Nodes[node_player.y][node_player.x].f = Nodes[node_player.y][node_player.x].g + Nodes[node_player.y][node_player.x].h;

    std::priority_queue<Node, std::vector<Node>, Nodes_queue> nodes_queue;
    nodes_queue.push(Nodes[node_player.y][node_player.x]);
    
    while (nodes_queue.size() > 0)
    {
        
        Node local_node = nodes_queue.top();
        // not go backwards
        nodes_queue.pop();

        // first time reach the goal
        if (local_node.x == node_goal.x && local_node.y == node_goal.y)
        {
            while (local_node.x != node_player.x || local_node.y != node_player.y)
            {
                ans.push_back(local_node);

                local_node = *(local_node.last_one);
            }

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
            neighbour_node_x = local_node.x + i;
            neighbour_node_y = local_node.y;
            //cout<<"x: "<<neighbour_node_x<<" y: "<<neighbour_node_y<<endl;

            // check vaild column index or not 
            if (neighbour_node_x > 39 || neighbour_node_x < 0)
                continue;
            if (Nodes[neighbour_node_y][neighbour_node_x].type != -22 && Nodes[neighbour_node_y][neighbour_node_x].type != -24)
                continue;

            // update neighbour node information and push it into nodes_queue
            if (Nodes[neighbour_node_y][neighbour_node_x].g > (local_node.g + 1))
            {
                Nodes[neighbour_node_y][neighbour_node_x].g = local_node.g + 1;
                Nodes[neighbour_node_y][neighbour_node_x].h = heuristic(Nodes[neighbour_node_y][neighbour_node_x], node_goal);
                Nodes[neighbour_node_y][neighbour_node_x].f = Nodes[neighbour_node_y][neighbour_node_x].g + 
                                                                    Nodes[neighbour_node_y][neighbour_node_x].h;
                Nodes[neighbour_node_y][neighbour_node_x].last_one = &(Nodes[local_node.y][local_node.x]);
                nodes_queue.push(Nodes[neighbour_node_y][neighbour_node_x]);
            } 
        }
        // +- y
        for (int i = -1; i < 2; i+=2)
        {
            neighbour_node_y = local_node.y + i;
            neighbour_node_x = local_node.x;

            // check vaild column index or not 
            if (neighbour_node_y > 29 || neighbour_node_y < 0)
                continue;
            if (Nodes[neighbour_node_y][neighbour_node_x].type != -22 && Nodes[neighbour_node_y][neighbour_node_x].type != -24)
                continue;

            // update neighbour node information and push it into nodes_queue
            if (Nodes[neighbour_node_y][neighbour_node_x].g > (local_node.g + 1))
            {
                Nodes[neighbour_node_y][neighbour_node_x].g = local_node.g + 1;
                Nodes[neighbour_node_y][neighbour_node_x].h = heuristic(Nodes[neighbour_node_y][neighbour_node_x], node_goal);
                Nodes[neighbour_node_y][neighbour_node_x].f = Nodes[neighbour_node_y][neighbour_node_x].g + 
                                                                    Nodes[neighbour_node_y][neighbour_node_x].h;
                Nodes[neighbour_node_y][neighbour_node_x].last_one = &(Nodes[local_node.y][local_node.x]);
                nodes_queue.push(Nodes[neighbour_node_y][neighbour_node_x]);
            }
        }

    
    }


    return ans;
}

int main() {

    vector<Node> a = findPath(stuff_id);

    for (int i = 0; i < a.size(); i++)
    {
        cout<<a[i].y<<", "<<a[i].x<<endl;
    }

    return 0;
}