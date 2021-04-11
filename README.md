# listgen
A Bash script containing functions to generate menus and lists without using Dialog/Yad/Whiptail/etc
The listgen scripts were originally developed as part of the independent Feliz installer for the Arch Linux operating system. Feliz moved onto using Dialog instead, but the Listgen functions remain independently. They are written entirely in bash, so you can edit them to suit your purposes.

The listgen module is self-contained and application-independent. It initialises all its own variables, and contains all the functions it needs; any of the functions may be called independently from any scripts. You only have to put a copy of the listgen.sh module in the same location as your scripts, and source it, to be able to add all the features of listgen to your scripts.
