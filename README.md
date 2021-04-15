# Liza

A BASH script containing a library of functions to generate user interfaces (menus, forms, buttons,etc) without using Dialog/Yad/Whiptail/etc

The Liza scripts were originally called Listgen, and were developed as part of the independent Feliz installer for the Arch Linux operating system. Feliz moved onto using Dialog instead, but the Listgen functions remained independent for sharing. Now renamed Liza, they are written entirely in bash, so you can edit them to suit your purposes.

The Liza module is self-contained and application-independent. It initialises all its own variables, and contains all the functions it needs; any of the functions may be called independently from any scripts. You only have to put a copy of the listgen.sh module in the same location as your scripts, and source it, to be able to add all the features of Liza to your scripts.
