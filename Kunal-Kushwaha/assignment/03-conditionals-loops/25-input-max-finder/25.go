// 25. Take integer inputs till the user enters 0 and print the largest number from all.

package main

import "fmt"

func main() {
	var n int
	var largest = 0
	for {
		fmt.Scan(&n)
		if n == 0 {
			break
		}
		if n > largest {
			largest = n
		}
	}
	fmt.Println("Largest number is ''", largest, "''")
}
