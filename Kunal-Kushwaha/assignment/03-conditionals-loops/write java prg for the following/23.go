// 23. Input a number and print all the factors of that number (use loops).

package main

import "fmt"

func main() {
	var n int
	fmt.Print("Enter number : ")
	fmt.Scan(&n)
	var array []int

	for i := 2; i < n; i++ {
		if n%i == 0 {
			array = append(array, i)
		}
	}
	fmt.Println(array)
}
