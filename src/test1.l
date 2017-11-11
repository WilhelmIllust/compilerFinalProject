%option noyywrap
%{
#include <stdio.h>
//#include <string>
#include <malloc.h>
#include <string>
#include <iostream>
#include <stdlib.h>
#include "test1.tab.h"
int lineno = 1;
char *p=NULL;
%}

digit		    [0-9]
digits		  {digit}+
number		  [-]?{digits}(\.{digits})?([Ee][+-]?{digits})?
point_list  \{point\s*\[({number},?\s?)*\]\}
string_type [Ss][Tt][Rr][Ii][Nn][Gg]
letter_		  [a-zA-Z_]
M_info      ambientIntensity|shininess|transparency
lightdata   {letter_}*Light
colordata   {letter_}*Color
identifier  {letter_}({letter_}|{digit})*
comment		  \#[^\n]*\n
TRUE_VALUE  [Tt](RUE|rue)|[Yy][Ee][Ss]
FALSE_VALUE [Ff](ALSE|alse)|[Nn][Oo]
indexlist   Indexed({letter_}*)Set
material    [Mm][Aa][Tt][Ee][Rr][Ii][Aa][Ll]
info_type   [Ii][Nn][Ff][Oo]
shape_hints [Ss]hapeHints
shape_hints_num  creaseAngle
literal		  (\"[^\"]*\")|(\'[^\']*\')
float_num   [+-]?[0-9]*\.[0-9]+
newline		  \n
whitespace  [ \t]+

%%
{comment}              { /* 註解忽略" */}
{literal} 	           {
                          std::string temp(yytext);
                          temp.replace(0,1,"");
                          temp.replace(temp.length()-1,temp.length()-1,"");
                          yylval.s = new std::string(temp);
                          return STR;
                        }
{TRUE_VALUE}            {
                          yylval.b = true;
                          return BOOLEAN_VALUE;
                        }
{FALSE_VALUE}           {
                          yylval.b = false;
                          return BOOLEAN_VALUE;
                        }
","   	                {return COMMA;}
"}"   	                {return right_curly_bracket;}
"{"   	                {return left_curly_bracket;}
"["   	                {return left_square_bracket;}
"]"   	                {return right_square_bracket;}
"direction"             {yylval.b = false; return VERTEX_HOMO;}
"location"              {yylval.b = true; return VERTEX_HOMO;}
"intensity"             {return intensity_data;}
{colordata}             {
                          yylval.s = new std::string(yytext);
                          return Color_type;
                        }
{lightdata}             {
                          yylval.s = new std::string(yytext);
                          return Light_data;
                        }
"vertexOrdering"        {
                          yylval.i = 0;
                          return SHAPE_HINTS_ENUM;
                        }
"shapeType"             {
                          yylval.i = 1;
                          return SHAPE_HINTS_ENUM;
                        }
"faceType"              {
                          yylval.i = 2;
                          return SHAPE_HINTS_ENUM;
                        }
"UNKNOWN_ORDERING"      {
                          yylval.i = 0;
                          return VERTEX_ORDERING_ENUM;
                        }
"CLOCKWISE"             {
                          yylval.i = 1;
                          return VERTEX_ORDERING_ENUM;
                        }
"COUNTERCLOCKWISE"      {
                          yylval.i = 2;
                          return VERTEX_ORDERING_ENUM;
                        }
"UNKNOWN_SHAPE_TYPE"    {
                          yylval.i = 0;
                          return SHAPE_TYPE_ENUM;
                        }
"SOLID"                 {
                          yylval.i = 1;
                          return SHAPE_TYPE_ENUM;
                        }
"UNKNOWN_FACE_TYPE"     {
                          yylval.i = 0;
                          return FACE_TYPE_ENUM;
                        }
"CONVEX"                {
                          yylval.i = 1;
                          return FACE_TYPE_ENUM;
                        }
"NONCONVEX"                {
                          yylval.i = 2;
                          return FACE_TYPE_ENUM;
                        }
"dropOffRate"           {return DROP_OFF_RATE;}
"cutOffAngle"           {return CUT_OFF_ANGLE;}
"on"                    {return LIGHT_ON;}
{string_type}           {return STRING_TYPE;}
[dD][eE][fF]            {return define_data;}
[Ss]eparator            {return Separator_data;}
[Pp][Oo][Ii][Nn][Tt]  	{return Point_data;}
"coordIndex"	          {return coordIndex_data;}
{M_info}                {
                            yylval.s = new std::string(yytext);
                            return Material_info;
                        }
{indexlist}             {
                            std::string temp(yytext);
                            temp.replace(0,7,"");
                            temp.replace(temp.length()-3,temp.length()-1,"");
                            yylval.s = new std::string(temp);
                            return Index_data;
                        }
{material}              {return Material_data;}
{info_type}             {return INFO_TYPE;}
{shape_hints}           {return SHAPE_HINTS_TYPE;}
{shape_hints_num}       {yylval.s = new std::string(yytext); return SHAPE_HINTS_NUMBER;}
[Cc]oordinate[0-9]+     {
                            int point_dim;
                            sscanf(&yytext[10], "%d", &point_dim);
                            yylval.i = point_dim;
                            return Coordinate_data;
                        }
{float_num}             {yylval.f = strtof(yytext, &p); return FLOAT_NUMBER;}
{number}                {yylval.f = strtof(yytext, &p); return NUMBER;}
[a-zA-Z_][a-zA-Z_0-9]*  {yylval.s = new std::string(yytext); return ID;}
.|\n                    {/* 怪東西忽略 */}
{whitespace}            {/* 空白忽略 */}
%%

/*int main(int argc, char *argv[])
{
   yylex();
   return 0;
}*/
