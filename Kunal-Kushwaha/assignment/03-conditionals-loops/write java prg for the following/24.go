// 24. Take integer inputs till the user enters 0 and print the sum of all numbers (HINT: while loop)

package main

import "fmt"

func main() {
	var n int
	var sum = 0
	for {
		fmt.Scan(&n)
		if n == 0 {
			break
		}
		sum += n
	}
	fmt.Println("total Sum is : ", sum)
}
