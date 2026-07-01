/*
12. [Write a function to check if a given triplet is a Pythagorean triplet or not.]
(https://www.geeksforgeeks.org/find-pythagorean-triplet-in-an-unsorted-array/)
(A Pythagorean triplet is when the sum of the square of two numbers is equal to the
square of the third number).
*/

package main

import "fmt"

func main() {
	var a, b, c int
	fmt.Scan(&a, &b, &c)
	if pythagorasTriplet(a, b, c) == true {
		fmt.Println("Pythagoras Triplet")
	} else {
		fmt.Println("Not a Pythagoras Triplet")
	}
}
func pythagorasTriplet(a, b, c int) bool {
	if a*a+b*b == c*c {
		return true
	} else {
		return false
	}
}
