// 17. Find if a number is palindrome or not

package main

import (
	"fmt"
	"strconv"
)

func main() {
	var number = 1000
	var lenNumber = len(strconv.Itoa(number))
	var sum int
	for i := 0; i <= lenNumber; i++ {
		digit := number % 10
		var digitPow int
		for i := 1; i <= lenNumber; i++ {
			digitPow *= digit
		}
		sum += digitPow
	}
	if sum == number {
		fmt.Println("Palindrome")
	} else {
		fmt.Println("Not Palindrome")
	}
}
