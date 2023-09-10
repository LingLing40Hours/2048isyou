import itertools;

def print_rects():
    l = list(itertools.permutations(range(4)))
    for p1 in l:
        a = p1[0];
        c = p1[1];
        w = p1[2];
        y = p1[3];
        for p2 in l:
            b = p2[0];
            d = p2[1];
            x = p2[2];
            z = p2[3];
            if c > a and d > b and y > w and z > x:
                #print("r1 = ({}, {}), ({}, {}), r2 = ({}, {}), ({}, {})".format(a, b, c, d, w, x, y, z));
                for i in range(a, c+1):
                    for j in range(b, d+1):
                        
            
