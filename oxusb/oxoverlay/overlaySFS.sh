#!/bin/sh
#
#  By: oxdabit
#  Date: 06/08/2021
#  Mail: 0xdabit@gmail.com
#  Twitter: @0xDA_bit
#
#  Created 2021 by David Alavrez aka 0xDA_bit, Barcelona to work on Raspian as custom init script
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see
#    <http://www.gnu.org/licenses/>.
#
#  Tested with Raspbian Buster lite
#

#
# Follow installation guide in: https://github.com/OxDAbit/overlayRoot.sh
#

# SFS file mount method
if  [ $1 = "-f" ]; then
	files=$2

	while [ -z "$flag" ]
	do
	        fl=`echo $files | awk -F : '{print $1}'`
	        echo "SFS $fl loaded"

	        mkdir /lib/live/mounted/squashed/${fl}
	        echo "Folder /lib/live/mounted/squashed/$fl created"

	        mount --move /mnt/mnt/squashed/${fl} /lib/live/mounted/squashed/${fl}
	        if [ $? -ne 0 ]; then
	               echo "ERROR: could not move squashed into newroot"
	               /bin/bash
	        else
	               echo "SQUASHED folder succesfully mounted"
	        fi

	        indice=$(expr index "$files" ':')
	        if [ $indice = 0 ]; then
	                flag="OFF"
	        else
	                indice=$((indice+1))
	                files=$(echo $files | cut -c$((indice))-)
        	fi
	done
fi

# Umount method
if  [ $1 = "-u" ]; then
        files=$2

        while [ -z "$flag" ]
        do
                fl=`echo $files | awk -F : '{print $1}'`
		umount /lib/live/mounted/squashed/${fl}

                indice=$(expr index "$files" ':')
                if [ $indice = 0 ]; then
                        flag="OFF"
                else
                        indice=$((indice+1))
                        files=$(echo $files | cut -c$((indice))-)
                fi
        done
fi
