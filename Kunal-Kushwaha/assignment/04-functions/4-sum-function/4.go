// 4. [Write a program to print the sum of two numbers
//  entered by user by defining your own method.]
// (https://code4coding.com/addition-of-two-numbers-in-java-using-method/)

package main

import "fmt"

func main() {
	var num1, num2 int
	fmt.Scan(&num1, &num2)
	fmt.Println(sumOfTwo(num1, num2))
}
func sumOfTwo(num1, num2 int) int {
	return num1 + num2
}
