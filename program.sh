#!/bin/bash
read -p "please enter the file name: " filename

red='\e[1;31m'
underline_red='\e[4;31m'
reset='\e[0m'
green='\e[32m'
if [ ! -e "$filename" ]; then 
	echo -ne "$red""\nERROR!,""$underline_red""FILE NOT FOUND\n""$reset"
fi 



# function to print the menu 
printMenu() {  

echo -ne '\e[32m' '\n		1. Show or print student records (all semesters).
		2. Show or print student records for a specific semester.
		3. Show or print the overall average.
		4. Show or print the average for every semester.
		5. Show or print the total number of passed hours.
		6. Show or print the percentage of total passed hours in relation to total F and FA
		hours.
		7. Show or print the total number of hours taken for every semester.
		8. Show or print the total number of courses taken.
		9. Show or print the total number of labs taken.
		10. Insert the new semester record.
		11. Change in course grade.
		0. Exit the program\n\n'"$reset"

}

# function to print one semester grades
printSem() {


	local line=$1

	local year=$(cut -d';' -f1 <<< "$line" | cut -d'/' -f1)
	local sem=$(cut -d';' -f1 <<< "$line" | cut -d'/' -f2)

	printf "\n%-20s%-20s\n" "YEAR" "SEM"
	printf "%-20s%-20d\n" "$year" "$sem"
	echo -ne "----------------------------------------------------\n"


	printf "%-20s%-20s\n" "COURSE" "GRADE"
	local marks="$(cut -d';' -f2 <<< "$line" | sed 's/FA/50/g' | sed 's/F/55/g')"
	noOfMarks=$(tr ',' '\12' <<< "$line" | wc -l)
	for ((i = 1; i <=noOfMarks; i++)); do 
		local course=$(cut -d',' -f$i <<< "$marks" | cut -d' ' -f2)
		local grade=$(cut -d',' -f$i <<< "$marks" | cut -d' ' -f3)
		printf "%-20s%-20d\n" "$course" "$grade"
	done

	echo -ne "\n***************************************************\n"
}

# function to call printSemester on all semester 
printAllSems() {

	while read -r line; do 
	
		printSem "$line"
		
	done<"$filename"
}




# function to print a speceific semester grades 
printSpecificSems() {

	read -p "please enter semester number: " semester

	while read -r line; do 

		
		sem1=$(cut -d';' -f1 <<< "$line")
		
		if [[ $sem1 -eq $semester ]]; then 
		
			printSem "$line"
		fi
	done<"$filename"

}

# function to calculate average for a specefic semester
calcSemsAverage() {

	 line=$1 # line is passes as first parameter
	 average=$2 # average is passed as second parameter (0 is passed and the value is changed in the function)
	
	 sum=0
	 hours=0
	 
 	marks=$(cut -d';' -f2 <<< "$line" | sed 's/FA/50/g' | sed 's/F/55/g')
 	
 	noOfMarks=$(echo $line | tr ',' '\12' | wc -l)
 	
 	# loop through the marks and calculate hours and total points 
	for ((i = 1; i <= noOfMarks; ++i)); do
	
		grade="$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f3)"
		code="$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f2)"
		
		
		if [[ $grade != "I" ]]; then 
			hours=$((hours+${code:5:1}))
		fi 
			
		if [[ $grade == "I" ]]; then
			:
		else
			sum=$((sum+(grade*${code:5:1})))
		fi
	
	done 
	# calculate the average of the courses
	average="$(echo "$sum / $hours" | bc -l)"
}
# calculate average for each semester 
calAverageForEachSem() {

	printf "\n%-20s%-20s\n" "SEMESTER" "AVERAGE"
	while read -r line; do 
	
		calcSemsAverage "$line" "$average"
		printf "%-20s%-20.3f\n" "$(cut -d";" -f1 <<< "$line")" "$average"
	
	done<"$filename"
}




passedHours() {


	passed=0
	declare -A arr
	
	while read -r line; do 
	
		local marks
		marks=$(cut -d';' -f2 <<< "$line")
		noOfMarks=$(echo $line | tr ',' '\12' | wc -l)
		for ((i = 1; i <=noOfMarks; ++i)); do
		
			grade="$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f3)"
			code="$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f2)"
			
			if [ "$grade" != "I" ] && [ "$grade" != "FA" ] && [ "$grade" != "F" ]; then  
				arr[$code]=$grade	
				
			fi

		done 
	
	done<"$filename"
	
	for key in "${!arr[@]}"; do 
		hour=${key:5:1}
		passed=$((passed+hour))
	done
	
	echo -ne "$passed\n"
	
}

# calculate average of all semesters 
totalAvg() {

	declare -A arr
	
	while read -r line; do 
	
		local marks
		marks=$(cut -d';' -f2 <<< "$line" | sed 's/FA/50/g' | sed 's/F/55/g')
		noOfMarks=$(echo $line | tr ',' '\12' | wc -l)
		for ((i = 1; i <=noOfMarks; i++)); do
			grade="$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f3)"
			code="$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f2)"
			
			if [[ "$grade" != "I" ]]; then 
			
				arr[$code]=$grade
			fi
			
			
		done
	
	done<"$filename"


 	local sum=0
	local hours=0
	
	for key in "${!arr[@]}"; do
		hour="${key:5:6}"
		sum=$((sum+(arr[$key]*hour)))
		hours=$((hours+hour))
	done	
	local avg
	avg=$(echo "$sum / $hours" | bc -l)  	
	echo "$avg"
}


percentagePassed() {

	declare -A arr
	local passed=0
	local all=0
	
	
	while read -r line; do 
	
		local marks
		marks=$(cut -d';' -f2 <<< "$line")
		noOfMarks=$(echo $line | tr ',' '\12' | wc -l)
		for ((i = 1; i <=noOfMarks; i++)); do
		
			grade="$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f3)"
			code="$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f2)"
		
			if [[ $grade != "I" ]]; then
				arr[$code]=$grade
			fi
			
		done
	done<"$filename"
	
	
	for key in "${!arr[@]}"; do
		hour=${key:5:1}
		all=$((all+hour))
		grade=${arr[$key]}
		
		if [ "$grade" != "F" ] && [ "$grade" != "FA" ]; then
			passed=$((passed+hour))
		fi
		
	done
	
	printf "\npercentage of passed hours = %.3f\n\n" "$(bc -l <<<"$passed / $all")"
}


hoursTakenEachSem() {

	printf "%-20s%-20s\n" "SEMESTER" "HOURS"
	while read -r line; do 
	
	hours=0
	local marks
	marks=$(cut -d';' -f2 <<< "$line")
	noOfMarks=$(echo $line | tr ',' '\12' | wc -l)
	for ((i = 1; i <=noOfMarks; i++)); do
		code="$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f2)"
		hours=$((hours+${code:5:1}))
	done
	
	local sem
	sem=$(cut -d';' -f1 <<<"$line")
	
	
	printf "%-20s%-20d\n" "$sem" "$hours"	
	
	
	done<"$filename"
}


totalCoursesTaken() {


	declare -A arr
	
	local total=0
	
	while read -r line; do 
	
		local marks
		marks=$(cut -d';' -f2 <<< "$line")
		noOfMarks=$(echo $line | tr ',' '\12' | wc -l)
		for ((i = 1; i <=noOfMarks; i++)); do
			code="$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f2)"
			arr[$code]=$grade
		done
	done<"$filename"


	for key in "${!arr[@]}"; do
		total=$((total+1))
	done

	printf "Total courses taken is %d\n" "$total"
}

# total number of labs taken (second number in course code is 1 which is the number of hours)
totalLabsTaken() {

	declare -A arr
		
	local total=0
	
	while read -r line; do 
	
		local marks
		marks=$(cut -d';' -f2 <<< "$line")
		noOfMarks=$(echo $line | tr ',' '\12' | wc -l)
		for ((i = 1; i <=noOfMarks; i++)); do
			code="$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f2)"
			arr[$code]=$grade
		done
	done<"$filename"


	for key in "${!arr[@]}"; do
		hour=${key:5:1}
		if [[ $hour -eq 1 ]]; then
			total=$((total+1))
		fi 
	done

	printf "Total LAB's taken is %d\n" "$total"

}
# insert new semester record 
insertNew() {

	read -p 'Please enter year/semester. e.g. 2021-2022/1: ' year_sem
	
	y1=$(cut -d'-' -f1 <<< $year_sem)
	y2=$(cut -d'-' -f2 <<< $year_sem | cut -d'/' -f1)
	# s must be 1, 2 or 3 for 1st, 2nd or summer semester respectively 
	s=$(cut -d'/' -f2 <<< $year_sem)  
	
	# difference between year1 and year2 in semester e.g. 2021-2022, it should be one always. 
	diff=$((y2-y1)) 
	
	# check if record already exists in file 
	found=$(grep $year_sem $filename) 
	
	while [[ $diff != "1" ]] || [[ $s -gt 3 ]] || [[ $s -lt 1 ]] || [[ ! -z "$found" ]]; do 
	
		echo -ne $red"\nError in semester,$underline_red please enter semester in this format: YEAR-YEAR+1/SEM, where sem is 1,2 or 3.$reset Make sure that the semester is not already in the file.\n"$reset
		
		read -p "Semester: " year_sem
		
		y1=$(cut -d'-' -f1 <<< $year_sem)
		y2=$(cut -d'-' -f2 <<< $year_sem | cut -d'/' -f1)
		s=$(cut -d'-' -f2 <<< $year_sem | cut -d'/' -f2)
		
		diff=$((y2-y1))
		
		found=$(grep $year_sem $filename)
		
	done
	
	
	while true; do 
	
	
	local hours
	hours=0
	flag=0
	
		read -p "Enter course_1 grade_1, course_2 grade_2..., course_n grade_n:  " record
		
		noOfMarks=$(echo $record | tr ',' '\12' | wc -l)
		
		
		line=$(sed 's/, /,/g' <<< "$record")
	
		for ((i=1; i<=noOfMarks; i++)); do 
		
			code=$(cut -d',' -f$i <<< "$line" | cut -d' ' -f1)
			grade=$(cut -d',' -f$i <<< "$line" | cut -d' ' -f2)
			dep=$(tr -dc '[A-Za-z]' <<< "$code")
			num=$(tr -dc '[0-9]' <<< "$code")
			
			
			
		
			if [[ "$dep" != "ENEE" ]] && [[ "$dep" != "ENCS" ]] || [[ $num -gt 5999 ]] || [[ $num -lt 2000 ]] || [[ $grade -lt 60 ]] 				|| [[ $grade -gt 99 ]] && [[ "$grade" != "F" ]] && [[ "$grade" != "FA" ]] && [[ "$grade" != "I" ]]; then
			
				echo -ne $red"Invalid record format, please enter valid record"$reset
				flag=1		
				break
			fi 
			
			
			hours=$((hours+${code:5:1}))
	
		done 

		
		if [[ $s -lt 3 ]] && [[ $hours -lt 12 ]] || [[ $hours -gt 18 ]]; then 
		
			echo -ne $red"Invalid number of hours, please enter courses with at least 12 hours and not more than 18\n"$reset 
			flag=1
			continue
		
		elif [[ $s -eq 3 ]] && [[ $hours -gt 12 ]]; then 
			echo -ne $red"Invalid number of hours, please enter courses with at most 12 hours (summer semester).\n"$reset
			flag=1
			continue
		fi
		
		if [[ $flag -eq 0 ]]; then 
		
			echo "$year_sem; $record" >> "$filename"
			echo -ne $green"\ninserted record succesfuly\n"$reset
			break
		fi
	done 
	
}
# change mark of a specefic course 
changeMark() {

	read -p "Enter course code: " code
	
	declare -A arr
	
	while read -r line; do 
	
		marks=$(cut -d';' -f2 <<< "$line")
		noOfMarks=$(echo $line | tr ',' '\12' | wc -l)
		for ((i = 1; i <=noOfMarks; i++)); do 
		
			course=$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f2)
			grade=$(cut -d',' -f$i <<<"$marks" | cut -d' ' -f3)
			
			arr[$course]=$grade
		
		done
	done<"$filename" 

	local mark=0
	
	for key in "${!arr[@]}"; do
	
		if [[ "$key" == "$code" ]]; then 
			mark=${arr[$key]}
		fi
	done
	
	if [[ $mark -eq 0 ]]; then 
	
		echo -ne "No such corse code\n"
		sleep 2
	
	else
		read -p "Please Enter new mark\: " newMark
		
		while  ! { [ $newMark -le 99 ] && [ $newMark -ge 60 ] || [ $newMark == "F" ] || [ $newMark == "FA" ] || [ $newMark == 					"I" ]; } do 
		
			echo -ne "$red""Please enter a valid grade: ""$reset"
			read -r newMark
		done
		
		
		echo -ne '\e[32m'"Do you want to change the mark from $mark to $newMark (y/n): "'\e[0m'
		
		read -r ans 
		
		if [[ $ans == y ]]; then 
			tr "$mark" "$newMark" < "$filename"
			echo -ne "\ndone\n" 
			break 
		fi
	
	fi
}



while true; do 
	printMenu
	read -p "please enter your choice: " choice
	
	case $choice in 
	
		1)
		printAllSems
		;;
		
		2)
		printSpecificSems
		;;
		
		3)
		totalAvg
		;;
		
		4)
		calAverageForEachSem
		;;
		
		5)
		passedHours
		;;
		
		6)
		percentagePassed
		;;
		
		7)
		hoursTakenEachSem
		;;
		
		8)
		totalCoursesTaken
		;;
		
		9)
		totalLabsTaken
		;;
		
		10)
		insertNew
		;;
		
		11)
		changeMark
		;;
		
		0)
		echo -ne $red"\nEXITED\n"$reset
		exit 0
		;;
		
		*)
		echo -ne $underline_red"\nPlease enter a valid choice\n"$reset
		;;

		esac
	done 
