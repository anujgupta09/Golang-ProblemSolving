// 2. [Define a program to find out whether a given number is even or odd.]
// (https://www.geeksforgeeks.org/java-program-to-check-if-a-given-integer-is-odd-or-even/)

package main

import "fmt"

func main() {
	var num int
	fmt.Scan(&num)
	fmt.Print(oddOrEven(num))
}
func oddOrEven(num int) string {
	if num%2 == 0 {
		return "even"
	} else {
		return "odd"
	}
}
