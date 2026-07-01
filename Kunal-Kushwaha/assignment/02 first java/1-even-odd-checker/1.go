// 1. Write a program to print whether a number is even or odd, also take input from the user.

package main

import "fmt"

func main() {
	var num int
	fmt.Scan(&num)
	if num%2 == 0 {
		fmt.Println("Even")
	} else {
		fmt.Println("Odd")
	}
}
