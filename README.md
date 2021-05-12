# lister

A BASH script containing a library of functions to generate user interfaces - especially menus and picklists, but also forms, buttons, etc, and all without using Dialog/Yad/Whiptail/etc.

Now including an enum function and a function to print up to four columns of interactive radio buttons.

This project was originally called Listgen. Any existing projects using the Listgen module should still continue to work as before, but will not be compatible with lister. The scripts have been completely rewritten for lister, and it uses different references. Consequently, if you are using Listgen, and do not want to change the code you are using to reference it, then you should stay with Listgen. However, lister is more efficient, and has more features, so any new projects will benefit from making the change.

The interfaces provided by lister are intentionally more basic than Dialog and the others. The lister interfaces use no colours, and do not draw pretty boxes; they are intended for tasks where a more graphical interface is simply not possible. This means that they can be used on older or lower powered hardware - wherever Linux is installed. They are written entirely in BASH, and are GNU licensed, so you can edit them to suit your purposes.

The lister module is self-contained and application-independent. It initialises all its own variables, and contains all the functions it needs; any of the functions may be called independently from any scripts. You only have to put a copy of the lister.sh module in the same location as your scripts, and source it, to be able to add all the features of lister to your scripts.

By the way, lister is named after Dave Lister, the lovable character in the television series Red Dwarf.

(revision 210512 Elizabeth Mills May 2021)
