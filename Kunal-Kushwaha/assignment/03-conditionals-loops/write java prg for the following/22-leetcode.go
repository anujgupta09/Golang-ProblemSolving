package main

import "fmt"

func main() {
	fmt.Println(subtractProductAndSum(234))
}

func subtractProductAndSum(n int) int {

	var product = 1
	var sum = 0

	for n > 0 {
		digit := n % 10
		n = n / 10
		product *= digit
		sum += digit
	}
	return (product - sum)
}
