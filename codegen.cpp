#include "y.tab.c"
#include "lex.yy.c"
#include <algorithm>
#include <iostream>
#include <vector>
#include <iomanip>
using namespace std;


typedef struct _TargetQuad {
    string op;
    string arg1;
    string arg2;
    string result;
} TargetQuad;

TargetQuad T[1000];
int nextTargetQuad = 1;
int Target_leaders[1000];
int TargetCode_block_number = 0;
int quad_to_target[1000]; // Map from quad labels to target labels

struct regDescriptor {
    bool isfree;
    string name; // name of the variable/temp
};
regDescriptor* regs = nullptr;
int numRegisters;

int find_free_register() { // returns the index of the free register
    for (int i = 0; i < numRegisters; i++) {
        if (regs[i].isfree) return i;
    }
    return -1;
}

int find_register_with_var(const string& var) { // finds the register that contains the variable else returns -1
    for (int i = 0; i < numRegisters; i++) {
        if (regs[i].name == var) return i;
    }
    return -1;
}

// int load_reg(const string& var) { // returns a reg idx for the variable
//     int reg = find_free_register();
//     if (reg != -1) {
//         regs[reg].isfree = false;
//         regs[reg].name = var;
//         // // store the quad in the target code
//         // T[nextTargetQuad].op = "LD";
//         // T[nextTargetQuad].arg1 = var;
//         // T[nextTargetQuad].result = "R" + to_string(reg);
//         // //update the symbol table
//         // int var_idx = find_var_from_st(var);
//         // if(var_idx != -1){
//         //     st[var_idx].reg = reg;
//         // }
//         nextTargetQuad++;
//         return reg;
//     }
//     cout << "Spilling variable " << var << endl;
//     return -1;
// }

void free_register(int reg) { // frees the register
    regs[reg].isfree = true;
    regs[reg].name = "";
}

void free_all_registers() { // frees all the registers
    for (int i = 0; i < numRegisters; i++) {
        free_register(i);
    }
}

int find_var_from_st(const string& var) { // finds the index of the variable in the symbol table
    for (int i = 0; i < nextSymbol; i++) {
        if (st[i].name == var) return i;
    }
    return -1;
}

void free_reg_from_st(const string& var) { // frees the register of a variable from the symbol table 
    int index = find_var_from_st(var);
    if (index != -1) {
        st[index].reg = -1;
    }
}

void free_all_regs_from_st() { // frees all the registers from the symbol table
    for (int i = 0; i < nextSymbol; i++) {
        st[i].reg = -1;
    }
}

bool isNumber(const string& str) { // checks if the string is a number
    if (str.empty()) return false;
    char* end = nullptr;
    strtol(str.c_str(), &end, 10);
    return (*end == 0);
}


vector<int> store_ops; // stores the quad numbers of the Store operations i.e. = operations

void generate_store(){ // at the end of a block
    // the arg1 will already be in a register
    for (int j = 0; j < store_ops.size(); j++) {
        int reg = find_register_with_var(quads[store_ops[j]].arg1); // find the register that contains the variable
        T[nextTargetQuad].op = "ST";
        T[nextTargetQuad].arg1 = "R" + to_string(reg);
        T[nextTargetQuad].result = quads[store_ops[j]].result;
        quad_to_target[store_ops[j]] = nextTargetQuad; // map the quad to the target label
        nextTargetQuad++;
    }
    // free the registers
    free_all_regs_from_st();
    free_all_registers();
    store_ops.clear();

    // add the target leader
    Target_leaders[TargetCode_block_number++] = nextTargetQuad;
}

void generate_load(int quad_num){
    // this func is called when some arg is not already in a register
    // n = $2 : nothing to do, but store the quad number in store_ops
    // $2 is already in a register
    
    store_ops.push_back(quad_num);
    quad_to_target[quad_num] = nextTargetQuad;
    if(!isNumber(quads[quad_num].arg1))  return;

    // n = 2:  2 will be loaded in a register
    int reg = find_free_register();
    regs[reg].isfree = false;
    regs[reg].name = quads[quad_num].arg1;
    if(isNumber(quads[quad_num].arg1)){
        T[nextTargetQuad].op = "LDI";
    }
    else{
        T[nextTargetQuad].op = "LD";
        // store the reg no in the sym tab entry of the var
        int var_idx = find_var_from_st(quads[quad_num].arg1);
        if(var_idx != -1){
            st[var_idx].reg = reg;
        }
    }
    T[nextTargetQuad].arg1 = quads[quad_num].arg1;
    T[nextTargetQuad].result = "R" + to_string(reg);
    nextTargetQuad++;

    // the below case is handled in generate_expr
    // n = m + 2: m will be loaded in a register, but 2 will NOT, and result will be stored in a register
}

void generate_expr(int quad_num){
    // check if the args are already in registers
    // if not, load them in registers
    // then perform the operation and store the result in a register
    // then store the result in the symbol table
    // if the result is already in a register, then just perform the operation
    // else store the result in a register

    quad_to_target[quad_num] = nextTargetQuad;

    if(isNumber(quads[quad_num].arg1)){
        T[nextTargetQuad].arg1 = quads[quad_num].arg1;
    }
    else{
        int reg1 = find_register_with_var(quads[quad_num].arg1);
        if(reg1 == -1){
            reg1 = find_free_register();
            regs[reg1].isfree = false;
            regs[reg1].name = quads[quad_num].arg1;
            // update the symbol table
            int var_idx = find_var_from_st(quads[quad_num].arg1);
            if(var_idx != -1){
                st[var_idx].reg = reg1;
            }
            // load the arg1 in a register
            T[nextTargetQuad].op = "LD";
            T[nextTargetQuad].arg1 = quads[quad_num].arg1;
            T[nextTargetQuad].result = "R" + to_string(reg1);
            nextTargetQuad++;
        }
        T[nextTargetQuad].arg1 = "R" + to_string(reg1);
    }
    if(isNumber(quads[quad_num].arg2)){
        T[nextTargetQuad].arg2 = quads[quad_num].arg2;
    }
    else{
        int reg2 = find_register_with_var(quads[quad_num].arg2);
        if(reg2 == -1){
            reg2 = find_free_register();
            regs[reg2].isfree = false;
            regs[reg2].name = quads[quad_num].arg2;
            // update the symbol table
            int var_idx = find_var_from_st(quads[quad_num].arg2);
            if(var_idx != -1){
                st[var_idx].reg = reg2;
            }
            // load the arg2 in a register
            T[nextTargetQuad].op = "LD";
            T[nextTargetQuad].arg1 = quads[quad_num].arg2;
            T[nextTargetQuad].result = "R" + to_string(reg2);
            nextTargetQuad++;
        }
        T[nextTargetQuad].arg2 = "R" + to_string(reg2);
    }

    if (quads[quad_num].op == "+") T[nextTargetQuad].op = "ADD";
    else if (quads[quad_num].op == "-") T[nextTargetQuad].op = "SUB";
    else if (quads[quad_num].op == "*") T[nextTargetQuad].op = "MUL";
    else if (quads[quad_num].op == "/") T[nextTargetQuad].op = "DIV";
    else if (quads[quad_num].op == "%") T[nextTargetQuad].op = "REM";

    int reg = find_register_with_var(quads[quad_num].result);
    if(reg == -1){
        reg = find_free_register();
        regs[reg].isfree = false;
        regs[reg].name = quads[quad_num].result;
        // update the symbol table
        int var_idx = find_var_from_st(quads[quad_num].result);
        if(var_idx != -1){
            st[var_idx].reg = reg;
        }
    }
    T[nextTargetQuad].result = "R" + to_string(reg);
    nextTargetQuad++;
}

void generate_goto(int quad_num){
    quad_to_target[quad_num] = nextTargetQuad;
    T[nextTargetQuad].op = "JMP";
    T[nextTargetQuad].result = quads[quad_num].result; 
    // todo: update the target label to quad_to_target[quads[quad_num].result]
    nextTargetQuad++;
}

void generate_iffalse(int quad_num){
    // op is some reln
    // if some arg is not in a register, load it in a register
    // then perform the operation and store the result in a register
    // then store the result in the symbol table
    // if the result is already in a register, then just perform the operation
    // else store the result in a register
    quad_to_target[quad_num] = nextTargetQuad;

    int reg1 = find_register_with_var(quads[quad_num].arg1);
    if(reg1 == -1){
        reg1 = find_free_register();
        regs[reg1].isfree = false;
        regs[reg1].name = quads[quad_num].arg1;
        // update the symbol table
        int var_idx = find_var_from_st(quads[quad_num].arg1);
        if(var_idx != -1){
            st[var_idx].reg = reg1;
        }
        // load the arg1 in a register
        T[nextTargetQuad].op = "LD";
        T[nextTargetQuad].arg1 = quads[quad_num].arg1;
        T[nextTargetQuad].result = "R" + to_string(reg1);
        nextTargetQuad++;
    }
    T[nextTargetQuad].arg1 = "R" + to_string(reg1);

    if(isNumber(quads[quad_num].arg2)){
        T[nextTargetQuad].arg2 = quads[quad_num].arg2;
    }
    else{
        int reg2 = find_register_with_var(quads[quad_num].arg2);
        if(reg2 == -1){
            reg2 = find_free_register();
            regs[reg2].isfree = false;
            regs[reg2].name = quads[quad_num].arg2;
            // update the symbol table
            int var_idx = find_var_from_st(quads[quad_num].arg2);
            if(var_idx != -1){
                st[var_idx].reg = reg2;
            }
            // load the arg2 in a register
            T[nextTargetQuad].op = "LD";
            T[nextTargetQuad].arg1 = quads[quad_num].arg2;
            T[nextTargetQuad].result = "R" + to_string(reg2);
            nextTargetQuad++;
        }
        T[nextTargetQuad].arg2 = "R" + to_string(reg2);
    }
    if (quads[quad_num].op == ">") T[nextTargetQuad].op = "JLE";
    else if (quads[quad_num].op == "<") T[nextTargetQuad].op = "JGE";
    else if (quads[quad_num].op == ">=") T[nextTargetQuad].op = "JLT";
    else if (quads[quad_num].op == "<=") T[nextTargetQuad].op = "JGT";
    else if (quads[quad_num].op == "!=") T[nextTargetQuad].op = "JEQ";
    else if (quads[quad_num].op == "==") T[nextTargetQuad].op = "JNE";

    nextTargetQuad++;
}


// generates the target code
void generate_target_code() {
    int current_block = 0;
    for(int qn = 1; qn < nextquad; qn++){
        if(qn==leaders[current_block]){
            generate_store();
            current_block++;
        }

        if(quads[qn].op == "="){
            generate_load(qn);
        }
        if(quads[qn].op == "goto"){
            generate_goto(qn);
        }
        else if(quads[qn].op == ">=" || quads[qn].op == "<=" || quads[qn].op == "!=" || quads[qn].op == "=="||  quads[qn].op == ">" || quads[qn].op == "<"){
            generate_iffalse(qn);
        }
        else if(quads[qn].op == "+" || quads[qn].op == "-" || quads[qn].op == "*" || quads[qn].op == "/" || quads[qn].op == "%"){
            generate_expr(qn);
        }
    }

    //store at last 
    generate_store();

    // now update the target labels
}


/*************printing functions*************/
void print_intermediate_code(Quad quads[]) {
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
    // Print header
    cout << "-------------------------------------------------------------" << endl;
    cout << "   Line   |   Op     |    Arg1     |     Arg2    |   Result" << endl;
    
    for(int i=1; i<nextquad; i++) {
        // Format each field with consistent width
        cout << "   " << setw(4) << i << "   |";
        cout << "   " << setw(4) << quads[i].op << "   |"; 
        cout << "   " << setw(7) << quads[i].arg1 << "   |";
        cout << "   " << setw(7) << quads[i].arg2 << "   |";
        cout << "   " << quads[i].result << endl;
    }
}

void print_symbol_table() {
    // Print header
    cout << "---------------------------------------------" << endl;
    cout << "   Index  |    Name    |  Is Temp |   Register" << endl;

    for(int i=0; i<nextSymbol; i++) {
        cout << "   " << setw(4) << i << "   |";
        cout << "   " << setw(6) << st[i].name << "   |";
        cout << "   " << setw(4) << st[i].is_temp << "   |";
        cout << "   " << setw(4) << st[i].reg << endl;
    }
}

void print_target_code() {
    // Print header
    cout << "-------------------------------------------------------------" << endl;
    cout << "   Line   |   Op     |      Src1   |      Src2   |   Dst" << endl;
    
    for(int i=1; i<nextTargetQuad; i++) {
        // Print block number if this line is a leader
        for(int j=0; j<TargetCode_block_number; j++) {
            if(i == Target_leaders[j]) {
                cout << "\nBlock " << j << ":\n";
                break;
            }
        }
        
        // Format each field with consistent width
        cout << "   " << setw(4) << i << "   |";
        cout << "   " << setw(4) << T[i].op << "   |";
        cout << "   " << setw(7) << T[i].arg1 << "   |"; 
        cout << "   " << setw(7) << T[i].arg2 << "   |";
        cout << "   " << T[i].result << endl;
    }
}


int main(int argc, char* argv[]) {
    // Parse command line arguments for number of registers
    numRegisters = 5;  // default
    if (argc > 1) {
        numRegisters = atoi(argv[1]);
        if (numRegisters <= 0) numRegisters = 5;
    }

    // Resize regs array to requested size
    delete[] regs;
    regs = new regDescriptor[numRegisters];
    
    for(int i=0; i<numRegisters; i++) {
        regs[i].isfree = 1;
        regs[i].name = "";
    }

    // Initialize quad_to_target array with -1
    for(int i=0; i<1000; i++) {
        quad_to_target[i] = -1;
    }

    yyparse();
    leaders[0] = 1;
    sort(leaders, leaders + blockCounter);
    print_intermediate_code(quads);

    generate_target_code();

    cout << endl << "\ntarget code:" << endl;
    print_target_code();

    // cout << endl << "\nquads:" << endl;
    // print_quad(quads);

    // cout << endl << "\nsymbol table:" << endl;
    // print_symbol_table();

    return 0;
} 