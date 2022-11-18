%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<stack>
#include<cmath>
#include<vector>
#include<regex>
#include<iterator>
#include "1805053SymTable.h"
#include "lex.yy.c"

using namespace std;



extern int line_count;
int yyparse (void);
int  yylex (void);
SymbolTable table(13);
bool suppress_function_calls;
int parserError = 0;
string current_func_def;
vector<string> global_temp_param_list;
vector<string> global_temp_arg_list;
vector<string> global_temp_param_list_for_scope;
vector<SymbolInfo*> global_temp_dec_list;
int global_temp_int;
int global_statement2_end=-42069;
string global_temp_var_type;
vector<string> library_functions;
string global_temp_return_type="void";
int global_temp_func_start_line_no = -1;
int stackElemInScope=-69420;
int labelCount = 0;
stack<int> stackElemCountStack;
ofstream asmCodeFile("tempAsmCodeSegment.asm");
ofstream asmStartFile("code.asm");
ForPrinting* whileTemp;
bool first_function_bool = false;
string global_inside_function = "";

string asmPrintProc = " \n\\
PRINTLN PROC \n\\
     \n\\
	PUSH BP \n\\
	MOV BP, SP \n\\
	MOV AX, [BP+4] \n\\
	POP BP \n\\
    PUSH SI \n\\
     \n\\
    LEA SI, NUMBER_STRING \n\\
    ADD SI, 5  \n\\
    CMP AX, 0 \n\\
    JGE NOT_NEG2:   \n\\
     \n\\
    NEG AX    \n\\
     \n\\
    PUSH AX \n\\
     \n\\
    MOV DL, '-' \n\\
    MOV AH, 2 \n\\
    INT 21H   \n\\
     \n\\
    POP AX \n\\
     \n\\
    NOT_NEG2: \n\\
     \n\\
    PRINT_LOOP:  \n\\
     \n\\
        DEC SI \n\\
        MOV DX, 0   \n\\
        MOV CX, 10 \n\\
        DIV CX \n\\
        ADD DL,'0'    \n\\
            \n\\
        MOV [SI], DL   \n\\
         \n\\
         \n\\
        CMP AX, 0 \n\\
        JNE PRINT_LOOP \n\\
         \n\\
    MOV DX, SI \n\\
    MOV AH, 9 \n\\
    INT 21H  \n\\
	MOV AH, 2 \n\\
    MOV DL, 13 \n\\
    INT 21H \n\\
    MOV DL, 10 \n\\
    INT 21H  \n\\
        \n\\
    POP SI     \n\\
     \n\\
    RET \n\\
    PRINTLN ENDP  \n\n ";


string trim(string s)
{     

    int start = 0;

    for(int i=0;i<s.length();i++){

      if (s[i]==32 || s[i]=='\t'){
         
         start++;
      }
      else{
         break;
      }
    }
   
    int end = s.length()-1;

    for(int i=s.length()-1;i>start;i--){

      if (s[i]==32 || s[i]=='\t')
         end--;
      else {
         break;
      }
    }

   string ret =  s.substr(start, end-start+1);
   // cout<<(s.length()-1)<<" start:"<<start<<" end:"<<end<<" sentence:"<<ret<<"___"<<endl;

   return ret;
   
}




string remove_comment(string s){
   for(int i=0;i<s.length();i++){
      if(s[i]==';')
         return s.substr(0,i);
   } 

   return s;
}



string optimize_code(string file_to_optimize){

   ofstream unoptimized_clean("1805053_unoptimized_clean.asm");
   ofstream optimized_clean("temp_optimized.asm");

   fstream newfile;

   newfile.open(file_to_optimize,ios::in); //open a file to perform read operation using file object

   vector<vector<string>> new_code;

   if (newfile.is_open()){   //checking whether the file is open
      string tp;
      while(getline(newfile, tp)){ //read data from file object and put it into string.
        
        if (regex_match (tp, regex("[\\s\t\n]*") ))
            continue;

        if (regex_match (tp, regex("[\\s\t\n]+;(.*?)") ))
            continue;

         tp = remove_comment(tp);
         tp = trim(tp);

         // cout <<"___________"<< tp << "____\n"; //print the data of the string

         vector<string> parts = {"null","null","null"};
         string temp;
         int k =0;
         int mid1=0;
       
         for(int i=0;i<tp.length();i++){

            // cout<<(int)tp[i]<<" ";

            if (tp[i]==' ' || tp[i]==32){
				
               		i++;
               parts[0]= tp.substr(0,i);
            //    cout<<"  !!parts 0 set to "<<parts[0]<<"!!  ";
              

               while(tp[i]==' ')
                  i++;
               mid1=i;
            }
            

            else if (tp[i]==','){
               i++;
               parts[1]= tp.substr(mid1,i-mid1-1);
            //    cout<<"  !!parts 1 set to "<<parts[1]<<"!!  ";
               parts[2]= tp.substr(i,tp.length()-i+1);
            //    cout<<"  !!parts 2 set to "<<parts[2]<<"!!  ";
               while(tp[i]==' ')
                  i++;
            
            }

            if (i==tp.length()-1){
               if(parts[1]=="null"){
                  parts[1]= tp.substr(mid1,i-mid1+1);

                // cout<<"  !!Xparts 1 set to "<<parts[1]<<"!!  ";
               }

            }

         }

        parts[0] = trim(parts[0]);
        parts[1] = trim(parts[1]);
        parts[2] = trim(parts[2]);


        new_code.push_back(parts);
       
	   
	    // cout << tp << "\n"; //print the data of the string
        // cout<<"   _PARTS1:"<<parts[0]<<"  _PARTS2:"<<parts[1]<<"  _PARTS3:"<<parts[2]<<endl<<endl;

        // if(parts[0]=="null" && parts[2]=="null")
        //     unoptimized_clean<<parts[1]<<endl;
        //  else if(parts[2]=="null")
        //     unoptimized_clean<<parts[0]<<" "<<parts[1]<<endl;
        //  else
        //     unoptimized_clean<<parts[0]<<" "<<parts[1]<<","<<parts[2]<<endl;

         
      }
      newfile.close(); //close the file object.

      vector<int> to_remove;

      for(int i=1;i<new_code.size();i++){
         if(new_code[i-1][0]=="PUSH" && new_code[i][0]=="POP" && new_code[i-1][1]==new_code[i][1]){
            // to_remove.push_back(i-1);
            // to_remove.push_back(i);
            new_code[i-1][0] = ";"+new_code[i-1][0];
            new_code[i][0] = ";"+new_code[i][0];
            
         }

         if((new_code[i-1][0]=="ADD" && new_code[i][0]=="ADD" && new_code[i-1][1]==new_code[i][1])
            ||
            (new_code[i-1][0]=="SUB" && new_code[i][0]=="SUB" && new_code[i-1][1]==new_code[i][1])
            ){
            // to_remove.push_back(i-1);
			try{
				stoi(new_code[i-1][2]);
				stoi(new_code[i][2]);
			}
			catch(...){
				continue;
			}
            new_code[i][2] = to_string(stoi(new_code[i-1][2])+stoi(new_code[i][2]));

            new_code[i-1][0] = ";"+new_code[i][0];
            
         }

		 if (new_code[i][0]=="ADD" && new_code[i][2]=="0"){
			 new_code[i][0] = ";"+new_code[i][0];
		 }
		 else if (new_code[i][0]=="SUB" && new_code[i][2]=="0"){
			 new_code[i][0] = ";"+new_code[i][0];
		 }

		 else if(new_code[i][0]=="JMP"){
			
			int k = i+1;
			while(k<new_code.size() && new_code[k][1].back()!=':'){
				new_code[k][0] = ";"+new_code[k][0];
				k++;
			}

		 }


      }

      for(int i=0;i<to_remove.size();i++){
         new_code.erase(new_code.begin()+to_remove[i]);
      }



      for(int i=0;i<new_code.size();i++){


         // cout<<"   _PARTS1:"<<new_code[i][0]<<"  _PARTS2:"<<new_code[i][1]<<"  _PARTS3:"<<new_code[i][2]<<endl<<endl;
         if(new_code[i][0]=="null" && new_code[i][2]=="null")
            optimized_clean<<new_code[i][1]<<endl;
         else if(new_code[i][2]=="null")
            optimized_clean<<new_code[i][0]<<" "<<new_code[i][1]<<endl;
         else
         optimized_clean<<new_code[i][0]<<" "<<new_code[i][1]<<","<<new_code[i][2]<<endl;


      }

      // unoptimized_clean.close();
      optimized_clean.close();


      return "temp_optimized.asm";
      


   }
}



string getDominantType(SymbolInfo* s1, SymbolInfo* s2){
	if (s1->getVarType()=="float")
		return "float";
	if (s2->getVarType()=="float")
		return "float";
	
	if (s1->getVarType()=="int")
		return "int";

	if (s2->getVarType()=="int")
		return "int";
	
	return "unknown type error";
}
void log_file(string str, int custom_line_count = -1){

	if (custom_line_count== -1)
		logFile <<"Line "<<line_count<<": "<< str <<endl;
	else
		logFile <<"Line "<<custom_line_count<<": "<< str <<endl;

}
void log_file_no_lineNo(string str){
	logFile <<endl << str <<endl<<endl;
}

string getStackDepth(SymbolInfo* i){
	return to_string( i->getStackLoc() * 2);
}
void print(string s){
	asmCodeFile<<"\t"<<s<<endl;
}

void print_start_file(string s){
	asmStartFile<<"\t"<<s<<endl;
}
void print_no_tab(string s){
	asmCodeFile<<s<<endl;
}
void print_main_code(string s){

	for(int i=0;i<s.length();i++){
		if(s[i]=='\n')
			s[i]='\t';
	}
	// cout<<s<<endl;

	asmCodeFile<<"\t\t\t\t\t"<<s<<endl;
}

void newLabel(string s){
	print(s);
}
void push(string s){
	print("PUSH "+s);
	stackElemInScope++;
}
void pop(string s){
	print("POP "+s);
	stackElemInScope--;
}

string address_stackQ(SymbolInfo* s){

		// print("stack loc of "+ s->getName() +" is "+ to_string(s->getStackLoc()));

		// if(table.lookup(s->getName()))
		// 	s = table.lookup(s->getName());
		if (s->getStackLoc()!= -42069){
			if(s->getStackLoc()>=0)
				return " [BP-"+to_string(2*s->getStackLoc())+"]";
			else
				return " [BP+"+to_string(-2*s->getStackLoc() +2 )+"]";
		}
		
		else
			return s->getAsm();
		
}

void log_error(string str, int custom_line_count = -1){
	
	if (custom_line_count== -1){
	errorFile <<"Error at line "<<line_count<<": "<< str <<endl<<endl;
	logFile <<"Error at line "<<line_count<<": "<< str <<endl<<endl;
	}
	else {
		errorFile <<"Error at line "<<custom_line_count<<": "<< str <<endl<<endl;
		logFile <<"Error at line "<<custom_line_count<<": "<< str <<endl<<endl;
	}
	parserError++;
}

void printTempParamList(){
	for (string i: global_temp_param_list)
    	cout << i << ' ';
	cout<<endl;
}


void printStringVector(vector<string> list){
	for (string i: list)
    	cout << i << ' ';
	cout <<endl;
}
bool alreadyInStringVector(vector<string> list, string elem){
	for (string i: list){
		if (i==elem){
			return true;
		}
	}
	return false;		
}
void yyerror(char *s)
{
	//write your code
	log_error(string(s)+" (Syntax Error)");
}


%}


%union {
	SymbolInfo* symPtr;
	ForPrinting* ForPrintingPtr;
}


%token <symPtr> ID CONST_INT CONST_FLOAT BITOP DO SWITCH DEFAULT DOUBLE CHAR CASE CONST_CHAR CONTINUE BREAK PRINTLN LCURL RCURL ADDOP MULOP LOGICOP RELOP  RPAREN LTHIRD RTHIRD COMMA SEMICOLON NOT LPAREN INT FLOAT VOID IF FOR ELSE WHILE RETURN INCOP DECOP ASSIGNOP 

%type <symPtr> type_specifier expression logic_expression rel_expression simple_expression term unary_expression factor variable expression_statement
%type <ForPrintingPtr> unit program func_declaration func_definition parameter_list statement  declaration_list var_declaration compound_statement arguments argument_list
%type <ForPrintingPtr> statements exp_rparen_action

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
 

/* %nonassoc low
%nonassoc high
 */



%%

start : program	{
		log_file("start : program");
		table.printAllScopeTable();
		logFile<<getOutputStream()<<endl;

		logFile<<"Total lines: "<< line_count<<endl;

		logFile<<"Total errors: "<< parserError<<endl;
	}
	;
program : program unit {
		log_file("program : program unit");

		$$ = new ForPrinting();
		$$->setToPrint($1->getToPrint()+"\n"+$2->getToPrint());
		log_file_no_lineNo($$->getToPrint());
	}
	| unit {
		log_file("program : unit");

		$$ = new ForPrinting();
		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());

	}
	;
	
unit : var_declaration {
		log_file("unit : var_declaration ");
		$$ = new ForPrinting();
		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());
	}
     | func_declaration {
		log_file("unit : func_declaration ");
		$$ = new ForPrinting();
		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());
	 }
     | func_definition {
		log_file("unit : func_definition ");
		$$ = new ForPrinting();
		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());
	 }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{	

			log_file("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
			
			if(!table.insert($2->getName(),"FUNCTION_NAME")){
				
				SymbolInfo* temp = table.lookup($2->getName());

				if (temp->getType()=="FUNCTION_NAME")
					log_error("Function "+$2->getName()+" already exists");
				else
					log_error($2->getName()+" already declared as a global variable");
			}
			else{

				SymbolInfo* temp = table.lookup($2->getName());
				temp->setFuncParameters(global_temp_param_list);


				temp->setFuncReturnType($1->getVarType());

			}
			

				// log_file("Function "+$2->getName()+" declaration accepted.");

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+"("+$4->getToPrint()+");");
			log_file_no_lineNo($$->getToPrint());

				
			

			global_temp_param_list_for_scope.clear();
			global_temp_param_list.clear();

				
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON{

			log_file("func_declaration: type_specifier ID LPAREN RPAREN SEMICOLON ");
			
			if(!table.insert($2->getName(),"FUNCTION_NAME")){
				
				SymbolInfo* temp = table.lookup($2->getName());

				if (temp->getType()=="FUNCTION_NAME")
					log_error("Function "+$2->getName()+" already exists");
				else
					log_error($2->getName()+" already declared as a global variable");
			}
			else{

				SymbolInfo* temp = table.lookup($2->getName());
				temp->setFuncParameters(global_temp_param_list);
				temp->setFuncReturnType($1->getVarType());

			}
			
		
				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+"();");
				log_file_no_lineNo($$->getToPrint());
			


				
		}
		;



func_definition : type_specifier ID LPAREN parameter_list RPAREN {

		global_inside_function = $[ID]->getName();
		print_no_tab($2->getName()+ " PROC");

		current_func_def = $2->getName();
		suppress_function_calls = false;

		stackElemInScope++; // for the return address?
		push("BP");
		print("MOV BP, SP");
		// print("ADD BP,2");


	
		}compound_statement
		{	

			log_file("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
			if(!table.insert($2->getName(),"FUNCTION_NAME")){
				
				//predeclared function

				SymbolInfo* temp = table.lookup($2->getName());

				if (temp->getType()!="FUNCTION_NAME")
					log_error($2->getName()+" already declared as a global variable" , global_temp_func_start_line_no);

				//NEW CODE
				else if (temp->getFuncDefined())
					log_error($2->getName()+" function has already been defined");
		
				else if (temp->getFuncParameters().size()!=global_temp_param_list.size()){

					log_error("Total number of arguments mismatch with declaration in function "+ $2->getName() , global_temp_func_start_line_no);
					}
		
				else if (temp->getFuncParameters()!=global_temp_param_list)
					log_error("Parameters do not match for function_definition "+$2->getName(), global_temp_func_start_line_no);

				else if(temp->getFuncReturnType()!=$1->getVarType())
					log_error("Return type mismatch with function declaration in function "+$2->getName(), global_temp_func_start_line_no);

				else if(temp->getFuncReturnType()!=global_temp_return_type){
					// log_error("Return Type do not match for function_definition and return statement", global_temp_func_start_line_no);
				}	

				
				// log_file($2->getName()+" function definition accepted");
				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+"("+$4->getToPrint()+")"+$[compound_statement]->getToPrint());
				log_file_no_lineNo($$->getToPrint());

				//NEW CODE
				temp->setFuncDefined(true);	

				global_temp_return_type = "void";

			}
			else{

				// log_file($2->getName()+" function definition accepted");
				SymbolInfo* temp = table.lookup($2->getName());
				temp->setFuncReturnType($1->getVarType());



				temp->setFuncParameters(global_temp_param_list);
				// cout<<$1->getToPrint()<<" set func param to "<<temp->getFuncParameters().size()<<endl;
				
				//NEW CODE
				temp->setFuncDefined(true);


				if(temp->getFuncReturnType()!=global_temp_return_type){
					// log_error("Return Type do not match for function_definition and return statement");
				}			
				global_temp_return_type="void";

				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+"("+$4->getToPrint()+")"+$[compound_statement]->getToPrint());
				log_file_no_lineNo($$->getToPrint());



			}



			print("func_exit_"+$2->getName()+":");
			pop("BP");
			pop("AX ;contains return addr");
			push("DX; contains return val"); //DX reserved for return value
			push("AX");
			print("RET");
			print("ENDP "+$2->getName());
			print_main_code(";function definition of "+$2->getToPrint());
			print("");
			print("");
			
			global_temp_param_list_for_scope.clear();
			global_temp_param_list.clear();
			global_inside_function = "";
		}



		| type_specifier ID LPAREN RPAREN {

			global_inside_function = $[ID]->getName();

			print_no_tab($2->getName()+ " PROC");

			current_func_def = $2->getName();

			if($2->getName()=="main"){
				print("MOV AX, @DATA");
				print("MOV DS, AX");
			}

			push("BP");
			print("MOV BP, SP");

			// if($2->getName()!="main"){
			// 	print("ADD BP,2");
			// }
			


		}compound_statement{

			log_file("func_definition: type_specifier ID LPAREN RPAREN compound_statement");
			global_temp_param_list_for_scope.clear();
			global_temp_param_list.clear();

			if(!table.insert($2->getName(),"FUNCTION_NAME")){
				
				//predeclared function
				SymbolInfo* temp = table.lookup($2->getName());

				if (temp->getType()!="FUNCTION_NAME")
					log_error($2->getName()+" already declared as a global variable" , global_temp_func_start_line_no);

				//NEW CODE
				else if (temp->getFuncDefined())
					log_error($2->getName()+" function has already been defined");
		
				else if (!temp->getFuncParameters().empty())
					log_error("Parameters do not match for function_definition "+$2->getName());

				else if (temp->getFuncReturnType()!=$1->getVarType())
					log_error("Return Type do not match for function_definition and function_declaration");

				else if(temp->getFuncReturnType()!=global_temp_return_type){
					// log_error("Return Type do not match for function_definition and return statement");
				}	

				temp->setFuncDefined(true);
				// log_file($2->getName()+" function definition (no param) accepted");
				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+"() \n"+$[compound_statement]->getToPrint());
				log_file_no_lineNo($$->getToPrint());
				
				global_temp_return_type = "void";

	
			}
			else{
				// log_file($2->getName()+" function definition (no param) accepted");
				SymbolInfo* temp = table.lookup($2->getName());
				temp->setFuncReturnType($1->getVarType());

				if(temp->getFuncReturnType()!=global_temp_return_type){
					// log_error("Return Type do not match for function_definition and return statement");
				}	

				global_temp_return_type="void";
				temp->setFuncDefined(true);

				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+"() "+$[compound_statement]->getToPrint());
				log_file_no_lineNo($$->getToPrint());

				

			}

			print("func_exit_"+$2->getName()+":");
			pop("BP");

			if($2->getName()=="main"){
				print("MOV AH, 4CH");
				print("INT 21H");
			}
			else
				print("RET");
			print("ENDP "+$2->getName());
			print_main_code(";function definition of "+$2->getToPrint());
			print("");
			print("");


			global_inside_function = "";
		}
 		;	



parameter_list : parameter_list COMMA type_specifier ID {

			
			global_temp_param_list.push_back($3->getVarType());
			//cout<<4<<" line: "<<line_count<<endl;
			//printStringVector(global_temp_param_list);
			
			
			$4->setVarType($3->getVarType());

			if(alreadyInStringVector(global_temp_param_list_for_scope,$4->getName()))
				log_error("Multiple declaration of "+$4->getName()+" in parameter");
				
			log_file("parameter_list : parameter_list COMMA type_specifier ID");
			global_temp_param_list_for_scope.push_back($4->getName());


			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint()+","+$3->getToPrint()+" "+$4->getToPrint());
			log_file_no_lineNo($$->getToPrint());

			// printTempParamList();
		}
		| parameter_list COMMA type_specifier{

			log_file("parameter_list : parameter_list COMMA type_specifier");
			global_temp_param_list.push_back($3->getVarType());
			//cout<<3<<" line: "<<line_count<<endl;
			//printStringVector(global_temp_param_list);
			
			
			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint()+" ,"+$3->getToPrint());
			log_file_no_lineNo($$->getToPrint());

			// printTempParamList();
			
		}
 		| type_specifier ID{

			log_file("parameter_list : type_specifier ID");

			global_temp_param_list.clear();
			global_temp_param_list_for_scope.clear();

			global_temp_param_list.push_back($1->getVarType());
			$2->setVarType($1->getVarType());
			global_temp_param_list_for_scope.push_back($2->getName());

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint()+" "+$2->getToPrint());
			log_file_no_lineNo($$->getToPrint());


			// printTempParamList();
		}
		| type_specifier{

			log_file("parameter_list : type_specifier");
			global_temp_param_list.clear();
			global_temp_param_list.push_back($1->getVarType());
			//cout<<1<<" line: "<<line_count<<endl;
			//printStringVector(global_temp_param_list);
			

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());
			// printTempParamList();
		}

		| type_specifier error{

			log_file("parameter_list : type_specifier error");
			global_temp_param_list.clear();
			global_temp_param_list.push_back($1->getVarType());

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());
			yyclearin;

		}
 		;

 		
compound_statement : LCURL{

			global_temp_func_start_line_no = line_count-1;
			table.enterScope();

			stackElemCountStack.push(stackElemInScope);

			stackElemInScope = 0;
			// cout<<"JUST ENTERED ";
			// table.printCurrentScopeID();
			// cout<<getOutputStream();

			// cout<<"about to insert: ";
			// printStringVector(global_temp_param_list_for_scope);
			

			int argument_count = -global_temp_param_list_for_scope.size();

			// table.printAllScopeTable();
			// cout<<getOutputStream()<<endl;

			int i = 0;
			for (string v: global_temp_param_list_for_scope){
				table.insert(v,"ID_NAME");

				SymbolInfo* temp = table.lookup(v);

				// temp->printEverything();
				// cout<<getOutputStream()<<endl;
				temp->setVarType(global_temp_param_list[i]);

				temp->setStackLoc(argument_count++); //minus stuff here
				print(";parameter "+temp->getName()+" at stack loc [BP +"+to_string(-2*argument_count+2)+"]");
				i++;

			}
			global_temp_param_list_for_scope.clear();

			} statements RCURL {


				log_file("compound_statement : LCURL statements RCURL");
			
			

				$$ = new ForPrinting();
				$$->setToPrint("{\n"+$[statements]->getToPrint()+"\n}");

	
				log_file_no_lineNo($$->getToPrint());


				table.printAllScopeTable();
				log_file_no_lineNo(getOutputStream());


				table.exitScope();
				print_main_code(";Deleting Number of variables declared in scope: "+to_string(stackElemInScope));
				print("ADD SP, "+to_string(2*stackElemInScope));
				stackElemInScope = stackElemCountStack.top();
				stackElemCountStack.pop();

				

				
			}
 		    | LCURL RCURL {
				$$ = new ForPrinting();
				$$->setToPrint("{\n  \n}");
				log_file_no_lineNo($$->getToPrint());


			}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON{


			log_file("var_declaration : type_specifier declaration_list SEMICOLON");
			// cout<<"INSERTION TIME!!!!\n";
		    // table.printCurrentScopeTable();
			// cout<<getOutputStream()<<endl;

			if ($1->getVarType()=="void"){
				log_error("Variable type cannot be void");
			}
			else

				

				for(SymbolInfo* ptr: global_temp_dec_list){
					// cout<<v<<endl;
					if(!table.insert(ptr->getName(), "ID_NAME")){
						log_error("Multiple declaration of "+ptr->getName());
					}
					else{
						SymbolInfo* temp = table.lookup(ptr->getName());
						temp -> setVarType($1->getVarType());
						temp -> setArrSize(ptr->getArrSize());


						if (temp->getArrSize()==0){

							

							
							if(table.getCurrentScopeID()=="1"){
								print_start_file(temp->getName()+" DW 1");
								temp->setAsm(temp->getName());
							}
							else{
								temp -> setStackLoc(++stackElemInScope);
								print("SUB SP, 2;"+temp->getName()+" declared, stack lock [BP-"+to_string(2*stackElemInScope)+"]");
							}
								
						}
						else {
							

							if(table.getCurrentScopeID()=="1"){
								print_start_file(temp->getName()+" DW "+to_string(temp->getArrSize())+" DUP(?)");
								temp->setAsm(temp->getName());
								temp->setIsGlobalArray(true);
								//DO LATER
							}
							else{	
								temp -> setStackLoc(++stackElemInScope);
								stackElemInScope+=(temp->getArrSize()-1);
								print("SUB SP, "+to_string(2*temp->getArrSize())+";"+temp->getName()+" declared");
							}

						}

						


						
					}


				}
			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+";");
			log_file_no_lineNo($$->getToPrint());

			global_temp_dec_list.clear();

				print_main_code(";"+$$->getToPrint());


			}

		|type_specifier declaration_list error SEMICOLON{

			log_file("var_declaration : type_specifier declaration_list error SEMICOLON");
			

			if ($1->getVarType()=="void"){
				log_error("Variable type cannot be void");
			}
			else
				for(SymbolInfo* ptr: global_temp_dec_list){
					// cout<<v<<endl;
					if(!table.insert(ptr->getName(), "ID_NAME")){
						log_error("Multiple declaration of "+ptr->getName());
					}
					else{
						SymbolInfo* temp = table.lookup(ptr->getName());
						temp -> setVarType($1->getVarType());
						temp -> setArrSize(ptr->getArrSize());
					}

				}

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+";");
			log_file_no_lineNo($$->getToPrint());

			global_temp_dec_list.clear();
			
		}
			
			
 		 ;
 		 
type_specifier	: INT {

			log_file("type_specifier : INT");
			$$ = new SymbolInfo("INT", "temp");
			$$->setVarType("int");
		
			$$->setToPrint("int");
			log_file_no_lineNo($$->getToPrint());
		}
 		| FLOAT{
			log_error("FLOATS NOT SUPPORTED");
			log_file("type_specifier : FLOAT");
			$$ = new SymbolInfo("FLOAT", "temp");
			$$->setVarType("float");

			$$->setToPrint("float");
			log_file_no_lineNo($$->getToPrint());
		}
 		| VOID{

			log_file("type_specifier : VOID");
			$$ = new SymbolInfo("VOID", "temp");
			$$->setVarType("void");

			$$->setToPrint("void");
			log_file_no_lineNo($$->getToPrint());
		}
 		;
 		
declaration_list : declaration_list COMMA ID
			{	
				log_file("declaration_list : declaration_list COMMA ID ");
				global_temp_dec_list.push_back(new SymbolInfo($3->getName(), "ID_NAME"));

				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+","+$3->getToPrint());
				log_file_no_lineNo($$->getToPrint());
			}

 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
				log_file("declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");
				
				SymbolInfo* temp = new SymbolInfo($3->getName(), "ID_NAME");
				temp->setArrSize( stoi($5->getName()) );
				global_temp_dec_list.push_back( temp );


				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+","+$3->getToPrint()+"["+$5->getToPrint()+"]");
				log_file_no_lineNo($$->getToPrint());
		  }
 		  | ID {
				log_file("declaration_list : ID");
				global_temp_dec_list.clear();
				global_temp_dec_list.push_back(new SymbolInfo($1->getName(), "ID_NAME"));

				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint());
				log_file_no_lineNo($$->getToPrint());
		  	}
 		  | ID LTHIRD CONST_INT RTHIRD {
				log_file("declaration_list : ID LTHIRD CONST_INT RTHIRD ");

				SymbolInfo* temp = new SymbolInfo($1->getName(), "ID_NAME");
				temp->setArrSize( stoi($3->getName()) );
				
				global_temp_dec_list.clear();
				global_temp_dec_list.push_back( temp );


				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+"["+$3->getToPrint()+"]");
				log_file_no_lineNo($$->getToPrint());


		  }
 		  ;
 		  
statements : statement
		{
			log_file("statements : statement");

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());
	
		}
	   | statements statement {
			log_file("statements : statements statement");

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint()+"\n"+$2->getToPrint());
			log_file_no_lineNo($$->getToPrint());
	   }
	   ;
	   



exp_rparen_action: expression RPAREN {

	$$ = new ForPrinting();
	$$->setToPrint($1->getToPrint()+")");
	$$->exp2_start_marker= labelCount++;
	$$->exp3_start_marker= labelCount++;
	$$->stmt1_start_marker= labelCount++;
	$$->stmt1_end_marker= labelCount++;
	$$->stmt2_start_marker= labelCount++;
	$$->stmt2_end_marker= labelCount++;
	

	if($1->getName()=="temp")
		pop("CX");
	else
		print("MOV CX ,"+address_stackQ($1));

	print("CMP CX, 0");
	print("JZ statement2_start"+to_string($$->stmt2_start_marker));
}

statement[main] : var_declaration {
		log_file("statement : var_declaration");
		$$ = new ForPrinting();
		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());

		}
	  | expression_statement {
		log_file("statement : expression_statement");
		$$ = new ForPrinting();
		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());


		if($1->getName()=="temp")
			pop("CX ;popping unassigned expression: "+$$->getToPrint());

		}
	  | compound_statement {
		log_file("statement : compound_statement");
		$$ = new ForPrinting();
		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());
		} 
	  | FOR LPAREN expression_statement[first] {

			// $[first] = new ForPrinting();
			$[first]->exp2_start_marker = labelCount++;
			$[first]->exp3_start_marker= labelCount++;
			$[first]->stmt1_start_marker= labelCount++;
			$[first]->stmt1_end_marker= labelCount++;
			$[first]->stmt2_start_marker= labelCount++;
			$[first]->stmt2_end_marker= labelCount++;


			if($[first]->getName()=="temp")
				pop("CX ;popping unassigned expression: "+$[first]->getToPrint());

				newLabel("for_loop_exp2_start"+to_string($[first]->exp2_start_marker)+":");

			} expression_statement[second]{

				pop("CX");
				print("CMP CX, 1");

				//true
				print("JE for_loop_stmt_start"+to_string($[first]->stmt1_start_marker));

				//not true
				print("JMP for_loop_stmt_end"+to_string($[first]->stmt1_end_marker));

				newLabel("for_loop_exp3_start"+to_string($[first]->exp3_start_marker)+":");

			} expression{

				if($[expression]->getName()=="temp")
					pop("CX ;popping unassigned expression: "+$[expression]->getToPrint());

				
				print("JMP for_loop_exp2_start"+to_string($[first]->exp2_start_marker));

				newLabel("for_loop_stmt_start"+to_string($[first]->stmt1_start_marker)+":");

			} RPAREN statement[sub] {
				log_file("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
				$$ = new ForPrinting();
				$$->setToPrint("for("+$[first]->getToPrint()+$[second]->getToPrint()+$[expression]->getToPrint()+")"+$[sub]->getToPrint() );
				log_file_no_lineNo($$->getToPrint());


				print("JMP for_loop_exp3_start"+to_string($[first]->exp3_start_marker));
				newLabel("for_loop_stmt_end"+to_string($[first]->stmt1_end_marker)+":");

				}
	 



	 /*exp_rparen_action: expression RPAREN {

	$$ = new ForPrinting();
	$$->setToPrint($1->getToPrint()+")");


	if($1->getName()=="temp")
		pop("CX");
	else
		print("MOV CX ,"+address_stackQ($1));

	print("CMP CX, 0");
	print("JZ "+newLabel("statement2_start:"));
	}*/
	 
	 
	 
	  |IF LPAREN exp_rparen_action statement %prec LOWER_THAN_ELSE{
		log_file("statement : IF LPAREN expression RPAREN statement");

		$$ = $3;
		$$->setToPrint("if ("+$3->getToPrint()+$4->getToPrint()+"\n");
		log_file_no_lineNo($$->getToPrint());



		print_main_code(";if ("+$3->getToPrint()+"...");
		newLabel("statement2_start"+to_string($$->stmt2_start_marker)+":");

		}





	  | IF LPAREN exp_rparen_action statement[first] ELSE {

		
		
		
		print("JMP statement2_end"+to_string($3->stmt2_end_marker));
		print("statement2_start"+to_string($3->stmt2_start_marker)+":");
			


	  } 

	  statement[second] {

		log_file("statement : IF LPAREN expression RPAREN statement ELSE statement");
		$$ = new ForPrinting();
		$$->setToPrint("if ("+$3->getToPrint()+$[first]->getToPrint()+"\n else \n"+$[second]->getToPrint() );
		log_file_no_lineNo($$->getToPrint());


		// if($[second]->getBaseRecursion()==true){
		newLabel("statement2_end"+to_string($3->stmt2_end_marker)+":");
		// global_statement2_end = -42069;
		print_main_code(";if ("+$3->getToPrint()+"...");
		
		// }

		/* $$->setBaseRecursion(false); */

		

		}


		
	  | WHILE LPAREN {



		whileTemp = new ForPrinting();
		whileTemp->exp2_start_marker= labelCount++;
		whileTemp->exp3_start_marker= labelCount++;
		whileTemp->stmt1_start_marker= labelCount++;
		whileTemp->stmt1_end_marker= labelCount++;
		whileTemp->stmt2_start_marker= labelCount++;
		whileTemp->stmt2_end_marker= labelCount++;

		newLabel("while_exp_start"+to_string(whileTemp->exp2_start_marker)+":");


	  }expression{

		pop("CX");
		print("CMP CX, 0");
		print("JZ while_stmt_end"+to_string(whileTemp->stmt1_end_marker));
		


	  } RPAREN statement[while] {
		log_file("statement : WHILE LPAREN expression RPAREN statement");

		$$ = new ForPrinting();
		$$->setToPrint("while ("+$[expression]->getToPrint()+")"+$[while]->getToPrint() );
		log_file_no_lineNo($$->getToPrint());


		print("JMP while_exp_start"+to_string(whileTemp->exp2_start_marker));
		newLabel("while_stmt_end"+to_string(whileTemp->stmt1_end_marker)+":");

		}





	  | PRINTLN LPAREN ID RPAREN SEMICOLON {
		log_file("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
		$$ = new ForPrinting();
		$$->setToPrint("println ("+$3->getToPrint()+");" );
		log_file_no_lineNo($$->getToPrint());


		SymbolInfo* temp = table.lookup($3->getName());

		push(address_stackQ(temp));

		print("CALL PRINTLN");

		print("ADD SP, 2 ; popping print param");
		stackElemInScope--;

		
		print_main_code(";"+$$->getToPrint());


		
		}
	  | RETURN expression SEMICOLON {



		log_file("statement : RETURN expression SEMICOLON ");

		global_temp_return_type = $2->getVarType();

		$$ = new ForPrinting();
		$$->setToPrint("return "+$2->getToPrint() +";");
		log_file_no_lineNo($$->getToPrint());
		
		if($2->getName()=="temp")
			pop("DX ;return statement popping expression"); // this DX will be caught by the compound_statement rule
		else
			print("MOV DX,"+address_stackQ($2));

		
		//NEW NEW CODE

		stack<int> tempStack;
		tempStack = stackElemCountStack;
		int tempStackElemInScope = stackElemInScope;

		while(!tempStack.empty()){
			print_main_code(";(Eefore return) Deleting Number of variables declared in scope: "+to_string(tempStackElemInScope));
			print("ADD SP, "+to_string(2*tempStackElemInScope));
			tempStackElemInScope = tempStack.top();
			tempStack.pop();
		}


		print("JMP func_exit_"+current_func_def);
		suppress_function_calls = true;

		print_main_code(";"+$$->getToPrint());

		}


	  ;
	  
expression_statement : SEMICOLON	{
				log_file("expression_statement : SEMICOLON	");
				$$ = new SymbolInfo("temp","EXPRESSION_STATEMENT_EMPTY");
				$$->setToPrint(";");
				log_file_no_lineNo($$->getToPrint());

			}
			| expression SEMICOLON {log_file("expression_statement : expression SEMICOLON	");
				
				$$ = new SymbolInfo(*$1);
				$$ -> setType("EXPRESSION_STATEMENT");

				$$->setToPrint($1->getToPrint()+";");
				log_file_no_lineNo($$->getToPrint());
			}
			| expression error{
				log_error("expression_statement : expression error. Missing semicolon");

				$$ = new SymbolInfo(*$1);
				$$ -> setType("EXPRESSION_STATEMENT");
				$$->setToPrint($1->getToPrint()+";");
				log_file_no_lineNo($$->getToPrint());
			}
			;
	  
variable : ID {
	log_file("variable : ID");

	if(!table.lookup($1->getName()))
		log_error("Undeclared variable "+$1->getName());
		else{
			$$ = table.lookup($1->getName());
			$$ -> setType("VARIABLE");
			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());
		}
	}
	
	 | ID LTHIRD expression RTHIRD {

		log_file("variable : ID LTHIRD expression RTHIRD ");
		if(!table.lookup($1->getName()))
			log_error("Undeclared variable "+$1->getName());
		
		SymbolInfo* temp = table.lookup($1->getName());

		$$ = new SymbolInfo($1->getToPrint()+"["+$3->getToPrint()+"]", "VARIABLE_INDEXED");
		$$ -> setVarType(temp->getElementType());
		$$ -> setStackLoc(temp->getStackLoc());
		$$ -> setIsGlobalArray(temp->getIsGlobalArray());
		$$ -> setAsm(temp->getAsm());

		if (temp->getArrSize()==0){
			log_error($1->getName()+" not an array");
			$$ -> setVarType(temp->getVarType());
		}
		

		else if ($3->getVarType()!="int"){
			log_error("Expression inside third brackets not an integer"); //Expression: "+$3->getToPrint()+", Var Type: "+ $3->getVarType(true));
		}
		
		$$->setToPrint($1->getToPrint()+"["+$3->getToPrint()+"]");
		log_file_no_lineNo($$->getToPrint());





		if ($3->getName()!="temp"){
			//expressions would have already been pushed
			print("MOV CX, "+address_stackQ($3));
			push("CX");
			
		}
		
		print_main_code(";"+$$->getToPrint()+" pushed index to stack");
		//CX contains the index
		//variables need to know they have a index in stack
		//Need to pass up the index until it's used or assigned.
		

	
	}

	 
	 ;
	 
expression : logic_expression	{
		log_file("expression : logic expression");

		$$ = new SymbolInfo(*$1);
		$$ -> setType("EXPRESSION");
		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());
		}
	   | variable ASSIGNOP logic_expression {

		log_file("expression : variable ASSIGNOP logic_expression ");
		
		if ($1->getVarType()=="void" || $3->getVarType()=="void")
			log_error("Void function used in expression");

		else if($1->getVarType()==$3->getVarType()){

		}

		else if($1->getVarType()=="float" && $3->getVarType()=="int"){
			// log_error("Type Mismatch. Casting int to float");
			// log_error($1->getName()+" AND "+$3->getName());
		}

		else if($1->getVarType()=="int" && $3->getVarType()=="float"){
			log_error("Type Mismatch. Casting float to int");
		}
		else if($1->getVarType()=="undeclared type" || $3->getVarType()=="undeclared type"){

		}
		else {
			log_error("Type Mismatch. Left operand is "+$1->getVarType()+" --- Right operand is "+$3->getVarType());
		}


		$$ = new SymbolInfo("temp", "EXPRESSION");
		$$->setToPrint($1->getToPrint()+"="+$3->getToPrint());
		log_file_no_lineNo($$->getToPrint());

	
		if ($3->getName()=="temp")
			pop("CX");
		else{
			
			print("MOV CX, "+address_stackQ($3));
			print_main_code(";"+$3->getName());
		}

		if ($1->getType()=="VARIABLE_INDEXED"){
			//the first elem in stack top should be the one pushed by logical_expression
			//the second elem should the one pushed by variable -> id[expression]
			//y[0] at [BP - 2]
			//y[1] at [BP - 4]
			//y[2] at [BP - 6]
			//y[3] at [BP - 8]
			//y[4] will be at [BP-10] or [BP-AX*2-2] or [BP-AX*2-base]
			print(";-----x[k]=y-----");
		
			pop("AX; contains k"); 
			print("SAL AX, 1");

			push("BP");
			if($1->getIsGlobalArray()){
				print("MOV BP, AX");
				print("MOV "+$1->getAsm()+"[BP], CX");
			}
			else{
				
				print("ADD AX, "+ getStackDepth($1));
				print("SUB BP, AX");
				print("MOV [BP], CX");
				
			}
			pop("BP");
			print(";----------");

		}
   
		else
			print("MOV "+address_stackQ($1)+", CX");

		push("CX ;redundant ASSIGNOP push for regularity");
		print_main_code(";"+$$->getToPrint());
	   }
	   ;
			
logic_expression : rel_expression 	{

			log_file("logic_expression : rel_expression");
			$$ = new SymbolInfo(*$1);
			$$ -> setType("LOGIC_EXPRESSION");

			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());
			
		}
		 | rel_expression LOGICOP rel_expression 	{
			log_file("logic_expression : rel_expression LOGICOP rel_expression ");
			if ($1->getVarType()!="int")
				log_error("Left operand of logical operation not an integer. It's a " +$1->getVarType());
			else if ($3->getVarType()!="int")
				log_error("Right operand of logical operation not an integer. It's a "+$3->getVarType());
			else{
				$$ = new SymbolInfo("temp","LOGIC_EXPRESSION");
				$$ -> setVarType("int");
				$$->setToPrint($1->getToPrint()+$2->getName()+$3->getToPrint() );
				log_file_no_lineNo($$->getToPrint());


				if ($1->getName()=="temp")
					pop("CX");
				else
					print("MOV CX, "+ address_stackQ($1));

				print("CMP CX, 0");
				



				if ($2->getName()=="&&"){

					print("JZ set_0_"+to_string(++labelCount));

					if ($3->getName()=="temp")
						pop("BX");			
					else
						print("MOV BX, "+ address_stackQ($3));
					
					print("CMP BX, 0");
					print("JZ set_0_"+to_string(labelCount));

					print("\t MOV CX, 1 \n\t JMP skip_zero"+to_string(++labelCount));

					print("set_0_"+to_string(labelCount-1)+": \n\t MOV CX, 0 \n\t skip_zero"+to_string(labelCount)+":");

				}
				else{
					print("JNZ set_1_"+to_string(++labelCount));
					if ($3->getName()=="temp")
						pop("BX");
					else
						print("MOV BX, "+ address_stackQ($3));

					
					print("CMP BX, 0");
					print("JNZ set_1_"+to_string(labelCount));


					print("\t MOV CX, 0 \n\t JMP skip_one"+to_string(++labelCount));

					print("set_1_"+to_string(labelCount-1)+": \n\t MOV CX, 1 \n\t skip_one"+to_string(labelCount)+":");


				}
				push("CX");
				$$ -> setStackLoc(stackElemInScope); //push(..) increments it
	
				print_main_code(";"+$$->getToPrint());


			}
		 }
		 ;
			
rel_expression	: simple_expression {
			log_file("rel_expression : simple_expression");
			$$ = new SymbolInfo(*$1);
			$$ -> setType("REL_EXPRESSION");


			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());
			
		}
		| simple_expression RELOP simple_expression	{
			log_file("rel_expression : simple_expression RELOP simple_expression");
			$$ = new SymbolInfo("temp","REL_EXPRESSION");
			$$ -> setVarType("int");


			$$->setToPrint($1->getToPrint()+$2->getName()+$3->getToPrint() );
			log_file_no_lineNo($$->getToPrint());

			//("<="|"=="|">="|"!="|">"|"<")

			if($3->getName()=="temp")
				pop("BX");
			else
				print("MOV BX,"+address_stackQ($3));

			if($1->getName()=="temp")
				pop("CX");
			else
				print("MOV CX,"+address_stackQ($1));

			print("CMP CX, BX");



			if($2->getName()=="<="){
				print("JLE set_1_"+to_string(++labelCount));
			}
			else if ($2->getName()=="=="){
				print("JE set_1_"+to_string(++labelCount));
			}
			else if ($2->getName()=="!="){
				print("JNE set_1_"+to_string(++labelCount));
			}
			else if ($2->getName()==">="){
				print("JGE set_1_"+to_string(++labelCount));
			}
			else if ($2->getName()==">"){
				print("JG set_1_"+to_string(++labelCount));
			}
			else if ($2->getName()=="<"){
				print("JL set_1_"+to_string(++labelCount));
			}

			print("MOV AX, 0 \n\tJMP skip_one"+to_string(++labelCount));

			print("set_1_"+to_string(labelCount-1)+": \n\tMOV AX,1 \n\tskip_one"+to_string(labelCount)+":");

			push("AX");

			print_main_code(";"+$$->getToPrint());

		}
		;
				
simple_expression : term {
			log_file("simple_expression : term");
			$$ = new SymbolInfo(*$1);
			$$->setType("SIMPLE_EXPRESSION");
			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());
		}
		  | simple_expression ADDOP term {
			log_file("simple_expression : simple_expression ADDOP term");
			if ($1->getVarType()=="void" || $3->getVarType()=="void")
				log_error("Void function used in expression");
			$$ = new SymbolInfo("temp","SIMPLE_EXPRESSION");
			$$ -> setVarType(getDominantType($1, $3));
			$$->setToPrint($1->getToPrint()+ $2->getName() + $[term]->getToPrint());
			log_file_no_lineNo($$->getToPrint());



			//simple_expression was pushed first and so term is on top of it. CX will hold term and BX will hold simple_expression
		  	
			if ($3->getName()=="temp")
				pop("CX");
			else
				print("MOV CX, "+ address_stackQ($3));

			if ($1->getName()=="temp")
					pop("BX");
			else
				print("MOV BX, "+ address_stackQ($1));


			if ($2->getName()=="+"){

				print("ADD BX, CX");
			}
			else{
				print("SUB BX, CX");
			}

			
			push("BX");

			$$ -> setStackLoc(stackElemInScope);

			table.printCurrentScopeID();

			print_main_code(";"+$$->getToPrint()+"  "+getOutputStream());

		  }

		| simple_expression ADDOP error term {

			
			log_file("simple_expression : simple_expression ADDOP error term");


			if ($1->getVarType()=="void" || $4->getVarType()=="void")
				log_error("Void function used in expression");

			$$ = new SymbolInfo("temp","SIMPLE_EXPRESSION");

			$$ -> setVarType(getDominantType($1, $4));

			$$->setToPrint($1->getToPrint()+ $2->getName() + $[term]->getToPrint());
		
			log_file_no_lineNo($$->getToPrint());
		  }

		  ;
					
term :	unary_expression {
		log_file("term : unary_expression");
		$$ = new SymbolInfo(*$1);
		$$ -> setType("TERM");

		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());
		}
     |  term MULOP unary_expression{
		
		log_file("term : term MULOP unary_expression");
		//possibly convert chars to numbers here.

		
		if ($1->getVarType()=="void" || $3->getVarType()=="void")
			log_error("Void function used in expression");

		$$ = new SymbolInfo("temp","TERM");
		$$ -> setVarType(getDominantType($1, $3));

		if($2->getName()=="%"){
			if ($1->getVarType()!="int"||$3->getVarType()!="int")
				log_error("Non-Integer operand on modulus operator");
			else if($3->getName()=="0")
				log_error("Modulus by Zero");
			$$ -> setVarType("int");		
		}


		$$->setToPrint($1->getToPrint()+$2->getName()+$3->getToPrint() );
		log_file_no_lineNo($$->getToPrint());


			if ($3->getName()=="temp")
				pop("BX");
			else
				print("MOV BX, "+ address_stackQ($3));

			if ($1->getName()=="temp")
				pop("AX");			
			else
				print("MOV AX, "+ address_stackQ($1));	
				

			if ($2->getName()=="*"){
				print("IMUL BX");
			}
			else if ($2->getName()=="/"){
				
				print("CWD");
				print("IDIV BX");
			}
			else{
				
				print("CWD");
				print("IDIV BX");
				print("MOV AX , DX");
			}
					
			push("AX");
			$$ -> setStackLoc(stackElemInScope);

			print_main_code(";"+$$->getToPrint());



	 }
     ;

unary_expression : ADDOP unary_expression	{


			if ($2->getVarType()=="void")
				log_error("Void function used in expression");

			log_file("unary_expression : ADDOP unary_expression");
			$$ = new SymbolInfo("temp","UNARY_EXPRESSION"); 
			$$->setVarType($2->getVarType());

			$$->setToPrint($1->getName()+$2->getToPrint());
			log_file_no_lineNo($$->getToPrint());



			if ($1->getName()=="-"){

				print("MOV CX, 0");
				if ($2->getName()=="temp"){
					pop("AX");
					print("SUB CX, AX");
				}
				else{			
					print("SUB CX, "+address_stackQ($2));
				}

				push("CX");
				$$ -> setStackLoc(stackElemInScope);
				print_main_code(";"+$$->getToPrint());
			}


			}
		 | NOT unary_expression {

			if ($2->getVarType()=="void")
				log_error("Void function used in expression");

			log_file("unary_expression : NOT unary_expression");
			$$ = new SymbolInfo("temp","UNARY_EXPRESSION"); 
			$$->setVarType("int");

			$$->setToPrint("!"+$2->getToPrint());
			log_file_no_lineNo($$->getToPrint());

			if ($2->getName()=="temp"){
				pop("CX");
			}
			else{			
				print("MOV CX, "+address_stackQ($2));
			}
			print("NOT CX");
			push("CX");


			$$ -> setStackLoc(stackElemInScope);
			print_main_code(";"+$$->getToPrint());

			}
		 | factor {

			log_file("unary_expression : factor");


			$$ = new SymbolInfo(*$1);
			$$->setType("UNARY_EXPRESSION");
			

			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());
		 }
		 ;
	
factor	: variable {
		log_file("factor : variable ");
		

		if ($1->getType()=="VARIABLE_INDEXED"){
			//when variable is reduced to factor, only the value is important not the location cuz its not gonna be set
			$$ = new SymbolInfo("temp", "FACTOR");
			$$-> setVarType($1->getVarType());

			print(";-----x[k]-----");
		
			pop("AX; contains k"); 
			print("SAL AX, 1");


			push("BP");
			if($1->getIsGlobalArray()){
				print("MOV BP, AX");
				print("MOV CX, "+$1->getAsm()+"[BP]");
			}
			else{
				
				print("ADD AX, "+ getStackDepth($1));
				print("SUB BP, AX");
				print("MOV CX, [BP]");
				
			}
			pop("BP");

			push("CX ;passing value of x[k]");
			print(";----------");
			print_main_code(";"+$1->getToPrint());
			
		}
		else{
			$$ = new SymbolInfo(*$1);
		}

		
		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());
		

	} 
	| ID LPAREN argument_list RPAREN {

		log_file("factor : ID LPAREN argument_list RPAREN");

		SymbolInfo* temp = table.lookup($1->getName());
		if ($1->getName()==global_inside_function){
			//recursive function
		}
		else if(!temp)
			log_error("Undeclared function "+$1->getName());
		else if (temp->getType()!="FUNCTION_NAME")
			log_error($1->getName()+" is not a function");
	
		//NEW CODE
		else if (!temp->getFuncDefined()){
			log_error($1->getName()+" has been declared but not defined");
		}
		else if (alreadyInStringVector(library_functions, temp->getName())){
			//pass
		}
	
		else if (temp->getFuncParameters().size()!=global_temp_arg_list.size()){
			cout<<temp->getFuncParameters().size()<<"  "<<global_temp_arg_list.size()<<endl;
			log_error("Total number of arguments mismatch in function "+ $1->getName());
		}
		else if (temp->getFuncParameters()!= global_temp_arg_list){

			int i = 0;

			for (string str1: temp->getFuncParameters()){
				if(str1 != global_temp_arg_list[i]){
					log_error("Type Mismatch. Trying to cast "+global_temp_arg_list[i]+" to "+str1);
					break;
				}
				i++;
			}
			// log_error("Arguments do not match function parameters. ");
		}

		
		$$ = new SymbolInfo("temp","FUNCTION_RETURN");
		$$->setToPrint($1->getToPrint()+"("+$3->getToPrint()+")");
		log_file_no_lineNo($$->getToPrint());
		
		if (temp)
			$$ ->setVarType(temp->getFuncReturnType());
		

		print("CALL "+$1->getName());
		
		print("POP DX ; return value"); //DX has the return value which may be garbage
		print("ADD SP, "+ to_string(2*global_temp_arg_list.size())+"; popping the arguments");

		

		//pushing increments this
		stackElemInScope -= global_temp_arg_list.size();


		push("DX; moves the value up like other factors."); //moves the value up like other factors. redundant but helps legibility 

		print_main_code(+";"+$$->getToPrint());
		global_temp_arg_list.clear();

		
	}

	| LPAREN expression RPAREN {
		log_file("factor : LPAREN expression RPAREN");
		$$ = new SymbolInfo(*$2);
		$$->setToPrint("("+$2->getToPrint()+")");
		log_file_no_lineNo($$->getToPrint());
	}
	| CONST_INT {
		log_file("factor : CONST_INT");
		$$ = new SymbolInfo(*$1);
	    $$ -> setAsm($1->getName());
		
		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());

	}
	| CONST_FLOAT {
		log_error("FLOATS NOT SUPPORTED");
		log_file("factor : CONST_FLOAT");
			$$ = new SymbolInfo(*$1);

		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());

	}
	| variable INCOP {

		log_file("factor : variable INCOP");
		$$ = new SymbolInfo("temp", "FACTOR");

		$$-> setVarType($1->getVarType());
		$$->setToPrint($1->getName()+$2->getToPrint());
		log_file_no_lineNo($$->getToPrint());

		//passing the old value with stack

		if ($1->getType()=="VARIABLE_INDEXED"){

			print(";----(x[k]++)------");
		
			pop("AX; contains k"); 
			print("SAL AX, 1");


			push("BP");
			if($1->getIsGlobalArray()){
				print("MOV BP, AX");
				print("MOV CX, "+$1->getAsm()+"[BP] ;saving old value");
				print("ADD "+$1->getAsm()+"[BP], 1 ;incrementing ");
				
			}
			else{
				
				print("ADD AX, "+ getStackDepth($1));
				print("SUB BP, AX");
				print("MOV CX, [BP] ;saving old value");
				print("ADD [BP], 1 ;incrementing");
				
			}

			pop("BP");

			
			push("CX; passing old value via stack");
			print(";----------");

			
		}
		else{
		
			print("MOV CX, "+address_stackQ($1));

			print("MOV AX, "+address_stackQ($1));

			print("ADD AX, 1");

			print("MOV "+address_stackQ($1)+", AX");


			push("CX");

		}
	
			print_main_code(";"+$$->getToPrint());

		//??	
	}
	| variable DECOP {
		//??
		log_file("factor : variable DECOP");
		$$ = new SymbolInfo("temp", "FACTOR");
		$$-> setVarType($1->getVarType());
		$$->setToPrint($1->getName()+$2->getToPrint());
		log_file_no_lineNo($$->getToPrint());

		if ($1->getType()=="VARIABLE_INDEXED"){

			print(";----(x[k]--)------");
		
			pop("AX ;contains k"); 
			print("SAL AX, 1");


			push("BP");
			if($1->getIsGlobalArray()){
				print("MOV BP, AX");
				print("MOV CX, "+$1->getAsm()+"[BP] ;saving old value");
				print("SUB "+$1->getAsm()+"[BP], 1 ;incrementing ");
				
			}
			else{
				
				print("ADD AX, "+ getStackDepth($1));
				print("SUB BP, AX");
				print("MOV CX, [BP] ;saving old value");
				print("SUB [BP], 1 ;decrementing");
				
			}

			pop("BP");

	
			push("CX ;passing old val via stack"); //passing old value with stack
			print(";----------");

			
		}
		else{
			print("MOV CX, "+address_stackQ($1));

			print("MOV AX, "+address_stackQ($1));

			print("SUB AX, 1");

			print("MOV "+address_stackQ($1)+", AX");


			push("CX");
		}
	
		print_main_code(";"+$$->getToPrint());

	}
	;
	
argument_list : arguments {
			log_file("argument_list : arguments");

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());
			}
			|{	log_file("argument_list :");

				$$ = new ForPrinting();
				$$->setToPrint("");
				log_file_no_lineNo($$->getToPrint());
				global_temp_arg_list.clear();
			  }
			  ;
	
arguments : arguments COMMA logic_expression {
			log_file("arguments : arguments COMMA logic_expression");
			global_temp_arg_list.push_back($3->getVarType());




			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint()+","+$3->getToPrint());
			log_file_no_lineNo($$->getToPrint());



			if($3->getName()!="temp"){
				print("MOV CX, "+address_stackQ($3));
				push("CX");
			}

		}
	      | logic_expression {

			log_file("arguments : logic_expression");
			global_temp_arg_list.clear();
			global_temp_arg_list.push_back($1->getVarType());

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());



			if($1->getName()!="temp"){
				print("MOV CX, "+address_stackQ($1));
				push("CX");
			}

		}
	      ;
 
%%

int main(int argc,char *argv[])
{
	
	if((yyin=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	asmStartFile<<".MODEL SMALL \n .STACK 400H \n.DATA  \n NUMBER_STRING DB '00000$'  \n";
	
	table.insert("printf", "FUNCTION_NAME");

	library_functions.push_back("printf");
	
	SymbolInfo* temp = table.lookup("printf");

	temp->setFuncReturnType("void");
	temp->setFuncDefined(true);

	yyparse();
	
	asmStartFile<<".CODE \n";


	asmCodeFile<<asmPrintProc<<endl;
	asmCodeFile<<"END MAIN\n";



	asmCodeFile.close();
	asmStartFile.close();
	logFile.close();
	errorFile.close();

	
	string temp_optimized = optimize_code("tempAsmCodeSegment.asm");
	
	
	ofstream final_optimized("optimized_code.asm");




	fstream newfile;
    newfile.open("code.asm",ios::in); //open a file to perform read operation using file object

	if (newfile.is_open()){   //checking whether the file is open
      string tp;
      while(getline(newfile, tp)){
		final_optimized<<tp<<endl;
	   }
	}
	newfile.close();

	newfile.open(temp_optimized,ios::in); //open a file to perform read operation using file object

	if (newfile.is_open()){   //checking whether the file is open
      string tp;
      while(getline(newfile, tp)){
		final_optimized<<tp<<endl;
	   }
	}
	newfile.close();
	final_optimized.close();


	ofstream final_file("code.asm", ios::app);

	newfile.open("tempAsmCodeSegment.asm",ios::in); //open a file to perform read operation using file object

	if (newfile.is_open()){   //checking whether the file is open
      string tp;
      while(getline(newfile, tp)){
		final_file<<tp<<endl;
	   }
	}
	newfile.close();	
	final_file.close();

	if(parserError>0){
		cout<<"INVALID CODE INPUT\n";
		ofstream file("code.asm");
		file.close();
		ofstream file2("optimized_code.asm");
		file2.close();
	}



	/* ifstream if_a ("asmStartFile",std::ios_base::binary);
	ifstream if_b("asmCodeFile", std::ios_base::binary);
	ofstream of_c("code", std::ios_base::binary);
	cout << if_a.rdbuf() << if_b.rdbuf();
	of_c.close();
	if_a.close(); 
	if_b.close(); */
	return 0;
}

