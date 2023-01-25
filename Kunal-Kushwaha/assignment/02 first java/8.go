// 8. To find out whether the given String is Palindrome or not.

package main

import "fmt"

func main() {

	var string1 string
	fmt.Scan(&string1)
	len := len(string1) - 1
	isPalindrome := true

	for i := 0; i <= len/2; i++ {
		if string1[i] != string1[len-i] {
			isPalindrome = false
		}
	}

	fmt.Println(isPalindrome)
}
