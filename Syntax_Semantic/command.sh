flex 1805053.l
bison -d  1805053.y -Wcounterexamples
g++ -std=c++17 -g -w 1805053.tab.c -o 1805053_code_gen.out
./1805053_code_gen.out $1
rm -f temp_optimized.asm tempAsmCodeSegment.asm parser_log.txt lex.yy.c 1805053.tab.h 1805053.tab.c 1805053_lex_token.txt 1805053_lex_log.txt 1805053_code_gen.out 