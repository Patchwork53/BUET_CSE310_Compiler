%option noyywrap
%option c++
%x NUM_READ
%x DOT_DETECTED
%x SOME_NUM_AFTER_DOT
%x COMPLETE_FLOAT
%x FLOAT_E_DETECTED
%x START_CONST_LITERAL
%x TOO_MANY_DECIMALS
%x MULTILINE_COMMENT_1
%x STAR_COMMENT
%x BUILD_COMPLEX_STRING
%{
#include<iostream>
#include<fstream>
#include<string>
#include "1805053SymTable.h"

using namespace std;

int line_count=1;
int pending_line_inc = 0;
int error_count=0;

// SymbolTable table(97); 
ifstream input;
ofstream logout;
ofstream tokenout;
string logStringBuilder = "";
string tokenStringBuilder = "";
SymbolTable table(7);

char handle_metachar(char c){

	char temp ;

	switch(c){
		case 'n':
		temp = int('\n');
		break;

		case '\"':
		temp = int('\"');
		break;

		case 't':
		temp = int('\t');
		break;

		case '\\':
		temp = int('\\');
		break;

		case 'a':
		temp = int('\a');
		break;

		case 'f':
		temp = int('\f');
		break;

		case '\'':
		temp = int('\'');
		break;

		case 'r':
		temp = int('\r');
		break;

		case 'b':
		temp = int('\b');
		break;

		case 'v':
		temp = int('\v');
		break;

		case '0':
		temp = int('\0');
		break;
	}

	return temp;
}
string _to_upper(string str){

	for(int i=0;i<str.length() ; i++){
		str[i] = toupper(str[i]);
	}
	return str;
}



void do_token_log(string type, string log_name, string token_name = "_NOT_GIVEN_" ){

	if(token_name == "_NOT_GIVEN_")
		token_name = log_name;

	logout<< "Line no "<< line_count<< ": Token <"<< type <<"> Lexeme "<< log_name <<" found"<<endl<<endl<<flush;
	tokenout<< "<" <<type <<", "<< token_name << ">" <<endl<<flush;
}

void do_token_log_arrow(string type, string log_name, string token_name = "_NOT_GIVEN_" ){

	if(token_name == "_NOT_GIVEN_")
		token_name = log_name;


	string token =  "<" +type +", "+ token_name + ">";

	logout<< "Line no "<< line_count<< ": Token <"<<type <<"> Lexeme "<< log_name  <<" found --> "<<token<<endl<<endl<<flush;
	
	tokenout<< token <<endl<<flush;
	
}


void do_token_log_insert(string type, string log_name, string token_name = "_NOT_GIVEN_" ){

	if(token_name == "_NOT_GIVEN_")
		token_name = log_name;

	logout<< "Line no "<< line_count<< ": Token <"<<type <<"> Lexeme "<< log_name  <<" found"<<endl<<endl<<flush;
	tokenout<< "<" <<type <<", "<< token_name << ">" <<endl<<flush;
	
	if(table.insert(log_name ,type))
		table.printAllScopeTable();

	logout<<getOutputStream()<<flush;
}


void do_token_log_insert_arrow(string type, string log_name, string token_name = "_NOT_GIVEN_" ){

	if(token_name == "_NOT_GIVEN_")
		token_name = log_name;

	string token =  "<" +type +", "+ token_name + ">";

	logout<< "Line no "<< line_count<< ": Token <"<<type <<"> Lexeme "<< log_name  <<" found --> "<<token<<endl<<endl<<flush;
	
	tokenout<< token <<endl<<flush;
	
	if(table.insert(log_name ,type))
		table.printAllScopeTable();

	logout<<getOutputStream()<<flush;
}


void logerror(string message){
	error_count++;
	logout<<"Error at line no "<< line_count<<": " << message <<endl<<endl<<flush;

}

%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
NOT_LETTER [^a-zA-Z]
ALPHANUMERIC [a-zA-Z0-9]
ALPHANUMERIC_ [a-zA-Z0-9_]
DIGIT [0-9]
NEWLINE \n

ANYTHING_BUT_NL [^\n]
ANYTHING_BUT_NL_SQ [^\n\']
ANYTHING_BUT_NL_BS [^\\\n]
ANYTHING_BUT_NL_BS_DQ [^\\\"\n]

ANYTHING_BUT_STAR [^*]
STAR_NO_BS [\*][^\/]

%%

{NEWLINE} {
	line_count++;
	//logout<<"newline"<<endl<<flush;
}



\/\/{ANYTHING_BUT_NL}*\\{NEWLINE} {
	pending_line_inc++;
	string yystring = yytext;

	logStringBuilder = yystring;

	BEGIN MULTILINE_COMMENT_1;
	
}

\/\/{ANYTHING_BUT_NL}*/{NEWLINE} {

	string type = "COMMENT";
	logout<< "Line no "<< line_count<< ": Token <"<< type <<"> Lexeme "<< yytext  <<" found"<<endl<<endl<<flush;
	
}

<MULTILINE_COMMENT_1>{ANYTHING_BUT_NL}+\\{NEWLINE} {
	pending_line_inc++;
	string yystring = yytext;
	logStringBuilder += yystring;
}

<MULTILINE_COMMENT_1>{ANYTHING_BUT_NL}*/{NEWLINE} {
	
	string type = "COMMENT";
	logout<< "Line no "<< line_count<< ": Token <"<< type <<"> Lexeme "<< logStringBuilder << yytext <<" found"<<endl<<endl<<flush;
	
	
	line_count+=pending_line_inc;
	pending_line_inc = 0;	
	BEGIN INITIAL;

	/*

		<MULTILINE_COMMENT_1>{NEWLINE} {
			pending_line_inc++;
			string type = "COMMENT";
			logout<< "Line no "<< line_count<< ": Token <"<< type <<"> Lexeme "<< logStringBuilder << yytext <<" found"<<endl<<endl<<flush;	

			line_count+=pending_line_inc;
			pending_line_inc = 0;	
			BEGIN INITIAL;
		}


	*/
}





\/\*({ANYTHING_BUT_STAR}*{STAR_NO_BS}*)*{ANYTHING_BUT_STAR}*\*\/ {

	string yystring = yytext;

	for (int i=0;i<yystring.length();i++){
		if (yystring[i]=='\n')
			pending_line_inc++;
	}

	string type = "STAR COMMENT";
	logout<< "Line no "<< line_count<< ": Token <"<< type <<"> Lexeme " << yytext <<" found"<<endl<<endl<<flush;	

	line_count+=pending_line_inc;
	pending_line_inc = 0;	
	
}

\/\*({ANYTHING_BUT_STAR}*{STAR_NO_BS}*)*{ANYTHING_BUT_STAR}*[^"*/"] {
	string yystring = yytext;

	for (int i=0;i<yystring.length();i++){
		if (yystring[i]=='\n')
			pending_line_inc++;
	}
	

	logerror("Unterminated star comment: " + string(yytext));

	line_count+=pending_line_inc;
	pending_line_inc = 0;	
}


\"{ANYTHING_BUT_NL_BS}*\" {
	string type = "STRING";
	string value = yytext;	
	// value = value.substr(1, value.length()-2);
    do_token_log_arrow(type, value);
}


\"{ANYTHING_BUT_NL_BS}*\\[ntaf\'rbv0'\"]  {

	string yystring = yytext;
	logStringBuilder = yystring;
	tokenStringBuilder = yystring.substr(0, yystring.length() - 2); // last two meta characters
	char temp = handle_metachar(yystring[yystring.length()-1]); // position of ntafrbv0 etc

	tokenStringBuilder+=temp;
	BEGIN BUILD_COMPLEX_STRING;

}

\"{ANYTHING_BUT_NL_BS}*\\{NEWLINE}  {
	pending_line_inc++;
	string yystring = yytext;

	logStringBuilder = yystring;
	tokenStringBuilder = yystring.substr(0, yystring.length() - 2); //last two is BS and NL

	BEGIN BUILD_COMPLEX_STRING;

}


\"{ANYTHING_BUT_NL_BS}*\\[^nt\\af\'rbv0'\"\n]{ANYTHING_BUT_NL}*\"  {
	logerror("Unrecognized escape character: " + string(yytext));
}

<BUILD_COMPLEX_STRING>{ANYTHING_BUT_NL_BS}*\\{NEWLINE} {
	pending_line_inc++;
	string yystring = yytext;
	logStringBuilder += yystring;
	tokenStringBuilder += yystring.substr(0, yystring.length() - 2); //last 2 is forward slash and newline

}



<BUILD_COMPLEX_STRING>{ANYTHING_BUT_NL_BS}*\\[ntaf\'rbv0'\"] {
	
	string yystring = yytext;
	logStringBuilder += yystring;
	tokenStringBuilder += yystring.substr(0, yystring.length() - 2);
	char temp = handle_metachar(yystring[yystring.length()-1]);
	tokenStringBuilder+=temp;

}


<BUILD_COMPLEX_STRING>{ANYTHING_BUT_NL_BS}*\\[^ntaf\'r\\bv0'\"] {

	logerror("unrecognized escape character: " + logStringBuilder + string(yytext));

	line_count+=pending_line_inc;
	pending_line_inc = 0;	
	BEGIN INITIAL;
}


<BUILD_COMPLEX_STRING>{ANYTHING_BUT_NL_BS}*\" {
	string yystring = yytext;

	logStringBuilder += yystring;

	tokenStringBuilder += yystring;
	string type = "STRING";
    do_token_log_arrow(type, logStringBuilder, tokenStringBuilder);

	line_count+=pending_line_inc;
	pending_line_inc = 0;	
	BEGIN INITIAL;
}




<BUILD_COMPLEX_STRING>{ANYTHING_BUT_NL_BS_DQ}* {

	logerror("Unterminated string with metachar/multiline: "+ logStringBuilder + yytext);


	line_count+=pending_line_inc;
	pending_line_inc = 0;	
	BEGIN INITIAL;
}


\"{ANYTHING_BUT_NL_BS_DQ}*  {
	logerror("Unterminated string: " + string(yytext));
	
}





"if" 		|
"for" 		|
"do" 		|
"int" 		|
"float" 	|
"void" 		|
"switch" 	|
"default" 	|
"else" 		|
"while" 	|
"break" 	|
"char" 		|
"double" 	|
"return"	|
"case" 		|
"continue" 	{

	string type = "<"+ _to_upper(yytext) +">";

	logout<< "Line no "<< line_count<< ": Token "<<type <<" Lexeme "<< yytext <<" found"<<endl<<endl<<flush;
	tokenout<< type <<endl<<flush;
		
}

("++"|"--") {do_token_log("INCOP",yytext);}

("<="|"=="|">="|"!="|">"|"<") {	do_token_log("RELOP",yytext); }

= {do_token_log("ASSIGNOP",yytext);}

("&&"|"||") {do_token_log("LOGICOP",yytext);}

! {do_token_log("NOT",yytext);}

[+-] {do_token_log("ADDOP",yytext);}

[*/%] {	do_token_log("MULOP",yytext);}

\(  {	do_token_log("LPAREN",yytext);}

\)  {	do_token_log("RPAREN",yytext);}

\{  {	do_token_log("LCURL",yytext); table.enterScope();} 

\}  {	do_token_log("RCURL",yytext); table.exitScope();}

\[  {	do_token_log("LTHIRD",yytext);}
\]  {	do_token_log("RTHIRD",yytext);}
\,  {	do_token_log("COMMA",yytext);}
\; {	do_token_log("SEMICOLON",yytext);}




(({DIGIT}*\.{DIGIT}+)|({DIGIT}+\.{DIGIT}*))(""|[Ee](""|"-"){DIGIT}+) {
	logStringBuilder = yytext;
	BEGIN COMPLETE_FLOAT;
}

<COMPLETE_FLOAT>{LETTER}+ {
	logStringBuilder+=yytext;
	logerror("Invalid prefix on ID or invalid suffix on Number: " + logStringBuilder);
	BEGIN INITIAL;
}

<COMPLETE_FLOAT>("."{ALPHANUMERIC}*)+ {
	logStringBuilder+=yytext;
	logerror("too many decimal points: " + logStringBuilder);
	BEGIN INITIAL;
}

<COMPLETE_FLOAT>{NOT_LETTER} {
	yyless(0);
	do_token_log_insert("CONST_FLOAT", logStringBuilder );
	BEGIN INITIAL;
}


(_|{LETTER}){ALPHANUMERIC_}* {
	do_token_log_insert("ID", yytext);
}

{DIGIT}+{LETTER}+ {
	logerror("Invalid prefix on ID or invalid suffix on Number " + string(yytext));
	}

{DIGIT}+ {
	do_token_log_insert("CONST_INT", yytext );
	}
	
{DIGIT}+{LETTER}+{ALPHANUMERIC}+("."{ALPHANUMERIC}*)* {
	logerror("Ill formed number: " + string(yytext));
}


\'\\\' {
	logerror("Unterminated character: " + string(yytext));
}
\'\' {
	logerror("Empty Character constant error: " + string(yytext));
}


\'{ANYTHING_BUT_NL}\' {
    
	do_token_log_insert_arrow("CONST_CHAR", string(yytext), string(1,yytext[1]) );
}
\'\\[nt\\af\'rbv0']\' {
	
	char temp = handle_metachar(yytext[2]);
	do_token_log_insert_arrow("CONST_CHAR", string(yytext), string(1,temp));

}
\'{ANYTHING_BUT_NL}{ANYTHING_BUT_NL}+\' {

	logerror("Multi character constant error : " + string(yytext));
	
}

\'{ANYTHING_BUT_NL_SQ}*/{NEWLINE} {
	logerror("Unterminated character: " + string(yytext));
}

{WHITESPACE}+ {}

. {
	// string yystring = yytext;
	// int ascii = char(yystring[0]);
	logerror("Unrecognized character: " + string(yytext));
}


%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	input.open(argv[1]);


	
	
	logout.open("1805053_log.txt");
	tokenout.open("1805053_token.txt");
	
	
	yyFlexLexer* lexer = new yyFlexLexer(input,logout);
	while(lexer->yylex() != 0){};


	table.printAllScopeTable();
    logout<<getOutputStream()<<endl;
	logout<<"Total lines: "<<line_count<<endl;
	logout<<"Total errors: "<<error_count<<endl;


	tokenout.close();
	logout.close();
	input.close();


	return 0;
}
