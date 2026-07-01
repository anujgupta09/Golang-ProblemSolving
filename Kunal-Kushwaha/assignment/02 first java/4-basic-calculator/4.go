// 4. Take in two numbers and an operator (+, -, *, /) and calculate the value. (Use if conditions)

package main

import "fmt"

func main() {

	var num1, num2 int
	var operator string
	fmt.Scan(&num1)
	fmt.Scan(&num2)
	fmt.Scan(&operator)

	if operator == "+" {
		fmt.Println(num1 + num2)
	} else if operator == "-" {
		fmt.Println(num1 - num2)
	} else if operator == "*" {
		fmt.Println(num1 * num2)
	} else if operator == "/" {
		fmt.Println(num1 / num2)
	} else {
		fmt.Println("Wrong Input .... try again ")
	}
}
