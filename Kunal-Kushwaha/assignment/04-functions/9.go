// 9. [Write a program to print the factorial of a number by defining a method named 'Factorial'.]
// (https://www.javatpofloat.com/factorial-program-in-java)

package main

import (
	"fmt"
	"math/big"
)

func main() {
	var num int
	fmt.Scan(&num)
	factorial := factorial(num)
	fmt.Println(factorial)
}
func factorial(num int) *big.Int {
	var fact *big.Int
	// var i int64
	for i := 1; i <= num; i++ {
		fact *= i
	}
	return fact
}
