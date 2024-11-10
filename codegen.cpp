#include "y.tab.c"
#include "lex.yy.c"
#include <algorithm>
#include <iostream>

using namespace std;

int main(int argc, char* argv[]) {
    // Parse command line arguments for number of registers
    int numRegisters = 5;  // default
    if (argc > 1) {
        numRegisters = atoi(argv[1]);
        if (numRegisters <= 0) numRegisters = 5;
    }
    
    yyparse();
    leaders[0] = 1;
    sort(leaders, leaders + blockCounter);
    int current_block = 0;

    for(int i=1; i<nextquad; i++) {
        if(leaders[current_block] == i) {
            if(i > 1) cout << endl;
            cout << "Block " << ++current_block << endl;
        }
        cout << "   " << i << "   : " << quads[i] << endl;
    }

    cout << endl;
    cout << "   " << nextquad << "   :";

    return 0;
} 