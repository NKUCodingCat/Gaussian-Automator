COMMAND="g09 "
fullfile="$(realpath $1)"
filename="${fullfile%.*}"
Log="$filename".log

# echo "$fullfile"
# echo "$Log"


Counter=0; LIMIT=5

$COMMAND $fullfile

while [ $Counter -lt $LIMIT ]; do

	if grep -q "Normal termination of Gaussian" "$Log"; then
		echo "Perfectly Done" # Geom Check PART, Continue to run
		break

	else
		if   grep -A 3 "Optimization stopped" "$Log" | grep -q "Number of steps exceeded"; then
			echo "$fullfile		Opt MORE"      # MAKE geom=check and rerun
			# backup .com & log, GET COORDINATES, MAKE NEW .com

			mv "$fullfile" "${Log}-bck-${Counter}"
			# GET COORD 
			til="$( cat "${Log}" | grep 'Symbolic Z-matrix' -B 2 | head -n 1 | cut -c 2- )"
			coord="$( python 3.py "${Log}" | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' )" 
			# Replace markers
			cat ./Gau-template.txt | sed "s/<TITLE>/${til}/" | sed "s/<recal_Count>/${Counter}/" | sed "s/<Coords>/${coord}/" > "$fullfile" 
			mv "$Log" "${Log}-bck-${Counter}"

		elif grep -q "Bend failed for angle" "$Log" || grep -q "Tors failed for dihedral" "$Log" ; then
			echo "$fullfile		Opt again"     # Recalculate (TO AVOID Angle=180)
			mv "$Log" "${Log}-bck-${Counter}"

		else
			echo "$fullfile		NOT WELL DONE" # Failed in any other ways
			break

		fi
	fi

	$COMMAND $fullfile

	Counter=$(($Counter+1))
done
