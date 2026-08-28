#!/bin/bash

# SYNOPSIS
# Kupo - Logo functions
#
# DESCRIPTION
# Provide function to load and show the banner of the app
#
# NOTES
# Author  : Izunia
# Version : 1.0.0
# License : MIT License



# SYNOPSIS
# Shows the Banner of the application
#
# DESCRIPTION
#
# Displays the banner composed of the title and logo as ASCII Art
#
# EXAMPLE
# Show-Banner
#
# OUTPUTS
# None
#
Show-Banner() {
    local left_art
    left_art=$(cat <<'EOF'
██╗  ██╗██╗   ██╗██████╗  ██████╗ 
██║ ██╔╝██║   ██║██╔══██╗██╔═══██╗
█████╔╝ ██║   ██║██████╔╝██║   ██║
██╔═██╗ ██║   ██║██╔═══╝ ██║   ██║
██║  ██╗╚██████╔╝██║     ╚██████╔╝
╚═╝  ╚═╝ ╚═════╝ ╚═╝      ╚═════╝ 
EOF
)

    local right_art
    right_art=$(cat <<'EOF'
          ####
         ########
         ########
         ######
              =
         -=   +
        #%%:* +
       +*#*-:=#  #@+=
     -:.::.::::::+%@#:+
   =::::::::::::::-%--#
  *::.::::::::::::.::-+
  :.::::::::::::::::--=
 ::*--::::::::::::::--=
=::-##*:::::::::::::---=
*::=##+::::::::::::-----    *##
+::::::::::::::-------=#%%##**+++*
 -::::::::::::*------*%%%%#*+++*
   --::::::::-------:=#%##*%++*
    ==+*=::-----*#*%##%@*++*%
 =::::=:::::::::--+*###****  #
=:::-=-::::::::::::--+
:::-=+-::::::::::=-::--+
    :...:::::::::#:::--%
   +:::::::::::::-+::--=
   +-=:::::-:::----==---+
    =-++-#*+=-----+=-+=-
    *=*=-=------=+++**
     +--+***++++=++++*
      +-=+**    #*+++++
       *++**
EOF
)
    mapfile -t left_lines <<< "$left_art"
    mapfile -t right_lines <<< "$right_art"

    local left_width=58
    local left_count=${#left_lines[@]}
    local right_count=${#right_lines[@]}
    local height=$left_count

    (( right_count > height )) && height=$right_count

    local left_top_padding=$(( (height - left_count) / 2 ))
    local i left_index left right left_len pad

    for (( i = 0; i < height; i++ )); do
        left_index=$(( i - left_top_padding ))

        if (( left_index >= 0 && left_index < left_count )); then
            left="${left_lines[$left_index]}"
            left="${left%"${left##*[![:space:]]}"}"   # trim trailing spaces
        else
            left=""
        fi

        if (( i < right_count )); then
            right="${right_lines[$i]}"
            right="${right%"${right##*[![:space:]]}"}"
        else
            right=""
        fi

        left_len=${#left}
        pad=$(( left_width - left_len ))
        (( pad < 0 )) && pad=0

        printf '%s%*s    %s\n' "$left" "$pad" "" "$right"
    done
}

