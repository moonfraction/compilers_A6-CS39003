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

TargetQuad T[1000]; // target code quads
int nextTargetQuad = 1; // next quad number for target code
int TargetCode_block_number = 0; // number of target code blocks
vector<int> Target_code_blocks; // target code quad numbers where that block starts
vector<int> store_ops; // stores the quad numbers of the Store operations i.e. "=" operations

// registers descriptor
struct regDescriptor {
    bool isfree;
    string name; // name of the variable/temp
};
regDescriptor* regs = nullptr; // array of registers
int numRegisters; // number of registers


/****************** REGISTERS FUNCTIONS ******************/
int find_free_register() { // returns the index of the free register
    for (int i = 1; i <= numRegisters; i++) if (regs[i].isfree) return i;
    return -1;
}

int find_register_with_var(const string& var) { // finds the register that contains the variable else returns -1
    for (int i = 1; i <= numRegisters; i++) if (regs[i].name == var) return i;
    return -1;
}

void free_register(int reg) { // frees the register at given index
    regs[reg].isfree = true;
    regs[reg].name = "";
}

void free_all_registers() { // frees all the registers
    for (int i = 1; i <= numRegisters; i++) free_register(i);
}

int find_var_from_st(const string& var) { // finds the index of the variable in the symbol table
    for (int i = 0; i < nextSymbol; i++) if (st[i].name == var) return i;
    return -1;
}

void free_reg_from_st(const string& var) { // frees the register of a variable from the symbol table 
    int index = find_var_from_st(var);
    if (index != -1) st[index].reg = -1;
}

void free_all_regs_from_st() { // frees all the registers from the symbol table
    for (int i = 0; i < nextSymbol; i++) st[i].reg = -1;
}

void update_reg_in_st(const string& var, int reg) { // updates the register of a variable in the symbol table
    regs[reg].isfree = false;
    regs[reg].name = var;
    // update the symbol table
    int var_idx = find_var_from_st(var);
    st[var_idx].reg = reg;
}

// auxiliary function 
bool isNumber(const string& str) { // checks if the string is a number
    if (str.empty()) return false;
    char* end = nullptr;
    strtol(str.c_str(), &end, 10);
    return (*end == 0);
}


/****************** TARGET CODE QUAD FUNCTIONS ******************/

void generate_store(){ // at the end of a block
    // the arg1 will already be in a register, to be stored in a memory
    for (int j = 0; j < store_ops.size(); j++) {
        int reg; // register that contains the temp/num
        // if the arg1 is a number, find the from reg descriptor
        if(isNumber(quads[store_ops[j]].arg1)) reg = find_register_with_var(quads[store_ops[j]].arg1);
        else { // if the arg1 is a variable, find from symtab
            int var_idx = find_var_from_st(quads[store_ops[j]].arg1);
            reg = st[var_idx].reg;
        }
        T[nextTargetQuad].op = "ST";
        T[nextTargetQuad].arg1 = "R" + to_string(reg);
        T[nextTargetQuad].result = quads[store_ops[j]].result;
        nextTargetQuad++;
    }
    // free the registers at the end of the block
    free_all_regs_from_st();
    free_all_registers();
    store_ops.clear();
}

void generate_load(int quad_num){
    //free the register of result if it is already in use
    int reg_res = find_register_with_var(quads[quad_num].result);
    if(reg_res != -1){
        free_register(reg_res);
        free_reg_from_st(quads[quad_num].result);
    }

    // store the quad number of the load operation - to be used at the end of the block
    store_ops.push_back(quad_num);

    // n = $2(or m): $2 is already in a register
    if(!isNumber(quads[quad_num].arg1)) {
        int reg_arg1 = find_register_with_var(quads[quad_num].arg1); // reg of the arg1
        // update the register descriptor for storing the result
        regs[reg_arg1].isfree = false;
        regs[reg_arg1].name = quads[quad_num].result;
        // update reg of arg1 in the symbol table
        int var_idx = find_var_from_st(quads[quad_num].arg1);
        st[var_idx].reg = reg_arg1;
        return;
    }

    // n = 2:  2 will be loaded in a register
    int reg = find_free_register();
    regs[reg].isfree = false;
    regs[reg].name = quads[quad_num].arg1;
    if(isNumber(quads[quad_num].arg1))T[nextTargetQuad].op = "LDI";
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

int gen_load_arg(const string& arg){
    int reg = find_register_with_var(arg);
    if(reg == -1){
        reg = find_free_register();
        update_reg_in_st(arg, reg);
        // load instruction for arg
        T[nextTargetQuad].op = "LD";
        T[nextTargetQuad].arg1 = arg;
        T[nextTargetQuad].result = "R" + to_string(reg);
        nextTargetQuad++;   
    }
    return reg;
}

void generate_expr(int quad_num){
    int Ra1, Ra2; // registers of the args

    if(!isNumber(quads[quad_num].arg1)) Ra1 = gen_load_arg(quads[quad_num].arg1);
    if(!isNumber(quads[quad_num].arg2)) Ra2 = gen_load_arg(quads[quad_num].arg2);

    // operation instruction
    if (quads[quad_num].op == "+") T[nextTargetQuad].op = "ADD";
    else if (quads[quad_num].op == "-") T[nextTargetQuad].op = "SUB";
    else if (quads[quad_num].op == "*") T[nextTargetQuad].op = "MUL";
    else if (quads[quad_num].op == "/") T[nextTargetQuad].op = "DIV";
    else if (quads[quad_num].op == "%") T[nextTargetQuad].op = "REM";

    // arg1 and arg2
    // we use a number as it is in the expression
    if(isNumber(quads[quad_num].arg1)) T[nextTargetQuad].arg1 = quads[quad_num].arg1;
    else T[nextTargetQuad].arg1 = "R" + to_string(Ra1);
    if(isNumber(quads[quad_num].arg2)) T[nextTargetQuad].arg2 = quads[quad_num].arg2;
    else T[nextTargetQuad].arg2 = "R" + to_string(Ra2);

    // result of the operation will be stored in a register (temporary variable)
    int reg = find_register_with_var(quads[quad_num].result);
    if(reg == -1){ // if not already in a register
        reg = find_free_register();
        update_reg_in_st(quads[quad_num].result, reg);
    }
    T[nextTargetQuad].result = "R" + to_string(reg);
    nextTargetQuad++;
}

void generate_goto(int quad_num){
    // before unconditional jump, store the variables in memory
    generate_store();

    T[nextTargetQuad].op = "JMP";
    T[nextTargetQuad].result = quads[quad_num].result; // todo: update the target code label
    nextTargetQuad++;
}

void generate_iffalse(int quad_num){
    int Ra1, Ra2; // registers of the args

    if(!isNumber(quads[quad_num].arg1)) Ra1 = gen_load_arg(quads[quad_num].arg1);
    if(!isNumber(quads[quad_num].arg2)) Ra2 = gen_load_arg(quads[quad_num].arg2);

    // branch instruction
    if (quads[quad_num].op == ">") T[nextTargetQuad].op = "JLE";
    else if (quads[quad_num].op == "<") T[nextTargetQuad].op = "JGE";
    else if (quads[quad_num].op == ">=") T[nextTargetQuad].op = "JLT";
    else if (quads[quad_num].op == "<=") T[nextTargetQuad].op = "JGT";
    else if (quads[quad_num].op == "!=") T[nextTargetQuad].op = "JEQ";
    else if (quads[quad_num].op == "==") T[nextTargetQuad].op = "JNE";

    // arg1 and arg2
    // we use a number as it is in the condition
    if(isNumber(quads[quad_num].arg1)) T[nextTargetQuad].arg1 = quads[quad_num].arg1;
    else T[nextTargetQuad].arg1 = "R" + to_string(Ra1);
    if(isNumber(quads[quad_num].arg2)) T[nextTargetQuad].arg2 = quads[quad_num].arg2;
    else T[nextTargetQuad].arg2 = "R" + to_string(Ra2);

    T[nextTargetQuad].result = quads[quad_num].result; // todo: update the target code label
    nextTargetQuad++;
}

void update_target_labels(){
    // Iterate through all target code instructions
    for(int i = 0; i < nextTargetQuad; i++) {
        // Check if instruction is a jump(conditional or unconditional)
        if(T[i].op == "JMP" || T[i].op == "JGT" || T[i].op == "JGE" || 
           T[i].op == "JLT" || T[i].op == "JLE" || T[i].op == "JEQ" || T[i].op == "JNE") {
            
            // Get the quad label from result field
            string quad_label = T[i].result; // intcode quad goto label
            int quad_num = stoi(quad_label);
            
            int block_num = 0; // goto block number
            if(quad_num == nextquad) { // if goto is the last instruction
                block_num = TargetCode_block_number;
            }
            else{
                // Find which block this goto belongs to
                while(block_num <= TargetCode_block_number && quad_num >= leaders[block_num]) block_num++;
                block_num--; // since the loop increments it one extra time
            }
            
            // Update jump target to corresponding target code block start quad number
            T[i].result = to_string(Target_code_blocks[block_num]);
        }
    }
}

/****************** TARGET CODE GENERATION ******************/
void generate_target_code() {
    int current_block = 0; // current target code block number
    for(int qn = 1; qn < nextquad; qn++){ // iterate through all the quads
        if(qn==leaders[current_block]){ // if the quad is a leader
            // store the variables in memory before starting a new block
            generate_store(); 
            current_block++;
            // store the target code quad number where the current block starts
            Target_code_blocks.push_back(nextTargetQuad); 
            TargetCode_block_number++; // increment the target code block number
        }

        // load
        if(quads[qn].op == "=") generate_load(qn);
        // goto(unconditional)
        else if(quads[qn].op == "goto") generate_goto(qn);
        // iffalse(conditional)
        else if(quads[qn].op == ">=" || quads[qn].op == "<=" || quads[qn].op == "!=" || 
                quads[qn].op == "==" || quads[qn].op == ">" || quads[qn].op == "<") generate_iffalse(qn);
        // expr
        else if(quads[qn].op == "+" || quads[qn].op == "-" || quads[qn].op == "*" || 
                quads[qn].op == "/" || quads[qn].op == "%") generate_expr(qn);
    }

    Target_code_blocks.push_back(nextTargetQuad);

    // update the target labels
    update_target_labels();
}

/************* PRINTING FUNCTIONS *************/
void print_intermediate_code(Quad quads[]) {
    int current_block = 0;
    for(int i=1; i<nextquad; i++) {
        if(leaders[current_block] == i) {
            if(i > 1) cout << endl;
            cout << "Block " << ++current_block << endl;
        }
        if (quads[i].op == "=") cout << "   " << i << "   : " << quads[i].result << " = " << quads[i].arg1 << endl;
        else if (quads[i].op == "goto") cout << "   " << i << "   : goto " << quads[i].result << endl;
        else if(quads[i].op == ">" || quads[i].op == "<" || quads[i].op == ">=" || quads[i].op == "<=" || quads[i].op == "!=" || quads[i].op == "==") 
            cout << "   " << i << "   : iffalse (" << quads[i].arg1 << " " << quads[i].op << " " << quads[i].arg2 << ") goto " << quads[i].result << endl;
        else cout << "   " << i << "   : " << quads[i].result << " = " << quads[i].arg1 << " "<<quads[i].op<<" "<< quads[i].arg2 << endl;
    }
    cout << endl;
    cout << "   " << nextquad << "   :";
}

void print_quad(Quad quads[]) {
    int curr_block = 0;
    for(int i=1; i<nextquad; i++) {
        // Print block number if this line is a leader
        if(i == leaders[curr_block]){
            cout << "__________________________________________________________" << endl;
            cout << "Block " << curr_block + 1 << endl;
            cout << "   Line   |     Op   |    Arg1     |     Arg2    |   Result" << endl;
            curr_block++;
        }
        
        cout << "   " << setw(4) << i << "   |";
        cout << "   " << setw(4) << quads[i].op << "   |"; 
        cout << "   " << setw(7) << quads[i].arg1 << "   |";
        cout << "   " << setw(7) << quads[i].arg2 << "   |";
        cout << "   " << quads[i].result << endl;
    }
}

void print_symbol_table() {
    cout << "----------------------------------------------" << endl;
    cout << "   Index  |    Name    |  Is Temp |   Register" << endl;

    for(int i=0; i<nextSymbol; i++) {
        cout << "   " << setw(4) << i << "   |";
        cout << "   " << setw(6) << st[i].name << "   |";
        cout << "   " << setw(4) << st[i].is_temp << "   |";
        cout << "   " << setw(4) << st[i].reg << endl;
    }
}

void print_target_quad() {
    int curr_target_block = 0;
    for(int i=1; i<nextTargetQuad; i++) {
        // Print block number if this line is a leader
        if(i == Target_code_blocks[curr_target_block]){
            cout << "__________________________________________________________" << endl;
            cout << "Block " << curr_target_block + 1 << endl;
            cout << "   Line   |     Op   |      Src1   |      Src2   |   Dst" << endl;
            curr_target_block++;
        }
        
        cout << "   " << setw(4) << i << "   |";
        cout << "   " << setw(4) << T[i].op << "   |";
        cout << "   " << setw(7) << T[i].arg1 << "   |"; 
        cout << "   " << setw(7) << T[i].arg2 << "   |";
        cout << "   " << T[i].result << endl;
    }
}

void print_target_code(){
   int curr_target_block = 0;
   for(int i=1; i<nextTargetQuad; i++){
    if(i == Target_code_blocks[curr_target_block]){
        if(curr_target_block != 0) cout << endl;
        cout << "Block " << ++curr_target_block << endl;
    }
    //JMP
    if(T[i].op == "JMP") cout << " " << setw(4) << i << "   : " << T[i].op << " " << T[i].result << endl;
    else if(T[i].op == "JGT" || T[i].op == "JGE" || T[i].op == "JLT" || T[i].op == "JLE" || T[i].op == "JEQ" || T[i].op == "JNE") 
        cout << " " << setw(4) << i << "   : " << T[i].op << " " << T[i].arg1 << " " << T[i].arg2 << " " << T[i].result << endl;
    else if(T[i].op == "LD" || T[i].op == "ST") //load(LD) and store(ST) instructions
        cout << " " << setw(4) << i << "   : " << T[i].op << " " << T[i].result << " " << T[i].arg1 << endl;
    else //remaining instructions(ADD, SUB, MUL, DIV, REM)
        cout << " " << setw(4) << i << "   : " << T[i].op << " " << T[i].result << " " << T[i].arg1 << " " << T[i].arg2 << endl;
   }

   cout << endl;
   cout<< " " << setw(4) << nextTargetQuad << "   :" << endl;
}

/************* MAIN FUNCTION *************/
int main(int argc, char* argv[]) {
    // Parse command line arguments for number of registers
    numRegisters = 5;  // default
    if (argc > 1) {
        numRegisters = atoi(argv[1]);
        if (numRegisters <= 0) numRegisters = 5;
    }

    // Resize regs array to requested size
    delete[] regs;
    regs = new regDescriptor[numRegisters + 1];
    for(int i=1; i<=numRegisters; i++) {
        regs[i].isfree = 1;
        regs[i].name = "";
    }

    // parse the input file
    yyparse();
    leaders[0] = 1;
    sort(leaders, leaders + blockCounter);
    
    generate_target_code();

    print_target_code();



    // cout << "\ntarget code quads:" << endl;
    // print_target_quad();
    // cout << endl;

    // cout << "\nintermediate code:" << endl;
    // print_intermediate_code(quads);
    // cout << endl;


    // cout << "\nintermediate code quads:" << endl;
    // print_quad(quads);
    // cout << endl;

    // cout << "\nsymbol table:" << endl;
    // print_symbol_table();

    return 0;
} 