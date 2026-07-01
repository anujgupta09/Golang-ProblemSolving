/*
10. [Write a function to find if a number is a palindrome or not. Take number as parameter.]
(https://www.geeksforgeeks.org/check-if-a-number-is-palindrome/)
*/

package main

import "fmt"

///////////////////// mian //////////////////////////////
func main() {
	var num string
	fmt.Scan(&num)
	if palindrome(num) == true {
		fmt.Println("Palindrome")
	} else {
		fmt.Println("Not Palindrome")
	}
}

///////////////////// palindrome ////////////////////////
func palindrome(num string) bool {
	var palindrome bool = true
	for i := 0; i < len(num); i++ {
		if num[i] != num[(len(num)-1)-i] {
			palindrome = false
		}
	}
	return palindrome
}
