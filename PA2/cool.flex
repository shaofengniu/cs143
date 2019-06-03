/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Dont remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}
%START COMMENT

/*
 * Define names for regular expressions here.
 */

CLASS           [Cc][Ll][Aa][Ss][Ss]
ELSE            [Ee][Ll][Ss][Ee]
FI              [Ff][Ii]
IF              [Ii][Ff]
IN              [Ii][Nn]
INHERITS        [Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss]
LET             [Ll][Ee][Tt]
LOOP            [Ll][Oo][Oo][Pp]
POOL            [Pp][Oo][Oo][Ll]
THEN            [Tt][Hh][Ee][Nn]
WHILE           [Ww][Hh][Ii][Ll][Ee]
CASE            [Cc][Aa][Ss][Ee]
ESAC            [Ee][Ss][Aa][Cc]
OF              [Oo][Ff]
DARROW          =>
NEW             [Nn][Ee][Ww]
ISVOID          [Ii][Ss][Vv][Oo][Ii][Dd]
STR_CONST       \"([^\\\"]|\\.)*\"
INT_CONST       [0-9]+
BOOL_CONST      t[Rr][Uu][Ee]|f[Aa][Ll][Ss][Ee]
TYPEID          [A-Z][A-Za-z0-9_]*
OBJECTID        [a-z][A-Za-z0-9_]*
ASSIGN          <-
NOT             [Nn][Oo][Tt]
LE              <=



%%



 /*
  *  Nested comments
  */

<INITIAL>{
  "(*"      BEGIN(COMMENT);
}
<COMMENT>{
  "*)"      BEGIN(INITIAL);
  [^*\n]+
  "*"
  \n        curr_lineno++;
}


 /*
  *  The multiple-character operators.
  */

{DARROW}		{ return (DARROW); }
{LE}        { return (LE); }
{ASSIGN}    { return (ASSIGN); }

 /*
  * The single-character operators.
  */
 [\.\@\~\+\-\*\/<=;:,{}()]  { return yytext[0]; }


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}     { return (CLASS); }
{ELSE}      { return (ELSE); }
{FI}        { return (FI); }
{IF}        { return (IF); }
{IN}        { return (IN); }
{INHERITS}  { return (INHERITS); }
{LET}       { return (LET); }
{LOOP}      { return (LOOP); }
{POOL}      { return (POOL); }
{THEN}      { return (THEN); }
{WHILE}     { return (WHILE); }
{CASE}      { return (CASE); }
{ESAC}      { return (ESAC); }
{OF}        { return (OF); }
{NEW}       { return (NEW); }
{ISVOID}    { return (ISVOID); }
{NOT}       { return (NOT); }






 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

 
{STR_CONST} {
  if (yyleng > MAX_STR_CONST - 1) {
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }

  string_buf_ptr = string_buf;
  bool quote = false;
  for (int i = 0; i < yyleng; i++) {
    switch (yytext[i]) {
      case '\\': quote = true; i++; break;
      case '\n': cool_yylval.error_msg = "Unterminated string constant"; return (ERROR); 
      case '\0': cool_yylval.error_msg = "String contains null character"; return (ERROR);
      default:
        if (!quote) {
          *string_buf_ptr++ = yytext[i++];
        } else {
          switch (yytext[i]) {
            case 'n': *string_buf_ptr++ = '\n'; break;
            case 't': *string_buf_ptr++ = '\t'; break;
            case 'b': *string_buf_ptr++ = '\b'; break;
            case 'f': *string_buf_ptr++ = '\f'; break;
            default: *string_buf_ptr++ = yytext[i];
          }
          quote = false;
        }
    }
  }
  *string_buf_ptr++ = 0;
  cool_yylval.symbol = stringtable.add_string(string_buf);
  return (STR_CONST);
 }
 
 /*
  * Int constants
  */
{INT_CONST} {
  cool_yylval.symbol = inttable.add_string(yytext);
  return (INT_CONST);
}
 /*
  * Bool constants
  */

{BOOL_CONST} {
  if (*yytext == 't') {
    cool_yylval.boolean = true;
  } else {
    cool_yylval.boolean = false;
  }
  return (BOOL_CONST);
}

{TYPEID} {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (TYPEID);
}

{OBJECTID} {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (OBJECTID);
}


 /*
  * White spaces.
  */
[\f\r\t\v ]+ {}

\n { curr_lineno++;}
%%
