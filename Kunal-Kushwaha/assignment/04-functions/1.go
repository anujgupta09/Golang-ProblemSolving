// Define two methods to print the maximum and the minimum number respectively among three numbers entered by the user.

package main

import "fmt"

func main() {
	var num1, num2, num3 int
	fmt.Scan(&num1, &num2, &num3)

	fmt.Print("Largest num : ")
	fmt.Println(largest(num1, num2, num3))

	fmt.Print("Smallest num is : ")
	fmt.Println(smallest(num1, num2, num3))
}

func largest(num1 int, num2 int, num3 int) int {
	var largestNum = num1

	if num2 > largestNum {
		largestNum = num2
	}
	if num3 > largestNum {
		largestNum = num3
	}
	return largestNum
}
func smallest(num1 int, num2 int, num3 int) int {
	var smallest = num1
	if num2 < smallest {
		smallest = num2
	}
	if num3 < smallest {
		num3 = smallest
	}
	return smallest
}
