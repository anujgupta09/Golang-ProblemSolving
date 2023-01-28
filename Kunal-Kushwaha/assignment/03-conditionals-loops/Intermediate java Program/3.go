// 3. Calculate Average Of N Numbers
package main

import (
	"fmt"
	"strconv"
)

func main() {

	var numArray []float32 = []float32{} //declaring slice
	var eleString string
	eleInt, err := strconv.Atoi(eleString)
	var count int = 0

	for {
		count += 1
		fmt.Print("Enter '", count, "' number ", " : ")
		fmt.Println("Type 'exit' to stop")
		fmt.Scan(&eleString)
		if eleString == "exit" { //to control exit from user i/p
			break
		}
		if err != nil {
			fmt.Println("Err : ", err)
		}
		numArray = append(numArray, float32(eleInt))
	}
	fmt.Println("Array : ", numArray, " ||  length : ", len(numArray))
	var sum float32 = 0
	var lengthOfn float32 = float32(len(numArray))
	var i float32
	for i = 0; i < lengthOfn; i++ {
		sum += numArray[int(i)]
	}
	fmt.Println("\nAverage of all '", lengthOfn, "' numbers is  ", sum/lengthOfn)
}
