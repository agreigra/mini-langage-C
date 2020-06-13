%code requires{
#include "Table_des_symboles.h"
#include "Attribute.h"
 }

%{

#include <stdio.h>
#include <stdlib.h>
extern int yylex();
extern int yyparse();


void yyerror (char* s) {
  printf ("%s\n",s);
}

void exit_error (char* s) {
  printf ("%s\n",s);
  exit(0);
}

%}

%union {
	attribute val;
  char * str;
  int entier;
}
%token <val> NUMI NUMF
%token <val>TINT TFLOAT STRUCT VOID
%token <val> ID
%token AO AF PO PF PV VIR
%token RETURN  EQ PRINT
%token <val> IF ELSE WHILE

%token <val> AND OR NOT DIFF EQUAL SUP INF
%token PLUS MOINS STAR DIV
%token DOT ARR

%left DIFF EQUAL SUP INF       // low priority on comparison
%left PLUS MOINS               // higher priority on + -
%left STAR DIV                 // higher priority on * /
%left OR                       // higher priority on ||
%left AND                      // higher priority on &&
%left DOT ARR                  // higher priority on . and ->
%nonassoc UNA                  // highest priority on unary operator

%type <val>  prog  typename type pointer vir vlist loop block decl_list decl var_decl exp bool_cond
%type <str>  params
%type <entier> while else if while_cond


%start prog



%%

prog : block                   {}
;

block:
decl_list inst_list            {}
;

// I. Declarations

decl_list : decl decl_list     {}
|                              {}
;

decl: var_decl PV              {}
| struct_decl PV               {}
| fun_decl                     {}
;

// I.1. Variables
var_decl : type vlist          {}
;

// I.2. Structures
struct_decl : STRUCT ID struct {}
;

struct : ao attr af            {}
;

attr : type ID                 {}
| type ID PV attr              {}

// I.3. Functions

fun_decl : type fun            {}
;

fun : fun_head fun_body        {fprintf(fichier, "};\n");};

fun_head : ID PO PF            {$1->type_val = ($<val>0)->type_val;
                                set_symbol_value($1->name,$1);
                                fprintf(fichier,"%s %s(){\n",get_type($1->type_val,$1->reg_number),$1->name);
                                }
| ID PO params PF              {$1->type_val = ($<val>0)->type_val;
                                set_symbol_value($1->name,$1);
                                fprintf(fichier,"%s %s( %s )\n{\n",get_type($1->type_val,$1->reg_number),$1->name,$3);
                                }
;

params: type ID vir params     {$2->type_val = $1->type_val;
                                $1->nbr_star = ($<val>0)->nbr_star;
                                $2->current_block = get_current_block()+1;
                                set_symbol_value($2->name,$2);
                                char * r = str_concat(get_type($1->type_val,$1->nbr_star)," ");
                                r  = str_concat(r,$2->name);
                                r = str_concat(r,"; ");
                                $$ = str_concat(r,$4);
                              }

| type ID                      {$2->type_val = $1->type_val;
                                $1->nbr_star = ($<val>0)->nbr_star;
                                $2->current_block = get_current_block()+1;
                                char * s = str_concat(get_type($1->type_val,$1->nbr_star)," ");
                                set_symbol_value($2->name,$2);
                                $$  = str_concat(s,$2->name);
                              }
vlist: ID vir vlist            {$1->type_val = ($<val>0)->type_val;
                                $1->nbr_star = ($<val>0)->nbr_star;
                                $1->current_block = get_current_block();
                                set_symbol_value($1->name,$1);
                                fprintf(fichier_entete,"%s %s;\n",get_type(($<val>1)->type_val,($<val>1)->nbr_star),$1->name);
                                }

| ID                           {$1->type_val = ($<val>0)->type_val;
                                  $1->nbr_star = ($<val>0)->nbr_star;
                                  $1->current_block = get_current_block();
                                  set_symbol_value($1->name,$1); //stocker la variable dans la table de symbole, vérifier si il n'est pas déjà utilisé
                                  fprintf(fichier_entete,"%s %s;\n",get_type(($<val>1)->type_val,($<val>1)->nbr_star),$1->name);
                                }
;

vir : VIR                      {$$=$<val>-1;}
;

fun_body : ao block af         {}
;

ao:AO                          {push_block();};
af:AF                          {remove_block();};

// I.4. Types
type
: typename pointer             {$1->nbr_star = $2->nbr_star; $$=$1;}
| typename                     {$1->nbr_star=0; $$=$1; }
;

typename
: TINT                         {$$ = $1;}
| TFLOAT                       {$$ = $1;}
| VOID                         {$$ = $1;}
| STRUCT ID                    {$$ = $1;}
;

pointer
: pointer STAR                 {attribute a =new_attribute();
                                a->nbr_star=$1->nbr_star+1;
                                $$=a;}
| STAR                         {attribute a = new_attribute(); a->nbr_star=1;$$=a; }
;



// II. Intructions

inst_list: inst inst_list     {} //modifier inst PV inst_list
|                             {}
;

inst:
ao block af                   {}
| aff PV                      {}
| ret PV                      {}
| cond                        {}
| loop                        {}
//| PV                        {}
|print PV                      {}
;

print: PRINT PO exp PF               {
                                          if($3->type_val==INT)
                                              fprintf(fichier,"printf(\"%s = %s\\n\",ri%d);\n",$3->name,"%d",$3->reg_number);
                                          else if($3->type_val==FLOAT)
                                              fprintf(fichier,"printf(\"%s = %s\\n\",rf%d);\n",$3->name,"%f",$3->reg_number);
                                        };
// II.1 Affectations

aff : ID EQ exp               {code_aff($1,$3);}
| STAR exp EQ exp             { if(($2->nbr_star==1)&&($4->nbr_star==0)){
                                    if(($2->type_val==INT)&&($4->type_val==INT))
                                    { fprintf(fichier, "*ri%d = ri%d;\n",$2->reg_number,$4->reg_number);}

                                    else if(($2->type_val==FLOAT)&&($4->type_val==FLOAT))
                                    {fprintf(fichier, "*rf%d = rf%d;\n",$2->reg_number,$4->reg_number);}
                                }

                                else if(($2->nbr_star>=2)&&($4->nbr_star>=1)){
                                  if(($2->type_val==INT)&&($4->type_val==INT))
                                  { fprintf(fichier, "*ri%d = ri%d;\n",$2->reg_number,$4->reg_number);}

                                  else if(($2->type_val==FLOAT)&&($4->type_val==FLOAT))
                                  {fprintf(fichier, "*rf%d = rf%d;\n",$2->reg_number,$4->reg_number);}
                                }

                              }
;


// II.2 Return
ret : RETURN exp              {fprintf(fichier, "return %s;\n",$2->name);}
| RETURN PO PF                {fprintf(fichier, "return;\n");}
;
// II.3. Conditionelles

cond :
if bool_cond inst else inst   {fprintf(fichier,"label%d:\n",$4);}
| if bool_cond inst           {fprintf(fichier,"label%d:\n",$1);}
;


bool_cond : PO exp PF         {fprintf(fichier, "if(!ri%d) goto label%d;\n",$2->reg_number,$<entier>0); $$ = $2;}
;

if : IF                       {int l=new_label();
                              $$ = l;}
;

else : ELSE                   {int l =new_label();
                                $$= l;
                              fprintf(fichier,"goto label%d;\nlabel%d:\n",l,($<entier>-2));}
;

// II.4. Iterations

loop : while while_cond inst  {fprintf(fichier,"goto label%d;\nlabel%d:\n",$1,$2);}
;

while_cond : PO exp PF        {int l = new_label();
                              $$ = l;
                              fprintf(fichier,"if (!ri%d) goto label%d;\n",$2->reg_number,l);}

while : WHILE                 {int l= new_label();
                              $$ = l;
                              fprintf(fichier,"label%d:\n",l);}
;


// II.3 Expressions
exp
// II.3.0 Exp. arithmetiques
: MOINS exp %prec UNA         {$$ = neg_attribute($2);}
| exp PLUS exp                {$$ = code_exp_arithm($1,$3,"+");}
| exp MOINS exp               {$$ = code_exp_arithm($1,$3,"-");}
| exp STAR exp                {$$ = code_exp_arithm($1,$3,"*");}
| exp DIV exp                 {$$ = code_exp_arithm($1,$3,"/");}
| PO exp PF                   {$$ = $2;}
| ID                          {attribute a = get_symbol_value($1->name);//On récupère l'ID dans la table des symbole pour avoir accès à ses champs
                              id_scope(a); //vérifier sa portée
                              a->reg_number = new_register(a);

                              if(a->type_val==FLOAT){
                              fprintf(fichier_entete, "float rf%d;\n",a->reg_number); //déclaration d'un registre
                              fprintf(fichier, "rf%d = %s;\n",a->reg_number,a->name); //affectation dans un registre
                              }
                              else if(a->type_val==INT){
                              fprintf(fichier_entete, "int ri%d;\n",a->reg_number); //declaration d'un registre
                              fprintf(fichier, "ri%d = %s;\n",a->reg_number,a->name); // affectation dans un registre
                              }
                              $$=a;
                              }

|NUMI                        {$1->reg_number = new_register($1);
                              fprintf(fichier_entete, "int ri%d;  //%d\n",$1->reg_number,$1->int_val); //déclaration d'un registre
                              fprintf(fichier, "ri%d = %d;\n",$1->reg_number,$1->int_val); //affectation de la valeur dans le registre
                              $$ = $1;
                              }
| NUMF                        {$1->reg_number = new_register($1);
                              fprintf(fichier_entete, "float rf%d; //%f\n",$1->reg_number,$1->float_val); //déclaration d'un registre
                              fprintf(fichier, "rf%d = %f;\n",$1->reg_number,$1->float_val); //affectation de la valeur dans le registre
                              $$ = $1;}

// II.3.1 Déréférencement

| STAR exp %prec UNA          {attribute a = new_attribute();
                                a->type_val = $2->type_val;
                                a->reg_number = new_register(a);
                                if($2->type_val ==INT)
                                  fprintf(stdout,"ri%d = *ri%d;\n",a->reg_number,$2->reg_number);
                                if($2->type_val ==FLOAT)
                                  fprintf(stdout,"rf%d = *rf%d;\n",a->reg_number,$2->reg_number);
                                $$ = a;}

// II.3.2. Booléens

| NOT exp %prec UNA           {$$ = code_exp_Not($1);}
| exp INF exp                 {$$ = code_exp_bool($1,$3,"<");}
| exp SUP exp                 {$$ = code_exp_bool($1,$3,">");}
| exp EQUAL exp               {$$ = code_exp_bool($1,$3,"==");}
| exp DIFF exp                {$$ = code_exp_bool($1,$3,"!=");}
| exp AND exp                 {$$ = code_exp_bool($1,$3,"&&");}
| exp OR exp                  {$$ = code_exp_bool($1,$3,"||");}

// II.3.3. Structures

| exp ARR ID                  {}
| exp DOT ID                  {}
| app                         {}
;

// II.4 Applications de fonctions

app : ID PO args PF           {};

args :  arglist               {}
|                             {}
;

arglist : exp VIR arglist     {}
| exp                         {}
;



%%
int main (int argc, char** argv) {

  stdin=fopen(argv[1],"r");

  // fichier test.h passé en parametre pour faire les declarations
  fichier_entete = NULL;
  char * entete = argv[2];

  fichier_entete=fopen(entete,"w");

  // fichier test.c passé en parametre pour mettre le code generé
  fichier = NULL;
  fichier =fopen(argv[3], "w");
  fprintf(fichier, "/* CODE GENERE PAR LE COMPILATEUR SIMPLE */\n\n");
  fprintf(fichier, "#include \"../%s\"\n\n",entete);
  fprintf(fichier, "#include<stdlib.h>\n#include<stdbool.h>\n#include<stdarg.h>\n#include<stdio.h>\n");
  fprintf(fichier, "int main(void){\n");
  yyparse();
  fprintf(fichier, "\nreturn EXIT_SUCCESS;\n}\n");
  return 0;
}
