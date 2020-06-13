/*
 *  Attribute.h
 *
 *  Created by Janin on 10/2019
 *  Copyright 2018 LaBRI. All rights reserved.
 *
 *  Module for a clean handling of attibutes values
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <stddef.h>
#include <string.h>
#ifndef ATTRIBUTE_H
#define ATTRIBUTE_H

FILE* fichier;
FILE* fichier_entete;


typedef enum {VOD,INT, FLOAT, STRCT,BOOL} type;
// typedef enum {TRUE,FALSE} bool;
struct ATTRIBUTE {
  char * name;
  int int_val;
  float float_val;
  bool bool_val;
  type type_val;
  int reg_number;
  int nbr_star;
  int current_block;
  /* other attribute's fields can goes here */

};

typedef struct ATTRIBUTE * attribute;

attribute new_attribute ();
/* returns the pointeur to a newly allocated (but uninitialized) attribute value structure */

int new_register(attribute a);
/* returns a reg_number */

char * get_type(type p, int nbrStar);
/* returns the real attribute type_val to print it in the generated code */

void code_aff(attribute x, attribute y );

attribute code_exp_arithm(attribute x, attribute y, char* op);
/* generates the code of the arithmetic expression and returns the resulting attribute*/

attribute neg_attribute(attribute x);

attribute code_exp_bool(attribute x, attribute y, char * op);
/* generates the code of the arithmetic expression and returns the resulting attribute*/
attribute code_exp_Not(attribute a);

int new_label();

void push_block();
void remove_block();
int get_current_block();
void id_scope(attribute a);

char* str_concat(char* s1, char* s2);
void begin_prog();
void end_prog();

void prototype(type t0, char* f, ...);
#endif
