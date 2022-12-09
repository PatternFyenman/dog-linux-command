#====== Function Definition ======

# $1: startw, $2:endw, $3:filedst, $4==1: extract content to tmp.file
extract(){
	if [ ${#2} == 0 ]
	then
		tmp=`sed -n "/$1/,/G/p" $3 | grep -Ev "($1)"`;
	else
		tmp=`sed -n "/$1/, /$2/p" $3 | grep -Ev "($1|$2)"`;
	fi
	t=1
	if [[ $4 == $t ]] 
	then
		sed -n "/$1/, /$2/p" $3 | grep -Ev "($1|$2)" > tmp.file
	fi
}

# $1: the line found, $2 is replaced with $3, $4: filename 
replace_line(){
	sed -i "/$1/s/$2/$3/g" $4
}

# search the first line containing $1, and the last line containing $2,
# replace the content $3 between these two lines with $4 in file $5.
replace_para(){
	sed -i "/$1/,/$2/ s/$3/$4/g" $5
}

# In the whole file $3, replace text $1 with $2
replace_file(){
	sed -i "s/$1/$2/g" $3;
}

# find the first line in file $3 containing $1 and the last line containing $2, 
# delete the  content between these two lines, excluding these two lines.
delete_para(){
	sed -i "/$1/,/$2/{/$1/!{/$2/!d}}" $3
}

# delete all the lines that contain the content $1 in file $2
delete_line(){
	sed -i "/$1/d" $2
}

# find the line containing $1 in file $3, apppend the text $2 in this line.
append_inline(){
	sed -i "/$1/s/$/$2/" $3
}

# find the line containing $1 in file $3, append content $2 below this line.
append_belowline(){
	sed -i "/$1/a $2" $3
}

# find the line containing $1 in file $3 ,append content $2 ahead of this line.
append_aheadofline(){
	sed -i "/$1/i $2" $3
}


# insert content $1 to the begining of the odd lines in file $2
insert_oddbegin(){
	sed -i "1~2s/^/$1/" $2 
}

# insert content $1 to the end of the odd lines in file $2
insert_oddend(){
	sed -i "1~2s/$/$1/" $2 
}

# insert content $1 ahead of the odd lines in flie $2
insert_oddahead(){
	sed -i "1~2i $1" $2
}

# find the line containing $1 in file $3,
# append the content in file $2 below this line.
appendfile_belowline(){
	sed -i "/$1/r $2" $3
}

# remove all the empty lines in file $1
remove_emptyline(){
	sed -i '/^[[:space:]]*$/d' $1
}


# replace / in a $variable with  \/
replace_slash(){
	tmp=${1//\//\\/}
}

# ===== Basic Parameters =====
projectname=${PWD##*/}
projectdir=`pwd`
filetype=".py"
# project statement location
pstate=""$projectdir"/project_statement.txt"
mddir="${projectdir}/docs/${projectname}.md"
texdir="${projectdir}/docs/${projectname}_PPT.tex"
templatemd=~/Documents/docstest/templates/template.md
templatetex=~/Documents/docstest/templates/template.tex

# ===== Generate markdown and latex files from the templates =====

if test -f $mddir 
then
	rm -f "$mdddir"
	cp $templatemd $mddir
	echo "Generate Markdown File: ${mddir}"
else
	echo "Generate Markdown File: ${mddir}"
	cp $templatemd $mddir
fi

if test -f $texdir 
then
	rm -f "$texdir"
	cp $templatetex $texdir
	echo "Generate Latex File: ${texdir}"
else
	echo "Generate Latex File: ${texdir}"
	cp $templatetex $texdir
fi

# ---- write metadata to the markdown file ----
# -- write title --
extract "TITLE" "AUTHOR" $pstate
title=$tmp
replace_line "# TITLE" "TITLE" "$title" $mddir

# -- write project name --
replace_line "PROJECTNAME" "$projectname" "" $mddir
replace_line "PROJECTNAME" "$" "$projectname" $mddir

# -- write author name --
extract "AUTHOR" "DATE" "$pstate"
author=$tmp
replace_para "AUTHOR" "DATE" "$author" "" $mddir
replace_line "AUTHOR" "$" "$author" $mddir

# -- write date name --
extract "DATE" "INTRODUCTION" "$pstate"
date=$tmp
replace_para "DATE" "INTRODUCTION" "$date" "" $mddir
append_inline "DATE" "$date" $mddir

# -- write introduction --
extract "INTRODUCTION" "Reference" $pstate
introduction=$tmp
delete_para "# ${title}" "Reference" $mddir
append_belowline "# ${title}" "$introduction\\n" $mddir

# ---- write metadata to the latex file ----
# -- write title --
extract "TITLE" "AUTHOR" $pstate
title=$tmp
replace_line "\\\title{@@}" "@@" "$title" $texdir

# -- write author name --
extract "AUTHOR" "DATE" $pstate
author=$tmp
replace_line "\\\author{@@}" "@@" "$author" $texdir 

# -- write institute name --
# !!! assuming it's UCAS, need further improving !!!
replace_line "\\\institute{@@}" "@@" "UCAS" $texdir

# -- write date --
extract "DATE" "INTRODUCTION" $pstate
date=$tmp
replace_line "\\\date{@@" "@@" "$date" $texdir


# -- write introduction --
extract "INTRODUCTION" "G" $pstate
introduction=$tmp
frametitle="\\\\frametitle{Introduction}\\n"
introMerge="\\\\\begin{frame}\\n${frametitle}${introduction}\\n\\\end{frame}\\n"
append_belowline "\\\section{Introduction}" "$introMerge" $texdir
echo "Meta data have been writen to ${projectname} documents."


# ---- write experiment reports to the markdown file ----
for expdir in `ls -d Experiment*`
do
	# only the first code file is needed to read TITLE, AUTHOR, INTRODUCTION
	readfile=`ls -A ./${expdir}/*${filetype} | head -n1`
	# -- write title --
	extract "\[TITLE\]" "\[AUTHOR\]" ${readfile}
	title=$tmp
	h2="## ${expdir}: ${title}"
	replace_file "$h2" "" ${mddir}
	append_aheadofline "# Reference" "$h2" ${mddir}


	# -- write background and purpose --
	extract "\[BACKGROUND\]" "\[PURPOSE\]" ${readfile}	
	background=$tmp

	extract "\[PURPOSE\]" "\[RESULT\]" ${readfile}
	purpose=$tmp

	h3="### why did we do this experiment?"
	content="$h3 \\n${background} ${purpose}\\n"
	append_belowline "$h2" "$content" ${mddir}

	h33="### Experiment results\\n@@${expdir}"
	append_aheadofline "Reference" "$h33\\n" ${mddir}

	## -- write results --
	codedirs=`ls -A ./${expdir}/*${filetype}`
	for readfile in $codedirs
	do
		extract "\[RESULT\]" "'''" ${readfile} 1
		
		remove_emptyline "tmp.file"

		# -- convert picture dir to picture markdown format --
		imgdir="!\[img\]("$projectdir"/"$expdir"/"
		replace_slash ${imgdir}
		imgn=$tmp
		insert_oddbegin "$imgn" "tmp.file"
		insert_oddend ")" "tmp.file"
		insert_oddahead "\\\n" "tmp.file"
		appendfile_belowline "@@${expdir}" "tmp.file" ${mddir}
		delete_line "@@${expdir}" ${mddir}
	done
done

# ---- write experiment reports to the latex file ----
# table of contents

for expdir in `ls -d Experiment*`
do
	readfile=`ls -A ./${expdir}/*${filetype} | head -n1`
	# -- write title --
	extract "\[TITLE\]" "\[AUTHOR\]" ${readfile}
	title=$tmp

	exptitle="\\\\\section{${expdir}: ${title}}"
	frametitle="\\\\\\frametitle{${expdir}: ${title}}\\n"
	
	replace_file "$exptitle" "" ${texdir}
	append_aheadofline "end{document}" "$exptitle" ${texdir}

	# -- write background and purpose --
	extract "\[BACKGROUND\]" "\[PURPOSE\]" ${readfile}
	background=$tmp
	extract "\[PURPOSE\]" "\[RESULT\]" ${readfile}
	purpose=$tmp
	h3="\\\\\begin{frame}\\n\\\\frametitle{why did we do this experiment?}\\n"
	content="$h3 \\n${background} ${purpose}\\n\\\\\end{frame}\\n@@${expdir}"
	append_belowline "$expdir" "$content" ${texdir}

	codedirs=`ls -A ./${expdir}/*${filetype}`
	## -- write results --
	for readfile in $codedirs
	do

		bf="\\\\\begin{frame}"
		bi="\\\\\begin{figure}"
		inclus="\\\\\includegraphics[width=0.75\\\textwidth]{"$projectdir"/"$expdir"/"
		inclun=${inclus//\//\\/}
		inclue="}"
		ei="\\\\\end{figure}"
		ef="\\\\\end{frame}"
		pf="${bf}${bi}${inclus}"
		pb="${inclue}${ei}"
		sf="\t"

		extract "\[RESULT\]" "'''" ${readfile} 1
		remove_emptyline "tmp.file"
		counter=0
		while read line
		do
			# find out odd or even line number 
			isEvenNo=$( expr $counter % 2 )

			if [ $isEvenNo -ne 0 ];then
				# even match
				replace_line "$line" "^" "$sf" "tmp.file"
			else
				nl=$( expr $counter + 1 )
				sed -i ""$nl"s/^/${inclun}/" "tmp.file"
				sed -i ""$nl"s/$/${inclue}/" "tmp.file"
			fi
		(( counter ++ ))
		done < "tmp.file"
		append_aheadofline "includegraphics" "${ef}\n${bf}\n${bi}\n" "tmp.file"
		append_belowline "includegraphics" "$ei" "tmp.file"
		remove_emptyline "tmp.file"
		sed -i '1d' "tmp.file" "tmp.file" #???? delete a "tmp.file2"

		sed -i '1i \\\\begin{frame}' "tmp.file" 
		sed -i '$a \\\\end{frame}' "tmp.file"

		append_belowline "begin{frame}" "$frametitle" "tmp.file"
		append_aheadofline "begin{frame}" "\\\\" "tmp.file"
		append_belowline "end{frame}" "\\\\" "tmp.file"
		
		appendfile_belowline "@@$expdir" "tmp.file" ${texdir}
		delete_line "@@$expdir" ${texdir}
	done
done
rm -f tmp*
echo "Experiment data have been writen to ${projectname} documents."

echo "=== generate pdf & ppt files ==="
pdfdir="${projectdir}/docs/${projectname}.pdf"
pandoc ${mddir} -o $pdfdir
echo "pdf location: "$pdfdir""

pptdir="${projectdir}/docs/${projectname}_PPT.pdf"
cd docs
if test -f tex
then
	rm -rf tex
	mkdir tex
else
	mkdir tex
fi	
cp ./${projectname}_PPT.tex ./tex/${projectname}_PPT.tex
cd tex
pdflatex ./${projectname}_PPT.tex > /dev/null
pdflatex ./${projectname}_PPT.tex > /dev/null
cp ${projectname}_PPT.pdf ../${projectname}_PPT.pdf
cd ..
rm -rf tex
cd ..
echo "ppt location: "$pptdir""

