Notre compilateur fait:
- un mécanisme de déclarations explicite de variables,
- des expresssion arithmétiques arbitraire de type calculatrice,
- des lectures ou écritures mémoires via des affectations avec variable utilisateur,
- un mécanisme de typage comprenant notamment int et float,
- des lectures ou écritures mémoires via des pointeurs
- définitions fonctions (pas d'appel de fonction)
- on a ajouté une règle qui permet de faire l'affichage des variables de type int et float pour permettre la vérification


Pour tester le compilateur, il suffit d'exécuter le fichier compil.sh en lui donnant en argument
un fichier test comme par exemple:

compil.sh test/test.Myc

Ainsi il génère deux fichier test.c et test.h dans le répertoire test et en suite il fait la compilation du fichier .c et l'exécute

