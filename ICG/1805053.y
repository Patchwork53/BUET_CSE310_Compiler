%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<stack>
#include<cmath>
#include "1805053SymTable.h"
#include "lex.yy.c"

using namespace std;



extern int line_count;
int yyparse (void);
int  yylex (void);
SymbolTable table(13);
int parserError = 0;
vector<string> global_temp_param_list;
vector<string> global_temp_param_list_for_scope;
vector<SymbolInfo*> global_temp_dec_list;
int global_temp_int;
string global_temp_var_type;
vector<string> library_functions;
string global_temp_return_type="void";
int global_temp_func_start_line_no = -1;



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

%type <symPtr> type_specifier expression logic_expression rel_expression simple_expression term unary_expression factor variable
%type <ForPrintingPtr> unit program func_declaration func_definition parameter_list expression_statement statement  declaration_list var_declaration compound_statement arguments argument_list
%type <ForPrintingPtr> statements

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE




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
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
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


					// cout<<line_count<<"####"<<endl;
					// printStringVector(temp->getFuncParameters());
					// printStringVector(global_temp_param_list);
					// cout<<"#__#"<<endl;
					
					log_error("Total number of arguments mismatch with declaration in function "+ $2->getName() , global_temp_func_start_line_no);
					}
		
				else if (temp->getFuncParameters()!=global_temp_param_list)
					log_error("Parameters do not match for function_definition "+$2->getName(), global_temp_func_start_line_no);

				else if(temp->getFuncReturnType()!=$1->getVarType())
					log_error("Return type mismatch with function declaration in function "+$2->getName(), global_temp_func_start_line_no);

				else if(temp->getFuncReturnType()!=global_temp_return_type){
					log_error("Return Type do not match for function_definition and return statement", global_temp_func_start_line_no);
				}	

				
				// log_file($2->getName()+" function definition accepted");
				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+"("+$4->getToPrint()+")"+$6->getToPrint());
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
				
				//NEW CODE
				temp->setFuncDefined(true);


				if(temp->getFuncReturnType()!=global_temp_return_type){
					log_error("Return Type do not match for function_definition and return statement");
				}			
				global_temp_return_type="void";

				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+"("+$4->getToPrint()+")"+$6->getToPrint());
				log_file_no_lineNo($$->getToPrint());



			}
			global_temp_param_list_for_scope.clear();
			global_temp_param_list.clear();
		}
		| type_specifier ID LPAREN RPAREN compound_statement{

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
					log_error("Return Type do not match for function_definition and return statement");
				}	

				
					// log_file($2->getName()+" function definition (no param) accepted");
					$$ = new ForPrinting();
					$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+"() \n"+$5->getToPrint());
					log_file_no_lineNo($$->getToPrint());
				
				global_temp_return_type = "void";

				
			}
			else{
				// log_file($2->getName()+" function definition (no param) accepted");
				SymbolInfo* temp = table.lookup($2->getName());
				temp->setFuncReturnType($1->getVarType());

				if(temp->getFuncReturnType()!=global_temp_return_type){
					log_error("Return Type do not match for function_definition and return statement");
				}	

				global_temp_return_type="void";

				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+"() "+$5->getToPrint());
				log_file_no_lineNo($$->getToPrint());

			}
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
			//cout<<2<<" line: "<<line_count<<endl;
			//printStringVector(global_temp_param_list);

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

				// cout<<"JUST ENTERED ";
				// table.printCurrentScopeID();
				// cout<<getOutputStream();

				// cout<<"about to insert: ";
				// printStringVector(global_temp_param_list_for_scope);
			
				int i = 0;
				for (string v: global_temp_param_list_for_scope){
					table.insert(v,"ID_NAME");

					SymbolInfo* temp = table.lookup(v);

					temp->setVarType(global_temp_param_list[i]);
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
					}

				}

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint()+" "+$2->getToPrint()+";");
			log_file_no_lineNo($$->getToPrint());

			global_temp_dec_list.clear();


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
	   
statement : var_declaration {
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
		}
	  | compound_statement {
		log_file("statement : compound_statement");
		$$ = new ForPrinting();
		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());
		} 
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement {
		log_file("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
		$$ = new ForPrinting();
		$$->setToPrint("for("+$3->getToPrint()+$4->getToPrint()+$5->getToPrint()+")"+$7->getToPrint() );
		log_file_no_lineNo($$->getToPrint());
		}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE{
		log_file("statement : IF LPAREN expression RPAREN statement");

		$$ = new ForPrinting();
		$$->setToPrint("if ("+$3->getToPrint()+")"+$5->getToPrint()+"\n");
		log_file_no_lineNo($$->getToPrint());

		}
	  | IF LPAREN expression RPAREN statement ELSE statement {
		log_file("statement : IF LPAREN expression RPAREN statement ELSE statement");
		$$ = new ForPrinting();
		$$->setToPrint("if ("+$3->getToPrint()+")"+$5->getToPrint()+"\n else \n"+$7->getToPrint() );
		log_file_no_lineNo($$->getToPrint());

		}
	  | WHILE LPAREN expression RPAREN statement {
		log_file("statement : WHILE LPAREN expression RPAREN statement");

		$$ = new ForPrinting();
		$$->setToPrint("while ("+$3->getToPrint()+")"+$5->getToPrint() );
		log_file_no_lineNo($$->getToPrint());

		}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON {
		log_file("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
		$$ = new ForPrinting();
		$$->setToPrint("println ("+$3->getToPrint()+");" );
		log_file_no_lineNo($$->getToPrint());
		}
	  | RETURN expression SEMICOLON {



		log_file("statement : RETURN expression SEMICOLON ");

		global_temp_return_type = $2->getVarType();

		$$ = new ForPrinting();
		$$->setToPrint("return "+$2->getToPrint() +";");
		log_file_no_lineNo($$->getToPrint());

		}

	  ;
	  
expression_statement 	: SEMICOLON	{
		log_file("expression_statement : SEMICOLON	");
		$$ = new ForPrinting();
		$$->setToPrint(";");
		log_file_no_lineNo($$->getToPrint());

	}
			| expression SEMICOLON {log_file("expression_statement : expression SEMICOLON	");
				$$ = new ForPrinting();
				$$->setToPrint($1->getToPrint()+";");
				log_file_no_lineNo($$->getToPrint());
			}
			| expression error{
				log_error("expression_statement : expression error. Missing semicolon");
				$$ = new ForPrinting();
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

		$$ = new SymbolInfo($1->getToPrint()+"["+$3->getToPrint()+"]", "VARIABLE");
		$$ -> setVarType(temp->getElementType());

		if (temp->getArrSize()==0){
			log_error($1->getName()+" not an array");
			$$ -> setVarType(temp->getVarType());
		}
		

		else if ($3->getVarType()!="int"){
			log_error("Expression inside third brackets not an integer"); //Expression: "+$3->getToPrint()+", Var Type: "+ $3->getVarType(true));
		}

	
		
		$$->setToPrint($1->getToPrint()+"["+$3->getToPrint()+"]");
		log_file_no_lineNo($$->getToPrint());
	
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



		/*	if($1->getVarType()==$3->getVarType()){
				// $1 = $3;
				$$ = $1;
				$$ -> setType("EXPRESSION");

				$$->setToPrint($1->getToPrint()+"="+$3->getToPrint());
				log_file_no_lineNo($$->getToPrint());
			}
			else if ($1->getVarType()=="float" && $3->getVarType()=="int"){
				$1 = $3;
				$1 -> setVarType("float");
				$$ = $1;
				$$ -> setType("EXPRESSION");

				$$->setToPrint($1->getToPrint()+"="+$3->getToPrint());
				log_file_no_lineNo($$->getToPrint());
			}
			else {
				log_error("Type mismatch. Trying to cast "+$3->getVarType()+" to "+$1->getVarType());
			}*/

		
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
		}
		;
				
simple_expression : term {
			log_file("simple_expression : term");
			$$ = new SymbolInfo(*$1);

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

			}
		 | NOT unary_expression {

			if ($2->getVarType()=="void")
				log_error("Void function used in expression");

			log_file("unary_expression : NOT unary_expression");
			$$ = new SymbolInfo("temp","UNARY_EXPRESSION"); 
			$$->setVarType("int");

			$$->setToPrint("!"+$2->getToPrint());
			log_file_no_lineNo($$->getToPrint());

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
		$$ = new SymbolInfo(*$1);

		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());

	} 
	| ID LPAREN argument_list RPAREN {

		log_file("factor : ID LPAREN argument_list RPAREN");

		SymbolInfo* temp = table.lookup($1->getName());


		
		if(!temp)
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
	

		else if (temp->getFuncParameters().size()!=global_temp_param_list.size()){
			log_error("Total number of arguments mismatch in function "+ $1->getName());
		}
		else if (temp->getFuncParameters()!= global_temp_param_list){

			int i = 0;

			for (string str1: temp->getFuncParameters()){
				if(str1 != global_temp_param_list[i]){
					log_error("Type Mismatch. Trying to cast "+global_temp_param_list[i]+" to "+str1);
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
		

		global_temp_param_list.clear();

		
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

		$$->setToPrint($1->getToPrint());
		log_file_no_lineNo($$->getToPrint());

	}
	| CONST_FLOAT {
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

		//??	
	}
	| variable DECOP {
		//??
		log_file("factor : variable DECOP");
		$$ = new SymbolInfo("temp", "FACTOR");
		$$-> setVarType($1->getVarType());

		$$->setToPrint($1->getName()+$2->getToPrint());
		log_file_no_lineNo($$->getToPrint());
	}
	;
	
argument_list : arguments {
			log_file("argument_list : arguments");

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());
			}
			|{	log_file("argument_list :");
				global_temp_param_list.clear();
			  }
			  ;
	
arguments : arguments COMMA logic_expression {
			log_file("arguments : arguments COMMA logic_expression");
			global_temp_param_list.push_back($3->getVarType());

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint()+","+$3->getToPrint());
			log_file_no_lineNo($$->getToPrint());
		}
	      | logic_expression {

			log_file("arguments : logic_expression");
			global_temp_param_list.clear();
			global_temp_param_list.push_back($1->getVarType());

			$$ = new ForPrinting();
			$$->setToPrint($1->getToPrint());
			log_file_no_lineNo($$->getToPrint());
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


	
	table.insert("printf", "FUNCTION_NAME");

	library_functions.push_back("printf");
	
	SymbolInfo* temp = table.lookup("printf");

	temp->setFuncReturnType("void");
	temp->setFuncDefined(true);

	yyparse();
	
	logFile.close();
	errorFile.close();
	return 0;
}

