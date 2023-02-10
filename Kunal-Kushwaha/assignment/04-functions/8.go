// 8. [Write a program that will ask the user to enter his/her marks (out of 100). Define a method that will display grades according to the marks entered as below:](https://www.techcrashcourse.com/2017/02/java-program-to-calculate-grade-of-students.html) <br/>

/*
Marks        Grade
91-100         AA
81-90          AB
71-80          BB
61-70          BC
51-60          CD
41-50          DD
<=40          Fail
*/

package main

import (
	"fmt"
	"strconv"
)

func main() {
	var array []int = []int{}
	var num string
	for {
		fmt.Scan(&num)
		if num == "exit" {
			break
		}
		intNum, err := strconv.Atoi(num)
		if intNum > 100 || intNum < 0 {
			fmt.Println("Invalid i/p wantedd between 0 to 100 oonly...")
			continue // continue from the start with out breaking looop
		}
		if err != nil {
			fmt.Println("Error  >>>  ", err)
		}
		array = append(array, intNum)
	}
	var grade string
	fmt.Println("Marks  Grade")
	for i := 0; i < len(array); i++ {
		switch {
		case array[i] <= 40:
			grade = "FAIL"
			// fmt.Println("Marks: ", array[i], " Grade : FAIL")
		case array[i] >= 41 && array[i] <= 50:
			grade = "DD"
			// fmt.Println("Marks: ", array[i], " Grade : DD...")
		case array[i] >= 51 && array[i] <= 60:
			grade = "CD"
			// fmt.Println("Marks: ", array[i], " Grade : CD...")
		case array[i] >= 61 && array[i] <= 70:
			grade = "BD"
			// fmt.Println("Marks: ", array[i], " Grade : BD...")
		case array[i] >= 71 && array[i] <= 80:
			grade = "BB"
			// fmt.Println("Marks: ", array[i], " Grade : BB...")
		case array[i] >= 81 && array[i] <= 90:
			grade = "AB"
			// fmt.Println("Marks: ", array[i], " Grade : AB...")
		case array[i] >= 91 && array[i] <= 100:
			grade = "AA"
			// fmt.Println("Marks: ", array[i], " Grade : AA...")
		}
		fmt.Println(array[i], "     ", grade)
	}
}
