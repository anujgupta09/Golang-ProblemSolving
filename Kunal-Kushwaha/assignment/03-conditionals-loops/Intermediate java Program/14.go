// 14. Armstrong Number In Java

package main

import (
	"fmt"
	"strconv"
)

func main() {

	var n int
	fmt.Scan(&n)
	var nbk = n                       // to compare at last
	var lenn = len(strconv.Itoa(nbk)) // to find how many times we have to power
	fmt.Println(lenn)
	var sum = 0

	for n > 0 {

		fmt.Println(n)
		digit := n % 10
		var digitProduct = 1 // to mul digit poperly
		fmt.Println("Digit: ", digit)
		n /= 10

		for i := 1; i <= lenn; i++ {
			digitProduct *= digit // keeping digit same and updating digitProduct
			fmt.Println("here : ", digitProduct)
		}

		sum += digitProduct
		fmt.Println("sum : ", sum)
	}

	if sum == nbk {
		fmt.Println("ArmStrong number", sum, nbk)
	} else {
		fmt.Println("Not armstrong number", sum, nbk)
	}
}
