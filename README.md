# Lister

A BASH script containing a library of functions to generate user interfaces - especially menus and picklists, but also forms, buttons, etc, and all without using Dialog, Yad, Whiptail, Zenity, etc.

Now including a simple enum function and a function to print up to four columns of interactive radio buttons.

This project was originally called Listgen. If you have Listgen as part of any existing projects, they should still continue to work as before, but do not replace Listgen with **Lister** - the scripts have been completely rewritten, and it uses different references, so it will not be compatible with your code. Consequently, if you are using Listgen, and do not want to change the code you are using to reference it, then you should stay with Listgen. However, **Lister** is more efficient, and has more features, so any new projects will benefit from making the change.

The interfaces provided by **Lister** are intentionally more basic than Dialog and the others. The **Lister** interfaces use no colours, and do not draw pretty boxes; they are intended for tasks where a more graphical interface is simply not possible. This means that they can be used on older or lower powered hardware - wherever Linux is installed. They are written entirely in BASH, and are GNU licensed, so you can edit them to suit your purposes.

The **Lister** module is self-contained and application-independent. It initialises all its own variables, and contains all the functions it needs; any of the functions may be called independently from any scripts. You only have to put a copy of the lister.sh module in the same location as your scripts, and source it, to be able to add all the features of **Lister** to your scripts.

(revision 210514 Elizabeth Mills)
