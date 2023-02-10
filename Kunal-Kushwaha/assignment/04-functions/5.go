// 5. [Define a method that returns the product of two numbers entered by user.](https://code4coding.com/java-program-to-multiply-two-numbers-using-method/)4444

package main

import "fmt"

func main() {
	var num1, num2 int
	fmt.Scan(&num1, &num2)
	fmt.Println(productOfTwo(num1, num2))
}
func productOfTwo(num1 int, num2 int) int {
	return num1 * num2
}
