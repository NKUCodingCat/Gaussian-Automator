COMMAND="g09 "
fullfile="$(realpath $1)"
filename="${fullfile%.*}"
Log="$filename".log

Counter=0; LIMIT=5
PY_SCR='import cclib, argparse, sys; Q =  {1:"H", 2:"He", 3:"Li", 4:"Be", 5:"B", 6:"C", 7:"N", 8:"O", 9:"F", 
       10:"Ne", 11:"Na", 12:"Mg", 13:"Al", 14:"Si", 15:"P", 16:"S", 17:"Cl", 18:"Ar", 19:"K", 20:"Ca", 
       21:"Sc", 22:"Ti", 23:"V", 24:"Cr", 25:"Mn", 26:"Fe", 27:"Co", 28:"Ni", 29:"Cu", 30:"Zn", 31:"Ga",
       32:"Ge", 33:"As", 34:"Se", 35:"Br", 36:"Kr", 37:"Rb", 38:"Sr", 39:"Y", 40:"Zr", 41:"Nb", 42:"Mo", 
       43:"Tc", 44:"Ru", 45:"Rh", 46:"Pd", 47:"Ag", 48:"Cd", 49:"In", 50:"Sn", 51:"Sb", 52:"Te", 53:"I", 
       54:"Xe", 55:"Cs", 56:"Ba", 57:"La", 58:"Ce", 59:"Pr", 60:"Nd", 61:"Pm", 62:"Sm", 63:"Eu", 64:"Gd", 
       65:"Tb", 66:"Dy", 67:"Ho", 68:"Er", 69:"Tm", 70:"Yb", 71:"Lu", 72:"Hf", 73:"Ta", 74:"W", 75:"Re", 
       76:"Os", 77:"Ir", 78:"Pt", 79:"Au", 80:"Hg", 81:"Tl", 82:"Pb", 83:"Bi", 84:"Po", 85:"At", 86:"Rn", 
       87:"Fe", 88:"Ra", 89:"Ac", 90:"Th", 91:"Pa", 92:"U", 93:"Np", 94:"Pu", 95:"Am", 96:"Cm", 97:"Bk", 
       98:"Cf", 99:"Es", 100:"Fm", 101:"Md", 102:"No", 103:"Lr", 104:"Rf", 105:"Db", 106:"Sg", 107:"Bh", 
       108:"Hs", 109:"Mt", 110:"Ds", 111:"Rg", 112:"Cn", 113:"Uut", 114:"Fl", 115:"Uup", 116:"Lv", 117:"Uus",
       118:"Uuo"}; parser = argparse.ArgumentParser(description="Process log file");
       parser.add_argument("Gau_log", nargs=1); args = parser.parse_args(); parser = cclib.io.ccopen(args.Gau_log[0], logstream=sys.stderr); data = parser.parse(); 
       print "\n".join(map(lambda x: "%-3s  %.6f  %.6f  %.6f"%tuple([x[0], ]+x[1]), zip(map(lambda x: Q[x], data.atomnos.tolist()), data.atomcoords[-1].tolist())))'
PY_file=$(mktemp /tmp/py_XXXX.py); echo $PY_SCR > "$PY_file";

$COMMAND $fullfile

while [ $Counter -lt $LIMIT ]; do

	if grep -q "Normal termination of Gaussian" "$Log"; then
		echo "$fullfile		Perfectly Done" # Geom Check PART, Continue to run
		break

	else
		if  grep -A 3 "Optimization stopped" "$Log" | grep -q "Number of steps exceeded"; then
			echo "$fullfile		Opt MORE"     
			# backup .com & log, GET COORDINATES, MAKE NEW .com

			mv "$fullfile" "${Log}-bck-${Counter}"
			# GET COORD 
			til="$( cat "${Log}" | grep 'Symbolic Z-matrix' -B 2 | head -n 1 | cut -c 2- | sed 's/ - recalc \([[:digit:]]\+\)$/<\1>/g' )"
			coord="$( python "$PY_file" "${Log}" | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' )" 
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

rm -f "$PY_file"
