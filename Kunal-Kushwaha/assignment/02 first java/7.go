// 7. To calculate Fibonacci Series up to n numbers.

package main

import (
	"fmt"
)

func main() {
	var numP = 1
	var numC = 1
	var n int
	fmt.Println("Enter nth number")
	fmt.Scan(&n)
	for i := 3; i <= n; i++ {
		fmt.Println(i)
		numTemp := numC
		numC = numP + numC
		numP = numTemp
	}
	fmt.Println(numC)
}
