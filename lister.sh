#!/bin/bash

# Developed by Elizabeth Mills
# Revision date: 25th April 2021

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

# Functions may return the content of a selected item via the global
# variable GlobalResult, and the item's menu number via GlobalResponse.
# All other variables are local, and passed as parameters between functions.
# See lister.manual for guidance on the use of these functions

# --------------------  ------------------------
# Class/Function  Line	Purpose
# --------------------  ------------------------
# .. Shared class ..    General-purpose functions
# CallNotFound     54   General warning message
# CallHeading      61   Prepare a new window with heading
# CallForm         84   Centred prompt for user-entry
# CallMessage     102   Prints a message with Ok button
# CallButtons     130   Prints one or two buttons
# .. Menu class ..      Displaying and using menus
# CallMenu        182   Generates a simple menu of one-word items
# CallLongMenu    309   Generates a menu of multi-word items
# CallFirstItem   447   Prints a single, centred item
# CallNextItem    472   Prints successive aligned items
# CallPrintRev    478   Reverses text colour at appointed position
# CallMoveCursor  493   Respond to keypress
# .. List class ..      Display long lists and accept user input
# CallLister      536   Generates a numbered list of one-word items in columns
# CallSelectPage  661   Used by CallLister to manage page handling
# CallPrintPage   728   Used by CallLister to display selected page
# --------------------  ------------------------

# Global variables
GlobalResponse=0                # Output (menu item number)
GlobalResult=""                 # Output (menu item text)
GlobalCursorRow=0               # For alignment across functions
GlobalBacktitle="~ LISTER ~"

# class Shared
# }
function CallNotFound   # Errror reporting
{   # Optional message text
    CallHeading
    PrintOne "$1 Please try again ..."
    CallButtons "Ok" 1 9
}

function CallHeading    # Always use this function to prepare the screen
{ 
    clear
    
    local winwidth limit text textlength startpoint
    
    winwidth=$(tput cols)                     # Recheck window width  
    text="$Backtitle"                         # Use Global variable
    textlength=$(echo $text | wc -c)          # Count characters
      
    if [ $textlength -ge $winwidth ]; then    # If text too long for window
        limit=$((winwidth-2))                   # Limit to 2 characters lt winwidth
        text="${text:0:$limit}"                 # Limit length of printed text
        textlength=$(echo $text | wc -c)        # Recount
    fi
    
    startpoint=$(( (winwidth - textlength) / 2 )) # Horizontal startpoint
    tput cup 0 $startpoint                     # Move cursor to startpoint
    tput bold                                 # Display will be bold
    printf "%-s\\n" "$text"
    tput sgr0                                 # Reset colour inversion
} # End CallHeading

function CallForm    # Aligned prompt for user-entry
{   # $1 Text for prompt
    # Returns user entry through $GlobalResponse

    local winwidth length startpoint empty
  
    winwidth=$(tput cols)
    length=${#1}
      
    if [ ${length} -le ${winwidth} ]; then
        startpoint=$(( (winwidth - length) / 2 ))
    else
        startpoint=0
    fi
    tput cup $GlobalCursorRow $startpoint                     # Move cursor to startpoint
    read -p "$1" GlobalResponse
} # End CallForm

function CallMessage    # Display a message with an 'Ok' button to close
{                       # $1 = message text

    local winwidth text textlength textRow buttonRow startpoint
       
    if [ ! "$1" ]; then text="No message passed"; else text="$1"; fi
    winwidth=$(tput cols)                # Recheck window width
    textlength=${#text}                  # Get length of message
       
    if [ ${textlength} -lt ${winwidth} ]; then
        startpoint=$(( (winwidth - textlength) / 2 ))
    elif [ ${textlength} -gt ${winwidth} ]; then
        startpoint=0
    else
        startpoint=$(( (winwidth - 10) / 2 ))
    fi
  
    CallHeading                                  # Prepare screen

    textRow=$(tput lines)
    textRow=$((textRow / 3))
    tput cup $textRow $startpoint                # Move cursor to startpoint
    printf "%-s\\n" "$text"
    buttonRow=$((textRow + 2))

    
    CallButtons "Ok" 1 $buttonRow                # Print ok button

    tput civis &                                 # Hide the cursor
    read -p ""
    tput cnorm                                   # Ensure normal cursor
} # End CallMessage

function CallButtons
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
} # End CallButtons
# } End class Shared

# class Menu
# {
function CallMenu  # Simple menu
{       # $1 String of single-word menu items (or the name of a file)
        # $2 button text eg: 'Ok Exit'
        # $3 May be a message or empty
        # Sets global variable GlobalResponse with the number of the item selected
        # and GlobalResult with the text of the item selected
        # Also sets the system return value ($?) with the number of the item selected
        # Read lister.manual for full details
  
    local winwidth startpoint padding itemlen maxlen counter menulist
    local name items buttontext message buttonRow item i
   
    winwidth=$(tput cols) 
    padding=""
    maxlen=1

    if [ -f "$1" ]; then                    # If a file
        menulist=""
        items=$(cat ${1} | wc -l)           # Count lines in file
        for (( i=1; i <= $items; ++i ))     # Load file contents into menulist
        do
            item="$(head -n ${i} ${1} | tail -n 1)" # Read item from file
            menulist="$menulist $item"                      # Add to variable
        done
    elif [[ "$1" == "" ]]; then
        CallMessage "No data to work with"
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
      "") message=""
      ;;
      *) message="$2"
    esac
   
    CallHeading                             # Prepare page
  
    counter=0
    # Find length of longest item for use in reverse colour
    for i in $menulist
    do
      counter=$((counter+1))
      if [ $counter -eq 1 ]; then
        maxlen=${#i}                    # Save length
      else
        itemlen=${#i}
        if [ $itemlen -gt $maxlen ]; then
          maxlen=$itemlen
        fi
      fi
    done

    items=$counter
    startpoint=$(( (winwidth - maxlen) /2 ))  # Position of first character
    
    # Now run through the list again to print each item
    counter=1
    GlobalCursorRow=3
    for i in $menulist
    do
      name="$i"                       # Read item from list
      if [ $counter -eq 1 ]; then     # First item - print highlighted
        CallPrintRev "$startpoint" "$longest" "$name" # Print reverse (padded)
        GlobalCursorRow=$((GlobalCursorRow + 1 ))
       else
        CallNextItem "$startpoint" "$name" # Print subsequent line
        GlobalCursorRow=$((GlobalCursorRow + 1 ))
      fi
      counter=$((counter+1))
    done
    
    GlobalCursorRow=$((GlobalCursorRow+1))
    buttonRow=$GlobalCursorRow
    selected=1
    selectedbutton=1
    CallButtons "$buttontext" "$selectedbutton" $buttonRow

    while :   # The cursor key action will change either the hightlighted menu item
    do        # or one of the buttons.
      CallMoveCursor   # Sets numeric $GlobalResponse for up/down or left/right)
      case "$GlobalResponse" in
        0)  # Ok/Return pressed
            GlobalResponse=$selected  # Exit with the menu 1tem number selected
            GlobalResult="$name"
            return $selected
            ;;
        1) # Up arrow:
            # First reprint currently selected item in plain
            GlobalCursorRow=$((selected+2))   # Set to new row (menu starts at row 3)
      
            # Use string cutting facilities   
            name="$(echo $menulist | cut -d' ' -f$selected)"
            length=$(echo "$name" | wc -c)          # Get length for padding
            spaces=$((longest-length))              # Calculate spaces to pad it out
            padding="$(printf '%*s' "$spaces")"     # Create spaces to make length
                                                      # To hide reversed padding
            tput cup "$GlobalCursorRow" "$startpoint"     # Move cursor
            printf "%-s\\v" "$name $padding" # Print the item
            # Next move the selected item
            if [ $selected -eq 1 ]; then            # If at top
                selected=$items                       # Move pointer to bottom
            else
                selected=$(( selected -1 ))           # Else move up one
            fi
            # Print newly selected item in reverse colour (padded)
            name="$(echo $menulist | cut -d' ' -f$selected)"
            GlobalCursorRow=$((selected+2))
            CallPrintRev "$startpoint" "$longest" "$name"
            ;;
        3) # Down arrow
            # First reprint currently selected item in plain
            GlobalCursorRow=$((selected+2))   # Set to new row (menu starts at row 3)
            name="$(echo $menulist | cut -d' ' -f$selected)"
            length=$(echo "$name" | wc -c)   # Get length for padding
            spaces=$((longest-length))              # Calculate spaces to pad it out
            padding="$(printf '%*s' "$spaces")"     # Create spaces to make length
                                                      # To hide reversed padding
            tput cup "$GlobalCursorRow" "$startpoint"     # Move cursor
            printf "%-s\\v" "$name $padding" # Print the item     
            # Next move the selected item
            if [ $selected -eq $items ]; then       # If at bottom
                selected=1                            # Move to top
            else
                selected=$((selected+1))              # Else move down one
            fi
            # Print newly selected item in reverse colour (padded)
            name="$(echo $menulist | cut -d' ' -f$selected)"
            GlobalCursorRow=$((selected+2))                # Set to new row
            CallPrintRev "$startpoint" "$longest" "$name"
            ;;
        4|2) # Right or left - button action, not a menu action
            if [ $selectedbutton -eq 1 ]; then  # Switch buttons
                selectedbutton=2
            else
                selectedbutton=1
            fi
            CallButtons "$buttontext" "$selectedbutton" $buttonRow
            ;;
        *) continue   # Do nothing
      esac
    done
} # End CallMenu

function CallLongMenu    # Advanced menuing function with extended descriptions
{   # $1 The name of the file containing the verbose menu items
    # $2 Optional button text eg: 'Ok Exit' (if empty will default to 'Ok Exit')
    # $3 Optional message (if message is required, $2 must be passed, even if null)
    # CallLongMenu requires the named file to exist.
    # longmenu.file shall contain the verbose menu items (max length 50 characters),
    # one item to a line 

    local filename winwidth message                               # Basics
    local items description longest length trimmed padding maxlen # Items
    local startpoint selected GlobalCursorRow spaces padding      # Printing
    local selectedbutton buttonrow buttontext                     # buttons
      
    # Check that the named file exists, if not, throw a wobbly
    if [ -f "$1" ]; then filename="$1"
    else CallMessage "$1 not found - unable to continue"   # Display error message
        return 0
    fi
      
    if [ "$2" == "" ]; then   # Needed for drawing and highlighting buttons
        buttontext="Ok Exit"
    else
        buttontext="$2"
    fi

    message="$3"
    winwidth=$(tput cols)             # Window width
    maxlen=$((winwidth -2))           # Maximum allowable item length
    items=$(cat "$filename" | wc -l)  # Count lines in file
    items=$((items + 1))              # Because 'wc -l' starts at 0
    longest=0
    
    # Find length of longest item in file for use in reverse colour
    for (( i=1; i <= items; ++i ))
    do
        # Get line $i from text file
        description="$(head -n ${i} ${filename} | tail -n 1)" # Read item from file
        length=$(echo "$description" | wc -c)                 # Length in characters
    
        # Make sure it's not longer than window width
        if [ $length -gt $maxlen ]; then
          trimmed="${description:0:$maxlen}"      # Trim the text
          description="$trimmed"                  # Save the shorter text
          length=$(echo "$description" | wc -c)   # Reset length
        fi
        # Compare with current longest. If longer, save as longest
        if [ $length -gt $longest ]; then
          longest=$length
          startpoint=$(( (winwidth - length) /2 ))   # Position of first character
        fi
    done
    
    # Now run through the file again to print each item (Top one will be highlighted)
    CallHeading
    GlobalCursorRow=3
    selected=1
    for (( i=1; i <= $items; ++i ))
    do
        description="$(head -n ${i} ${filename} | tail -n 1)" # Read item from file
        if [ $i -eq 1 ]; then                     # First item - print highlighted
          CallPrintRev "$startpoint" "$longest" "$description" # Print reverse (padded)
          GlobalCursorRow=$((GlobalCursorRow + 1 ))
         else
          CallNextItem "$startpoint" "$description" # Print subsequent line
          GlobalCursorRow=$((GlobalCursorRow + 1 ))
        fi
    done
    
    buttonrow=$((GlobalCursorRow+1))
    selected=1
    selectedbutton=1
    CallButtons "$buttontext" "$selectedbutton" $buttonrow
    
    while :   # The cursor key action will change either the hightlighted menu item
    do        # or one of the buttons.
        CallMoveCursor   # Sets numeric $GlobalResponse for up/down or left/right)
        case "$GlobalResponse" in
        0)  # Ok/Return pressed
            GlobalResponse=$selected
            GlobalResult=="$(head -n ${selected} ${filename} | tail -n 1)" # Read item from file
            return $selected  # Exit with the menu 1tem number selected
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
            CallPrintRev "$startpoint" "$longest" "$description"
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
            CallPrintRev "$startpoint" "$longest" "$description"
            ;;
        4|2) # Right or left - button action, not a menu action
            
            if [ $selectedbutton -eq 1 ]; then  # Switch buttons
              selectedbutton=2
            else
              selectedbutton=1
            fi
            CallButtons "$buttontext" "$selectedbutton" $buttonrow
            ;;
        *) continue   # Do nothing
        esac
    done
} # End CallLongMenu

function CallFirstItem  # Aligned text according to screen size
{                       # $1 Text to print

    local winwidth maxlen textprint textlength startpoint

    # GlobalCursorRow=1   # First item on first row (logical, aye?)
      
    winwidth=$(tput cols)                   # Recheck window width  
    maxlen=$((winwidth-2))                  # Set Limit to 2 characters < Width
    textprint="$1"                          # Text passed from caller
    textlength=$(echo $textprint | wc -c)   # Count characters 
       
    if [ $textlength -ge $maxlen ]; then
        textprint="${textprint:0:$maxlen}"  # Limit to printable length
        textlength=$maxlen
    fi
    startpoint=$(( (winwidth - textlength) /2 ))
      
    startpoint=$(( (winwidth - textlength) / 2 ))   # Horizontal startpoint
    tput cup $GlobalCursorRow $startpoint           # Move cursor to startpoint
      
    printf "%-s\\v" "$textprint"                    # Print the item
    GlobalCursorRow=$((GlobalCursorRow+1))          # Advance line counter
} # End CallFirstItem

function CallNextItem   # Subsequent item in an aligned list
{                       # $1 startpoint; $2 Item text
  tput cup "$GlobalCursorRow" "$1"  # Move cursor to row and startpoint
  printf "%-s\\n" "$2"              # Print with a following newline
}

function CallPrintRev   # Prints selected item by reversing colour
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

function CallMoveCursor # Reads keyboard and returns value via GlobalResponse
{  
    local keypress
      
    while :
    do
        tput civis &                          # Hide cursor
        read -rsn1 keypress                   # Capture key press
        case "$keypress" in
          "") # Ok/Return pressed
            tput cnorm
            GlobalResponse=0
            break
            ;;
        A) # Up arrow:
            tput cnorm
            GlobalResponse=1
            break
            ;;
        B) # Down arrow
            tput cnorm
            GlobalResponse=3
            break
            ;;
        C) # Right arrow
            tput cnorm
            GlobalResponse=4
            break
            ;;
        D) # Left arrow
            tput cnorm
            GlobalResponse=2
            break
            ;;
        *)  keypress=""
        esac
    done
} # End CallMoveCursor
# } End class Menu

# class List
# {
function CallLister  # Generates a (potentially multi-page) list from a file.
{   # Parameter: $1 is the name of the file containing all the items to be listed
    # The calling function must creates the file* before calling CallLister
    #       * The file must have one word per item, one item per line

        local totalItems lastItem itemLen testLen
        local winWidth displayWidth winCentre winHeight 
        local topRow bottomRow itemsInColumn counter
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
        pageWidth=4             # Start width accumulator with margins
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
            CallMessage "$1 not found - unable to continue"   # Display error message
            return 0
        fi
        
        grep -v '^$' ${1} > temp.file       # Make a clean working copy of the file

        totalItems=$(cat temp.file | wc -l)
        lastItem="$(tail -n 1 temp.file)"

        tput cnorm   # Ensure cursor is visible

        CallHeading  # Prepare the window

        # Fill the global array of columns. Each element in the array holds one column
        widthOfColumns=2
        counter=0         
        recordNumber=0
        # Start outer loop for entire file
        while [ $recordNumber -le $totalItems  ]
        do
            testLen=0  
            Column=""  
            # Inner loop:
            # Get length of each item in each column (save length of longest in each column)
            # Then add just enough to each array element to fit the window height
            for (( line=1; line <= $itemsInColumn; ++line ))
            do  
                recordNumber=$((recordNumber+1))  # Starts at 0, so add one for real number 
                item=$(head -n $recordNumber temp.file | tail -1)   # Read item from file     
                itemLen=${#item}                                    # Measure length                 
                itemLen=$((itemLen+3))                              # Add column spacing           
                if [ $itemLen -gt $testLen ]; then
                    testLen=$itemLen            # If longest in this column, save length         
                fi
           
                if [ $recordNumber -gt $totalItems ]; then      # Exit loop if last record          
                    break
                else
                    Column="$Column $item"              # Add this item to string variable
                fi
            done # ....  End of inner (column) loop 
       
            numberOfColumns=$((numberOfColumns+1))      # Increment columns counter
            # Add this column to the columns array, and its width to the widths array
            GlobalColumnsArray[${numberOfColumns}]="${Column}"
            GlobalColumnWidthsArray[${numberOfColumns}]=$testLen 
            Column=""   # Empty the string variable for the next column   

        done        # End of outer (file) loop

    rm temp.file    # Tidy up

    # Now build GlobalPagesArray with just enough columns to fit page width each time
    while :  # These elements are numeric (column numbers). The records are still
    do       # in GlobalColumnsArray. Iterate through each element of GlobalColumnsArray
        for (( column=1; column <= $numberOfColumns; ++column ))
        do
            if [ $((pageWidth+columnWidth+4)) -ge $displayWidth ]; then
                # If adding another column would exceed page width, save this page's width
                GlobalPageWidthsArray[${pageNumber}]=$pageWidth
                pageWidth=4    # and reset the variable for the next page
                # Copy the list of columns to the pages array
                # Note: This will not be triggered on the first iteration
                GlobalPagesArray[${pageNumber}]="${page}"
                # Then set next page, advance page counter
                pageNumber=$((pageNumber+1)) 
                page=""     # And empty the string variable for next list of columns
            fi

            columnWidth=0
            for item in ${GlobalColumnsArray[${column}]}
            do                                         # Test the length of each string
                itemLen=${#item}
                if [ $itemLen -gt $columnWidth ]; then
                    columnWidth=$((itemLen+3))         # Reset, including spaces between columns
                fi
            done
          
            # Check total width of columns does not exceed page width.
            if [ $((pageWidth+columnWidth+4)) -lt $winWidth ]; then # If page is not full ...
                pageWidth=$((pageWidth+columnWidth+4)) # Add column width to page width accumulator
                page="$page $column"                   # and append the column number to this page
            fi
            if [ $column -eq $numberOfColumns ]; then  # Last column reached
                lastPage=$pageNumber                   # Save
                GlobalPageWidthsArray[${pageNumber}]=$pageWidth # Add to arrays
                GlobalPagesArray[${pageNumber}]="${page}" 
                break 2
            fi
        done
    done
    #  Proceed to page-handling in CallSelectPage
    CallSelectPage $winHeight $winCentre $lastPage
} # End CallLister

function CallSelectPage    # Organises a (nominated) pageful of data for display
{       # $1 = winHeight; $2 = winCentre; $3 = lastPage

    local pageNumber lastPage advise previous next instructions instrLen
    local winHeight winCentre

    pageNumber=1   # Start at first page
    winHeight=$1
    winCentre=$2
    lastPage=$3
    advise="or ' ' to exit without choosing" 
    previous="Enter '<' for previous page"
    next="Enter '>' for next page"

    # Display appropriate page according to user input
    while :
    do
        case $pageNumber in
        1)  if [ $lastPage -gt 1 ]; then   # On page 1, with more than 1 page in total
                instructions="$next"
            else
                instructions=""
            fi
            GlobalCursorRow=1                       # Reset cursor to top of page
            CallPrintPage "$winHeight" "$winCentre" "$instructions" "$pageNumber" "$lastItem"
 
            case $? in           # Return code from CallPrintPage will be 0, 1, or 2
            1)  continue         # < (left arrow) = illegal call to previous page
            ;;
            2)  if [ $lastPage -gt 1 ]; then  # On page 1, with more than 1 page in total
                    pageNumber=$((pageNumber+1)) # > (right arrow) = next page
                    continue
                fi
            ;;
            *)  break                        # 0 : an item was selected or 'Exit' entered
            esac
        ;; 
        $lastPage) instructions="$previous"
            GlobalCursorRow=1                       # Reset cursor to top of page
            CallPrintPage "$winHeight" "$winCentre" "$instructions" "$pageNumber" "$lastItem"
            case $? in                       # Return will be 0, 1, or 2
            1)  pageNumber=$((pageNumber-1)) # < (left arrow) = previous page
            ;;
            2)  continue                     # > (right arrow) = illegal call to next page
            ;;
            *)  break                        # 0 : an item was selected or 'Exit' entered
            esac
        ;;
        *)  instructions="$previous - $next"
            GlobalCursorRow=1                       # Reset cursor to top of page
         
            CallPrintPage "$winHeight" "$winCentre" "$instructions" "$pageNumber" "$lastItem"
            case $? in                              # Return will be 0, 1, or 2
            1)  if [ $pageNumber -gt 1 ]; then      # Not on page 1
                    pageNumber=$((pageNumber-1))    # < (left arrow) = previous page
                fi
            ;;
            2)  if [ $pageNumber -lt $lastPage ]; then   # Not on last page
                    pageNumber=$((pageNumber+1))        # > (right arrow) = next page
                fi
            ;;
            *)  break                            # 0 : an item was selected or '' entered
            esac
        esac
    done
} # End CallSelectPage

function CallPrintPage      # Prints the page prepared and selected in CallSelectPage
{  # $1 winHeight; $2 winCentre; $3 instructions; $4 pageNumber; $5 lastItem;
   # The arrays used here are declared and initialised in CallLister as global in scope
   
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

    CallHeading $Backtitle    # Prepare window
    
    CallFirstItem "Page $pageNumber of $lastPage"

    thisPage="${GlobalPagesArray[${pageNumber}]}"      # String of column numbers for this page
    pageWidth=${GlobalPageWidthsArray[${pageNumber}]}  # Full width of this page
    columnStart=$(( winCentre - (pageWidth/2)))   
    topRow=$((GlobalCursorRow+1))
    GlobalCursorRow=$topRow
 
    while :
    do
        # counter=1
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
                
                if [ $item = $lastItem ]; then
                    break
                fi
                
                GlobalCursorRow=$((GlobalCursorRow+1))
                counter=$((counter+1))
            done
            columnStart=$((columnStart+columnWidth+2))  # Start next column at top
            GlobalCursorRow=$topRow 
        done

        saveStartPoint=SstartPoint
        startPoint=$((winCentre-(instrLen/2)))
        tput cup $((winHeight-4)) $startPoint   # Position cursor near bottom of screen
        echo "${instructions}"                  # eg: "Enter '>' for next page"
        adviseLen=${#advise}
        startPoint=$((winCentre-(adviseLen/2)))
        tput cup $((winHeight-2)) $startPoint 
        echo "${advise}"                        # eg: "or ' ' to exit without choosing"
        GlobalCursorRow=$((winHeight-3))
        CallForm "Enter the number of your selection: "
        startPoint=$saveStartPoint
       
        case $GlobalResponse in
        '') GlobalResult=""
            return 0                                    # Quit without selecting anything
        ;;
        "<") return 1                                   # Previous page, if valid
        ;;
        ">") return 2                                   # Next page, if valid
        ;;
        *[!0-9]*)   # CallHeading
            # CallFirstItem "Page $pageNumber of $lastPage"
            thisPage="${GlobalPagesArray[${pageNumber}]}"      # String of column numbers for this page
            pageWidth=${GlobalPageWidthsArray[${pageNumber}]}  # Full width of this page of columns
            columnStart=$(( winCentre - (pageWidth/2) -3 ))    # Centre it
            GlobalCursorRow=$topRow    
            continue
        ;;
        *)  counter=1    # A number has been entered. Find it in the columns of this page
            for column in ${thisPage}     # Outer loop iterates through the page variable
            do
                for item in ${GlobalColumnsArray[${column}]}  # Inner loop finds this item
                do
                    if [ $counter -eq $GlobalResponse ]; then      
                        GlobalResult=$item                 
                        return 0
                    fi
                    counter=$((counter+1))
                done
            done
        esac
    done
} # End CallPrintPage
# } End List class
