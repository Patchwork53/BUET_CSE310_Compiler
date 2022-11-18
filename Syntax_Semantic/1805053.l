%option noyywrap
%x COMPLETE_FLOAT
%x MULTILINE_COMMENT_1
%x BUILD_COMPLEX_STRING
%{
#include<iostream>
#include<fstream>
#include<string>
#include<FlexLexer.h>
#include "1805053.tab.h"


using namespace std;

int line_count=1;
int pending_line_inc = 0;
int error_count=0;


ofstream logout("1805053_lex_log.txt");
ofstream tokenout("1805053_lex_token.txt");

ofstream logFile("parser_log.txt");
ofstream errorFile("error.txt");

string logStringBuilder = "";
string tokenStringBuilder = "";
// SymbolTable table(7);
 

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

void do_keyword_token_log(string yytext){
	
	// cout<<"got this "<<yytext<<endl;
	string type = "<"+ _to_upper(yytext) +">";
	logout<< "Line no "<< line_count<< ": Token "<<type <<" Lexeme "<< yytext <<" found"<<endl<<endl<<flush;
	tokenout<< type <<endl<<flush;
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
	
	// if(table.insert(log_name ,type))
	// 	table.printAllScopeTable();

	logout<<getOutputStream()<<flush;
}


void do_token_log_insert_arrow(string type, string log_name, string token_name = "_NOT_GIVEN_" ){

	if(token_name == "_NOT_GIVEN_")
		token_name = log_name;

	string token =  "<" +type +", "+ token_name + ">";

	logout<< "Line no "<< line_count<< ": Token <"<<type <<"> Lexeme "<< log_name  <<" found --> "<<token<<endl<<endl<<flush;
	
	tokenout<< token <<endl<<flush;
	
	// if(table.insert(log_name ,type))
	// 	table.printAllScopeTable();

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


"if" 			{do_keyword_token_log(yytext); return IF;}
"for" 			{do_keyword_token_log(yytext); return FOR;}
"do" 			{do_keyword_token_log(yytext); return DO;}
"int" 			{do_keyword_token_log(yytext); return INT;}
"float" 		{do_keyword_token_log(yytext); return FLOAT;}
"void" 			{do_keyword_token_log(yytext); return VOID;}
"switch" 		{do_keyword_token_log(yytext); return SWITCH;}
"default" 		{do_keyword_token_log(yytext); return DEFAULT;}
"println" 		{do_keyword_token_log(yytext); return PRINTLN;}
"else" 			{do_keyword_token_log(yytext); return ELSE;}
"while" 		{do_keyword_token_log(yytext); return WHILE;}
"break" 		{do_keyword_token_log(yytext); return BREAK;}
"char" 			{do_keyword_token_log(yytext); return CHAR;}
"double" 		{do_keyword_token_log(yytext); return DOUBLE;}
"return"		{do_keyword_token_log(yytext); return RETURN;}
"case" 			{do_keyword_token_log(yytext); return CASE;}
"continue"		{do_keyword_token_log(yytext); return CONTINUE;}


"++" {do_token_log("INCOP",yytext); 
			yylval.symPtr = new SymbolInfo(yytext, "INCOP");
			yylval.symPtr -> setToPrint("++");
			return INCOP;}

"--" {do_token_log("DECOP",yytext); 
			yylval.symPtr = new SymbolInfo(yytext, "DECOP");
			yylval.symPtr -> setToPrint("--");
			return DECOP;}


("<="|"=="|">="|"!="|">"|"<") {	
	do_token_log("RELOP",yytext);
	yylval.symPtr = new SymbolInfo(yytext, "RELOP");
	 return RELOP;}
("&"|"|"|"^"|"<<"|">>") {do_token_log("BITOP", yytext); yylval.symPtr = new SymbolInfo(yytext, "BITOP"); return BITOP;}

= {do_token_log("ASSIGNOP",yytext); return ASSIGNOP;}

("&&"|"||") {do_token_log("LOGICOP",yytext); yylval.symPtr = new SymbolInfo(yytext, "LOGICOP"); return LOGICOP;}

! {do_token_log("NOT",yytext); return NOT;}

[+-] {do_token_log("ADDOP",yytext); yylval.symPtr = new SymbolInfo(yytext, "ADDOP"); return ADDOP;}

[*/%] {	do_token_log("MULOP",yytext); yylval.symPtr = new SymbolInfo(yytext, "MULOP"); return MULOP;}

\(  {	do_token_log("LPAREN",yytext); return LPAREN;}

\)  {	do_token_log("RPAREN",yytext); return RPAREN;}

\{  {	do_token_log("LCURL",yytext); 
		//table.enterScope();
		yylval.symPtr = new SymbolInfo(yytext, "LCURL");
		return LCURL;
	} 

\}  {	do_token_log("RCURL",yytext); 
		//table.exitScope();
		yylval.symPtr = new SymbolInfo(yytext, "RCURL");
		return RCURL;
	}

\[  {	do_token_log("LTHIRD",yytext); return LTHIRD;}
\]  {	do_token_log("RTHIRD",yytext); return RTHIRD;}
\,  {	do_token_log("COMMA",yytext);return COMMA;}
\; {	do_token_log("SEMICOLON",yytext); return SEMICOLON;}




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

	// cout<< "Float found ---- "<<logStringBuilder<<endl;
	yylval.symPtr = new SymbolInfo(logStringBuilder, "CONST_FLOAT");

	yylval.symPtr -> setVarType("float");
	yylval.symPtr -> setToPrint(logStringBuilder);


	return CONST_FLOAT;
}


(_|{LETTER}){ALPHANUMERIC_}* {

	
	string value = yytext;
	// cout<<"ID Detected: "<<value<<endl;
	do_token_log_insert("ID", value);
	yylval.symPtr = new SymbolInfo(value, "ID");
	yylval.symPtr -> setToPrint(value);
	return ID;
}

{DIGIT}+{LETTER}+ {
	logerror("Invalid prefix on ID or invalid suffix on Number " + string(yytext));
	}

{DIGIT}+ {

	string value = yytext;
	do_token_log_insert("CONST_INT", value );
	yylval.symPtr = new SymbolInfo(value, "CONST_INT");
	yylval.symPtr->setVarType("int");
	yylval.symPtr->setToPrint(value);
	return CONST_INT;
	
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

	yylval.symPtr = new SymbolInfo(yytext, "CONST_CHAR");
	yylval.symPtr -> setVarType("char");
	yylval.symPtr -> setToPrint(yytext);
	return CONST_CHAR;






}
\'\\[nt\\af\'rbv0']\' {
	
	char temp = handle_metachar(yytext[2]);
	do_token_log_insert_arrow("CONST_CHAR", string(yytext), string(1,temp));

	yylval.symPtr = new SymbolInfo(yytext, "CONST_CHAR");
	return CONST_CHAR;

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
	string message = "Unrecognized character: " + string(yytext);
	logerror(message);

	logFile<<"Error at line no "<< line_count<<": " << message <<endl<<endl<<flush;
	errorFile<<"Error at line no "<< line_count<<": " << message <<endl<<endl<<flush;
}


%%

