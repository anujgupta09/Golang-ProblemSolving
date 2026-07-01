// Input a year and find whether it is a leap year or not

package main

import (
	"fmt"
)

func main() {
	fmt.Println("'ANUJ SHIVSHANKAR GUPTA' IS THE BEST")
	var year int

	fmt.Scan(&year)
	fmt.Println(year)
	fmt.Println(year % 4)

	if year%4 == 0 {
		fmt.Println("It's a leap year ")
	} else {
		fmt.Println("It's not a leap year")
	}
}
