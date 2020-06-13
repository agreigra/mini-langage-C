#include "Attribute.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include "Table_des_symboles.h"
#include "Table_des_chaines.h"


static int int_reg = 1;
static int float_reg =1;
static int label = 1;

int new_register(attribute a){
    if(a->type_val==INT)
      return int_reg++;
    else if(a->type_val==FLOAT)
      return float_reg++;
    printf("ERROR, the argument is not an attribute with a valid type_val");
    return -1;
}

int new_label(){
  return label++;
}


char * get_type(type t,int nbrStar){

if(nbrStar==0){
  switch (t) {
    case INT: return "int"; break;
    case FLOAT: return "float"; break;
    case BOOL:  return "bool"; break;
    case STRCT: return "struct"; break;
    default: return "void"; break;
  }}
  else{
    char * stars = (char*)malloc((nbrStar+1) * sizeof(char));
    int i=0;
    for( i=0; i<nbrStar; i++){
      *(stars + i) = '*';
    }
    *(stars+ nbrStar) = '\0';
    return str_concat(get_type(t,0),stars);
  }

}

attribute new_attribute() {
  attribute r;
  r  = malloc (sizeof (struct ATTRIBUTE));
  return r;
};

void code_aff(attribute x, attribute y ){

    attribute a = get_symbol_value(x->name);
    id_scope(a);
    if(a->type_val!= y->type_val)
    {
        if((a->type_val== FLOAT)&&(y->type_val== INT)){
          int r = new_register(a);
          a->reg_number = r;
          fprintf(fichier_entete,"float rf%d;\n",r);
          fprintf(fichier,"rf%d = (float)ri%d;\n",r,y->reg_number);
          fprintf(fichier,"%s = rf%d;\n",a->name,r);
          }
        else
          {
          int r = new_register(a);
          a->reg_number = r;
          fprintf(fichier,"int ri%d;\n",r);
          fprintf(fichier,"ri%d = (int)rf%d;\n",r,y->reg_number);
          fprintf(fichier,"%s = ri%d;\n",a->name,r);
          }
    }
  else
  {   if(a->type_val== FLOAT)
        {fprintf(fichier,"%s = rf%d;\n",a->name,y->reg_number);}
      else if(a->type_val== INT)
        {fprintf(fichier,"%s = ri%d;\n",a->name,y->reg_number);}
  }
}

//Expression arithmétique
attribute code_exp_arithm(attribute x, attribute y, char* op){
  attribute a = new_attribute();
  if(x->type_val == y->type_val){
    a->type_val = x->type_val;
    int ri = new_register(a);
    a->reg_number = ri;

    if(x->type_val==INT){
      fprintf(fichier_entete, "int ri%d; //stocker le resultat\n",ri);
      fprintf(fichier, "ri%d = ri%d %s ri%d;\n",ri,x->reg_number,op,y->reg_number);}

    else if(x->type_val==FLOAT){
      fprintf(fichier_entete, "float rf%d; //stocker le resultat\n",ri);
      fprintf(fichier, "rf%d = rf%d %s rf%d;\n",ri,x->reg_number,op,y->reg_number);
    }

    else{
      fprintf(stderr, "types ne sont pas compatibles\n");
      exit (0);
    }

  }

  else if((x->type_val == INT)&&(y->type_val == FLOAT)){
    a->type_val = FLOAT;
    int num = new_register(a); //cast x, on déclare une variable
    fprintf(fichier_entete, "float rf%d; //pour faire le casting\n",num);
     fprintf(fichier, "rf%d = (float) ri%d\n",num,x->reg_number);
    int ri = new_register(a); //stocker le résultat
    a->reg_number = ri;
    fprintf(fichier_entete, "float rf%d; //stocker le resultat\n",ri);
    fprintf(fichier, "rf%d = rf%d %s rf%d;\n",ri,num,op,y->reg_number);

  }

  else if((x->type_val == FLOAT)&&(y->type_val == INT)){
    a->type_val = FLOAT;
    int num = new_register(a); //cast x, on déclare une variable
    fprintf(fichier_entete, "float rf%d //pour faire le casting \n",num);
    fprintf(fichier,"rf%d = (float) ri%d;\n",num,y->reg_number);
    int ri = new_register(a); //stocker le résultat
    a->reg_number = ri;
    fprintf(fichier_entete, "float rf%d; //stocker resultat\n",ri);
    fprintf(fichier, "rf%d = rf%d %s rf%d;\n",ri,num,op,x->reg_number);

  }
  else{
    fprintf(stderr, "erreur, types ne sont pas compatibles\n");
    exit (0);
  }
  return a;
}

//négatif Attribut
attribute neg_attribute(attribute x){
  attribute a = new_attribute();
  a->reg_number = x->reg_number;
  a->type_val = x->type_val;
  fprintf(fichier, "ri%d =-r%s%d;\n",x->reg_number,x->type_val==INT?"i":"f",x->reg_number);
  return a;
}

attribute code_exp_bool(attribute x, attribute y, char * op){
  attribute a = new_attribute();
  a->type_val = INT;
  int ri = new_register(a);
  a->type_val = BOOL;
  a->reg_number = ri;
  fprintf(fichier_entete, "int ri%d; // resultat de comparaison\n",ri);
  fprintf(fichier,"ri%d = r%s%d %s r%s%d;\n",ri,x->type_val==INT?"i":"f",x->reg_number ,op,y->type_val==INT?"i":"f",y->reg_number  );

  return a;
}

attribute code_exp_Not(attribute x){
  attribute a = new_attribute();
  a->type_val = BOOL;
  fprintf(fichier,"ri%d = !ri%d;\n",x->reg_number,x->reg_number);

  return a;
};

// ==================== Masquage block implementation ===================
/* Un Block est délimité par des accolades. On veut déterminer et introduire un système de block permettant de connaitre
 dans quel block nous nous situons. Pour cela, on définit un tableau de INT, avec pour chaque case un id, ainsi qu'une variable NEXT_BLOCK
 permettant d'indiquer la case du prochain block d'instruction. Cette case est donc pour l'instant vide.*/

#define NUMBER_BLOCK 100

int BLOCK_STACK[NUMBER_BLOCK]={1,0};

int NEXT_BLOCK = 1; //indicateur indique une case du tableau "vide", non utilisé. Les indices d'un tableau commence à 0.
int ID_BLOCK = 2; //id 1 est déjà utilisé pour le block du main(), ID_BLOCK est donc initialisé à 2. Les ID de chaque case du tableau commencent à 1.

/* Cette fonction  permet d'ajouter un nouveau bloc d'instruction à l'emplacement d'indice NEXT_BLOCK d'id ID_BLOCK*/
void push_block(){
    BLOCK_STACK[NEXT_BLOCK]=ID_BLOCK;
    NEXT_BLOCK += 1;
    ID_BLOCK += 1;
}

/*Cette fonction permet de déplacer l'indicateur d'une case en arrière, i-e que le dernier block d'intruction a été enlevé
On rappelle que NEXT_BLOCK est un indicateur qui pointe une case non utilisé. Il pointe l'emplacement du prochain block à venir.*/
void remove_block() {
  NEXT_BLOCK--;
}

/*Cette fonction permet d'obtenir l'id du block dans lequel nous nous situons. */
int get_current_block(){
  return BLOCK_STACK[NEXT_BLOCK-1];
}

/*Cette fonction permet de savoir dans quel block d'instruction se situe la variable pris en paramètre.
On parcourt donc le tableau de block BLOCK_STACK et on vérifie l'existence de l'indice du block*/
void id_scope(attribute a){
  for(int i = 0; i < NEXT_BLOCK; i++)
      if (a->current_block == BLOCK_STACK[i])
        return;
  fprintf(stderr,"variable non declaré //%d\n",a->current_block);
  exit(0);
}



char* str_concat(char* s1, char* s2) {
    char* r = malloc(strlen(s1)+strlen(s2)+2);
    strcpy(r,"");
    strcat(r,s1);
    strcat(r,s2);
    return r;
};
