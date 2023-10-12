#!/bin/bash

################################################################################
###	Lister - Developed by Elizabeth Mills - Version 2.00b EAM0002 2023/10/12 ###
################################################################################

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version. For a copy, write to:
#                 The Free Software Foundation, Inc.
#                  51 Franklin Street, Fifth Floor
#                    Boston, MA 02110-1301 USA

# This program is distributed in the hope that it will be useful, but
#      WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#            General Public License for more details.

# Some of these functions share the outcome of their processes via the
# global variables Gstring and Gnumber. Two other global variables,
# Grow and Gcol, track vertical and horizontal alignment. All other
# variables are local to their functions, and values must be passed as
# parameters between them.
# See lister.manual for guidance on the use of these functions.

# -------------------------------------------------------------
#       Shared .. General-purpose functions
# -------------------------------------------------------------
# DoHeading          63  Prepare a new window with heading
# DoForm             86  Centred prompt for user-entry
# DoMessage         103  Displays an error message in a pop-up terminal
# PrintButtons      108  Prints one or two buttons
# SwitchButtons     157  Alternate between two buttons
# DoEnum            168  Enumerate a string
# DoYesNo           205  Yes, it's a yes/no function
# -------------------------------------------------------------
#       Menus .. Displaying and using menus
# -------------------------------------------------------------
# DoMenu            233   Generates a simple menu of one-word items
# DoLongMenu        380   Generates a menu of multi-word items
# DoFirstItem       519   Prints a single, centred item
# DoNextItem        541   Prints successive aligned items
# DoPrintRev        547   Reverses text colour at appointed position
# DoKeypress        567   Respond to keypress
# --------------------------------------------------------------
#       Lists .. Display long lists and accept user input
# --------------------------------------------------------------
# DoLister          602 Generates a numbered list of one-word items in columns
# ListerSelectPage  733 sed by DoLister to manage page handling
# ListerPrintPage   796 Used by DoLister to display selected page
# DoMega            884 Pages full of extra long text, trimmed to fit
# MegaPage          933 Does the printing for DoMega
# DoRadio          1009 Accepts input of up to four columns of user-prompts
# RadioColumn      1118 Prints all the columns, with 'radio buttons'
# RadioSelect      1152 Responds to user input via cursor keys
# ---------------------------------------------------------------
# Global variables
Gtitle=""       # For headings
Gnumber=0       # Output (menu item number)
Gstring=""      # Output (menu item text)
Grow=0          # For row alignment across functions
Gcol=0          # For column alignment across functions
# ---------------------------------------------------------------
# Shared
#----------------------------------------------------------------
function DoHeading    # Always use this function to prepare the screen
{
    clear
    local winwidth limit text textlength
    winwidth=$(tput cols)                          # Recheck window width
    text="$Gtitle"                                 # Use global title if set
    textlength=${#text}                            # Count characters
    if [ $textlength -ge $winwidth ]; then         # If text too long for window
        limit=$((winwidth-2))                      # Limit to 2 characters lt winwidth
        text="${text:0:$limit}"                    # Limit length of printed text
        textlength=$(echo $text | wc -c)           # Recount
    fi
    headingCol=$(( (winwidth - textlength) / 2 ))  # Horizontal position
    tput cup 0 $headingCol                         # Move cursor to Gcol
    tput bold                                      # Display will be bold
    printf "%-s\\n" "$text"
    tput sgr0                                      # Reset colour inversion
    Grow=1
} # End DoHeading

function DoForm   # Centred prompt for user-entry
{                 # $1 Text for prompt
                  # Returns user entry through $Gstring
    local winwidth length # empty
    winwidth=$(tput cols); length=${#1}
    if [ ${length} -le ${winwidth} ]; then
        formCol=$(( (winwidth - length) / 2 ))
    else
        formCol=1
    fi
    tput cup $Grow $formCol     # Move cursor to Gcol
    read -p "$1" Gstring
} # End DoForm

function DoMessage    # Display an error message
{                     # $1 and $2 optional lines of message text
    local winwidth length pin
    winwidth=$(tput cols); length=${#1}
    if [ ${length} -le ${winwidth} ]; then
        pin=$(( (winwidth - length) / 2 ))
    else
        pin=1
    fi
    DoHeading               # EAM0001
    tput cup 2 $pin         # Move cursor to start position
    echo "$1 $2"            # EAM0001
    tput cup 4 $pin         # Move cursor to start position
    read -p "Please press [Enter] ..."
} # End DoMessage

function PrintButtons
{   # $1 Button text; $2 Highlight one of the buttons; $3 buttonRow
    # Button string should contain one or two words: eg: 'Ok' or 'Ok Exit'
    local characters buttoncount button1 button1len button2 button2len selected
    local buttonstring buttonstringlength buttonstart winwidth buttonRow
    winwidth=$(tput cols)
    if [ "$2" ]; then selected=$2
    else selected=1                         # If no button selected
    fi
   # Check for button row specified
    if [ "$3" ]; then buttonRow=$3
    else buttonRow=12
    fi
   # One or two buttons
    buttoncount=$(echo $1 | wc -w)
    if [ $buttoncount -eq 0 ]; then          # Exit in case of error
        echo "$(date +"%D %T") Line $LINENO - No buttons specified" > lister.log
        return 1
    fi
    button1="$(echo $1 | cut -d' ' -f1)"      # Text for 1st button
    characters=${#button1}                    # Count characters
    button1Len=$((characters+2))              # Add for braces
    button1string="[ $button1 ]"              # 1st button string
    if [ $buttoncount -gt 1 ]; then           # If second button
        button2="$(echo $1 | cut -d' ' -f2)"  # Text for 2nd button
        Len=$(echo $button2 | wc -c)          # Count characters
        button2Len=$((Len+3))                 # Add for braces and spaces
        button2string="[ $button2 ]"          # 2nd button string
    else                                      # Otherwise set variables to null
        button2=""
        button2Len=0
    fi
    buttonstart=$((( winwidth - button1Len - button2Len )/2))
    tput cup $buttonRow $buttonstart            # Reposition cursor
    if [ $selected -eq 1 ]; then tput rev; fi   # Reverse colour
    printf "%-s" "$button1string"               # Print button1
    tput sgr0                                  # Reset colour
    if [ $selected -eq 2 ]; then tput rev; fi   # Reverse colour
    printf "%-s\\n" "$button2string"            # Print button2
    tput sgr0                                  # Reset colour
    return $selected
} # End PrintButtons

function SwitchButtons       # $1 = Selected button
{
    local selected
    if [ $1 -eq 1 ]; then  # Switch buttons
        selected=2
    else
        selected=1
    fi
    return $selected
} # End SwitchButtons

function DoEnum # Enumerate a word from a string variable
{               # $1 String of space-separated one-word items
                # $2 Either a word to enumerate, or a number to look up

                # Returns item number as $? and item detail as $Gstring
    local items item counter x
    x=0     # Ensure numeric variable is used for cut command
    items=$(echo "$1" | wc -w)
    # Test if $2 numeric, word or null
    case $2 in
    "") Gstring=$(echo "$1" | cut -d' ' -f$items)    # No criteria supplied
        return $items                                   # Return word count
    ;;
    *[0-9]*)   x=$2
        Gstring=$(echo "$1" | cut -d' ' -f$x)        # Number supplied, find the word
        return $2                                       # Return the number
    ;;
    *)  counter=1                                       # Word supplied, find the number
        for item in $1
        do
            if [ $item == $2 ]; then
                Gstring="$item"
                break
            fi
            counter=$((counter+1))
            if [ $counter -gt $items ]; then            # In case $2 not found in $1
                Gstring="Not found"
                counter=0                               # Return not found
                break
            fi
        done
        return $counter
    esac
} # End DoEnum

function DoYesNo    # A yes/no function
{                   # $1 Text for prompt, eg: "Reload the csv?"
    local selected
    DoHeading
    Grow=$((Grow+2))
    DoFirstItem "$1"
    Grow=$((Grow+2))
    selected=1
    while true
    do
        PrintButtons "Yes No" $selected $Grow
        DoKeypress
        if [ $Gnumber -eq 0 ]; then   # User pressed [Enter]
            break
        fi
        SwitchButtons $selected
        selected=$?
    done
    Gstring="$(echo 'Yes No' | cut -d' ' -f ${selected})"
    return $selected
} # End Permission

# End Shared
# -------------------------------------------------------------
# Menus
#--------------------------------------------------------------
function DoMenu  # Simple menu
{       # $1 String of single-word menu items (or the name of a file)
        # $2 button text eg: 'Select Done' (if empty will default to 'Ok Exit')
        # $3 May be a headline or empty
        # Sets global variable Gnumber with the number of the item selected
        # and Gstring with the text of the item selected
        # Sets the system return value ($?) with the number of the button selected
    local winwidth padding itemlen longest counter menulist
    local name items buttontext message buttonRow item i column
    winwidth=$(tput cols); padding=""; longest=1
    if [[ "$1" == "" ]]; then
        DoMessage "No data to work with"
        return 1
    elif [ -f "$1" ]; then                          # If a file
        menulist=""
        items=$(cat ${1} | wc -l)                   # Count lines in file
        items=$((items+1))                          # wc counts newlines, so add 1
        for (( i=1; i < $items; ++i ))              # Load file contents into menulist
        do
            item="$(head -n ${i} ${1} | tail -n 1)" # Read item from file
            menulist="$menulist $item"              # Add to variable
        done
    else
        menulist="$1"
    fi
   # Button text passed?
    if [ ! $2 ]; then buttontext="Ok Exit"; else buttontext="$2"; fi

    case $3 in
      "") message=" " ;;
      *) message="$3"
    esac
    DoHeading                             # Prepare page
    Grow=$((Grow+1))
    DoFirstItem "$message"
    Grow=$((Grow+1))
    counter=0
    # Find length of longest item for use in reverse colour
    for i in $menulist
    do
      counter=$((counter+1))
      if [ $counter -eq 1 ]; then
        longest=${#i}                    # Save length
      else
        itemlen=${#i}
        if [ $itemlen -gt $longest ]; then
          longest=$itemlen
        fi
      fi
    done
    items=$counter
    Gcol=$(( (winwidth - longest) /2 ))  # Position of first character
    # Now run through the list again to print each item
    counter=1
    for i in $menulist
    do
      name="$i"                       # Read item from list
      if [ $counter -eq 1 ]; then     # First item - print highlighted
        DoPrintRev "$longest" "$name" # Print reverse (padded)
        Grow=$((Grow + 1 ))
       else
        DoNextItem "$name" # Print subsequent line
        Grow=$((Grow + 1 ))
      fi
      counter=$((counter+1))
    done
   Grow=$((Grow+1))
   DoFirstItem "Use cursor keys to navigate"
   buttonRow=$((Grow+1))
   selected=1
   selectedbutton=1
   PrintButtons "$buttontext" $selectedbutton $buttonRow
   name="$(echo $menulist | cut -d' ' -f1)"          # Set at top item
   while true          # The cursor key action will change either the
   do                  # hightlighted menu item or one of the buttons
     DoKeypress  # Sets numeric $Gnumber for up/down or left/right)
     case "$Gnumber" in
     0)  # Ok/Return pressed
         if [ $selectedbutton -eq 1 ]; then
             Gnumber=$selected  # Exit with the menu 1tem selected
             Gstring="$name"
         else
             Gnumber=0          # Exit with no 1tem selected
             Gstring=""
         fi
         return $selectedbutton
     ;;
     1)  # Up arrow:
         # First reprint currently selected item in plain
         Grow=$((selected+3))   # Set to new row (menu starts at row 3)
         # Use string cutting facilities
         name="$(echo $menulist | cut -d' ' -f$selected)"
         length=$(echo "$name" | wc -c)              # Get length for padding
         spaces=$((longest-length))                  # Calculate spaces to pad it out
         padding="$(printf '%*s' "$spaces")"         # Create spaces to make length
                                                     # To hide reversed padding
         tput cup $Grow $Gcol   # Move cursor
         printf "%-s\\v" "$name $padding"            # Print the item
         # Next move the selected item
         if [ $selected -eq 1 ]; then                # If at top
             selected=$items                         # Move pointer to bottom
         else
             selected=$(( selected -1 ))             # Else move up one
         fi
         # Print newly selected item in reverse colour (padded)
         name="$(echo $menulist | cut -d' ' -f$selected)"
         Grow=$((selected+3))
         DoPrintRev "$longest" "$name"
     ;;
     3) # Down arrow
         # First reprint currently selected item in plain
         Grow=$((selected+3))   # Set to new row (menu starts at row 4)
         name="$(echo $menulist | cut -d' ' -f$selected)"
         length=$(echo "$name" | wc -c)              # Get length for padding
         spaces=$((longest-length))                  # Calculate spaces to pad it out
         padding="$(printf '%*s' "$spaces")"         # Create spaces to make length
                                                     # To hide reversed padding
         tput cup $Grow $Gcol   # Move cursor
         printf "%-s\\v" "$name $padding"            # Print the item in plain
         # Next move the selected item
         if [ $selected -eq $items ]; then           # If at bottom
             selected=1                              # Move to top
         else
             selected=$((selected+1))                # Else move down one
         fi
         # Print newly selected item in reverse colour (padded)
         name="$(echo $menulist | cut -d' ' -f$selected)"
         Grow=$((selected+3))             # Set to new row
         DoPrintRev "$longest" "$name"
     ;;
     4|2) # Right or left - button action, not a menu action
         SwitchButtons $selectedbutton
         selectedbutton=$?
         PrintButtons "$buttontext" $selectedbutton $buttonRow
     ;;
     *) continue   # Do nothing
     esac
   done
} # End DoMenu

function DoLongMenu    # Advanced menuing function with extended descriptions
{  # $1 The name of the file containing the verbose menu items
   # $2 Optional button text eg: 'Ok Exit' (if empty will default to 'Ok Exit')
   # $3 Optional headline (if headline is required, $2 must be passed, even if null)
   # DoLongMenu requires the named file to exist. It must contain all the verbose
   # menu items (max length 50 characters), one item to a line, no more than 20 items
   # If the 'Ok' button is selected, DoLongMenu saves the selected item in the
   # Gstring variable. Otherwise, Gstring is set to "".
   # If the 'Ok' button is selected, return sends 1, otherwise 2.
    local filename winwidth message                               # Basics
    local items description longest length trimmed padding maxlen # Items
    local selected Grow spaces padding      # Printing
    local selectedbutton buttonrow buttontext                     # buttons
    # Check that the named file exists, if not, throw a wobbly
    if [ -f "$1" ]; then
        filename="$1"
    else
        DoMessage "$1 not found - unable to continue"   # Display error message
        return 0
    fi
   # Needed for drawing and highlighting buttons
    if [ "$2" == "" ]; then
        buttontext="Ok Exit"
    else
        buttontext="$2"
    fi
    headline="$3"
    winwidth=$(tput cols)             # Window width
    maxlen=$((winwidth -2))           # Maximum allowable item length
    items=$(cat "$filename" | wc -l)  # Count lines in file
    longest=0
    # Find length of longest item in file for use in reverse colour
    for (( i=1; i <= items; ++i ))
    do
        description="$(head -n ${i} ${filename} | tail -n 1)" # Read item from file
        length=$(echo "$description" | wc -c)                 # Length in characters
        if [ $length -gt $maxlen ]; then
          trimmed="${description:0:$maxlen}"      # Trim the text
          description="$trimmed"                  # Save the shorter text
          length=$(echo "$description" | wc -c)   # Reset length
        fi

        if [ $length -gt $longest ]; then
          longest=$length
          Gcol=$(( (winwidth - length) /2 ))   # Position of first character
        fi
    done
    DoHeading
    Grow=2
    DoFirstItem "$headline"
    Grow=3
    # Now run through the file again to print each item (Top one will be highlighted)
    for (( i=1; i <= $items; ++i ))
    do
        description="$(head -n ${i} ${filename} | tail -n 1)" # Read item from file
        if [ $i -eq 1 ]; then                     # First item - print highlighted
          DoPrintRev "$longest" "$description" # Print reverse (padded)
          Grow=$((Grow + 1 ))
         else
          DoNextItem "$description" # Print subsequent line
          Grow=$((Grow + 1 ))
        fi
    done
    Grow=$((Grow+1))
    DoFirstItem "Use cursor keys to navigate"
    buttonrow=$((Grow)); selected=1; selectedbutton=1
    PrintButtons "$buttontext" $selectedbutton $buttonrow
    while true          # The cursor key action will change either the hightlighted
    do                  # menu item or one of the buttons.
        DoKeypress      # Sets numeric $Gnumber for up/down or left/right)
        case "$Gnumber" in
        0)  # Button 1 or button 2 pressed
            Gnumber=$selected
            if [ $selectedbutton -eq 2 ]; then
                Gstring=""                 # No mresult on exit button
            else
                Gstring="$(head -n ${selected} ${filename} | tail -n 1)" # Read item from file
            fi
            return $selectedbutton  # Button 1 or 2
        ;;
        1) # Up arrow:
            # First reprint currently selected item in plain
            Grow=$((selected+2))   # Set to new row (menu starts at row 3)
            description="$(head -n ${selected} ${filename} | tail -n 1)"
            length=$(echo "$description" | wc -c)   # Get length for padding
            spaces=$((longest-length))              # Calculate spaces to pad it out
            padding="$(printf '%*s' "$spaces")"     # Create spaces to make length
                                                    # To hide reversed padding
            tput cup $Grow $Gcol     # Move cursor
            printf "%-s\\v" "$description $padding" # Print the item
            # Next move the selected item
            if [ $selected -eq 1 ]; then            # If at top
              selected=$items                       # Move pointer to bottom
            else
              selected=$(( selected -1 ))           # Else move up one
            fi
            # Print newly selected item in reverse colour (padded)
            description="$(head -n ${selected} ${filename} | tail -n 1)"
            Grow=$((selected+2))
            DoPrintRev "$longest" "$description"
        ;;
        3) # Down arrow
            # First reprint currently selected item in plain
            Grow=$((selected+2))   # Set to new row (menu starts at row 3)
            description="$(head -n ${selected} ${filename} | tail -n 1)"
            length=$(echo "$description" | wc -c)   # Get length for padding
            spaces=$((longest-length))              # Calculate spaces to pad it out
            padding="$(printf '%*s' "$spaces")"     # Create spaces to make length
                                                    # To hide reversed padding
            tput cup $Grow $Gcol     # Move cursor
            printf "%-s\\v" "$description $padding" # Print the item
            # Next move the selected item
            if [ $selected -eq $items ]; then       # If at bottom
              selected=1                            # Move to top
            else
              selected=$((selected+1))              # Else move down one
            fi
            # Print newly selected item in reverse colour (padded)
            description="$(head -n ${selected} ${filename} | tail -n 1)"
            Grow=$((selected+2))                # Set to new row
            DoPrintRev "$longest" "$description"
        ;;
        4|2) # Right or left - button action, not a menu action
            SwitchButtons $selectedbutton
            selectedbutton=$?
            PrintButtons "$buttontext" $selectedbutton $buttonrow
        ;;
        *) continue   # Do nothing
        esac
    done
} # End DoLongMenu

function DoFirstItem  # Aligned text according to screen size. May be a menu item.
{   # $1 Text to print	$2 (if present = false - not a menu item)				!* EAM002 *!
    local winwidth maxlen textprint textlength
    local isMenu="$1"
    winwidth=$(tput cols)                       # Recheck window width
    maxlen=$((winwidth-2))                      # Limit to 2 characters < Width
    textprint="$1"                              # Text passed from caller
    textlength=$(echo $textprint | wc -c)       # Count characters
    if [ $textlength -ge $maxlen ]; then
        textprint="${textprint:0:$maxlen}"      # Limit to printable length
        textlength=$maxlen
    fi
    if [ "$isMenu" ]; then								# Not a menu item				!* EAM002 *!
		fiCol=$(( (winwidth - textlength) / 2 ))  # First item start point	!* EAM002 *!
		tput cup $Grow $fiCol                     # Move cursor to fiCol		!* EAM002 *!
    else														# Is a menu item				!* EAM002 *!
		Gcol=$(( (winwidth - textlength) / 2 ))   # First item start point	!* EAM002 *!
		tput cup $Grow $Gcol                      # Move cursor to Gcol		!* EAM002 *!
	fi
    printf "%-s\\v" "$textprint"                # Print the item
    Grow=$((Grow+1))                            # Advance line counter
    return 0
} # End DoFirstItem

function DoNextItem     # Subsequent item in an aligned list
{                       # $1 Item text
  tput cup $Grow $Gcol  # Move cursor to row and Gcol
  printf "%-s\\n" "$1"  # Print with a following newline
}

function DoPrintRev     # Prints selected item by reversing colour
{                                            # $1 Length of longest; $2 Item text
    local longest padding spaces itemlength
    longest=$1
    itemlength=$(echo $2 | wc -c)            # Get length
    itemlength=$(( itemlength - 1 ))         # Get length
    if [ $itemlength -lt $longest ]; then
        spaces=$((longest-itemlength))       # Calculate spaces needed to pad it out
        padding="$(printf '%*s' "$spaces")"  # Create spaces to make length
    else
        padding=""
    fi
    tput cup $Grow $Gcol                     # Move cursor to Gcol
    tput rev                                 # Reverse colour
    printf "%-s" "$2${padding}"              # Reprint item at this position
    tput sgr0                                # Reset colour
}

function DoKeypress # Reads keyboard and returns value via Gnumber
{
    local keypress
    while true  # Respond to user keypress
    do
        tput civis &                          # Hide cursor
        read -rsn1 keypress                   # Capture key press
        tput cnorm                            # Reset cursor
        case "$keypress" in
        "") # Ok/Return pressed
            Gnumber=0; break
            ;;
        A) # Up arrow:
            Gnumber=1; break
            ;;
        B) # Down arrow
            Gnumber=3; break
            ;;
        C) # Right arrow
            Gnumber=4; break
            ;;
        D) # Left arrow
            Gnumber=2; break
            ;;
        x)  Gnumber=5; break         # New radio-buttons option
            ;;
        *)  keypress=""
        esac
    done
} # End DoKeypress
# End Menus
# ----------------------------------------------------------
# Lists
# ----------------------------------------------------------
function DoLister  # Generates a (potentially multi-page) list from a file.
{   # Parameter: $1 is the name of the file containing all the items to be listed
    # The calling function must create the file* before calling DoLister
    #       * The file must have one word per item, one item per line
        local totalItems lastItem itemLen testLen winWidth displayWidth
        local winCentre winHeight topRow bottomRow itemsInColumn counter
        local page pageNumber pageWidth columnWidth lastPage
        local column numberOfColumns widthOfColumns recordNumber
        # The following arrays are global in scope, as they are shared between
        # functions. However, they are specific to this class, so they
        # are declared here, not at the top of lister.sh
        declare -a GlobalColumnsArray      # Array to hold all prepared columns
        declare -a GlobalColumnWidthsArray # And one for their widths
        declare -a GlobalPagesArray        # Each element = list of columns forming the page
        declare -a GlobalPageWidthsArray   # Each element = width of columns forming the page
        page=""                 # List of column numbers for the selected page
        pageNumber=1            # Page selector
        pageWidth=3             # Start width accumulator with margins
        columnWidth=0; lastPage=0
        # Establish terminal size and set variables
        winWidth=$(tput cols)               # Start with full terminal width
        displayWidth=$((winWidth-4))        # Allow for two characters margin each side
        winCentre=$((winWidth/2))           # page centre used to calculate start point
        winHeight=$(tput lines)             # Full height of terminal
        topRow=4                            # Leave space for heading
        Grow=1                   # Start cursor at top of page
        bottomRow=$((winHeight-4))          # Leave space for footer
        itemsInColumn=$((bottomRow-topRow)) # Number of items in each column
        # Check that the named file exists, if not, throw a wobbly
        if [ ! -f "$1" ]; then
            DoMessage "$1 not found - unable to continue"   # Display error message
            return 0
        fi
        grep -v '^$' ${1} > lister-temp.file       # Make a clean working copy of the file
        totalItems=$(cat lister-temp.file | wc -l)
        totalItems=$((totalItems+1))                # wc counts newlines, so add 1
        lastItem="$(tail -n 1 lister-temp.file)"
        tput cnorm   # Ensure cursor is visible
        DoHeading  # Prepare the window
        # Fill the global array of columns. Each element in the array holds one column
        widthOfColumns=2
        counter=0
        recordNumber=0
        # Start outer loop for entire file
        while [ $recordNumber -le $totalItems  ]
        do
            testLen=0
            Column=""
            # Get length of each item in each column (save length of longest in each
            # column) then add just enough to each element to fit the window height
            for (( line=1; line <= $itemsInColumn; ++line ))
            do
                recordNumber=$((recordNumber+1)) # Is 0 at start of outer loop
                item=$(head -n $recordNumber lister-temp.file | tail -1) # Read item
                itemLen=${#item}                       # Measure length
                itemLen=$((itemLen+3))                 # Add column spacing
                if [ $itemLen -gt $testLen ]; then
                    testLen=$itemLen  # If longest in this column, save length
                fi

                if [ $recordNumber -gt $totalItems ]; then # Exit loop if last
                    break
                else
                    Column="$Column $item"        # Add this item to string variable
                fi
            done # End of inner (column) loop

            numberOfColumns=$((numberOfColumns+1))      # Increment columns counter
            # Add this column to the columns array, and its width to the widths array
            GlobalColumnsArray[${numberOfColumns}]="${Column}"
            GlobalColumnWidthsArray[${numberOfColumns}]=$testLen
            Column=""   # Empty the string variable for the next column
        done # End of outer (file) loop
    rm lister-temp.file    # Tidy up
    # Now build GlobalPagesArray with just enough columns to fit page width each time
    while true  # These elements are numeric (column numbers). The records are still
    do       # in GlobalColumnsArray. Iterate through each element of GlobalColumnsArray
        for (( column=1; column <= $numberOfColumns; ++column ))
        do
            if [ $((pageWidth+columnWidth+4)) -gt $displayWidth ]; then
                # If adding another column would exceed page width, save current width
                GlobalPageWidthsArray[${pageNumber}]=$pageWidth
                column=$((column-1))         # Reset counter so we don't lose this column
                pageWidth=3    # and reset the variable for the next page
                # Copy the list of columns to the pages array
                # Note: This will not be triggered on the first iteration
                GlobalPagesArray[${pageNumber}]="${page}"
                # Then set next page, advance page counter
                pageNumber=$((pageNumber+1))
                page=""     # And empty the string variable for next list of columns
                continue # Do no more on this iteration
            fi
            columnWidth=0 # Iterate through each element of GlobalColumnsArray for this
            for item in ${GlobalColumnsArray[${column}]} # column to find the widest
            do
                itemLen=${#item}
                if [ $itemLen -gt $columnWidth ]; then
                    columnWidth=$((itemLen+3)) # Reset (allow spaces between columns)
                fi
            done
            # Check that adding this column will not exceed page width.
            if [ $((pageWidth+columnWidth+4)) -lt $winWidth ]; then # Page not full
                pageWidth=$((pageWidth+columnWidth+4)) # Add column width to page width
                page="$page $column"       # and append the column number to this page
            fi
            # Update if last column reached
            if [ $column -eq $numberOfColumns ]; then
                lastPage=$pageNumber                   # We now know how many pages
                GlobalPageWidthsArray[${pageNumber}]=$pageWidth  # Add width and
                GlobalPagesArray[${pageNumber}]="${page}"        # page to arrays
                break 2
            fi
        done
    done
    #  Proceed to page-handling in ListerSelectPage
    ListerSelectPage $winHeight $winCentre $lastPage
} # End DoLister

function ListerSelectPage   # Organises a (nominated) pageful of data for display
{                       # $1 = winHeight; $2 = winCentre; $3 = lastPage
    local pageNumber lastPage advise previous next instructions instrLen
    local winHeight winCentre
    pageNumber=1; winHeight=$1; winCentre=$2; lastPage=$3
    advise="or ' ' to exit without choosing"
    previous="Enter 'p' for previous page"
    next="Enter 'n' for next page"
    while true    # Display appropriate page according to user input
    do
        case $pageNumber in
        1)  if [ $lastPage -gt 1 ]; then   # On any page with more than 1 page in total
                instructions="$next"
            else
                instructions=""
            fi
            Grow=1                       # Reset cursor to top of page
            ListerPrintPage "$winHeight" "$winCentre" "$instructions" "$pageNumber" "$lastItem"

            case $? in           # Return code from ListerPrintPage will be 0, 1, or 2
            1)  continue         # < (left arrow) = illegal call to previous page
            ;;
            2)  if [ $lastPage -gt 1 ]; then        # More than 1 page in total
                    pageNumber=$((pageNumber+1))    # > (right arrow) = next page
                    continue
                fi
            ;;
            *)  break                    # An item was selected or 'Exit' entered
            esac
        ;;
        $lastPage) instructions="$previous"
            Grow=1                       # Reset cursor to top of page
            ListerPrintPage "$winHeight" "$winCentre" "$instructions" "$pageNumber" "$lastItem"
            case $? in                       # Return will be 0, 1, or 2
            1)  pageNumber=$((pageNumber-1)) # < (left arrow) = previous page
            ;;
            2)  continue                 # > (right arrow) = illegal call to next page
            ;;
            *)  break                    # 0 : an item was selected or 'Exit' entered
            esac
        ;;
        *)  instructions="$previous - $next"
            Grow=1                       # Reset cursor to top of page

            ListerPrintPage "$winHeight" "$winCentre" "$instructions" "$pageNumber" "$lastItem"
            case $? in                              # Return will be 0, 1, or 2
            1)  if [ $pageNumber -gt 1 ]; then      # Not on page 1
                    pageNumber=$((pageNumber-1))    # < (left arrow) = previous page
                fi
            ;;
            2)  if [ $pageNumber -lt $lastPage ]; then   # Not on last page
                    pageNumber=$((pageNumber+1))        # > (right arrow) = next page
                fi
            ;;
            *)  break                  # 0 : an item was selected or '' entered
            esac
        esac
    done
} # End ListerSelectPage

function ListerPrintPage      # Prints the page prepared and selected in ListerSelectPage
{  # $1 winHeight; $2 winCentre; $3 instructions; $4 pageNumber; $5 lastItem;
   # The arrays used here are declared and initialised in DoLister as global in scope
    local pageWidth columnStart thisPage pageNumber
    local counter columnWidth instructions instrLen lastItem advisLen
    local winHeight winCentre topRow
    winHeight=$1; winCentre=$2; instrLen=${#3}; instructions="$3"
    pageNumber="$4"; lastItem="$5"; counter=1
    DoHeading $Gtitle                          # Prepare window
    DoFirstItem "Page $pageNumber of $lastPage"
    thisPage="${GlobalPagesArray[${pageNumber}]}" # Get column numbers for this page
    pageWidth=${GlobalPageWidthsArray[${pageNumber}]}  # Get width of this page
    columnStart=$(( winCentre - (pageWidth/2)))
    topRow=$((Grow+1))
    Grow=$topRow
    while true  # Do the printing thing
    do
        # Outer loop iterates through columns for this page, getting the column numbers
        for column in ${thisPage}
        do
            columnWidth=${GlobalColumnWidthsArray[${column}]}

            if [ -z "$columnWidth" ]; then
                continue
            fi
            # Inner loop iterates through contents of GlobalColumnsArray getting the
            for item in ${GlobalColumnsArray[${column}]} # contents of each element
            do
                # Move cursor to print point
                tput cup $Grow $columnStart
                printf "%-s\n" "${counter}) $item"

                if [ "$item" == "$lastItem" ]; then break; fi

                Grow=$((Grow+1))
                counter=$((counter+1))
            done
            columnStart=$((columnStart+columnWidth+2))  # Start next column at top
            Grow=$topRow
        done
        instrCol=$((winCentre-(instrLen/2)))
        tput cup $((winHeight-4)) $instrCol   # Position cursor near bottom of screen
        echo "${instructions}"                  # eg: "Enter '>' for next page"
        adviseLen=${#advise}
        instrCol=$((winCentre-(adviseLen/2)))
        tput cup $((winHeight-2)) $instrCol
        echo "${advise}"                        # eg: "or ' ' to exit without choosing"
        Grow=$((winHeight-3))
        DoForm "Enter the number of your selection: "
        Gnumber="$Gstring"
        case $Gstring in
        "")  return 0                             # Quit without selecting anything
        ;;
        'p'|'P') return 1                         # Previous page, if valid
        ;;
        'n'|'N') return 2                         # Next page, if valid
        ;;
        *[!0-9]*)   # Not numbers
            thisPage="${GlobalPagesArray[${pageNumber}]}"   # Get the string of column
                                                            # numbers for this page
            pageWidth=${GlobalPageWidthsArray[${pageNumber}]}  # Get the full width of
                                                               # this page of columns
            columnStart=$(( winCentre - (pageWidth/2) -3 ))    # Centre it
            Grow=$topRow
            continue
        ;;
        *)  counter=1  # A number has been entered. Find it in the columns of this page
            for column in ${thisPage}  # Outer loop iterates through the page variable
            do                         # Inner loop finds this item
                for item in ${GlobalColumnsArray[${column}]}
                do
                    if [ $counter -eq $Gnumber ]; then
                        Gstring=$item                    # And sends it home
                        return 0
                    fi
                    counter=$((counter+1))
                done
            done
        esac
    done
} # End ListerPrintPage

function DoMega   # Cleans up crude data from input file and prepares mega-work.file
{   # Generates a (potentially multi-page) numbered list from a file
    # Parameters:
    # $1 Name of the file containing all the items; $2 information to print above list
    local advise previous next instructions pages pageNumber width
    local winHeight items i counter line display saveCursorRow term1
    if [ ! -f "$1" ]; then
        DoMessage "The file $1 is needed but was not found."
        return 1
    fi
    term1="$2"
    width=$(tput cols); width=$((width-2))              # Allow margin
    items=$(cat $1 | wc -l); items=$((items+1))         # wc counts newlines, so add 1
    winHeight=$(tput lines); display=$((winHeight-6))   # Items to display in one pageful
    pages=$((items/display)); remainder=$((items%display))  # May need extra page
   
    if [ $pages -eq 0 ]; then
        pages=1
    elif [ $remainder -gt 0 ]; then
        pages=$((pages+1))
    fi
    rm mega-work.file 2>/dev/null  # Clear the work file (hide errors)
    # 1) Read the input file, number each item, shorten to fit page width and save to a new file
    for (( i=1; i < items; ++i ))
    do
        line="$(head -n ${i} ${1} | tail -n 1)"            # Read one line at a time
        line="$i:$line"                                         # Number it
        echo ${line##*( )} | cut -c 1-$width  >> mega-work.file    # cut it down to fit width
    done

    if [ $items -le $display ]; then    # DoLongMenu is more convenient for a single page
        DoLongMenu "mega-work.file" "Ok Exit" "$term1"
        rm mega-work.file 2>/dev/null  # Clear the work file
        return $?
    fi

    pageNumber=1                # Start at first page
    Grow=2
    counter=1                   # For locating items in the file

    MegaPage $pageNumber $pages $display $items $counter "$term1"   # Prints the page
    rm mega-work.file 2>/dev/null  # Clear the work file (hide errors)

} # End DoMega

function MegaPage     # The actual printing bit
{                     # $1 pageNumber; $2 pages; $3 display; #4 items; $5 counter;
                      # $6 information to be printed above the list
    local advise previous next instructions pages pageNumber term1
    local winHeight items i counter line display saveCursorRow
    advise="Or ' ' to exit without choosing"
    previous="Enter 'p' for previous page"
    next="'n' for next page"
    pageNumber=$1; pages=$2; display=$3; items=$4; counter=$5; term1="$6"
    while true      # Print the actual page
    do
        if [ $pageNumber -eq 1 ]; then
            instructions="Enter $next"
        elif [ $pageNumber -eq $pages ]; then
            instructions="$previous"
        else
            instructions="$previous or $next"
        fi
        DoHeading
        Grow=1
        DoFirstItem "$term1"
        Grow=2
        DoFirstItem "Page $pageNumber of $pages"
        Grow=3

        for (( line=1; line <= $display; ++line ))
        # Print a pageful up to max number of lines to display
        do
            item=$(head -n $counter mega-work.file | tail -1)  # Read item from file

            if [ $line -eq 1 ]; then                        # First item on this page
                tput cup $Grow $Gcol                        # Move cursor to start
                printf "%-s\\v" "$item"                     # Print the item
            else
                DoNextItem "$item"                          # Bug fix EAM0001
            fi

            counter=$((counter+1))
            if [ $counter -gt $items ]; then                # Exit loop if last record
                Grow=$((Grow+1))
                break
            fi
            Grow=$((Grow+1))
        done

        DoFirstItem "$instructions"
        DoFirstItem "$advise"
        DoForm "Enter the number of your selection : "
        case "$Gstring" in
        "") return 0                                   # Backing out
        ;;
        'p'|'P') if [ $pageNumber -ne 1 ]; then        # Ignore illegal call to previous page
                pageNumber=$((pageNumber-1))
            fi
         ;;
        'n'|'N') if [ $pageNumber -ne $pages ]; then   # Ignore illegal call to next page
                pageNumber=$((pageNumber+1))
            fi
        ;;
        *[!0-9]*) continue                      # Other characters that are not numbers
        ;;
        *)  # A number was entered
            counter="$Gstring"  # Convert char to int & use to find the item in the file
            Gstring="$(head -n ${counter} mega-work.file | tail -n 1)"
            return $counter
        esac
        counter=$(((pageNumber*display)+1-display))
    done
} # End MegaPage

function DoRadio {  # A function to print up to four columns of radio buttons. The user
                    # moves the cursor using the cursor keys, and marks one button in
                    # each column by pressing 'x'
    # $1 Headline text; $2 (and optional $3 & $4) are prompt text for the radio buttons
    # $2, $3 & $4 are strings of space-separated one-word prompts.
    # The first item in each of $2, $3 and $4 are column headings (required)
    # Sets global variable Gstring with the position of the selected item in each column
    # (eg: 4 1 5 2) You can then relate each number to the string variable using DoEnum
    local headline column1 column2 column3 marked results
    local item i counter savecursorrow width columns
    local longest1 longest2 longest3 longest4
    local firstpoint items1 items2 items3 items4

    # Load the parameters
    headline="$1"; column1="$2"; column2="$3"; column3="$4"; column4="$5"
    longest1=1; longest2=1; longest3=1; longest4=1;
    items1=0; items2=0; items3=0; items4=0

    # Find the longest item in each column
    for item in $column1
    do
        if [ ${#item} -gt $longest1 ]; then longest1=${#item}; fi # Get length of longest
    done
    columns=1
    longest1=$((longest1+1))  # Add a space b button
    if [ "$column2" != "" ]; then
        for item in $column2
        do
            if [ ${#item} -gt $longest2 ]; then longest2=${#item}; fi # Get length of longest
        done
        columns=$((columns+1))
        longest2=$((longest2+1))
    fi
    # Get length of longest
    if [ "$column3" != "" ]; then
        for item in $column3
        do
            if [ ${#item} -gt $longest3 ]; then longest3=${#item}; fi
        done
        columns=$((columns+1))
        longest3=$((longest3+1))
    fi
   # Get length of longest
    if [ "$column4" != "" ]; then
        for item in $column4
        do
            if [ ${#item} -gt $longest4 ]; then longest4=${#item}; fi # Get length of longest
        done
        columns=$((columns+1))
        longest4=$((longest4+1))
    fi
    width=$(tput cols)
    margin=$(((width-longest1-longest2-longest3-longest4)/(columns*2)))
    radioCol=$margin
    DoHeading
    Grow=$((Grow + 1 ))
    DoFirstItem "$headline"
    Grow=$((Grow + 1 ))
    savecursorrow=$Grow              # Top row of columns
    counter=0
    # Get page height and set cursor row 4 up from bottom
    Grow=$(tput lines)
    Grow=$((Grow-4))
    # User guidance
    DoFirstItem "Use cursor keys to navigate"
    DoFirstItem "'x' to select/deselect"
    DoFirstItem "[Enter] when done"
    # Print all the columns and buttons
    Grow=$savecursorrow
    RadioColumn "$column1" 3 1 $((margin)) $longest1
    firstpoint=$?  # Position of first radio button
    items1=$Gnumber
    longest1=$((longest1+margin))
    # Add for columns
    if [ "$column2" != "" ]; then
        Grow=$savecursorrow    # Top of column
        RadioColumn "$column2" 3 2 $((margin+longest1)) $longest2
        items2=$Gnumber
        longest2=$((longest2+margin))  # Add for columns
    fi
    # Add for columns
    if [ "$column3" != "" ]; then
        Grow=$savecursorrow
        RadioColumn "$column3" 3 3 $((margin+longest1+longest2)) $longest3
        items3=$Gnumber
        longest3=$((longest3+margin))
    fi
    # Add for columns
    if [ "$column4" != "" ]; then
        Grow=$savecursorrow
        RadioColumn "$column4" 3 3 $((margin+longest1+longest2+longest3)) $longest4
        items4=$Gnumber
        longest4=$((longest4+margin))  # Add for columns
    fi
    Grow=$((savecursorrow+1))
    RadioSelect $columns $firstpoint "$longest1 $longest2 $longest3 $longest4" "$items1 $items2 $items3 $items4"
} # End DoRadio

function RadioColumn { # Handle printing of one column, its header and the items in it
                            # $1 items; $2 total columns (1 to 4);
                            # $3 this column (1 to 4); $4 "" $5 longest
    local list columns column longest width
    local item i items savecursorrow
    list="$1"; columns=$2; column=$3; items=0
    savecursorrow=$Grow
    longest=$5
    # Draw the column of items
    for item in $list
    do
        if [ $items -eq 0 ]; then
            tput cup $Grow $radioCol  # Move cursor to row and Gcol
            printf "\e[4m%-s\n\e[0m" " $item "
        else
            DoNextItem "$item"
        fi
        Grow=$((Grow + 1 ))
        items=$((items+1))
    done
    items=$((items-1))  # Exclude headings
    # Reset position to top row and print all radio buttons for this column
    radioCol=$((radioCol+longest))
    Grow=$((savecursorrow+1))    # After column heading
    for (( i=1; i<=items; i++ )) # Now draw a ( ) beside each
    do
        DoNextItem "( )"
        Grow=$((Grow + 1 ))
    done
    Gnumber=$items
    return 0
} # End RadioColumn

function RadioSelect {  # Highlight the top radio button of the first column, then the
                        # next one as the cursor is moved, switch columns according to
                        # cursor movement. Mark an item as selected or deselected if the
                        # user presses 'x'. Also unmark a previously selected item in
                        # the column if the user selects a different one.
    # $1 number of columns (to monitor column switching); $2 firstpoint (initially column1)
    # $3 string containing the lengths of the longest items in each column
    # $4 string containing the number of items in each column
    local columns column marked1 marked2 marked3 selected
    local item i counter savecursorrow firstpoint columnwidth unmark toprow
    declare -a marked
    declare -a items
    declare -a longest
    marked[1]=0; marked[2]=0; marked[3]=0; marked[4]=0; selected=1; column=1; unmark=0
    columns=$1
    firstpoint=$2                   # Position over the first pair of brackets
    longest[1]=$(echo $3 | cut -d' ' -f1)
    longest[2]=$(echo $3 | cut -d' ' -f2)
    longest[3]=$(echo $3 | cut -d' ' -f3)
    longest[4]=$(echo $3 | cut -d' ' -f4)
    toprow=$Grow; savecursorrow=$Grow
    radioCol=$firstpoint
    DoPrintRev 3 "( )"  # And mark initial selected item
    items[1]=$(echo $4 | cut -d' ' -f1)
    items[2]=$(echo $4 | cut -d' ' -f2)
    items[3]=$(echo $4 | cut -d' ' -f3)
    items[4]=$(echo $4 | cut -d' ' -f4)
    while true  # The cursor key action will change either the
    do          # selected radio button or one of the bottom buttons
        DoKeypress      # Sets numeric $Gnumber for up/down or left/right)
        case "$Gnumber" in
        0)  Gstring="${marked[1]} ${marked[2]} ${marked[3]} ${marked[4]}"
            return 0
        ;;
        1)  # Up arrow:
            # First reprint currently selected item in plain
            Grow=$((selected+toprow-1))   # Set to new row (from top)

            tput cup "$Grow" "$firstpoint"   # Move cursor
            if [ ${marked[${column}]} -eq $selected ]; then
                printf "(x)"            # Print selected item in plain   "( )"
            else
                printf "( )"            # Print unselected item in plain
            fi
            # Next move the selected item
            if [ $selected -eq 1 ]; then                # If at top
                selected=${items[${column}]}                         # Move pointer to bottom
            else
                selected=$(( selected -1 ))             # Else move up one
            fi
            # Print newly selected item in reverse colour (padded)
            Grow=$((selected+toprow-1))
            radioCol="$firstpoint"
            if [ ${marked[${column}]} -eq $selected ]; then
                DoPrintRev 3 "(x)"         # Print selected item in plain   "( )"
            else
                DoPrintRev 3 "( )"         # Print unselected item in plain
            fi
        ;;
        3) # Down arrow
            # First reprint currently selected item in plain
            Grow=$((selected+toprow-1))   # Set to new row (menu starts at row 4)
            tput cup "$Grow" "$firstpoint"   # Move cursor
            if [ ${marked[${column}]} -eq $selected ]; then
                printf "(x)"            # Print selected item in plain   "( )"
            else
                printf "( )"            # Print unselected item in plain
            fi
            # Next move the selected item
            if [ $selected -eq ${items[${column}]} ]; then  # If at bottom
                selected=1                                  # Move to top
            else
                selected=$((selected+1))                    # Else move down one
            fi
            # Print newly selected item in reverse colour (padded)
             Grow=$((selected+toprow-1))         # Set to new row
             radioCol="$firstpoint"
            if [ ${marked[${column}]} -eq $selected ]; then
                DoPrintRev 3 "(x)"            # Hilight marked item
            else
                DoPrintRev 3 "( )"            # Highlight unmarked item
            fi
        ;;
        4)  # Switch column right
            if [ $column -lt $columns ] && [ $columns -gt 1 ]; then
                # Reprint currently selected button in plain (marked or unmarked)
                tput cup "$Grow" "$firstpoint"   # Position cursor
                if [ ${marked[${column}]} -eq $selected ]; then
                    printf "(x)"            # Print selected item in plain
                else
                    printf "( )"            # Print unselected item in plain
                fi

                selected=1                  # First item in new column
                Grow=$toprow     # Top of new column
                column=$((column + 1))      # Advance column
                firstpoint=$((firstpoint + ${longest[${column}]}))  # How far to jump
                tput cup "$Grow" "$firstpoint"           # Position cursor

                # Find out if the selected item in the new column is marked or not
                # and print as appropriate (highlighted)
                radioCol="$firstpoint"
                if [ ${marked[${column}]} -eq $selected ]; then
                    DoPrintRev 3 "(x)"         # Hilight marked item
                else
                    DoPrintRev 3 "( )"         # Highlight unmarked item
                fi
            fi
            continue    # Then loop
        ;;
        2)  # Switch column left
            if [ $column -gt 1 ]; then
                # Reprint currently selected button in plain (marked or unmarked)
                tput cup "$Grow" "$firstpoint"   # Position cursor
                if [ ${marked[${column}]} -eq $selected ]; then
                    printf "(x)"            # Print selected item in plain   "( )"
                else
                    printf "( )"            # Print unselected item in plain
                fi

                selected=1                                      # Top item of new column
                Grow=$toprow                             # Top row
                firstpoint=$((firstpoint - ${longest[${column}]}))  # How far to jump
                column=$((column - 1))                          # Then retard column number
                tput cup "$Grow" "$firstpoint"       # Position cursor
               radioCol="$firstpoint"
                # Find out if the selected item in the new column is marked or not
                # and print as appropriate (highlighted
                if [ ${marked[${column}]} -eq $selected ]; then
                    DoPrintRev 3 "(x)"         # Hilight marked item
                else
                    DoPrintRev 3 "( )"         # Highlight unmarked item
                fi

                # Find out if the selected item in the new column is marked or not
                # and print as appropriate (highlighted
                if [ ${marked[${column}]} -eq $selected ]; then
                    DoPrintRev 3 "(x)"         # Hilight marked item
                else
                    DoPrintRev 3 "( )"         # Highlight unmarked item
                fi
            fi
            continue    # Then loop
        ;;
        5) # Remove or add an x in the brackets of the selected (hightlighted) item
            radioCol="$firstpoint"
            if [ ${marked[${column}]} -eq $selected ]; then
                DoPrintRev 3 "( )"
                marked[${column}]=0
            else
            # If another button in this column was previously marked, unmark it
                if [ ${marked[${column}]} -ne 0 ]; then
                    unmark=${marked[${column}]}
                    unmark=$((unmark+toprow-1))
                 #   savecursorrow=$Grow     # Save current row
                    tput cup "$unmark" "$firstpoint"    # Move cursor to the marked item
                    printf "( )"                        # Print it unmarked in plain
                    tput cup "$Grow" "$firstpoint" # Restore the current cursor position
                fi
            # Then print this one as marked and record in the array ...
                DoPrintRev 3 "(x)"
                marked[${column}]=$selected
            fi
        ;;
        *)  continue
        esac
    done
} # End RadioSelect
# End Lists

function Debug() {
    # Copy and insert at any point ...
    # Debug "$BASH_SOURCE" "$FUNCNAME" "$LINENO" " any variables "
    echo            # Make sure output is on a new line
    read -p "In file: $1, function:$2, at line:$3 $4"
    return 0
} # End Debug
