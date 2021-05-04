#!/bin/bash

# Developed by Elizabeth Mills
# Revision 21.05.04.1 May 2021

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
# global variables GlobalChar and GlobalInt. One other global variable
# is used - GlobalCursorRow, which tracks vertical alignment. All other
# variables are local to their functions, and values must be passed as
# parameters between them.
# See lister.manual for guidance on the use of these functions

# -------------------------------------------------------------
#       Shared .. General-purpose functions
# -------------------------------------------------------------
# DoHeading      60   Prepare a new window with heading
# DoForm         83   Centred prompt for user-entry
# DoMessage     101   Prints a message with Ok button
# DoButtons     106   Prints one or two buttons
# -------------------------------------------------------------
#       Menus .. Displaying and using menus
# -------------------------------------------------------------
# DoMenu        158   Generates a simple menu of one-word items
# DoLongMenu    315   Generates a menu of multi-word items
# DoFirstItem   461   Prints a single, centred item
# DoNextItem    482   Prints successive aligned items
# DoPrintRev    488   Reverses text colour at appointed position
# DoKeypress    503   Respond to keypress
# --------------------------------------------------------------
#       Lists .. Display long lists and accept user input
# --------------------------------------------------------------
# DoLister      541   Generates a numbered list of one-word items in columns
# DoSelectPage  673   Used by DoLister to manage page handling
# DoPrintPage   739   Used by DoLister to display selected page
# DoMega        834   Pages full of extra long text, trimmed to fit
# DoMegaPage    884   Does the printing for DoMega
# ---------------------------------------------------------------

# Global variables
GlobalInt=0                # Output (menu item number)
GlobalChar=""                 # Output (menu item text)
GlobalCursorRow=0               # For alignment across functions

# ---------------------------------------------------------------
# Shared
#----------------------------------------------------------------
function DoHeading    # Always use this function to prepare the screen
{ 
    clear
    
    local winwidth limit text textlength startpoint
    winwidth=$(tput cols)                           # Recheck window width  
    text="$Backtitle"                               # Use Global variable
    textlength=$(echo $text | wc -c)                # Count characters
      
    if [ $textlength -ge $winwidth ]; then          # If text too long for window
        limit=$((winwidth-2))                       # Limit to 2 characters lt winwidth
        text="${text:0:$limit}"                     # Limit length of printed text
        textlength=$(echo $text | wc -c)            # Recount
    fi
    
    startpoint=$(( (winwidth - textlength) / 2 ))   # Horizontal startpoint
    tput cup 0 $startpoint                          # Move cursor to startpoint
    tput bold                                       # Display will be bold
    printf "%-s\\n" "$text"
    tput sgr0                                       # Reset colour inversion
    GlobalCursorRow=$((GlobalCursorRow+1))
} # End DoHeading

function DoForm    # Centred prompt for user-entry
{   # $1 Text for prompt
    # Returns user entry through $GlobalInt

    local winwidth length startpoint empty
  
    winwidth=$(tput cols)
    length=${#1}
      
    if [ ${length} -le ${winwidth} ]; then
        startpoint=$(( (winwidth - length) / 2 ))
    else
        startpoint=0
    fi
    tput cup $GlobalCursorRow $startpoint                     # Move cursor to startpoint
    read -p "$1" GlobalChar
} # End DoForm

function DoMessage    # Display a message with an 'Ok' button to close
{                     # $1 and $2 optional lines of message text
    xterm -T " Error" -geometry 90x10+300+250 -fa monospace -fs 10 -e "echo '$1' && echo '$2' && read -p 'Please press [Enter] ...'"
} # End DoMessage

function DoButtons
{   # $1 Button text; $2 Highlight one of the buttons; $3 buttonRow
    # Button string should contain one or two words: eg: 'Ok' or 'Ok Exit'
   
    local characters buttoncount button1 button1len button2 button2len selected
    local buttonstring buttonstringlength buttonstart winwidth buttonRow

    if [ "$2" ]; then selected=$2
    else selected=1                         # If no button selected
    fi

    if [ "$3" ]; then buttonRow=$3
    else buttonRow=12                       # If no button row specified
    fi
      
    winwidth=$(tput cols)  
    buttoncount=$(echo $1 | wc -w)           # One or two buttons
    if [ $buttoncount -eq 0 ]; then          # Exit in case of error
        echo "$(date +"%D %T") Line $LINENO - No buttons specified" > lister.log
        return 1
    fi

    button1="$(echo $1 | cut -d' ' -f1)"      # Text for 1st button
    characters=$(echo $button1 | wc -c)       # Count characters 
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
    tput sgr0 	                                # Reset colour

    if [ $selected -eq 2 ]; then tput rev; fi   # Reverse colour
    printf "%-s\\n" "$button2string"            # Print button2
    tput sgr0 	                                # Reset colour
    return $selected
} # End DoButtons
# End Shared
# -------------------------------------------------------------
# Menus
#--------------------------------------------------------------
function DoMenu  # Simple menu
{       # $1 String of single-word menu items (or the name of a file)
        # $2 button text eg: 'Ok Exit'
        # $3 May be a headline or empty
        # Sets global variable GlobalInt with the number of the item selected
        # and GlobalChar with the text of the item selected
        # Also sets the system return value ($?) with the number of the item selected
  
    local winwidth startpoint padding itemlen longest counter menulist
    local name items buttontext message buttonRow item i
    winwidth=$(tput cols) 
    padding=""
    longest=1

    if [ -f "$1" ]; then                    # If a file
        menulist=""
        items=$(cat ${1} | wc -l)           # Count lines in file
        items=$((items+1))                  # wc counts newlines, so add 1
        for (( i=1; i <= $items; ++i ))     # Load file contents into menulist
        do
            item="$(head -n ${i} ${1} | tail -n 1)" # Read item from file
            menulist="$menulist $item"              # Add to variable
        done
    elif [[ "$1" == "" ]]; then
        DoMessage "No data to work with"
        return 1
    else
        menulist="$1"    
    fi

    if [ ! $2 ]; then
        buttontext="Ok Exit"
    else
        buttontext="$2"
    fi
  
    case $3 in
      "") message=" "
      ;;
      *) message="$3"
    esac
   
    DoHeading                             # Prepare page
    GlobalCursorRow=$((GlobalCursorRow+1))
    DoFirstItem "$message"
    GlobalCursorRow=$((GlobalCursorRow+1))
    
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
    startpoint=$(( (winwidth - longest) /2 ))  # Position of first character
    
    # Now run through the list again to print each item
    counter=1
    for i in $menulist
    do
      name="$i"                       # Read item from list
      if [ $counter -eq 1 ]; then     # First item - print highlighted
        DoPrintRev "$startpoint" "$longest" "$name" # Print reverse (padded)
        GlobalCursorRow=$((GlobalCursorRow + 1 ))
       else
        DoNextItem "$startpoint" "$name" # Print subsequent line
        GlobalCursorRow=$((GlobalCursorRow + 1 ))
      fi
      counter=$((counter+1))
    done
    GlobalCursorRow=$((GlobalCursorRow+1))
    DoFirstItem "Use cursor keys to navigate"
    buttonRow=$((GlobalCursorRow+1))
    selected=1
    selectedbutton=1
    DoButtons "$buttontext" "$selectedbutton" $buttonRow

    while true          # The cursor key action will change either the
    do                  # hightlighted menu item or one of the buttons
    
        DoKeypress  # Sets numeric $GlobalInt for up/down or left/right)
        case "$GlobalInt" in
        0)  # Ok/Return pressed
            if [ $selectedbutton -eq 1 ]; then 
                GlobalInt=$selected  # Exit with the menu 1tem selected
                GlobalChar="$name"
            else
                GlobalInt=0          # Exit with no 1tem selected
                GlobalChar=""
            fi
            return $selected
        ;;
        1)  # Up arrow:
            # First reprint currently selected item in plain
            GlobalCursorRow=$((selected+3))   # Set to new row (menu starts at row 3)
            # Use string cutting facilities   
            name="$(echo $menulist | cut -d' ' -f$selected)"
            length=$(echo "$name" | wc -c)              # Get length for padding
            spaces=$((longest-length))                  # Calculate spaces to pad it out
            padding="$(printf '%*s' "$spaces")"         # Create spaces to make length
                                                        # To hide reversed padding
            tput cup "$GlobalCursorRow" "$startpoint"   # Move cursor
            printf "%-s\\v" "$name $padding"            # Print the item
            # Next move the selected item
            if [ $selected -eq 1 ]; then                # If at top
                selected=$items                         # Move pointer to bottom
            else
                selected=$(( selected -1 ))             # Else move up one
            fi
            # Print newly selected item in reverse colour (padded)
            name="$(echo $menulist | cut -d' ' -f$selected)"
            GlobalCursorRow=$((selected+3))
            DoPrintRev "$startpoint" "$longest" "$name"
        ;;
        3) # Down arrow
            # First reprint currently selected item in plain
            GlobalCursorRow=$((selected+3))   # Set to new row (menu starts at row 4)
            name="$(echo $menulist | cut -d' ' -f$selected)"
            length=$(echo "$name" | wc -c)              # Get length for padding
            spaces=$((longest-length))                  # Calculate spaces to pad it out
            padding="$(printf '%*s' "$spaces")"         # Create spaces to make length
                                                        # To hide reversed padding
            tput cup "$GlobalCursorRow" "$startpoint"   # Move cursor
            printf "%-s\\v" "$name $padding"            # Print the item in plain  
            # Next move the selected item
            if [ $selected -eq $items ]; then           # If at bottom
                selected=1                              # Move to top
            else
                selected=$((selected+1))                # Else move down one
            fi
            # Print newly selected item in reverse colour (padded)
            name="$(echo $menulist | cut -d' ' -f$selected)"
            GlobalCursorRow=$((selected+3))             # Set to new row
            DoPrintRev "$startpoint" "$longest" "$name"
        ;;
        4|2) # Right or left - button action, not a menu action
            if [ $selectedbutton -eq 1 ]; then  # Switch buttons
                selectedbutton=2
            else
                selectedbutton=1
            fi
            DoButtons "$buttontext" "$selectedbutton" $buttonRow
        ;;
        *) continue   # Do nothing
        esac
    done
} # End DoMenu

function DoLongMenu    # Advanced menuing function with extended descriptions
{   # $1 The name of the file containing the verbose menu items
    # $2 Optional button text eg: 'Ok Exit' (if empty will default to 'Ok Exit')
    # $3 Optional headline (if headline is required, $2 must be passed, even if null)
    # DoLongMenu requires the named file to exist.
    # longmenu.file must contain the verbose menu items (max length 50 characters),
    # one item to a line, no more than 20 items

    local filename winwidth message                               # Basics
    local items description longest length trimmed padding maxlen # Items
    local startpoint selected GlobalCursorRow spaces padding      # Printing
    local selectedbutton buttonrow buttontext                     # buttons
      
    # Check that the named file exists, if not, throw a wobbly
    if [ -f "$1" ]; then
        filename="$1"
    else
        DoMessage "$1 not found - unable to continue"   # Display error message
        return 0
    fi
      
    if [ "$2" == "" ]; then 
        buttontext="Ok Exit"  # Needed for drawing and highlighting buttons
    else
        buttontext="$2"
    fi

    headline="$3"
    winwidth=$(tput cols)             # Window width
    maxlen=$((winwidth -2))           # Maximum allowable item length
    items=$(cat "$filename" | wc -l)  # Count lines in file
    items=$((items+1))                # wc counts newlines, so add 1
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
          startpoint=$(( (winwidth - length) /2 ))   # Position of first character
        fi
    done
    
    DoHeading
    GlobalCursorRow=2
    DoFirstItem "$headline"
    GlobalCursorRow=3
    
    # Now run through the file again to print each item (Top one will be highlighted)
    selected=1
    for (( i=1; i <= $items; ++i ))
    do
        description="$(head -n ${i} ${filename} | tail -n 1)" # Read item from file
        if [ $i -eq 1 ]; then                     # First item - print highlighted
          DoPrintRev "$startpoint" "$longest" "$description" # Print reverse (padded)
          GlobalCursorRow=$((GlobalCursorRow + 1 ))
         else
          DoNextItem "$startpoint" "$description" # Print subsequent line
          GlobalCursorRow=$((GlobalCursorRow + 1 ))
        fi
    done
 
    GlobalCursorRow=$((GlobalCursorRow+1))
    DoFirstItem "Use cursor keys to navigate"
    buttonrow=$((GlobalCursorRow))
    selected=1
    selectedbutton=1
    DoButtons "$buttontext" "$selectedbutton" $buttonrow
    
    while true          # The cursor key action will change either the hightlighted
    do                  # menu item or one of the buttons.
        DoKeypress      # Sets numeric $GlobalInt for up/down or left/right)
        case "$GlobalInt" in
        0)  # Button 1 or button 2 pressed
            GlobalInt=$selected
            if [ $selectedbutton -eq 2 ]; then
                GlobalChar=""                 # No mresult on exit button
            else
                GlobalChar="$(head -n ${selected} ${filename} | tail -n 1)" # Read item from file
            fi
            return $selectedbutton  # Button 1 or 2
        ;;
        1) # Up arrow:
            # First reprint currently selected item in plain
            GlobalCursorRow=$((selected+2))   # Set to new row (menu starts at row 3)
            description="$(head -n ${selected} ${filename} | tail -n 1)"
            length=$(echo "$description" | wc -c)   # Get length for padding
            spaces=$((longest-length))              # Calculate spaces to pad it out
            padding="$(printf '%*s' "$spaces")"     # Create spaces to make length
                                                    # To hide reversed padding
            tput cup "$GlobalCursorRow" "$startpoint"     # Move cursor
            printf "%-s\\v" "$description $padding" # Print the item
            # Next move the selected item
            if [ $selected -eq 1 ]; then            # If at top
              selected=$items                       # Move pointer to bottom
            else
              selected=$(( selected -1 ))           # Else move up one
            fi
            # Print newly selected item in reverse colour (padded)
            description="$(head -n ${selected} ${filename} | tail -n 1)"
            GlobalCursorRow=$((selected+2))
            DoPrintRev "$startpoint" "$longest" "$description"
        ;;
        3) # Down arrow
            # First reprint currently selected item in plain
            GlobalCursorRow=$((selected+2))   # Set to new row (menu starts at row 3)
            description="$(head -n ${selected} ${filename} | tail -n 1)"
            length=$(echo "$description" | wc -c)   # Get length for padding
            spaces=$((longest-length))              # Calculate spaces to pad it out
            padding="$(printf '%*s' "$spaces")"     # Create spaces to make length
                                                    # To hide reversed padding
            tput cup "$GlobalCursorRow" "$startpoint"     # Move cursor
            printf "%-s\\v" "$description $padding" # Print the item     
            # Next move the selected item
            if [ $selected -eq $items ]; then       # If at bottom
              selected=1                            # Move to top
            else
              selected=$((selected+1))              # Else move down one
            fi
            # Print newly selected item in reverse colour (padded)
            description="$(head -n ${selected} ${filename} | tail -n 1)"
            GlobalCursorRow=$((selected+2))                # Set to new row
            DoPrintRev "$startpoint" "$longest" "$description"
        ;;
        4|2) # Right or left - button action, not a menu action
            
            if [ $selectedbutton -eq 1 ]; then  # Switch buttons
              selectedbutton=2
            else
              selectedbutton=1
            fi
            DoButtons "$buttontext" "$selectedbutton" $buttonrow
        ;;
        *) continue   # Do nothing
        esac
    done
} # End DoLongMenu

function DoFirstItem  # Aligned text according to screen size
{                     # $1 Text to print
    local winwidth maxlen textprint textlength startpoint
    winwidth=$(tput cols)                   # Recheck window width  
    maxlen=$((winwidth-2))                  # Set Limit to 2 characters < Width
    textprint="$1"                          # Text passed from caller
    textlength=$(echo $textprint | wc -c)   # Count characters 
       
    if [ $textlength -ge $maxlen ]; then
        textprint="${textprint:0:$maxlen}"  # Limit to printable length
        textlength=$maxlen
    fi
     
    startpoint=$(( (winwidth - textlength) / 2 ))   # Horizontal startpoint
    tput cup $GlobalCursorRow $startpoint           # Move cursor to startpoint
      
    printf "%-s\\v" "$textprint"                    # Print the item
    GlobalCursorRow=$((GlobalCursorRow+1))          # Advance line counter
    return $startpoint
} # End DoFirstItem

function DoNextItem   # Subsequent item in an aligned list
{                       # $1 startpoint; $2 Item text
  tput cup "$GlobalCursorRow" "$1"  # Move cursor to row and startpoint
  printf "%-s\\n" "$2"              # Print with a following newline
}

function DoPrintRev   # Prints selected item by reversing colour
{    # $1 Startpoint $2 Length of longest; $3 Item text

    local longest padding spaces itemlength
    
    longest="$2"
    itemlength=$(echo "$3" | wc -c)     # Get length
    spaces=$((longest-itemlength))      # Calculate spaces needed to pad it out
    padding="$(printf '%*s' "$spaces")" # Create spaces to make length
    tput cup "$GlobalCursorRow" "$1"    # Move cursor to startpoint
    tput rev                            # Reverse colour
    printf "%-s" "$3 $padding"          # Reprint item at this position
    tput sgr0 	                        # Reset colour
}

function DoKeypress # Reads keyboard and returns value via GlobalInt
{  
    local keypress
      
    while true  # Respond to user keypress
    do
        tput civis &                          # Hide cursor
        read -rsn1 keypress                   # Capture key press
        tput cnorm                            # Reset cursor
        case "$keypress" in
        "") # Ok/Return pressed
            GlobalInt=0
            break
            ;;
        A) # Up arrow:
            GlobalInt=1
            break
            ;;
        B) # Down arrow
            GlobalInt=3
            break
            ;;
        C) # Right arrow
            GlobalInt=4
            break
            ;;
        D) # Left arrow
            GlobalInt=2
            break
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
        columnWidth=0
        lastPage=0

        # Establish terminal size and set variables
        winWidth=$(tput cols)               # Start with full terminal width
        displayWidth=$((winWidth-4))        # Allow for two characters margin each side
        winCentre=$((winWidth/2))           # page centre used to calculate start point
        winHeight=$(tput lines)             # Full height of terminal
        topRow=4                            # Leave space for heading
        GlobalCursorRow=1                   # Start cursor at top of page
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
    #  Proceed to page-handling in DoSelectPage
    DoSelectPage $winHeight $winCentre $lastPage
} # End DoLister

function DoSelectPage   # Organises a (nominated) pageful of data for display
{                       # $1 = winHeight; $2 = winCentre; $3 = lastPage

    local pageNumber lastPage advise previous next instructions instrLen
    local winHeight winCentre

    pageNumber=1 
    winHeight=$1
    winCentre=$2
    lastPage=$3
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
            GlobalCursorRow=1                       # Reset cursor to top of page
            DoPrintPage "$winHeight" "$winCentre" "$instructions" "$pageNumber" "$lastItem"
 
            case $? in           # Return code from DoPrintPage will be 0, 1, or 2
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
            GlobalCursorRow=1                       # Reset cursor to top of page
            DoPrintPage "$winHeight" "$winCentre" "$instructions" "$pageNumber" "$lastItem"
            case $? in                       # Return will be 0, 1, or 2
            1)  pageNumber=$((pageNumber-1)) # < (left arrow) = previous page
            ;;
            2)  continue                 # > (right arrow) = illegal call to next page
            ;;
            *)  break                    # 0 : an item was selected or 'Exit' entered
            esac
        ;;
        *)  instructions="$previous - $next"
            GlobalCursorRow=1                       # Reset cursor to top of page
         
            DoPrintPage "$winHeight" "$winCentre" "$instructions" "$pageNumber" "$lastItem"
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
} # End DoSelectPage

function DoPrintPage      # Prints the page prepared and selected in DoSelectPage
{  # $1 winHeight; $2 winCentre; $3 instructions; $4 pageNumber; $5 lastItem;
   # The arrays used here are declared and initialised in DoLister as global in scope

    local pageWidth columnStart thisPage pageNumber
    local counter columnWidth instructions instrLen lastItem advisLen
    local winHeight winCentre startPoint topRow

    winHeight=$1
    winCentre=$2
    instrLen=${#3}
    instructions="$3"
    pageNumber="$4"
    lastItem="$5"
    counter=1

    DoHeading $Backtitle                          # Prepare window
    DoFirstItem "Page $pageNumber of $lastPage"

    thisPage="${GlobalPagesArray[${pageNumber}]}" # Get column numbers for this page
    pageWidth=${GlobalPageWidthsArray[${pageNumber}]}  # Get width of this page
    columnStart=$(( winCentre - (pageWidth/2)))   
    topRow=$((GlobalCursorRow+1))
    GlobalCursorRow=$topRow
 
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
                tput cup $GlobalCursorRow $columnStart   
                printf "%-s\n" "${counter}) $item"
                
                if [ "$item" == "$lastItem" ]; then
                    break
                fi
                
                GlobalCursorRow=$((GlobalCursorRow+1))
                counter=$((counter+1))
            done
            columnStart=$((columnStart+columnWidth+2))  # Start next column at top
            GlobalCursorRow=$topRow 
        done

        startPoint=$((winCentre-(instrLen/2)))
        tput cup $((winHeight-4)) $startPoint   # Position cursor near bottom of screen
        echo "${instructions}"                  # eg: "Enter '>' for next page"
        adviseLen=${#advise}
        startPoint=$((winCentre-(adviseLen/2)))
        tput cup $((winHeight-2)) $startPoint 
        echo "${advise}"                        # eg: "or ' ' to exit without choosing"
        GlobalCursorRow=$((winHeight-3))
        DoForm "Enter the number of your selection: "
        GlobalInt="$GlobalChar"
        case $GlobalChar in
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
            GlobalCursorRow=$topRow    
            continue
        ;;
        *)  counter=1  # A number has been entered. Find it in the columns of this page
            for column in ${thisPage}  # Outer loop iterates through the page variable
            do                         # Inner loop finds this item
                for item in ${GlobalColumnsArray[${column}]} 
                do
                    if [ $counter -eq $GlobalInt ]; then      
                        GlobalChar=$item                    # And sends it home
                        return 0
                    fi
                    counter=$((counter+1))
                done
            done
        esac
    done
} # End DoPrintPage

function DoMega   # Cleans up crude data from input file and prepares mega-work.file
{   # Generates a (potentially multi-page) numbered list from a file
    # Parameters:
    # $1 Name of the file containing all the items; $2 information to print above list

    local advise previous next instructions pages pageNumber width
    local winHeight items i counter line display startpoint saveCursorRow term1

    if [ ! -f "$1" ]; then
        DoMessage "The file $1 is needed but was not found."
        return 1
    fi
    
    term1="$2"
    width=$(tput cols)
    width=$((width-2))
    items=$(cat $1 | wc -l)         # Count lines in file
    items=$((items+1))              # wc counts newlines, so add 1
    winHeight=$(tput lines)
    display=$((winHeight-6))        # Items to display in one pageful
    pages=$((items/display))
    remainder=$((items%display))    # May need extra page
    if [ $pages -eq 0 ]; then
        pages=1
    elif [ $remainder -gt 0 ]; then
        pages=$((pages+1))
    fi

    rm mega-work.file 2>/dev/null  # Clear the work file (hide errors)

    # 1) Read the input file, number each item, shorten to fit page width and save to a new file
    for (( i=1; i <= items; ++i )) 
    do
        line="$(head -n ${i} ${1} | tail -n 1)"            # Read one line at a time
        line="$i:$line"                                         # Number it
        echo ${line##*( )} | cut -c 1-$width  >> mega-work.file    # Remove all leading spaces
    done                                                        # and cut it down to fit width

    if [ $items -le $display ]; then    # DoLongMenu is more convenient for a single page
        DoLongMenu "mega-work.file" "Ok Exit" "$term1"
        return $?
    fi

    pageNumber=1                # Start at first page
    GlobalCursorRow=2
    counter=1                   # For locating items in the file

    DoMegaPage $pageNumber $pages $display $items $counter "$term1"   # Prints the page
} # End DoMega

function DoMegaPage     # The actual printing bit
{                       # $1 pageNumber; $2 pages; $3 display; #4 items; $5 counter;
                        # $6 information to be printed above the list

    local advise previous next instructions pages pageNumber term1
    local winHeight items i counter line display startpoint saveCursorRow

    advise="Or ' ' to exit without choosing" 
    previous="Enter 'p' for previous page"
    next="'n' for next page"
    pageNumber=$1
    pages=$2
    display=$3
    items=$4
    counter=$5
    term1="$6"

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
        GlobalCursorRow=1
        DoFirstItem "$term1"
        GlobalCursorRow=2
        DoFirstItem "Page $pageNumber of $pages"
        GlobalCursorRow=3    
     
        # Print a pageful up to max number of lines to display
        for (( line=1; line <= $display; ++line ))
        do
            item=$(head -n $counter mega-work.file | tail -1)  # Read item from file     
            if [ $line -eq 1 ]; then                        # First item on this page
                tput cup $GlobalCursorRow 2                 # Move cursor to startpoint
                printf "%-s\\v" "$item"                     # Print the item
            else
                DoNextItem 2 "$item"
            fi       
            counter=$((counter+1)) 
            if [ $counter -gt $items ]; then                # Exit loop if last record
                GlobalCursorRow=$((GlobalCursorRow+1)) 
                break
            fi
            GlobalCursorRow=$((GlobalCursorRow+1)) 
        done

        DoFirstItem "$instructions"             
        DoFirstItem "$advise"
        DoForm "Enter the number of your selection : "

        case "$GlobalChar" in
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
            counter="$GlobalChar"   # Convert char to int and use to find the item in the file
            GlobalChar="$(head -n ${counter} mega-work.file | tail -n 1)"
            return 0
        esac
        counter=$(((pageNumber*display)+1-display))
    done
} # End DoMegaPage
# End Lists