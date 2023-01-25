// 5. Take 2 numbers as input and print the largest number.

package main

import "fmt"

func main() {
	var num1, num2 int
	fmt.Println("enter 1st num")
	fmt.Scan(&num1)
	fmt.Println("enter 2nd num")
	fmt.Scan(&num2)

	fmt.Printf(" \n num1 = %d \n num2 = %d \n", num1, num2)

	if num1 > num2 {
		fmt.Println("\n num1 is largest")
	} else {
		fmt.Println("\n num2 is largest")
	}
}
