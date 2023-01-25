// 6. Input currency in rupees and output in USD.

package main

import "fmt"

func main() {
	var amountInRupees int
	fmt.Println("Enter Amount in Rupees")
	fmt.Scan(&amountInRupees)
	var USD int
	USD = amountInRupees / 82
	fmt.Println("AMOUNT in USD :", USD)
}
