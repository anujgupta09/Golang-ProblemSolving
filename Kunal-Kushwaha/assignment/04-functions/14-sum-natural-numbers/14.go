/*
14. [Write a function that returns the sum of first n natural numbers.]
(https://www.geeksforgeeks.org/program-find-sum-first-n-natural-numbers/)
*/

package main

import "fmt"

func main() {
	var n int
	fmt.Print("Give nth  natural number upto which sum needs to be calculated : ")
	fmt.Scan(&n)
	sum := sumOfN(n)
	fmt.Println("Sum of all the natural number upto nth number : ", sum)
}
func sumOfN(n int) int {
	var sum = 0
	for i := 1; i <= n; i++ {
		sum += i
	}
	return sum
}
