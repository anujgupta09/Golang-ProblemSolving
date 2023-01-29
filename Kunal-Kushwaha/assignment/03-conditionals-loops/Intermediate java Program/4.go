// 4. Calculate Discount Of Product

package main

import "fmt"

func main() {
	var priceOfProduct, discountInPercent int
	fmt.Print("Enter Amount of Pruduct and Discount in Percent : ")
	fmt.Scan(&priceOfProduct, &discountInPercent)

	discountOnProduct := priceOfProduct * discountInPercent / 100
	discountedPriceOfProduct := priceOfProduct - discountOnProduct

	fmt.Println("Discounted price : ", discountedPriceOfProduct, "|| Discount applied : ", discountOnProduct)
}
