#include "y.tab.c"
#include "lex.yy.c"
#include <algorithm>
#include <iostream>

using namespace std;

void instructions(Quad quads[]) {
    int current_block = 0;
    for(int i=1; i<nextquad; i++) {
        if(leaders[current_block] == i) {
            if(i > 1) cout << endl;
            cout << "Block " << ++current_block << endl;
        }
        if (quads[i].op == "=") {
            cout << "   " << i << "   : " << quads[i].result << " = " << quads[i].arg1 << endl;
        }
        else if (quads[i].op == "goto") {
            cout << "   " << i << "   : goto " << quads[i].result << endl;
        }
        else if (quads[i].op == ">") {
            cout << "   " << i << "   : iffalse (" << quads[i].arg1 << " > " << quads[i].arg2 << ") goto " << quads[i].result << endl;
        }
        else if (quads[i].op == "<") {
            cout << "   " << i << "   : iffalse (" << quads[i].arg1 << " < " << quads[i].arg2 << ") goto " << quads[i].result << endl;
        }
        else if (quads[i].op == ">=") {
            cout << "   " << i << "   : iffalse (" << quads[i].arg1 << " >= " << quads[i].arg2 << ") goto " << quads[i].result << endl;
        }
        else if (quads[i].op == "<=") {
            cout << "   " << i << "   : iffalse (" << quads[i].arg1 << " <= " << quads[i].arg2 << ") goto " << quads[i].result << endl;
        }
        else if (quads[i].op == "!=") {
            cout << "   " << i << "   : iffalse (" << quads[i].arg1 << " != " << quads[i].arg2 << ") goto " << quads[i].result << endl;
        }
        else if (quads[i].op == "==") {
            cout << "   " << i << "   : iffalse (" << quads[i].arg1 << " == " << quads[i].arg2 << ") goto " << quads[i].result << endl;
        }
        else if (quads[i].op == "+") {
            cout << "   " << i << "   : " << quads[i].result << " = " << quads[i].arg1 << " + " << quads[i].arg2 << endl;
        }
        else if (quads[i].op == "-") {
            cout << "   " << i << "   : " << quads[i].result << " = " << quads[i].arg1 << " - " << quads[i].arg2 << endl;
        }
        else if (quads[i].op == "*") {
            cout << "   " << i << "   : " << quads[i].result << " = " << quads[i].arg1 << " * " << quads[i].arg2 << endl;
        }
        else if (quads[i].op == "/") {
            cout << "   " << i << "   : " << quads[i].result << " = " << quads[i].arg1 << " / " << quads[i].arg2 << endl;
        }
        else if (quads[i].op == "%") {
            cout << "   " << i << "   : " << quads[i].result << " = " << quads[i].arg1 << " % " << quads[i].arg2 << endl;
        }
    }
    cout << endl;
    cout << "   " << nextquad << "   :";
}

void print_quad(Quad quads[]) {
    for(int i=1; i<nextquad; i++) {
        cout << "   " << i << "   : " << quads[i].op << " " << quads[i].arg1 << " " << quads[i].arg2 << " " << quads[i].result << endl;
    }
}

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
    instructions(quads);

    cout << endl << "\nquads:" << endl;
    print_quad(quads);

    return 0;
} 