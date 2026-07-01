// 3. Take a number as input and print the multiplication table for it.

package main

import "fmt"

func main() {
	var number int
	fmt.Scanln(&number)
	fmt.Println("")
	for i := 1; i <= 10; i++ {
		fmt.Printf("%d * %d  = %d \n", number, i, number*i)
	}
}
